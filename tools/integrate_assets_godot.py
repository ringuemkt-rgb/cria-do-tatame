#!/usr/bin/env python3
"""Integra assets gerados no projeto Godot 4.2+.

Gera manifests de importacao, confere arquivos esperados e cria cenas-base
simples quando possivel. Nao substitui QA manual no editor.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
SCENES = ROOT / "scenes"
MANIFEST_PATH = ROOT / "data" / "ai" / "asset_manifest_v01.json"
OUT_IMPORT = ROOT / "assets" / "generated_metadata" / "godot_import_manifest.json"


def read_json(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def expected_sprite_paths(manifest: Dict[str, Any]) -> List[str]:
    paths: List[str] = []
    for char_id, char in manifest.get("characters", {}).items():
        actions = char.get("actions", [])
        directions = char.get("directions", ["side_right"])
        for action in actions:
            for direction in directions:
                paths.append(f"assets/sprites/{char_id}/{char_id}_{action}_{direction}_v01.png")
    return paths


def expected_background_paths(manifest: Dict[str, Any]) -> List[str]:
    paths: List[str] = []
    for arena_id, arena in manifest.get("arenas", {}).items():
        for layer in arena.get("layers", []):
            paths.append(f"assets/backgrounds/{arena_id}/{arena_id}_{layer}.png")
    return paths


def create_character_scene_stub(char_id: str) -> Path:
    out_dir = SCENES / "generated_characters"
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{char_id}.tscn"
    if path.exists():
        return path
    content = f"""[gd_scene load_steps=1 format=3]

[node name=\"{char_id}\" type=\"Node2D\"]

[node name=\"Sprite\" type=\"Sprite2D\" parent=\".\"]
centered = true

[node name=\"AnimationPlayer\" type=\"AnimationPlayer\" parent=\".\"]
"""
    path.write_text(content, encoding="utf-8")
    return path


def main() -> int:
    manifest = read_json(MANIFEST_PATH)
    report: Dict[str, Any] = {"sprites": [], "backgrounds": [], "created_scenes": [], "missing": []}

    for rel in expected_sprite_paths(manifest):
        exists = (ROOT / rel).exists()
        report["sprites"].append({"path": rel, "exists": exists})
        if not exists:
            report["missing"].append(rel)

    for rel in expected_background_paths(manifest):
        exists = (ROOT / rel).exists()
        report["backgrounds"].append({"path": rel, "exists": exists})
        if not exists:
            report["missing"].append(rel)

    for char_id in manifest.get("characters", {}).keys():
        path = create_character_scene_stub(char_id)
        report["created_scenes"].append(str(path.relative_to(ROOT)))

    OUT_IMPORT.parent.mkdir(parents=True, exist_ok=True)
    OUT_IMPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"ok": True, "manifest": str(OUT_IMPORT), "missing_count": len(report["missing"])}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
