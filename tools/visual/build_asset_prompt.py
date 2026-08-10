#!/usr/bin/env python3
"""Build a candidate-generation prompt from the canonical visual protocol.

This tool makes prompts repeatable; it does not certify visual fidelity or
promote generated output into shipping paths.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
PROTOCOL_PATH = ROOT / "data" / "visual" / "visual_gameplay_protocol_v01.json"
BRIEFS_PATH = ROOT / "data" / "visual" / "vertical_slice_asset_briefs_v01.json"


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain an object")
    return value


def get_brief(brief_id: str) -> dict[str, Any]:
    for brief in load_json(BRIEFS_PATH).get("briefs", []):
        if isinstance(brief, dict) and brief.get("id") == brief_id:
            return brief
    raise ValueError(f"unknown visual brief: {brief_id}")


def build_prompt(brief: dict[str, Any]) -> dict[str, Any]:
    protocol = load_json(PROTOCOL_PATH)
    style = protocol.get("house_style", {})
    palette = style.get("palette", {})
    resolved_palette = {
        token: f"#{palette[token]}"
        for token in brief.get("palette_tokens", [])
        if token in palette
    }
    references = {
        item.get("id"): item.get("role")
        for item in protocol.get("reference_board", [])
        if isinstance(item, dict)
    }
    reference_roles = [references[item] for item in brief.get("reference_ids", []) if item in references]
    positive = ", ".join(
        [
            str(brief.get("subject", "")),
            str(style.get("name", "HD Pixel Art 2.5D Regional Premium")),
            "Brazilian Jiu-Jitsu positional grappling",
            "Baixo Sul da Bahia",
            "crisp intentional pixel clusters",
            "one-pixel dark outline",
            "nearest-neighbor runtime export",
            "single top-left lighting direction",
            "clear silhouette and quiet playfield center",
            f"target resolution {brief.get('resolution', [1280, 720])[0]}x{brief.get('resolution', [1280, 720])[1]}",
            "palette " + ", ".join(f"{key} {value}" for key, value in resolved_palette.items()),
            "reference roles " + ", ".join(reference_roles),
            "safe zones " + ", ".join(brief.get("safe_zones", [])),
        ]
    )
    negative = ", ".join(
        [
            "anti-alias blur",
            "smooth vector art",
            "photorealism",
            "3D render",
            "watermark",
            "baked UI text",
            *[str(item).replace("_", " ") for item in brief.get("forbidden", [])],
        ]
    )
    return {
        "brief_id": brief.get("id"),
        "status": "candidate_prompt_only",
        "positive_prompt": positive,
        "negative_prompt": negative,
        "required_review": brief.get("required_review", []),
        "promotion_allowed": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("brief_id")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    payload = build_prompt(get_brief(args.brief_id))
    serialized = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(serialized, encoding="utf-8")
        print(f"[visual-prompt] wrote candidate prompt: {args.output}")
    else:
        print(serialized, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
