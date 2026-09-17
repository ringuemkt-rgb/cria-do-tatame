#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(rel: str) -> dict:
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    bridge = load("data/combat/grappling_v2_combat_manager_bridge_v1.json")
    contract = load("data/combat/grappling_engine_v2_contract.json")
    if bridge.get("authorities", {}).get("scene") != "CombatManager":
        errors.append("scene_must_be_CombatManager")
    if bridge.get("authorities", {}).get("presentation") != "CriaGrapplingEngineV2":
        errors.append("presentation_must_be_v2")
    if "bridge_becomes_autoload" not in bridge.get("forbidden", []):
        errors.append("missing_autoload_forbid")
    if contract.get("authorities", {}).get("scene_authority") != "src/autoloads/CombatManager.gd":
        errors.append("contract_missing_scene_authority")
    if contract.get("authority_firewall", {}).get("shadow_runtime_may_change_winner") is not False:
        errors.append("firewall_winner")
    presenter = ROOT / "src/combat/GrapplingV2CombatBridge.gd"
    if not presenter.is_file():
        errors.append("missing_bridge_script")
    if "extends Node" in presenter.read_text(encoding="utf-8"):
        errors.append("bridge_must_not_be_node_autoload")
    if errors:
        print("FAIL")
        for err in errors:
            print(err)
        return 1
    print("OK grappling_v2_bridge")
    return 0


if __name__ == "__main__":
    sys.exit(main())
