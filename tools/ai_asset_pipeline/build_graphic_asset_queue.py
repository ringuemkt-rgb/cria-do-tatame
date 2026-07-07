#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, Iterable

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "data" / "visual" / "graphic_asset_catalog_v01.json"
PROMPTS = ROOT / "prompts" / "visual" / "GRAPHIC_ASSET_PROMPTS_MASTER_V01.md"
OUT = ROOT / "tools" / "ai_asset_pipeline" / "generated_queue" / "graphic_asset_queue_v01.jsonl"

GLOBAL_STYLE = "HD Pixel Art 2.5D Regional Premium, Baixo Sul da Bahia, black graphite and burned gold, mobile-readable, no real brands, no long text inside image"


def write_jsonl(rows: Iterable[Dict]) -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with OUT.open("w", encoding="utf-8") as fh:
        for row in rows:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")
            count += 1
    return count


def main() -> int:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    rows = []

    for character in catalog.get("characters", []):
        char_id = character["id"]
        for pose in character.get("set", []):
            rows.append({
                "task_id": f"character::{char_id}::{pose}",
                "type": "character_sprite",
                "target": char_id,
                "variant": pose,
                "prompt": f"{GLOBAL_STYLE}, transparent background sprite, {char_id}, pose {pose}, consistent proportions, game-ready",
                "output_path": f"assets/graphics/characters/{char_id}/{char_id}_{pose}_v01.png"
            })

    for technique in catalog.get("techniques", []):
        tech_id = technique["id"]
        for asset in technique.get("assets", []):
            rows.append({
                "task_id": f"technique::{tech_id}::{asset}",
                "type": "technique_asset",
                "target": tech_id,
                "variant": asset,
                "prompt": f"{GLOBAL_STYLE}, Brazilian jiu-jitsu sport technique {tech_id}, clean safe technical pose, no embedded text, asset type {asset}",
                "output_path": f"assets/graphics/techniques/{tech_id}/{tech_id}_{asset}_v01.png"
            })

    for arena in catalog.get("arenas", []):
        arena_id = arena["id"]
        for layer in arena.get("layers", []):
            rows.append({
                "task_id": f"arena::{arena_id}::{layer}",
                "type": "arena_layer",
                "target": arena_id,
                "variant": layer,
                "prompt": f"{GLOBAL_STYLE}, parallax arena layer {layer}, {arena.get('mood', '')}, no text, game background",
                "output_path": f"assets/graphics/arenas/{arena_id}/{arena_id}_{layer}_v01.png"
            })

    for ui_id in catalog.get("ui", []):
        rows.append({
            "task_id": f"ui::{ui_id}",
            "type": "ui_asset",
            "target": ui_id,
            "variant": "default",
            "prompt": f"{GLOBAL_STYLE}, clean game UI element {ui_id}, dark panel, gold border, no text, mobile-first",
            "output_path": f"assets/graphics/ui/{ui_id}_v01.png"
        })

    for item in catalog.get("marketing", []):
        rows.append({
            "task_id": f"marketing::{item}",
            "type": "marketing_asset",
            "target": item,
            "variant": "default",
            "prompt": f"{GLOBAL_STYLE}, premium marketing graphic {item}, Ruan Macacao Silva, Cria do Tatame game, no real logos, no long text",
            "output_path": f"assets/graphics/marketing/{item}_v01.png"
        })

    total = write_jsonl(rows)
    print(json.dumps({"ok": True, "tasks": total, "output": str(OUT)}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
