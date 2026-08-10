#!/usr/bin/env python3
"""Validate deterministic, action-based ground stamina and its runtime consumer."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STAMINA_PATH = ROOT / "data" / "combat" / "ground_stamina_v01.json"
GRAPH_PATH = ROOT / "data" / "combat" / "ground_graph_v01.json"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    stamina = load_json(STAMINA_PATH)
    graph = load_json(GRAPH_PATH)
    require(stamina.get("$schema") == "ground_stamina_v1", "invalid ground stamina schema")
    require(stamina.get("simulation") == "per_resolved_action_deterministic", "stamina must resolve per action")
    require(stamina.get("runtime_owner") == "CombatManager", "stamina introduced a second runtime owner")
    policy = stamina.get("policy", {})
    for key in ["wall_clock_drain", "background_process", "health_damage", "injury_outcome", "submission_terminal_actions_scaled"]:
        require(policy.get(key) is False, f"unsafe or nondeterministic stamina policy enabled: {key}")

    graph_states = {str(item.get("id", "")) for item in graph.get("states", []) if isinstance(item, dict)}
    state_costs = stamina.get("state_action_surcharge", {})
    require(set(state_costs) == graph_states, "stamina states must mirror the single canonical FSM")
    maximum = float(stamina.get("limits", {}).get("max_action_surcharge", 0.0))
    require(0.0 < maximum <= 2.0, "ground surcharge cap is outside the approved range")
    require(all(0.0 <= float(value) <= maximum for value in state_costs.values()), "ground surcharge exceeds its cap")

    bands = stamina.get("fatigue_bands", [])
    require([float(item.get("gas_at_or_below", -1)) for item in bands] == [50.0, 25.0, 10.0], "fatigue thresholds changed")
    require([float(item.get("submission_effectiveness", 0)) for item in bands] == [0.92, 0.78, 0.60], "fatigue effectiveness changed")
    require(all(-0.14 <= float(item.get("chance_modifier", 1)) <= 0.0 for item in bands), "fatigue chance modifier is unsafe")

    registry = (ROOT / "src" / "autoloads" / "DataRegistry.gd").read_text(encoding="utf-8")
    manager = (ROOT / "src" / "autoloads" / "CombatManager.gd").read_text(encoding="utf-8")
    exchange = (ROOT / "src" / "combat" / "SubmissionExchange.gd").read_text(encoding="utf-8")
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    require('"ground_stamina"' in registry, "DataRegistry does not load ground stamina")
    require("GroundStaminaRulesScript" in manager and "decorate_technique" in manager, "CombatManager does not consume ground stamina")
    require("submission_effectiveness" in manager and "effectiveness" in exchange, "submission fatigue is not integrated")
    require("func _process" not in (ROOT / "src" / "combat" / "GroundStaminaRules.gd").read_text(encoding="utf-8"), "stamina cannot drain by frame")
    require('GroundStamina="' not in project, "ground stamina must not become an autoload")

    print("[ground-stamina] ok: 14 FSM states, per-action surcharge, three bounded fatigue bands and deterministic submission scaling")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
