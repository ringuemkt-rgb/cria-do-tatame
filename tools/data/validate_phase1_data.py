#!/usr/bin/env python3
"""Validate the Phase 1 data backbone against canon_lock. Fail closed.

The validator intentionally does not invent balance values. Numeric Utility AI
calibration remains pending EPIC55 and training balance remains pending EPIC56.
"""
from __future__ import annotations

import json
import pathlib
import sys
from typing import Any

ROOT = pathlib.Path(".")
DATA = ROOT / "data"
ERRORS: list[str] = []

BACKBONES = [
    "world/world_map_v4.json",
    "world/arena_info_v1.json",
    "world/clandestine_v1.json",
    "factions/factions_v2.json",
    "combat/roster_v3.json",
    "combat/ai_weights_v1.json",
    "progression/training_exercises_v2.json",
    "brand/canon_lock.json",
    "visual/ui_theme_v2.json",
    "visual/icons_manifest_v1.json",
]


def load(rel: str) -> dict[str, Any]:
    path = DATA / rel
    if not path.exists():
        ERRORS.append(f"missing:{rel}")
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        ERRORS.append(f"invalid_json:{rel}:{exc}")
        return {}
    if not isinstance(value, dict):
        ERRORS.append(f"root_not_object:{rel}")
        return {}
    return value


def expect(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def main() -> int:
    wm = load("world/world_map_v4.json")
    arena_info = load("world/arena_info_v1.json")
    clandestine = load("world/clandestine_v1.json")
    factions = load("factions/factions_v2.json")
    roster = load("combat/roster_v3.json")
    ai = load("combat/ai_weights_v1.json")
    training = load("progression/training_exercises_v2.json")
    lock = load("brand/canon_lock.json")
    theme = load("visual/ui_theme_v2.json")
    icons = load("visual/icons_manifest_v1.json")

    # Backbone completeness.
    expect(len(BACKBONES) == 10, "internal:backbone_count!=10")

    # Canon headline.
    expect(lock.get("tese") == "Ser forte é ser gentil.", "canon:tese")
    setting = lock.get("setting", {})
    expect(setting.get("regiao") == "Baixo Sul da Bahia", "canon:setting.regiao")
    expect(setting.get("hub") == "Ituberá", "canon:setting.hub")

    # World/map counts and geography.
    nodes_list = wm.get("nodes", [])
    nodes = {
        node.get("id"): node
        for node in nodes_list
        if isinstance(node, dict) and isinstance(node.get("id"), str)
    }
    counts = wm.get("canonical_counts", {})
    expect(len(wm.get("pages", [])) == 10, "world:pages!=10")
    expect(len(wm.get("municipalities", [])) == 14, "world:municipalities!=14")
    expect(len(nodes_list) == 40, "world:nodes!=40")
    expect(counts.get("pages") == 10, "world:canonical_counts.pages")
    expect(counts.get("municipalities") == 14, "world:canonical_counts.municipalities")
    expect(counts.get("nodes") == 40, "world:canonical_counts.nodes")

    expected_geo = {
        "arena_do_dique": "itubera",
        "quartel_pf": "valenca",
        "quartel_cacaueira": "itubera",
        "ferro_velho_lapa": "salvador",
        "pancada_grande": "itubera",
    }
    for node_id, municipality in expected_geo.items():
        expect(nodes.get(node_id, {}).get("mun") == municipality, f"geo:{node_id}!={municipality}")
    expect("ponte_do_saici" in nodes, "geo:ponte_do_saici_missing")
    expect(wm.get("aliases", {}).get("ponte_do_saci") == "ponte_do_saici", "geo:ponte_alias")

    prohibited = ["Rio de Janeiro", "Chapada Diamantina"]
    world_text = json.dumps(wm, ensure_ascii=False) + json.dumps(arena_info, ensure_ascii=False)
    for term in prohibited:
        expect(term not in world_text, f"canon_diff:prohibited_world_term:{term}")

    # Arena info must describe exactly the same canonical node inventory.
    arena_rows = arena_info.get("arenas", [])
    arena_ids = {
        row.get("id")
        for row in arena_rows
        if isinstance(row, dict) and isinstance(row.get("id"), str)
    }
    expect(arena_info.get("count") == 40, "arena_info:declared_count!=40")
    expect(len(arena_rows) == 40, "arena_info:rows!=40")
    expect(arena_ids == set(nodes), "arena_info:ids_do_not_match_world_map")

    # Three current factions. Support the Phase-1 explicit id/display schema,
    # while canon_lock remains the compact sigla/nome source.
    phase_factions = factions.get("factions", [])
    faction_map = {
        row.get("id", row.get("sigla")): row.get("display_name", row.get("nome"))
        for row in phase_factions
        if isinstance(row, dict)
    }
    faction_colors = {
        row.get("id", row.get("sigla")): row.get("color", row.get("cor"))
        for row in phase_factions
        if isinstance(row, dict)
    }
    lock_factions = {
        row.get("sigla"): row
        for row in lock.get("faccoes", [])
        if isinstance(row, dict)
    }
    expected_factions = {
        "ALE": ("Os Aleluiados", "#FF9408"),
        "LEM": ("Lá Ele Mil Vezes", "#4A6741"),
        "NTM": ("Nós Tem o Molho", "#3FE3F5"),
    }
    expect(set(faction_map) == set(expected_factions), "factions:ids")
    for faction_id, (name, color) in expected_factions.items():
        expect(faction_map.get(faction_id) == name, f"faction:{faction_id}:name")
        expect(faction_colors.get(faction_id) == color, f"faction:{faction_id}:color")
        expect(lock_factions.get(faction_id, {}).get("nome") == name, f"canon_diff:{faction_id}:name")
        expect(lock_factions.get(faction_id, {}).get("cor") == color, f"canon_diff:{faction_id}:color")

    # Current roster authority is 17 fighters. Do not synthesize missing fighters.
    fighters = roster.get("fighters", roster.get("roster", roster.get("lutadores", [])))
    expect(roster.get("count") == 17, "roster:declared_count!=17")
    expect(len(fighters) == 17, "roster:count!=17")
    fighter_ids = [row.get("id") for row in fighters if isinstance(row, dict)]
    expect(len(set(fighter_ids)) == 17, "roster:duplicate_ids")

    # Seven clandestine arenas are present in world_map_v4.
    clandestine_rows = clandestine.get("arenas", [])
    expected_clandestine_ids = {
        node.get("id")
        for node in nodes_list
        if isinstance(node, dict) and node.get("tipo") == "clandestina"
    }
    actual_clandestine_ids = {
        row.get("id")
        for row in clandestine_rows
        if isinstance(row, dict) and isinstance(row.get("id"), str)
    }
    expect(len(expected_clandestine_ids) == 7, "world:clandestine_count!=7")
    expect(len(clandestine_rows) == 7, "clandestine:rows!=7")
    expect(actual_clandestine_ids == expected_clandestine_ids, "clandestine:ids_do_not_match_world_map")

    # Training remains semantic until EPIC56. The only locked numeric decay is -1/day.
    expect(training.get("conditioning_decay_per_day") == -1, "training:conditioning_decay_per_day!=-1")
    expect(training.get("numeric_calibration_status") == "pending_epic56", "training:calibration_status")

    # Utility AI stays fail-closed until EPIC55.
    expect(ai.get("numeric_calibration_status") == "pending_epic55", "ai:calibration_status")
    profiles = ai.get("profiles", [])
    expect(len(profiles) == 17, "ai:profiles!=17")
    expect(all(row.get("weights") is None for row in profiles if isinstance(row, dict)), "ai:numeric_weights_present")

    # Visual/brand locks remain data/reference, never asset promotion.
    expect(theme.get("brand", {}).get("bg") == "#0B0B0D", "ui_theme:brand_bg")
    expect(theme.get("brand", {}).get("border") == "#C9971C", "ui_theme:brand_border")
    expect(theme.get("brand", {}).get("text") == "#EDE6D6", "ui_theme:brand_text")
    expect(icons.get("status") == "reference_candidate", "icons:status")
    expect(icons.get("shipping") is False, "icons:shipping_must_be_false")

    if ERRORS:
        print("PHASE1_DATA=FAIL")
        print("CANON_DIFF=DIRTY")
        for error in ERRORS:
            print(f"- {error}")
        return 1

    print("PHASE1_DATA=PASS")
    print("BACKBONES=10/10")
    print("CANON_DIFF=CLEAN")
    print("WORLD=10_pages/14_municipalities/40_nodes")
    print("ROSTER=17")
    print("CLANDESTINE=7")
    print("AI_CALIBRATION=pending_epic55")
    print("TRAINING_CALIBRATION=pending_epic56")
    print("SHIPPING_PROMOTION=none")
    return 0


if __name__ == "__main__":
    sys.exit(main())
