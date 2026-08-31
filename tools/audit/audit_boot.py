#!/usr/bin/env python3
"""Fail-closed audit for EPIC 16 canonical visual layer."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def read_json(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    checks: list[str] = []

    required = [
        "data/visual/canon_lock.json",
        "data/combat/environment_modifiers.json",
        "scenes/combat/combat_hud_v2.tscn",
        "src/combat/combat_hud_v2.gd",
        "scenes/world/world_map_ui.tscn",
        "scenes/world/world_map_ui.gd",
        "scenes/social/crialive_v2.tscn",
        "scenes/social/crialive_v2.gd",
        "scenes/hubs/skill_tree_v2.tscn",
        "scenes/hubs/skill_tree_v2.gd",
        "addons/AsepriteWizard/plugin.cfg",
        "addons/AsepriteWizard/LICENSE",
        "addons/AsepriteWizard/CRIA_PIN.json",
        "tools/animation/build_fight_sprites.py",
    ]
    for rel in required:
        if not (ROOT / rel).is_file():
            errors.append(f"missing:{rel}")
    if errors:
        print(json.dumps({"ok": False, "errors": errors}, ensure_ascii=False))
        return 1

    lock = read_json("data/visual/canon_lock.json")
    modifiers = read_json("data/combat/environment_modifiers.json")
    pin = read_json("addons/AsepriteWizard/CRIA_PIN.json")

    expected_identity = {
        "protagonist_display": 'Ruan "Macacão" Silva',
        "setting_display": "Baixo Sul da Bahia",
    }
    for key, expected in expected_identity.items():
        if lock.get("identity", {}).get(key) != expected:
            errors.append(f"canon_identity:{key}")
    expected_factions = {"ALE": "Os Aleluiado", "LEM": "Lá Ele Mil Vezes", "NTM": "Nós Tem Um Molho"}
    for faction_id, display in expected_factions.items():
        if lock.get("factions", {}).get(faction_id, {}).get("display") != display:
            errors.append(f"canon_faction:{faction_id}")
    expected_sponsors = {"cacau_bahia", "pratigi_surf", "camamu_ostras", "dende_oil"}
    if set(lock.get("sponsors", {})) != expected_sponsors:
        errors.append("canon_sponsors")
    checks.append("canon_lock")

    cards = modifiers.get("cards", [])
    expected_cards = {
        "areia_fofa", "mobilidade", "plateia", "por_do_sol", "mare_alta", "mare_baixa",
        "chuva", "neblina", "fogo", "poeira", "cimento", "silencio",
    }
    if {card.get("id") for card in cards} != expected_cards:
        errors.append("environment_card_ids")
    for card in cards:
        effects = card.get("effects", {})
        if not effects or not all(isinstance(value, (int, float)) for value in effects.values()):
            errors.append(f"numeric_effects:{card.get('id', 'unknown')}")
    checks.append("environment_modifiers")

    scene_contracts = {
        "scenes/combat/combat_hud_v2.tscn": [
            "StandPhaseHUD", "GroundPhaseHUD", "EnvironmentHand", "EnvironmentCard1",
            "EnvironmentCard2", "EnvironmentCard3", "Ruan \\\"Macacão\\\" Silva",
        ],
        "scenes/world/world_map_ui.tscn": ["DominoOverlay", "TideOverlay", "MapNodes", "Routes", "Baixo Sul da Bahia"],
        "scenes/social/crialive_v2.tscn": ["CrisisPanel", "SponsorsPanel", "FactionReputation", "Cacau Bahia", "Pratigi Surf", "Camamu Ostras", "Dendê Oil"],
        "scenes/hubs/skill_tree_v2.tscn": ["TecnicaBranch", "PressaoBranch", "FriezaBranch", "LegadoBranch"],
    }
    scene_text = ""
    for rel, needles in scene_contracts.items():
        text = (ROOT / rel).read_text(encoding="utf-8")
        scene_text += "\n" + text
        for needle in needles:
            if needle.casefold() not in text.casefold():
                errors.append(f"scene_contract:{rel}:{needle}")
    tree = (ROOT / "scenes/hubs/skill_tree_v2.tscn").read_text(encoding="utf-8")
    for branch in ("Tecnica", "Pressao", "Frieza", "Legado"):
        for tier in range(1, 6):
            if f'{branch}Tier{tier}' not in tree:
                errors.append(f"skill_tree:{branch}:tier_{tier}")
    checks.append("scene_structure")

    runtime_contracts = {
        "src/autoloads/CombatManager.gd": [
            "func _on_takedown_resolved", "enter_solo", "func _on_stand_up", "exit_to_standing",
        ],
        "src/autoloads/FactionDirectorManager.gd": [
            "_apply_clandestine_player_victory", "territory_changed.emit",
        ],
        "src/autoloads/CriaLiveManager.gd": ["signal post_published", "post_published.emit"],
        "src/autoloads/TrainingManager.gd": ["signal technique_leveled_up", "technique_leveled_up.emit"],
        "src/autoloads/WorldDirectorManager.gd": [
            "signal time_advanced", "time_advanced.emit", "signal tide_changed", "tide_changed.emit",
        ],
        "scenes/combat/CombatArenaBase.tscn": ["combat_hud_v2.tscn", "CombatHUDv2"],
        "scenes/ui/CriaLiveUI.tscn": ["crialive_v2.tscn", "CriaLiveV2"],
        "scenes/world/WorldMapScreen.tscn": ["world_map_ui.tscn", "WorldMapV2"],
        "scenes/hubs/TerreiroDaLuta.gd": ["SKILL_TREE_SCENE", "_on_skill_tree"],
    }
    for rel, needles in runtime_contracts.items():
        text = (ROOT / rel).read_text(encoding="utf-8")
        for needle in needles:
            if needle not in text:
                errors.append(f"runtime_binding:{rel}:{needle}")
    checks.append("runtime_bindings")

    existing_ui_contracts = {
        "scenes/combat/CombatArenaBase.tscn": ['RUAN \\"MACACÃO\\" SILVA', "DAVI RELÂMPAGO"],
        "scenes/ui/CombatHUD.tscn": ['RUAN \\"MACACÃO\\" SILVA', "DAVI RELÂMPAGO"],
        "scenes/world/WorldMapScreen.tscn": ["BAIXO SUL DA BAHIA", "ITUBERÁ"],
        "scenes/main_menu/MainMenu.tscn": ["BAIXO SUL DA BAHIA"],
        "scenes/hubs/TerreiroDaLuta.tscn": ["DAVI RELÂMPAGO"],
    }
    for rel, needles in existing_ui_contracts.items():
        text = (ROOT / rel).read_text(encoding="utf-8")
        for needle in needles:
            if needle.casefold() not in text.casefold():
                errors.append(f"existing_ui_canon:{rel}:{needle}")
    checks.append("existing_ui_canon")

    active_ui = "\n".join(path.read_text(encoding="utf-8", errors="replace") for path in (ROOT / "scenes").rglob("*.tscn"))
    forbidden_strings = ["".join(parts) for parts in lock.get("forbidden_ui_sequences", [])]
    for forbidden in forbidden_strings:
        if re.search(re.escape(forbidden), active_ui, flags=re.IGNORECASE):
            errors.append(f"forbidden_ui:{forbidden}")
    checks.append("forbidden_ui")

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    if 'run/main_scene="res://scenes/main_menu/MainMenu.tscn"' not in project:
        errors.append("main_scene")
    if 'enabled=PackedStringArray("res://addons/AsepriteWizard/plugin.cfg")' not in project:
        errors.append("aseprite_plugin_disabled")
    plugin_cfg = (ROOT / "addons/AsepriteWizard/plugin.cfg").read_text(encoding="utf-8")
    plugin_license = (ROOT / "addons/AsepriteWizard/LICENSE").read_text(encoding="utf-8")
    if 'version="8.2.0"' not in plugin_cfg or pin.get("commit") != "1dc9a1ef0b3c2112d5ac26eec8e1f5197ec83eb1":
        errors.append("aseprite_pin")
    if "MIT License" not in plugin_license:
        errors.append("aseprite_license")
    checks.append("boot_and_addon")

    result = {"ok": not errors, "checks": checks, "errors": errors}
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
