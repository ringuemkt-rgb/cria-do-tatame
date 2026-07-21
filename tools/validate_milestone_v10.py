#!/usr/bin/env python3
"""Valida se as alegações do marco audiovisual v10 continuam verificáveis."""

from __future__ import annotations

import json
import hashlib
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MILESTONE = ROOT / "data/production/vertical_slice_milestone_v10.json"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    errors: list[str] = []
    require(MILESTONE.is_file(), "contrato do marco v10 ausente", errors)
    if errors:
        print("ERRO: " + errors[0])
        return 1

    milestone = load_json(MILESTONE)
    character_art = load_json(ROOT / "data/visual/character_art_manifest_v01.json")
    audio = load_json(ROOT / "data/audio/audio_event_catalog_v01.json")
    world_map = load_json(ROOT / "data/visual/world_map_art_v01.json")
    character_claims = milestone.get("character_art", {})
    audio_claims = milestone.get("audio", {})

    require(len(character_art.get("characters", [])) == int(character_claims.get("canonical_characters", -1)), "contagem de personagens diverge", errors)
    require(len(character_art.get("vertical_slices", [])) == int(character_claims.get("idle_animation_packs", -1)), "contagem de idles diverge", errors)
    require(int(character_art.get("source_pose_library", {}).get("action_key_pose_count", -1)) == int(character_claims.get("action_key_poses", -2)), "contagem de poses diverge", errors)
    require(int(character_art.get("action_animation_batch", {}).get("pack_count", -1)) == int(character_claims.get("priority_action_packs", -2)), "contagem de ações prioritárias diverge", errors)
    require(int(character_art.get("action_animation_batch", {}).get("frame_count", -1)) == int(character_claims.get("priority_action_frames", -2)), "contagem de frames prioritários diverge", errors)

    events = list(audio.get("events", []))
    categories = Counter(str(event.get("category", "")) for event in events)
    require(len(events) == int(audio_claims.get("event_count", -1)), "contagem total de áudio diverge", errors)
    for category in ("combat", "ui", "crowd", "ambience", "music"):
        require(categories[category] == int(audio_claims.get(category, -1)), f"áudio/{category} diverge", errors)

    require(set(world_map.get("node_positions", {})) == {"itubera", "salvador", "zambiapunga", "camamu_manguezal"}, "mapa não possui os quatro hubs canônicos", errors)
    for path in (
        "assets/graphics/arenas/arena_do_dique_v01/manifest.json",
        "assets/graphics/hubs/terreiro_da_luta_v01/manifest.json",
        "assets/graphics/world/baixo_sul_map_v01/manifest.json",
        "scenes/hubs/NPCPresencePanel.gd",
        "src/gamefeel/CombatVFXController.gd",
        "docs/production/VISUAL_AUDIO_WORLD_MILESTONE_V10.md",
    ):
        require((ROOT / path).is_file(), f"arquivo integrado ausente: {path}", errors)

    review = milestone.get("review_board", {})
    review_path = ROOT / str(review.get("path", ""))
    require(review_path.is_file(), "painel visual de revisão ausente", errors)
    if review_path.is_file():
        require(sha256(review_path) == review.get("sha256"), "hash do painel de revisão diverge", errors)

    combat_scene = (ROOT / "scenes/combat/CombatArenaBase.gd").read_text(encoding="utf-8")
    require('arena_id: String = "arena_do_dique"' in combat_scene, "cena de combate não inicia no Dique", errors)
    require("play_ambience(\"arena_idle_loop\")" in combat_scene, "ambiência da arena não está ligada", errors)
    audio_manager = (ROOT / "src/autoloads/AudioManager.gd").read_text(encoding="utf-8")
    require("DEFAULT_POOL_SIZE: int = 24" in audio_manager, "pool mobile de áudio não está configurado", errors)
    require(milestone.get("release_claim") == "vertical_slice_candidate_not_complete_game_or_release_build", "alegação de release insegura", errors)
    require(milestone.get("quality_gates", {}).get("godot_4_2_runtime") != "passed", "Godot marcado como aprovado sem gate real", errors)
    require(milestone.get("quality_gates", {}).get("android_device") != "passed", "Android marcado como aprovado sem gate real", errors)

    if errors:
        for error in errors:
            print(f"ERRO: {error}")
        print(f"Marco v10 reprovado: {len(errors)} problema(s).")
        return 1
    print(f"Marco v10 aprovado: {len(events)} áudios, {len(character_art.get('characters', []))} personagens e 3 ambientes/mapas contratados.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
