#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

PATHS = {
    "contract": ROOT / "data/combat/grappling_engine_v2_contract.json",
    "grips": ROOT / "data/combat/grip_topology_v1.json",
    "reactions": ROOT / "data/combat/grappling_reaction_policy_v1.json",
    "motion": ROOT / "data/animation/grappling_motion_matching_profile_v1.json",
    "research": ROOT / "data/research/grappling_engine_research_registry_v1.json",
    "grip_runtime": ROOT / "src/combat/GrapplingGripGraphV1.gd",
    "microstate": ROOT / "src/combat/GrapplingMicroStateV1.gd",
    "reaction_runtime": ROOT / "src/combat/GrapplingReactionSelectorV1.gd",
    "matcher": ROOT / "src/animation/GrapplingMotionMatcherV1.gd",
    "facade": ROOT / "src/combat/CriaGrapplingEngineV2.gd",
}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def validate_contract(contract: dict) -> None:
    require(contract.get("version") == "2.0.0", "engine contract version must be 2.0.0")
    require(contract.get("authorities", {}).get("combat_truth") == "src/combat/BJJGraphReducerV2.gd", "BJJGraphReducerV2 must remain combat authority")
    firewall = contract.get("authority_firewall", {})
    for key in (
        "shadow_runtime_may_change_reducer_position",
        "shadow_runtime_may_change_score",
        "shadow_runtime_may_change_winner",
        "shadow_runtime_may_change_rng",
        "motion_clip_may_change_outcome",
        "reaction_selector_may_execute_defense",
        "renderer_may_invent_grip",
    ):
        require(firewall.get(key) is False, f"authority firewall must keep {key}=false")
    require(contract.get("runtime_performance_targets", {}).get("heavy_ml_in_runtime") is False, "heavy ML must stay out of runtime")
    require(contract.get("runtime_performance_targets", {}).get("runtime_3d_physics_required") is False, "runtime 3D physics must not be required")


def validate_grips(grips: dict) -> None:
    require(grips.get("version") == "1.0.0", "grip topology version mismatch")
    require(grips.get("principles", {}).get("one_active_grip_per_hand") is True, "one-grip-per-hand rule missing")
    require(grips.get("principles", {}).get("maximum_active_hand_grips_per_player") == 2, "max grip slots must be two")
    seen: set[str] = set()
    gi_only = 0
    shared = 0
    for spec in grips.get("grip_types", []):
        grip_id = spec.get("id")
        require(isinstance(grip_id, str) and grip_id, "grip id missing")
        require(grip_id not in seen, f"duplicate grip type: {grip_id}")
        seen.add(grip_id)
        modes = spec.get("modes", [])
        require(modes and set(modes).issubset({"gi", "nogi"}), f"invalid modes for grip {grip_id}")
        require(spec.get("targets"), f"grip {grip_id} has no targets")
        if modes == ["gi"]:
            gi_only += 1
        if set(modes) == {"gi", "nogi"}:
            shared += 1
    require(gi_only >= 5, "gi topology is too shallow")
    require(shared >= 5, "shared body-control topology is too shallow")
    require("cross_collar" in seen and "underhook" in seen and "wrist_control" in seen, "core grip families missing")


def validate_reactions(reactions: dict) -> None:
    require(reactions.get("version") == "1.0.0", "reaction policy version mismatch")
    ids: set[str] = set()
    for row in reactions.get("reactions", []):
        rid = row.get("id")
        require(isinstance(rid, str) and rid, "reaction id missing")
        require(rid not in ids, f"duplicate reaction id: {rid}")
        ids.add(rid)
        for attack_type in row.get("attack_types", []):
            require(attack_type == attack_type.strip() and attack_type, f"invalid attack type token in {rid}: {attack_type!r}")
        require(set(row.get("modes", [])).issubset({"gi", "nogi"}), f"invalid reaction mode: {rid}")
    require({"sprawl_frame", "frame_hip_escape", "grip_break_posture", "wrist_peel_head_position"}.issubset(ids), "core reaction families missing")
    hard = reactions.get("hard_rules", {})
    require(hard.get("selector_executes_combat_action") is False, "reaction selector may not execute combat")
    require(hard.get("selector_changes_score") is False, "reaction selector may not score")


def validate_motion(profile: dict) -> None:
    require(profile.get("version") == "1.0.0", "motion matching profile version mismatch")
    runtime = profile.get("runtime", {})
    require(runtime.get("ml_inference") is False, "motion matcher may not require runtime ML")
    require(runtime.get("deterministic") is True, "motion matcher must be deterministic")
    require(profile.get("pixel_constraints", {}).get("shared_pair_pivot_required") is True, "paired pivot gate missing")
    require(profile.get("pixel_constraints", {}).get("sync_map_required_for_paired_technique") is True, "sync map gate missing")
    weights = profile.get("weights", {})
    for key in profile.get("query_features", []):
        if key == "previous_clip_id":
            continue
        require(key in weights, f"missing motion weight for {key}")
        require(float(weights[key]) > 0.0, f"motion weight must be positive: {key}")


def validate_research(research: dict) -> None:
    require(research.get("version") == "1.0.0", "research registry version mismatch")
    ids: set[str] = set()
    for row in research.get("sources", []):
        rid = row.get("id")
        require(rid not in ids, f"duplicate research source: {rid}")
        ids.add(rid)
        require(row.get("shipping_dependency") is False, f"research source must not become shipping dependency: {rid}")
    require({"interagent_cvpr2026", "protomotions3", "mimickit", "godot_motion_matching_guilherme"}.issubset(ids), "high-value research references missing")


def validate_gdscript_surfaces() -> None:
    expected_classes = {
        "grip_runtime": "class_name GrapplingGripGraphV1",
        "microstate": "class_name GrapplingMicroStateV1",
        "reaction_runtime": "class_name GrapplingReactionSelectorV1",
        "matcher": "class_name GrapplingMotionMatcherV1",
        "facade": "class_name CriaGrapplingEngineV2",
    }
    for key, token in expected_classes.items():
        text = PATHS[key].read_text(encoding="utf-8")
        require(token in text, f"missing GDScript class declaration: {token}")
    facade = PATHS["facade"].read_text(encoding="utf-8")
    require("authoritative_state_changed_by_grappling_engine_v2" in facade, "facade must explicitly expose authority firewall evidence")
    require("BaseRuntimeScript" in facade and "CriaGrapplingRuntimeV1.gd" in facade, "v2 facade must wrap v1 runtime")


def main() -> int:
    for path in PATHS.values():
        require(path.exists(), f"missing required file: {path.relative_to(ROOT)}")
    contract = load_json(PATHS["contract"])
    grips = load_json(PATHS["grips"])
    reactions = load_json(PATHS["reactions"])
    motion = load_json(PATHS["motion"])
    research = load_json(PATHS["research"])
    validate_contract(contract)
    validate_grips(grips)
    validate_reactions(reactions)
    validate_motion(motion)
    validate_research(research)
    validate_gdscript_surfaces()
    print(
        "Grappling Engine V2 contract OK — "
        f"{len(grips['grip_types'])} grip types, "
        f"{len(reactions['reactions'])} reactions, "
        f"{len(research['sources'])} research sources"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
