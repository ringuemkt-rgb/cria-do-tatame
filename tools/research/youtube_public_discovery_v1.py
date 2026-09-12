#!/usr/bin/env python3
"""Official-API YouTube discovery adapter for CRIA Public Video Intelligence V1.

Uses only YouTube Data API search/video metadata endpoints. It never downloads
video/audio/captions and never claims visual observation from metadata.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
PLANNER = ROOT / "tools/research/plan_public_video_research_v1.py"
API_BASE = "https://www.googleapis.com/youtube/v3"


def api_get(endpoint: str, params: dict[str, Any], api_key: str, timeout: float = 20.0) -> dict[str, Any]:
    query = dict(params)
    query["key"] = api_key
    url = f"{API_BASE}/{endpoint}?{urllib.parse.urlencode(query)}"
    request = urllib.request.Request(url, headers={"User-Agent": "cria-do-tatame-public-video-intelligence/1.0"})
    with urllib.request.urlopen(request, timeout=timeout) as response:  # noqa: S310 - fixed Google API host
        payload = json.loads(response.read().decode("utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("YouTube API response root must be object")
    return payload


def planned_queries(limit: int) -> list[str]:
    proc = subprocess.run(
        [sys.executable, str(PLANNER), "--limit", str(limit), "--json"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    report = json.loads(proc.stdout)
    out: list[str] = []
    seen: set[str] = set()
    for target in report.get("next_targets", []):
        for query in target.get("queries", []):
            if isinstance(query, str) and query and query not in seen:
                seen.add(query)
                out.append(query)
    return out


def search_request(query: str, max_results: int, region: str, language: str, creative_commons_only: bool) -> dict[str, Any]:
    params: dict[str, Any] = {
        "part": "snippet",
        "type": "video",
        "q": query,
        "maxResults": max(1, min(max_results, 50)),
        "regionCode": region,
        "relevanceLanguage": language,
        "videoEmbeddable": "true",
    }
    if creative_commons_only:
        params["videoLicense"] = "creativeCommon"
    return params


def details_request(ids: list[str]) -> dict[str, Any]:
    return {
        "part": "snippet,contentDetails,statistics,status",
        "id": ",".join(ids),
    }


def normalize_video(item: dict[str, Any], discovered_by: list[str]) -> dict[str, Any]:
    vid = str(item.get("id", ""))
    snippet = item.get("snippet", {}) if isinstance(item.get("snippet"), dict) else {}
    details = item.get("contentDetails", {}) if isinstance(item.get("contentDetails"), dict) else {}
    stats = item.get("statistics", {}) if isinstance(item.get("statistics"), dict) else {}
    status = item.get("status", {}) if isinstance(item.get("status"), dict) else {}
    license_value = status.get("license")
    rights_hint = "OPEN_LICENSE_CANDIDATE_REQUIRES_REVIEW" if license_value == "creativeCommon" else "PUBLIC_REFERENCE_RIGHTS_UNRESOLVED"
    return {
        "source_id": f"youtube:{vid}",
        "platform": "youtube",
        "video_id": vid,
        "source_locator": f"https://www.youtube.com/watch?v={vid}",
        "title": snippet.get("title"),
        "publisher_or_channel": snippet.get("channelTitle"),
        "channel_id": snippet.get("channelId"),
        "published_at": snippet.get("publishedAt"),
        "description": snippet.get("description"),
        "duration_iso8601": details.get("duration"),
        "caption_flag": details.get("caption"),
        "declared_license": license_value,
        "embeddable": status.get("embeddable"),
        "privacy_status": status.get("privacyStatus"),
        "view_count": stats.get("viewCount"),
        "like_count": stats.get("likeCount"),
        "comment_count": stats.get("commentCount"),
        "discovered_by": discovered_by,
        "rights_hint": rights_hint,
        "capability_state": "METADATA_READY",
        "evidence_mode": "METADATA_ONLY",
        "visual_observation_claimed": False,
        "caption_text_acquired": False,
        "raw_media_acquired": False,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--query", action="append", default=[])
    ap.add_argument("--plan-targets", type=int, default=4, help="derive queries from this many project targets when --query is omitted")
    ap.add_argument("--max-results", type=int, default=5)
    ap.add_argument("--region", default="BR")
    ap.add_argument("--language", default="pt")
    ap.add_argument("--creative-commons-only", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    queries = [q for q in args.query if q.strip()] or planned_queries(max(1, args.plan_targets))
    query_specs = [search_request(q, args.max_results, args.region, args.language, args.creative_commons_only) for q in queries]

    if args.dry_run:
        print(json.dumps({
            "ok": True,
            "mode": "DRY_RUN_OFFICIAL_API_ONLY",
            "queries": queries,
            "search_requests": query_specs,
            "downloads_media": False,
            "downloads_captions": False,
            "visual_observation_claimed": False,
        }, ensure_ascii=False, indent=2))
        return 0

    api_key = os.environ.get("YOUTUBE_API_KEY", "").strip()
    if not api_key:
        print(json.dumps({
            "ok": True,
            "status": "DISCOVERY_ADAPTER_UNAVAILABLE",
            "reason": "YOUTUBE_API_KEY is not configured in this execution environment",
            "queries_ready": queries,
            "downloads_media": False,
            "downloads_captions": False,
        }, ensure_ascii=False, indent=2))
        return 0

    id_to_queries: dict[str, list[str]] = {}
    api_errors: list[dict[str, str]] = []
    for query, params in zip(queries, query_specs):
        try:
            payload = api_get("search", params, api_key)
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ValueError, json.JSONDecodeError) as exc:
            api_errors.append({"query": query, "error": str(exc)})
            continue
        for item in payload.get("items", []):
            if not isinstance(item, dict):
                continue
            ident = item.get("id", {})
            vid = ident.get("videoId") if isinstance(ident, dict) else None
            if isinstance(vid, str) and vid:
                id_to_queries.setdefault(vid, []).append(query)

    normalized: list[dict[str, Any]] = []
    ids = sorted(id_to_queries)
    for offset in range(0, len(ids), 50):
        batch = ids[offset:offset + 50]
        try:
            details = api_get("videos", details_request(batch), api_key)
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ValueError, json.JSONDecodeError) as exc:
            api_errors.append({"query": "video_details", "error": str(exc)})
            continue
        for item in details.get("items", []):
            if not isinstance(item, dict):
                continue
            vid = str(item.get("id", ""))
            normalized.append(normalize_video(item, id_to_queries.get(vid, [])))

    normalized.sort(key=lambda row: (row.get("title") or "", row.get("video_id") or ""))
    print(json.dumps({
        "ok": True,
        "status": "DISCOVERY_COMPLETE" if normalized else "DISCOVERY_NO_RESULTS",
        "sources": normalized,
        "source_count": len(normalized),
        "errors": api_errors,
        "downloads_media": False,
        "downloads_captions": False,
        "visual_observation_claimed": False,
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
