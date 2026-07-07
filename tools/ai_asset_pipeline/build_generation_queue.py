#!/usr/bin/env python3
"""Build a generation queue for Cria do Tatame assets.

This script does not call external APIs. It reads the asset manifest and writes
JSONL task files that can be consumed by ComfyUI, Diffusers scripts, or a manual
production workflow.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, Iterable

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "data" / "ai" / "asset_manifest_v01.json"
OUT_DIR = ROOT / "tools" / "ai_asset_pipeline" / "generated_queue"


def read_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def write_jsonl(path: Path, rows: Iterable[Dict[str, Any]]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", encoding="utf-8") as file:
        for row in rows:
            file.write(json.dumps(row, ensure_ascii=False) + "\n")
            count += 1
    return count


def character_tasks(manifest: Dict[str, Any]) -> Iterable[Dict[str, Any]]:
    for character_id, data in manifest.get("characters", {}).items():
        for action in data.get("actions", []):
            directions = data.get("directions", ["side_right"])
            for direction in directions:
                yield {
                    "type": "character_sprite",
                    "character_id": character_id,
                    "action": action,
                    "direction": direction,
                    "frames": data.get("frames_per_action", 8),
                    "style_anchor": data.get("style_anchor", ""),
                    "output": f"assets/sprites/{character_id}/{character_id}_{action}_{direction}_v01.png",
                }


def arena_tasks(manifest: Dict[str, Any]) -> Iterable[Dict[str, Any]]:
    for arena_id, data in manifest.get("arenas", {}).items():
        for layer in data.get("layers", []):
            yield {
                "type": "arena_layer",
                "arena_id": arena_id,
                "layer": layer,
                "mood": data.get("mood", ""),
                "output": f"assets/backgrounds/{arena_id}/{arena_id}_{layer}.png",
            }


def audio_tasks(manifest: Dict[str, Any]) -> Iterable[Dict[str, Any]]:
    audio = manifest.get("audio", {})
    for track in audio.get("music_tracks", []):
        yield {
            "type": "music_loop",
            "id": track,
            "output": f"assets/audio/music/{track}_loop_v01.ogg",
        }
    for sfx in audio.get("sfx", []):
        yield {
            "type": "sfx",
            "id": sfx,
            "output": f"assets/audio/sfx/{sfx}.wav",
        }


def cutscene_tasks(manifest: Dict[str, Any]) -> Iterable[Dict[str, Any]]:
    for cutscene_id in manifest.get("cutscenes", []):
        yield {
            "type": "cutscene",
            "id": cutscene_id,
            "output": f"assets/videos/cutscenes/{cutscene_id}.mp4",
        }


def main() -> None:
    manifest = read_json(MANIFEST)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    counts = {
        "characters": write_jsonl(OUT_DIR / "characters.jsonl", character_tasks(manifest)),
        "arenas": write_jsonl(OUT_DIR / "arenas.jsonl", arena_tasks(manifest)),
        "audio": write_jsonl(OUT_DIR / "audio.jsonl", audio_tasks(manifest)),
        "cutscenes": write_jsonl(OUT_DIR / "cutscenes.jsonl", cutscene_tasks(manifest)),
    }
    with (OUT_DIR / "summary.json").open("w", encoding="utf-8") as file:
        json.dump(counts, file, ensure_ascii=False, indent=2)
    print(json.dumps(counts, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
