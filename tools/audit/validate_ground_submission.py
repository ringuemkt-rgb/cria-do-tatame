#!/usr/bin/env python3
"""Validate the single-FSM ground graph and safe deterministic submission exchange."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
GROUND_PATH = ROOT / "data" / "combat" / "ground_graph_v01.json"
ANATOMY_PATH = ROOT / "data" / "combat" / "submissions_anatomy_v01.json"
EXCHANGE_PATH = ROOT / "data" / "combat" / "submission_exchange_v01.json"
TECHNIQUES_PATH = ROOT / "data" / "techniques.json"


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    ground = load_json(GROUND_PATH)
    anatomy = load_json(ANATOMY_PATH)
    exchange = load_json(EXCHANGE_PATH)
    techniques = load_json(TECHNIQUES_PATH).get("techniques", [])
    technique_map = {
        str(item.get("id", "")): item
        for item in techniques
        if isinstance(item, dict) and item.get("id")
    }

    require(ground.get("$schema") == "ground_graph_v1", "invalid ground graph schema")
    require(ground.get("runtime_owner") == "CombatStateMachine", "ground graph attempts to own a second FSM")
    require(ground.get("perspective") == "player_relative", "ground graph perspective changed")
    states = ground.get("states", [])
    state_ids = {str(item.get("id", "")) for item in states if isinstance(item, dict)}
    require(len(states) == 14 and len(state_ids) == 14, "ground graph must mirror the fourteen runtime states")
    edges = ground.get("edges", [])
    edge_ids = [str(item.get("technique_id", "")) for item in edges if isinstance(item, dict)]
    require(len(edge_ids) == len(set(edge_ids)), "ground graph contains duplicate technique edges")
    require(set(edge_ids) == set(technique_map), "ground graph must cover the active technique catalog exactly")
    for edge in edges:
        technique_id = str(edge.get("technique_id", ""))
        technique = technique_map[technique_id]
        require(edge.get("from") in state_ids and edge.get("to") in state_ids, f"unknown state in edge {technique_id}")
        require(edge.get("from") == technique.get("entry_state"), f"entry mismatch for {technique_id}")
        require(edge.get("to") == technique.get("exit_state"), f"exit mismatch for {technique_id}")

    require(anatomy.get("$schema") == "submissions_anatomy_v1", "invalid submission anatomy schema")
    safety = anatomy.get("safety_contract", {})
    require(safety.get("tap_has_priority") is True, "tap priority is mandatory")
    require(safety.get("release_on_tap") is True, "release-on-tap is mandatory")
    require(safety.get("graphic_injury") is False, "graphic injury conflicts with canon")
    require(safety.get("injury_reward") is False, "injury cannot be rewarded")
    require(safety.get("real_world_instruction") is False, "anatomy data cannot become a training guide")
    require(safety.get("human_bjj_review_required") is True, "human BJJ review is mandatory")
    records = anatomy.get("records", [])
    require(len(records) == 12, "submission anatomy must contain exactly twelve records")
    record_ids = {str(item.get("id", "")) for item in records if isinstance(item, dict)}
    require(len(record_ids) == 12, "submission anatomy IDs must be unique")
    runtime_techniques: set[str] = set()
    for record in records:
        require(record.get("uniforms"), f"missing uniform gate for {record.get('id')}")
        require(record.get("target_region") and record.get("mechanism_summary"), f"missing abstract anatomy for {record.get('id')}")
        require(record.get("gameplay_response_family"), f"missing response family for {record.get('id')}")
        require("progression" not in record and "escapes" not in record and "flick" not in record, f"instructional fields leaked into {record.get('id')}")
        for technique_id in record.get("technique_ids", []):
            require(technique_id in technique_map, f"anatomy references unknown technique {technique_id}")
            if record.get("runtime_enabled") is True:
                runtime_techniques.add(str(technique_id))
    require(runtime_techniques == {"chave_braco", "triangulo", "mata_leao"}, "only the three shipping submissions may be runtime-enabled")
    heel_hook = next((item for item in records if item.get("id") == "heel_hook"), {})
    require(heel_hook.get("runtime_enabled") is False, "heel hook cannot be globally enabled")
    require(heel_hook.get("competition_gate") == "adult_brown_black_no_gi_only", "heel hook gate is incomplete")
    gate = anatomy.get("rules_snapshot", {}).get("heel_hook_gate", {})
    require(gate.get("uniform") == "no_gi" and set(gate.get("belts", [])) == {"brown", "black"}, "official heel-hook ruleset gate is incomplete")

    serialized_anatomy = json.dumps(anatomy, ensure_ascii=False).lower()
    for fragment in ["girar o polegar", "empilhar e", "puxar cotovelo", "girar na direção", "desgaste_por_seg"]:
        require(fragment not in serialized_anatomy, f"real-world procedural instruction leaked into anatomy: {fragment}")

    require(exchange.get("$schema") == "submission_exchange_v1", "invalid submission exchange schema")
    require(exchange.get("simulation") == "turn_based_deterministic", "submission exchange must be deterministic and turn based")
    require([item.get("id") for item in exchange.get("phases", [])] == [
        "setup", "lock", "technical_pressure", "tap_or_escape", "referee_or_recovery"
    ], "submission phase contract changed")
    rules = exchange.get("rules", {})
    require(rules.get("tap_priority") is True, "exchange lost tap priority")
    require(rules.get("damage_meter") is False and rules.get("injury_outcome") is False, "exchange exposes an injury/damage minigame")
    actions = exchange.get("actions", [])
    action_ids = {str(item.get("id", "")) for item in actions if isinstance(item, dict)}
    require({"submission_tap", "submission_release", "submission_escape", "submission_pressure"} <= action_ids, "safe submission actions are incomplete")
    outcomes = set(exchange.get("approved_outcomes", []))
    require(outcomes == {"tap", "escape", "release", "technical_stop", "time_or_points"}, "submission outcomes are not the approved safe set")
    for profile_id, profile in exchange.get("arena_safety_profiles", {}).items():
        require(profile.get("intervention_enabled") is True, f"arena safety intervention disabled: {profile_id}")

    texts = {
        "registry": (ROOT / "src" / "autoloads" / "DataRegistry.gd").read_text(encoding="utf-8"),
        "manager": (ROOT / "src" / "autoloads" / "CombatManager.gd").read_text(encoding="utf-8"),
        "resolver": (ROOT / "src" / "combat" / "TechniqueResolver.gd").read_text(encoding="utf-8"),
        "exchange": (ROOT / "src" / "combat" / "SubmissionExchange.gd").read_text(encoding="utf-8"),
        "signals": (ROOT / "src" / "autoloads" / "SignalBus.gd").read_text(encoding="utf-8"),
        "arena": (ROOT / "scenes" / "combat" / "CombatArenaBase.tscn").read_text(encoding="utf-8"),
        "hud": (ROOT / "scenes" / "ui" / "SubmissionHUD.tscn").read_text(encoding="utf-8"),
        "project": (ROOT / "project.godot").read_text(encoding="utf-8"),
    }
    require('"ground_graph"' in texts["registry"] and '"submission_exchange"' in texts["registry"], "DataRegistry does not own the new contracts")
    require("GroundGraphRulesScript" in texts["manager"] and "SubmissionExchangeScript" in texts["manager"], "CombatManager does not consume ground/submission contracts")
    require("starts_submission_exchange" in texts["resolver"], "submission setup still applies direct health damage")
    require("turn_count += 1" in texts["exchange"] and "RandomNumberGenerator" not in texts["exchange"], "exchange is not deterministic")
    require("submission_exchange_changed" in texts["signals"] and "submission_resolved" in texts["signals"], "submission signals are incomplete")
    require("SubmissionHUD.tscn" in texts["arena"], "combat arena does not instance SubmissionHUD")
    require("CONTROLE TECNICO" in texts["hud"] and "PROGRESSO DE ESCAPE" in texts["hud"], "SubmissionHUD lacks its two safe meters")
    require("custom_minimum_size = Vector2(0, 64)" in texts["arena"], "context actions lost the 64px Android touch target")
    require('GroundStateMachine="' not in texts["project"] and 'SubmissionExchange="' not in texts["project"], "new combat systems must not become autoloads")
    require(not (ROOT / "src" / "combat" / "GroundStateMachine.gd").exists(), "a second positional state machine was introduced")
    require(not (ROOT / "src" / "combat" / "SubmissionMinigame.gd").exists(), "unsafe real-time pressure/damage minigame was introduced")

    print(
        "[ground-submission] ok: 21 canonical edges, one FSM, twelve abstract anatomy records, "
        "three runtime submissions, deterministic control/escape exchange and safe HUD"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
