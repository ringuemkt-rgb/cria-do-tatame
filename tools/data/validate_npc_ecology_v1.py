#!/usr/bin/env python3
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data/world/npc_ecology_contract_v1.json"
WORLD_PATH = ROOT / "data/world/world_map_v4.json"
ENGINE_PATH = ROOT / "src/world/NPCEcologyEngineV1.gd"


def fail(message: str):
    print(f"NPC_ECOLOGY_FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main():
    contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    world = json.loads(WORLD_PATH.read_text(encoding="utf-8"))
    engine = ENGINE_PATH.read_text(encoding="utf-8")

    nodes = world.get("nodes", [])
    node_ids = [row.get("id") for row in nodes if isinstance(row, dict)]
    if len(node_ids) != len(set(node_ids)):
        fail("world map has duplicate node ids")
    expected_nodes = int(world.get("canonical_counts", {}).get("nodes", 0))
    if expected_nodes and len(node_ids) != expected_nodes:
        fail(f"world map canonical node count mismatch: {len(node_ids)} != {expected_nodes}")

    tier_ids = [row.get("id") for row in contract.get("simulation_tiers", [])]
    if tier_ids != ["L0_DORMANT", "L1_STATISTICAL", "L2_ACTIVE_REGION", "L3_FULL_RUNTIME"]:
        fail("simulation tiers are incomplete or reordered")

    policy = contract.get("core_policy", {})
    required_true = [
        "offline_core_required",
        "intention_requires_rules_validation",
        "same_seed_and_actions_require_same_state",
        "unknown_node_fails_closed",
        "npc_cannot_use_unknown_information",
    ]
    for key in required_true:
        if policy.get(key) is not True:
            fail(f"core policy {key} must be true")
    if policy.get("llm_may_mutate_world_directly") is not False:
        fail("LLM direct world mutation must be false")

    required_methods = [
        "func validate_profiles",
        "func new_state",
        "func step",
        "func resolve_schedule",
        "func can_access_fact",
        "func remember",
        "func set_event_override",
        "func _tier_for_node",
        "func _select_goal",
        "func _deterministic_jitter",
    ]
    missing = [marker for marker in required_methods if marker not in engine]
    if missing:
        fail("runtime engine missing methods: " + ", ".join(missing))

    completion = contract.get("completion_requirements", {})
    if completion.get("population_source_required_for_shipping") is not True:
        fail("shipping must require a population source")
    if completion.get("runtime_scene_evidence_required_for_shipping") is not True:
        fail("shipping must require runtime scene evidence")

    print(f"NPC_ECOLOGY_OK world_nodes={len(node_ids)} tiers={len(tier_ids)} runtime_foundation=true shipping=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
