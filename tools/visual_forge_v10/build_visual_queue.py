#!/usr/bin/env python3
"""Build the canonical Cria Visual Forge production queue.

Reads the existing production manifest and emits deterministic JSONL jobs for
characters, signatures, techniques, arenas, UI and audio-adjacent VFX.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "data" / "visual" / "visual_forge_config_v10.json"
MANIFEST = ROOT / "data" / "visual" / "production_manifest_v02.json"
OUTPUT = ROOT / "data" / "visual" / "generated" / "visual_jobs_v10.jsonl"


def read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def job(asset_type: str, subject_id: str, variant: str, output: dict[str, Any], must_preserve: list[str], qa: list[str]) -> dict[str, Any]:
    return {
        "job_id": "__".join([asset_type, subject_id, variant]).replace(" ", "_").lower(),
        "asset_type": asset_type,
        "subject_id": subject_id,
        "variant": variant,
        "status": "queued",
        "output": output,
        "prompt_contract": {
            "must_preserve": must_preserve,
            "negative": [
                "photography",
                "3D render",
                "cartoon infantil",
                "pessoa real",
                "marca real",
                "blur",
                "texto longo incorporado",
                "deriva anatômica"
            ]
        },
        "qa_gates": qa
    }


def build() -> list[dict[str, Any]]:
    config = read(CONFIG)
    manifest = read(MANIFEST)
    dims = config["dimensions"]
    profiles = manifest["animation_profiles"]
    jobs: list[dict[str, Any]] = []

    for character in manifest["characters"]:
        cid = character["id"]
        jobs.append(job(
            "character_portrait", cid, "default",
            {"size": dims["portrait"], "transparent": True, "anchor": "center"},
            ["identidade", "silhueta", "roupa", "função narrativa"],
            ["canon_identity", "transparent_background", "mobile_readability", "palette_compliance"]
        ))
        seen: set[str] = set()
        for profile in character["profiles"]:
            for animation in profiles[profile]:
                if animation in seen:
                    continue
                seen.add(animation)
                jobs.append(job(
                    "character_animation", cid, animation,
                    {"frame_count": 8, "frame_size": dims["combat_frame"], "transparent": True, "anchor": "bottom_center"},
                    ["mesmo personagem", "mesma direção", "mesma escala", "mesma paleta", "faixa inteira em uma geração"],
                    ["stable_proportions", "shared_anchor", "transparent_background", "clear_action", "no_frame_drift"]
                ))
        for signature in character.get("signature", []):
            jobs.append(job(
                "paired_technique", cid, signature,
                {"frame_count": 12, "frame_size": dims["combat_frame"], "transparent": True, "anchor": "bottom_center", "paired": True},
                ["atacante canônico", "oponente adulto neutro", "representação segura", "contato legível", "sincronização pareada"],
                ["bjj_coherence", "paired_sync", "safe_representation", "shared_anchor"]
            ))

    for technique in manifest["paired_techniques"]:
        tid = technique["id"]
        jobs.append(job(
            "technique_icon", tid, "default",
            {"size": dims["technique_icon"], "transparent": True},
            ["uma silhueta técnica", "sem texto", "leitura em 48 px"],
            ["icon_readability_48px", "transparent_background", "palette_compliance"]
        ))
        jobs.append(job(
            "technique_card", tid, "default",
            {"size": dims["technique_card"], "transparent": False, "text_reserved": True},
            ["ação focal", "zona de título vazia", "zona de estatísticas vazia", "sem copy incorporada"],
            ["composition", "reserved_text_zones", "safe_representation", "palette_compliance"]
        ))

    for arena in manifest["arenas"]:
        for variant in arena["variants"]:
            for layer, transparent in [
                ("bg_far", False), ("bg_mid", True), ("play_area", True),
                ("foreground", True), ("overlay_particles", True)
            ]:
                jobs.append(job(
                    "arena_layer", arena["id"], f"{variant}_{layer}",
                    {"size": dims["arena_layer"], "transparent": transparent, "layer": layer},
                    ["Baixo Sul", "parallax separado", "área de combate limpa", "horizonte consistente", "sem texto"],
                    ["parallax_separation", "horizon_consistency", "mobile_readability", "palette_compliance"]
                ))

    for screen in manifest["ui_screens"]:
        jobs.append(job(
            "ui_screen", screen, "landscape_16_9",
            {"size": dims["ui_reference"], "safe_area_percent": config["quality_gates"]["mobile_safe_area_percent"]},
            ["centro limpo", "touch targets grandes", "contraste AA", "painéis modulares", "texto no Godot"],
            ["safe_area", "touch_target_80px", "contrast", "one_second_readability"]
        ))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", encoding="utf-8") as file:
        for item in jobs:
            file.write(json.dumps(item, ensure_ascii=False) + "\n")
    return jobs


if __name__ == "__main__":
    queue = build()
    print(f"Visual queue generated: {len(queue)} jobs -> {OUTPUT}")
