#!/usr/bin/env python3
"""Fail-closed validator for the P1 fight-graphics execution board.

This validates planning state only. It never approves art, rights, biomechanics,
Godot integration or shipping.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
BOARD = ROOT / "production/p1/p1_fight_graphics_execution_v1.json"
QUEUE = ROOT / "production/p1/cria_art_p1_commands_v1.json"

EXPECTED_BATCH_COUNTS = {
    "P1-CHAR-01": 10,
    "P1-TECH-01": 7,
    "P1-ARENA-01": 10,
    "P1-UI-01": 5,
}
EXPECTED_FOCUS = {
    "P1-CHAR-001": "p1_char:ruan_macacao:char_turnaround",
    "P1-CHAR-006": "p1_char:davi_relampago:char_turnaround",
    "P1-TECH-001": "p1_paired:t001:paired_technique",
}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def requirement_id_for_command(cmd: dict[str, Any]) -> str:
    source_id = str(cmd.get("source_id") or cmd["id"]).strip()
    kind = str(cmd.get("kind", "UNKNOWN")).lower()
    category = "p1_" + str(cmd.get("kind", "asset")).split("_")[0].lower()
    return f"{category}:{source_id}:{kind}".lower()


def flatten_queue(queue: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for batch in queue.get("batches", []):
        for cmd in batch.get("commands", []):
            cid = cmd["id"]
            if cid in result:
                raise ValueError(f"duplicate command id: {cid}")
            result[cid] = cmd
    return result


def validate() -> list[str]:
    errors: list[str] = []
    board = load_json(BOARD)
    queue = load_json(QUEUE)
    commands = flatten_queue(queue)

    if board.get("shipping") is not False:
        errors.append("board shipping must remain false")
    policy = board.get("policy", {})
    if policy.get("board_may_not_set_shipping_true") is not True:
        errors.append("board must explicitly forbid setting shipping=true")
    if policy.get("active_coverage_link_requires_real_binary") is not True:
        errors.append("active coverage links must require real binaries")

    batch_counts = {b["id"]: len(b.get("commands", [])) for b in queue.get("batches", [])}
    if batch_counts != EXPECTED_BATCH_COUNTS:
        errors.append(f"P1 queue counts drifted: {batch_counts}")
    if len(commands) != 32:
        errors.append(f"P1 queue must contain 32 commands, got {len(commands)}")

    summary = board.get("summary", {})
    if summary.get("total_commands") != 32:
        errors.append("board total_commands must be 32")
    if summary.get("batches") != EXPECTED_BATCH_COUNTS:
        errors.append("board batch summary drifted from canonical P1 queue")

    statuses = board.get("command_status", {})
    if set(statuses) != set(commands):
        missing = sorted(set(commands) - set(statuses))
        extra = sorted(set(statuses) - set(commands))
        errors.append(f"board command coverage mismatch missing={missing} extra={extra}")

    work_orders = {x["command_id"]: x for x in board.get("priority_work_orders", [])}
    for command_id, expected_requirement in EXPECTED_FOCUS.items():
        cmd = commands.get(command_id)
        if not cmd:
            errors.append(f"missing canonical focus command {command_id}")
            continue
        derived = requirement_id_for_command(cmd)
        if derived != expected_requirement:
            errors.append(f"{command_id}: derived requirement id drifted: {derived}")
        item = work_orders.get(command_id)
        if not item:
            errors.append(f"missing priority work order entry for {command_id}")
            continue
        if item.get("requirement_id") != expected_requirement:
            errors.append(f"{command_id}: board requirement id mismatch")
        path = ROOT / item.get("work_order", "")
        if not path.exists():
            errors.append(f"{command_id}: work order file missing: {path}")

    templates = board.get("coverage_link_templates", [])
    if len(templates) != 3:
        errors.append("exactly three initial coverage templates are expected")
    for item in templates:
        rid = item.get("requirement_id")
        if rid not in EXPECTED_FOCUS.values():
            errors.append(f"unexpected coverage template requirement: {rid}")
        if item.get("asset_paths") != []:
            errors.append(f"{rid}: template asset_paths must stay empty until binaries exist")
        for gate in ("qa_passed", "human_approved", "rights_cleared", "godot_integrated", "shipping"):
            if item.get(gate) is not False:
                errors.append(f"{rid}: template gate {gate} must begin false")

    for command_id, status in statuses.items():
        if "shipping" in status and status["shipping"] is True:
            errors.append(f"{command_id}: command status may not claim shipping")

    ruan = load_json(ROOT / "production/p1/work_orders/ruan_identity_master_v1.json")
    davi = load_json(ROOT / "production/p1/work_orders/davi_identity_master_v1.json")
    t001 = load_json(ROOT / "production/p1/work_orders/t001_baiana_paired_v1.json")

    for name, work in (("ruan", ruan), ("davi", davi), ("t001", t001)):
        if work.get("shipping") is not False:
            errors.append(f"{name}: work order shipping must remain false")
        template = work.get("coverage_template", {})
        if template.get("asset_paths") != []:
            errors.append(f"{name}: work order coverage template must not pre-link binaries")
        if template.get("shipping") is not False:
            errors.append(f"{name}: work order coverage template may not ship")

    if ruan.get("requirement_id") != EXPECTED_FOCUS["P1-CHAR-001"]:
        errors.append("Ruan work order requirement id mismatch")
    if davi.get("requirement_id") != EXPECTED_FOCUS["P1-CHAR-006"]:
        errors.append("Davi work order requirement id mismatch")
    if t001.get("requirement_id") != EXPECTED_FOCUS["P1-TECH-001"]:
        errors.append("t001 work order requirement id mismatch")

    phases = t001.get("paired_contract", {}).get("phases", [])
    if phases != ["anticipation", "entry", "establish", "stabilize", "response", "recovery"]:
        errors.append("t001 paired phase order drifted")
    if len(t001.get("blocking_plan", [])) != 6:
        errors.append("t001 blocking plan must have exactly six phases")
    if t001.get("entry_state") != "standing_neutral" or t001.get("exit_state") != "half_guard_top":
        errors.append("t001 entry/exit drifted from slice KG")

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("P1 Fight Graphics Execution V1: FAIL")
        for error in errors:
            print(f"- {error}")
        return 1
    print("P1 Fight Graphics Execution V1: PASS")
    print("commands=32 focus=Ruan_identity,Davi_identity,t001_Baiana shipping=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
