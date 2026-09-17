#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def require(ok: bool, message: str) -> None:
    if not ok:
        raise AssertionError(message)

def main() -> int:
    contract = load("data/combat/combat_core_v2_contract.json")
    timers = load("data/combat/ruleset_timers_v1.json")
    timing = load("data/combat/bjj_timing_windows_v1.json")
    state = load("data/combat/combat_state_v2.json")

    require(contract["version"] == "1.0.0", "combat core contract version drift")
    require(contract["authorities"]["scene_and_legacy_runtime"] == "CombatManager", "CombatManager must remain judge")
    require(contract["authorities"]["factions_may_bias_only"] is True, "factions may bias only")
    require(contract["authorities"]["crialive_may_decide_combat"] is False, "CriaLive cannot decide combat")
    require(contract["migration"]["reducer_flip_allowed"] is False, "reducer flip must remain blocked before true parity harness")
    require(contract["deck"] == {
        "min_size": 6,
        "max_size": 8,
        "hand_size": 6,
        "preset_ids": ["ofensivo", "defensivo", "adaptativo"],
        "seeded_shuffle": True,
        "draws_only_from_selected_deck": True,
    }, "deck contract drift")
    require(int(timing["input_profiles"]["touch"]["minimum_counter_window_ms"]) >= 250, "touch counter floor below 250 ms")
    require(int(timing["tiers"]["tight"]["window_ms"]) >= 250, "tight counter window below accessibility floor")
    require(int(timers["profiles"]["ibjjf"]["duration_sec"]) == 360, "campaign IBJJF profile drift")
    require(int(timers["profiles"]["adcc"]["duration_sec"]) == 300, "campaign ADCC profile drift")
    require(bool(timers["profiles"]["clandestina"]["sudden_death"]), "clandestina must be sudden death")
    require(state["state"]["virada_disponivel"] == {"p1": True, "p2": True}, "Virada initial flags wrong")
    require(contract["save"]["save_version"] == 6, "Combat Core must stay on save v6")
    require(contract["save"]["deck_and_presets_persisted"] is True, "deck/presets must persist")
    require(contract["save"]["mid_fight_resume_supported"] is False, "do not claim mid-fight resume before implementation")
    require(contract["save"]["mid_fight_resume_required_before_release"] is True, "mid-fight resume must remain a release gate")

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    for forbidden in ("CombatDeckRuntimeV2", "CornerSystem", "ScoutingSystem", "ComebackSystem", "CombatCoreV2Coordinator"):
        require(f"{forbidden}=" not in project, f"{forbidden} must not be autoload")

    manager = (ROOT / "src/autoloads/CombatManager.gd").read_text(encoding="utf-8")
    require("prepare_combat_v2" in manager, "CombatManager V2 preparation bridge missing")
    require("activate_virada_do_cria" in manager, "Virada bridge missing")
    require("combat_core_v2.finish_result" in manager, "post-fight clip bridge missing")
    require("deck_card_not_in_hand" in manager, "V2 hand authority missing")

    terreiro = (ROOT / "scenes/hubs/TerreiroDaLuta.gd").read_text(encoding="utf-8")
    require("PreFightHub.tscn" in terreiro, "Terreiro must route Davi through pre-fight")

    print("Combat Core V2 contract OK")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
