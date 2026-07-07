#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[2]
REQUIRED = [
    "data/ai/asset_pipeline_models_v01.json",
    "data/ai/asset_manifest_v01.json",
    "prompts/ai_asset_generation/PIXEL_ART_CHARACTER_PROMPTS.md",
    "prompts/ai_asset_generation/ARENA_AUDIO_VIDEO_PROMPTS.md",
    "tools/ai_asset_pipeline/build_generation_queue.py",
    "tools/ai_asset_pipeline/generate_image_assets.py",
]


def read_json(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    errors: List[str] = []
    for rel in REQUIRED:
        if not (ROOT / rel).exists():
            errors.append(f"Arquivo ausente: {rel}")
    manifest_path = ROOT / "data/ai/asset_manifest_v01.json"
    if manifest_path.exists():
        manifest = read_json(manifest_path)
        if "ruan_macacao" not in manifest.get("characters", {}):
            errors.append("Manifesto sem ruan_macacao")
        if not manifest.get("arenas"):
            errors.append("Manifesto sem arenas")
        if not manifest.get("audio", {}).get("sfx"):
            errors.append("Manifesto sem SFX")
    report = {"ok": not errors, "errors": errors}
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
