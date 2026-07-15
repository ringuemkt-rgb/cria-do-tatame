#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "data" / "visual" / "production_manifest_v02.json"

REQUIRED_PATHS = [
    "project.godot",
    "export_presets.cfg",
    "package.json",
    "tools/build/check_environment.ps1",
    "tools/build/build_android_debug.ps1",
    "tools/build/build_windows_debug.ps1",
    "tools/ai_asset_pipeline/build_production_queue_v02.py",
    "docs/production/APK_VISUAL_COMPLETION_PLAN_V09.md",
    "data/visual/production_manifest_v02.json",
]

VALID_STATES = {
    "long_range",
    "mid_range",
    "close_range",
    "clinch",
    "takedown_defense",
    "player_top_guard",
    "player_bottom_guard",
    "player_top_half_guard",
    "player_bottom_half_guard",
    "player_top_side",
    "player_bottom_side",
    "player_top_mount",
    "player_bottom_mount",
    "player_top_turtle",
    "player_bottom_turtle",
    "player_back_attack",
    "player_back_defense",
    "technical_finish",
}


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def duplicate_ids(items: list[dict[str, Any]]) -> list[str]:
    ids = [str(item.get("id", "")) for item in items]
    return sorted(key for key, count in Counter(ids).items() if key and count > 1)


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    for relative in REQUIRED_PATHS:
        if not (ROOT / relative).exists():
            errors.append(f"arquivo obrigatório ausente: {relative}")

    package_path = ROOT / "package.json"
    if package_path.exists():
        package_text = package_path.read_text(encoding="utf-8").lower()
        if "capacitor" in package_text:
            errors.append("package.json ainda referencia Capacitor; Godot deve ser o único runtime de exportação")

    preset_path = ROOT / "export_presets.cfg"
    if preset_path.exists():
        preset = preset_path.read_text(encoding="utf-8")
        for token in ["name=\"Android Debug\"", "platform=\"Android\"", "name=\"Windows Desktop Debug\""]:
            if token not in preset:
                errors.append(f"export_presets.cfg sem contrato obrigatório: {token}")

    if MANIFEST_PATH.exists():
        manifest = read_json(MANIFEST_PATH)
        if manifest.get("canon_protagonist") != "ruan_macacao":
            errors.append("manifesto audiovisual não aponta ruan_macacao como protagonista canônico")

        profiles = manifest.get("animation_profiles", {})
        characters = manifest.get("characters", [])
        techniques = manifest.get("paired_techniques", [])
        arenas = manifest.get("arenas", [])

        for group_name, items in [("characters", characters), ("paired_techniques", techniques), ("arenas", arenas)]:
            for duplicate in duplicate_ids(items):
                errors.append(f"ID duplicado em {group_name}: {duplicate}")

        for character in characters:
            character_id = character.get("id", "sem_id")
            for profile in character.get("profiles", []):
                if profile not in profiles:
                    errors.append(f"personagem {character_id} referencia profile inexistente: {profile}")
            if not character.get("profiles"):
                warnings.append(f"personagem {character_id} sem profile de animação")

        for technique in techniques:
            technique_id = technique.get("id", "sem_id")
            if technique.get("entry") not in VALID_STATES:
                errors.append(f"técnica {technique_id} com estado de entrada inválido: {technique.get('entry')}")
            if technique.get("exit") not in VALID_STATES:
                errors.append(f"técnica {technique_id} com estado de saída inválido: {technique.get('exit')}")
            frames = technique.get("frames_target")
            if not isinstance(frames, int) or frames < 4 or frames > 96:
                errors.append(f"técnica {technique_id} com frames_target inválido: {frames}")

        for arena in arenas:
            arena_id = arena.get("id", "sem_id")
            if arena.get("layers", 0) < 4:
                errors.append(f"arena {arena_id} possui menos de quatro camadas")
            if not arena.get("variants"):
                errors.append(f"arena {arena_id} não possui variante visual")

        required_outputs = set(manifest.get("quality_gate", {}).get("required_files", []))
        expected = {"spritesheet.png", "frames", "preview.gif", "metadata.json", "qa_report.md"}
        missing_outputs = sorted(expected - required_outputs)
        if missing_outputs:
            errors.append(f"quality gate sem outputs essenciais: {', '.join(missing_outputs)}")

        if len(characters) < 10:
            warnings.append("manifesto possui menos de dez personagens")
        if len(techniques) < 20:
            warnings.append("manifesto possui menos de vinte técnicas sincronizadas")
        if len(arenas) < 10:
            warnings.append("manifesto possui menos de dez arenas")

    report = {
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
        "counts": {
            "characters": len(read_json(MANIFEST_PATH).get("characters", [])) if MANIFEST_PATH.exists() else 0,
            "paired_techniques": len(read_json(MANIFEST_PATH).get("paired_techniques", [])) if MANIFEST_PATH.exists() else 0,
            "arenas": len(read_json(MANIFEST_PATH).get("arenas", [])) if MANIFEST_PATH.exists() else 0,
        },
    }

    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
