#!/usr/bin/env python3
"""Fail-closed validator for CRIA Grappling Runtime V1 golden chain."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
GRAPH_PATH = ROOT / "data/bjj/bjj_kg_slice_ruan_davi_v1.json"
GOLDEN_PATH = ROOT / "data/combat/golden_chain_ruan_davi_v1.json"
BINDINGS_PATH = ROOT / "data/combat/grappling_physical_bindings_slice_v1.json"
MOTION_PATH = ROOT / "data/visual/golden_chain_motion_requirements_v1.json"
PHYSICAL_SCHEMA_PATH = ROOT / "assets/schemas/grappling_physical_state_v1.schema.json"
RUNTIME_PATH = ROOT / "src/combat/CriaGrapplingRuntimeV1.gd"
PHYSICAL_RUNTIME_PATH = ROOT / "src/combat/GrapplingPhysicalStateV1.gd"
GRAPH_RUNTIME_PATH = ROOT / "src/combat/GrapplingConnectionGraphV1.gd"
MOTION_RUNTIME_PATH = ROOT / "src/animation/BJJMotionBindingV1.gd"
SMOKE_PATH = ROOT / "tests/grappling_golden_chain_smoke.gd"

PHASES = ["anticipation", "entry", "establish", "stabilize", "response", "recovery"]


def fail(message: str) -> None:
    print(f"GRAPPLING_GOLDEN_CHAIN_FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"{path.relative_to(ROOT)} invalid: {exc}")
    if not isinstance(value, dict):
        fail(f"{path.relative_to(ROOT)} must be an object")
    return value


def text(path: Path) -> str:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def technique_index(graph: dict[str, Any]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for raw in graph.get("techniques", []):
        if isinstance(raw, dict) and raw.get("id"):
            out[str(raw["id"])] = raw
    return out


def validate() -> dict[str, Any]:
    graph = load_json(GRAPH_PATH)
    golden = load_json(GOLDEN_PATH)
    bindings = load_json(BINDINGS_PATH)
    motion = load_json(MOTION_PATH)
    physical_schema = load_json(PHYSICAL_SCHEMA_PATH)

    if graph.get("full_graph_claim") is not False:
        fail("slice graph must not claim full graph authority")
    if graph.get("source_status", {}).get("promotion_blocked") is not True:
        fail("slice graph promotion must remain blocked")
    if golden.get("status") != "SLICE_ONLY_FAIL_CLOSED" or golden.get("shipping") is not False:
        fail("golden chain must remain slice-only and shipping=false")
    if golden.get("motion_authority") != "VISUAL_ONLY_NON_AUTHORITATIVE":
        fail("motion authority must remain non-authoritative")
    if golden.get("motion_phases") != PHASES:
        fail("golden chain phases must match canonical six-phase order")
    if physical_schema.get("$id") != "cria.grappling_physical_state.v1.schema":
        fail("unexpected physical-state schema id")

    positions = {str(p.get("id")) for p in graph.get("positions", []) if isinstance(p, dict) and p.get("id")}
    techniques = technique_index(graph)
    used_ids: set[str] = set()

    success_chain = golden.get("success_chain", [])
    if not isinstance(success_chain, list) or len(success_chain) < 4:
        fail("success_chain must contain the representative four-step path")
    expected_from = "standing_neutral"
    for index, step in enumerate(success_chain):
        if not isinstance(step, dict):
            fail(f"success_chain[{index}] must be an object")
        tid = str(step.get("technique_id", ""))
        if tid not in techniques:
            fail(f"success chain invents unknown technique: {tid}")
        source = techniques[tid]
        declared_from = str(step.get("from", ""))
        declared_to = str(step.get("to", ""))
        if declared_from != str(source.get("from", "")) or declared_to != str(source.get("to", "")):
            fail(f"success chain transition disagrees with graph: {tid}")
        if declared_from != expected_from:
            fail(f"success chain is discontinuous before {tid}: expected {expected_from}, got {declared_from}")
        if declared_from not in positions or declared_to not in positions:
            fail(f"success chain references unknown position: {tid}")
        declared_event = str(step.get("scoring_event", ""))
        source_event = str(source.get("scoring_event", ""))
        if declared_event != source_event:
            fail(f"success chain scoring event disagrees with graph: {tid}")
        expected_from = declared_to
        used_ids.add(tid)
    if expected_from != "submission":
        fail("success chain must end at submission")

    defense_branches = golden.get("defense_branches", [])
    if not isinstance(defense_branches, list) or len(defense_branches) < 2:
        fail("two representative defense branches are required")
    for index, branch in enumerate(defense_branches):
        if not isinstance(branch, dict):
            fail(f"defense_branches[{index}] must be an object")
        attack_id = str(branch.get("attack_id", ""))
        counter_id = str(branch.get("counter_id", ""))
        if attack_id not in techniques or counter_id not in techniques:
            fail(f"defense branch references unknown technique: {attack_id}/{counter_id}")
        attack = techniques[attack_id]
        counter = techniques[counter_id]
        counter_ids = {str(c.get("technique_id", "")) for c in attack.get("counters", []) if isinstance(c, dict)}
        if counter_id not in counter_ids:
            fail(f"counter relation absent from graph: {attack_id}->{counter_id}")
        if str(branch.get("from", "")) != str(attack.get("from", "")):
            fail(f"defense branch from-state disagrees with attack: {attack_id}")
        if str(branch.get("to", "")) != str(counter.get("to", "")):
            fail(f"defense branch result disagrees with counter: {counter_id}")
        if float(branch.get("defense_elapsed_ms", -1)) < 0:
            fail(f"defense branch timing missing: {attack_id}")
        used_ids.update([attack_id, counter_id])

    for index, branch in enumerate(golden.get("alternate_branches", [])):
        if not isinstance(branch, dict):
            fail(f"alternate_branches[{index}] must be an object")
        tid = str(branch.get("technique_id", ""))
        if tid not in techniques:
            fail(f"alternate branch invents unknown technique: {tid}")
        source = techniques[tid]
        if str(branch.get("from", "")) != str(source.get("from", "")) or str(branch.get("to", "")) != str(source.get("to", "")):
            fail(f"alternate branch transition disagrees with graph: {tid}")
        used_ids.add(tid)

    if motion.get("shipping") is not False:
        fail("motion requirement ledger cannot be shipping evidence")
    if motion.get("phases") != PHASES:
        fail("motion requirements must use canonical six-phase order")
    motion_rows = {str(row.get("technique_id", "")): row for row in motion.get("requirements", []) if isinstance(row, dict)}
    missing_motion = sorted(used_ids - set(motion_rows))
    if missing_motion:
        fail(f"golden techniques missing motion requirements: {missing_motion}")
    for tid in used_ids:
        row = motion_rows[tid]
        source = techniques[tid]
        if str(row.get("from", "")) != str(source.get("from", "")) or str(row.get("to", "")) != str(source.get("to", "")):
            fail(f"motion requirement transition disagrees with graph: {tid}")
        if row.get("asset_status") == "APPROVED_FINAL" and row.get("human_approval") is not True:
            fail(f"approved final motion lacks human approval: {tid}")

    policy = bindings.get("policy", {})
    if policy.get("runtime_may_apply_pending_binding") is not False:
        fail("pending physical binding must never be runtime-applicable")
    if policy.get("runtime_may_infer_hidden_contact") is not False:
        fail("runtime must not infer hidden grappling contacts")
    binding_rows = {str(row.get("technique_id", "")): row for row in bindings.get("bindings", []) if isinstance(row, dict)}
    missing_bindings = sorted(used_ids - set(binding_rows))
    if missing_bindings:
        fail(f"golden techniques missing physical binding ledger rows: {missing_bindings}")
    approved_bindings = 0
    for tid in used_ids:
        row = binding_rows[tid]
        status = str(row.get("review_status", ""))
        if status not in {"PENDING", "APPROVED", "FAIL"}:
            fail(f"invalid physical binding review status: {tid}:{status}")
        if status == "APPROVED":
            approved_bindings += 1
            if not row.get("evidence_refs") or not str(row.get("reviewer", "")).strip():
                fail(f"approved binding lacks evidence/reviewer: {tid}")
            if not row.get("phase_edges"):
                fail(f"approved binding lacks phase edges: {tid}")

    runtime = text(RUNTIME_PATH)
    physical_runtime = text(PHYSICAL_RUNTIME_PATH)
    graph_runtime = text(GRAPH_RUNTIME_PATH)
    motion_runtime = text(MOTION_RUNTIME_PATH)
    smoke = text(SMOKE_PATH)
    required_runtime_tokens = [
        "BJJGraphReducerV2.gd",
        '"renderer_authoritative": false',
        '"authoritative_state_changed_by_renderer": false',
        "PhysicalStateScript.from_reducer_state",
        "motion_binding.build_request",
    ]
    for token in required_runtime_tokens:
        if token not in runtime:
            fail(f"grappling runtime missing authority token: {token}")
    if '"UNKNOWN"' not in physical_runtime or "review_status" not in physical_runtime:
        fail("physical runtime must preserve unknowns and reviewed-binding gate")
    if "validate_edge" not in graph_runtime or "EDGE_TYPES" not in graph_runtime:
        fail("connection graph validator incomplete")
    if '"may_mutate_combat": false' not in motion_runtime or '"visual_only": true' not in motion_runtime:
        fail("motion binding must be visual-only")
    if "GRAPPLING_GOLDEN_CHAIN_SMOKE PASS" not in smoke:
        fail("golden-chain Godot smoke marker missing")

    return {
        "ok": True,
        "golden_techniques": len(used_ids),
        "success_steps": len(success_chain),
        "defense_branches": len(defense_branches),
        "approved_physical_bindings": approved_bindings,
        "pending_physical_bindings": len(used_ids) - approved_bindings,
        "full_graph_claim": False,
        "shipping": False,
    }


def main() -> int:
    report = validate()
    print("GRAPPLING_GOLDEN_CHAIN_PASS " + json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
