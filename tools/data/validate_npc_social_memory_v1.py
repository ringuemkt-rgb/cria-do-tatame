#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/world/npc_social_memory_contract_v1.json"
ECOLOGY = ROOT / "data/world/npc_ecology_contract_v1.json"
COMPONENT = ROOT / "src/world/NPCSocialMemoryV1.gd"
MANAGER = ROOT / "src/autoloads/NPCMemoryManager.gd"
PROJECT = ROOT / "project.godot"
SAVE = ROOT / "src/autoloads/SaveManager.gd"
WORLD = ROOT / "src/autoloads/WorldState.gd"


def fail(message: str) -> None:
    print(f"NPC_SOCIAL_MEMORY_FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        fail(f"{path.relative_to(ROOT)} root must be object")
    return value


def main() -> int:
    for path in (CONTRACT, ECOLOGY, COMPONENT, MANAGER, PROJECT, SAVE, WORLD):
        if not path.is_file():
            fail(f"missing required file: {path.relative_to(ROOT)}")

    contract = load(CONTRACT)
    ecology = load(ECOLOGY)
    component = COMPONENT.read_text(encoding="utf-8")
    manager = MANAGER.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")
    save = SAVE.read_text(encoding="utf-8")
    world = WORLD.read_text(encoding="utf-8")

    principles = contract.get("principles", {})
    for key in (
        "fact_is_not_belief",
        "belief_is_not_claim",
        "private_knowledge_requires_perception_or_reveal",
        "provenance_required",
        "memory_is_bounded",
        "memory_is_versioned",
        "llm_cannot_write_memory",
        "same_state_and_actions_are_deterministic",
    ):
        if principles.get(key) is not True:
            fail(f"principle must remain true: {key}")

    if contract.get("runtime_authority") != "NPCMemoryManager":
        fail("NPCMemoryManager must own social-memory runtime state")
    if contract.get("save_owner") != "SaveManager":
        fail("SaveManager must own persistence")

    event_types = contract.get("event_types", [])
    if event_types != ["FACT_OBSERVED", "FACT_REVEALED", "CLAIM_HEARD", "RELATIONSHIP_DELTA"]:
        fail("event types changed or reordered")

    axes = set(contract.get("relationship_axes", []))
    required_axes = {"respect", "trust", "affection", "rivalry", "fear", "debt", "suspicion"}
    if not required_axes.issubset(axes):
        fail("relationship axes incomplete")

    limits = contract.get("limits", {})
    for key in ("event_log", "known_facts_per_npc", "beliefs_per_npc", "episodes_per_npc", "contradictions_per_npc", "provenance_per_record"):
        value = int(limits.get(key, 0))
        if value <= 0 or value > 256:
            fail(f"memory limit invalid: {key}={value}")

    policy = contract.get("contradiction_policy", {})
    if policy.get("canonical_fact_wins") is not True or policy.get("claim_never_overwrites_fact") is not True:
        fail("canonical fact must always outrank claims/beliefs")

    required_component_methods = (
        "func new_state",
        "func normalize_state",
        "func ingest_event",
        "func knows_fact",
        "func get_npc_context",
        "func choose_action",
        "func _apply_fact",
        "func _apply_claim",
        "func _record_contradiction",
        "func _adjust_relationship",
        "func _deterministic_jitter",
    )
    for marker in required_component_methods:
        if marker not in component:
            fail(f"component missing method: {marker}")

    forbidden_component_fragments = (
        "HTTPRequest",
        "http://",
        "https://",
        "LocalAIManager",
        "record_event(\"mission",
        "WorldState.modify_reputation",
    )
    for marker in forbidden_component_fragments:
        if marker in component:
            fail(f"social-memory component contains forbidden dependency/write: {marker}")

    if 'NPCMemoryManager="*res://src/autoloads/NPCMemoryManager.gd"' not in project:
        fail("NPCMemoryManager is not registered as autoload")
    if 'data["npc_memory_state"] = NPCMemoryManager.to_dict()' not in save:
        fail("SaveManager does not serialize NPC memory")
    if 'NPCMemoryManager.load_from_dict(parsed.get("npc_memory_state", {}))' not in save:
        fail("SaveManager does not restore NPC memory")
    if 'not parsed.has("npc_memory_state")' not in save:
        fail("legacy saves missing NPC memory are not migration candidates")
    if "NPCMemoryManager.reset()" not in world:
        fail("new game does not reset NPC memory")

    for marker in (
        "func observe_fact",
        "func reveal_fact",
        "func hear_claim",
        "func adjust_relationship",
        "func choose_action",
        "func to_dict",
        "func load_from_dict",
        "producer_forbidden",
    ):
        if marker not in manager:
            fail(f"NPCMemoryManager missing contract marker: {marker}")

    ecology_scopes = set(ecology.get("knowledge_scopes", []))
    memory_scopes = set(contract.get("knowledge_scopes", []))
    if ecology_scopes != memory_scopes:
        fail("social-memory knowledge scopes diverge from NPC ecology contract")

    print(
        "NPC_SOCIAL_MEMORY_OK "
        f"events={len(event_types)} axes={len(axes)} bounded=true persistent=true llm_write=false"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
