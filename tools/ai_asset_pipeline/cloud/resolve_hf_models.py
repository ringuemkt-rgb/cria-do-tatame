#!/usr/bin/env python3
"""Resolve Hugging Face refs to immutable commit SHAs for one research batch."""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[3]
DEFAULT_REGISTRY = ROOT / "data" / "ai" / "model_registry_v02.json"


class ModelResolutionError(RuntimeError):
    """Raised when a model is unregistered, blocked or changes license metadata."""


def load_registry(path: Path) -> dict[str, Any]:
    """Load and minimally validate the versioned model registry."""

    value = json.loads(path.read_text(encoding="utf-8"))
    models = value.get("models") if isinstance(value, dict) else None
    if not isinstance(models, list):
        raise ModelResolutionError(f"Registry has no models list: {path}")
    return value


def atomic_write(path: Path, value: dict[str, Any]) -> None:
    """Write a private batch snapshot atomically."""

    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    fd, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def _license_from_info(info: Any) -> str | None:
    card_data = getattr(info, "card_data", None)
    if card_data is None:
        return None
    if isinstance(card_data, dict):
        value = card_data.get("license")
    else:
        value = getattr(card_data, "license", None)
    return str(value) if value else None


def resolve_models(
    registry: dict[str, Any],
    requested_ids: list[str],
    allow_research: bool,
) -> list[dict[str, Any]]:
    """Resolve selected model refs while enforcing adoption and license gates."""

    try:
        from huggingface_hub import HfApi
    except ImportError as exc:
        raise ModelResolutionError(
            "huggingface_hub is missing; install requirements-colab.txt"
        ) from exc

    by_id = {str(item.get("id")): item for item in registry["models"]}
    missing = sorted(set(requested_ids) - set(by_id))
    if missing:
        raise ModelResolutionError(f"Models are not registered: {', '.join(missing)}")
    api = HfApi(token=os.environ.get("HF_TOKEN"))
    resolved: list[dict[str, Any]] = []
    for model_id in requested_ids:
        entry = by_id[model_id]
        status = entry.get("adoption_status")
        if status == "research_only" and not allow_research:
            raise ModelResolutionError(
                f"{model_id} is research_only; pass --allow-research for non-shipping experiments"
            )
        if status != "research_only" and status != "candidate_generation_allowed":
            raise ModelResolutionError(f"{model_id} is blocked by adoption_status={status!r}")
        requested_ref = str(entry.get("requested_ref") or "main")
        info = api.model_info(model_id, revision=requested_ref, files_metadata=False)
        commit_sha = str(getattr(info, "sha", "") or "")
        if len(commit_sha) < 12:
            raise ModelResolutionError(f"Hugging Face returned no immutable SHA for {model_id}")
        live_license = _license_from_info(info)
        recorded_license = entry.get("license")
        if live_license and recorded_license and live_license != recorded_license:
            raise ModelResolutionError(
                f"License metadata changed for {model_id}: registry={recorded_license}, hub={live_license}"
            )
        resolved.append(
            {
                "id": model_id,
                "requested_ref": requested_ref,
                "resolved_revision": commit_sha,
                "license": live_license or recorded_license or "unverified",
                "adoption_status": status,
                "source_url": f"https://huggingface.co/{model_id}/tree/{commit_sha}",
            }
        )
    return resolved


def build_parser() -> argparse.ArgumentParser:
    """Build command-line arguments."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--model", action="append", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--allow-research", action="store_true")
    return parser


def run(argv: Iterable[str] | None = None) -> int:
    """Resolve models and persist a session snapshot."""

    args = build_parser().parse_args(list(argv) if argv is not None else None)
    registry = load_registry(args.registry)
    models = resolve_models(registry, args.model, args.allow_research)
    snapshot = {
        "schema_version": 1,
        "registry_contract": registry.get("contract_id"),
        "resolved_at": datetime.now(timezone.utc).isoformat(),
        "models": models,
        "shipping_approval": False,
        "purpose": "offline_candidate_research",
    }
    atomic_write(args.output, snapshot)
    print(json.dumps({"ok": True, "output": str(args.output), "models": models}, ensure_ascii=False, indent=2))
    return 0


def main() -> int:
    """CLI entrypoint."""

    try:
        return run()
    except (ModelResolutionError, OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"Hugging Face resolution error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
