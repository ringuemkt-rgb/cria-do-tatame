#!/usr/bin/env python3
"""Validate the gold-slice P1 visual authoring queue against Sprite Forge V2."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/visual/p1_visual_build_contract_v2.json"
FORGE = ROOT / "data/visual/sprite_forge_contract_v2.json"
QUEUE = ROOT / "production/p1/cria_art_p1_commands_v1.json"
SLICE = ROOT / "data/bjj/bjj_kg_slice_ruan_davi_v1.json"
WORLD = ROOT / "data/world/arena_info_v1.json"
ROSTER = ROOT / "data/combat/roster_v3.json"


def load(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"{path}: expected object")
    return data


def normalized_location(value: str, aliases: dict[str, str]) -> str:
    return aliases.get(value, value)


def main() -> int:
    errors: list[str] = []
    for path in (CONTRACT, FORGE, QUEUE, SLICE, WORLD, ROSTER):
        if not path.exists():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")
    if errors:
        print(json.dumps({"ok": False, "errors": errors}, indent=2))
        return 1

    contract = load(CONTRACT)
    forge = load(FORGE)
    queue = load(QUEUE)
    slice_data = load(SLICE)
    world = load(WORLD)
    roster = load(ROSTER)

    if contract.get("shipping") is not False:
        errors.append("P1 visual contract must remain shipping=false")

    scope = contract.get("scope", {})
    fighters = set(scope.get("fighters", []))
    canonical_locations = set(scope.get("canonical_world_locations", []))
    aliases = scope.get("location_aliases", {})
    executable = set(scope.get("executable_bjj_techniques", []))
    excluded = set(scope.get("excluded_legality_fixture_techniques", []))

    roster_ids = {row.get("id") for row in roster.get("fighters", [])}
    if not fighters or not fighters.issubset(roster_ids):
        errors.append("P1 fighters must resolve in roster_v3")

    world_ids = {row.get("id") for row in world.get("arenas", [])}
    if not canonical_locations.issubset(world_ids):
        errors.append(f"P1 canonical world ids missing from arena_info_v1: {sorted(canonical_locations - world_ids)}")
    for alias, canonical in aliases.items():
        if canonical not in canonical_locations:
            errors.append(f"location alias {alias} points outside P1 canonical locations: {canonical}")

    technique_ids = {row.get("id") for row in slice_data.get("techniques", [])}
    if not executable.issubset(technique_ids):
        errors.append(f"P1 executable technique ids missing from slice: {sorted(executable - technique_ids)}")
    if not excluded.issubset(technique_ids):
        errors.append(f"P1 excluded fixture ids missing from slice: {sorted(excluded - technique_ids)}")
    expected_executable = technique_ids - excluded
    if executable != expected_executable:
        errors.append(
            "P1 executable technique set must equal slice techniques minus explicit legality fixtures: "
            f"missing={sorted(expected_executable - executable)} extra={sorted(executable - expected_executable)}"
        )

    identity_files = contract.get("identity_gate", {}).get("visual_canon_required", {})
    if set(identity_files) != fighters:
        errors.append("identity_gate must name every P1 fighter exactly once")
    for fighter_id, rel in identity_files.items():
        path = ROOT / rel
        if not path.exists():
            errors.append(f"missing P1 visual canon for {fighter_id}: {rel}")
            continue
        visual = load(path)
        if visual.get("character_id") != fighter_id:
            errors.append(f"visual canon character_id mismatch for {fighter_id}")
        if visual.get("shipping") is not False:
            errors.append(f"visual canon cannot self-promote shipping: {fighter_id}")
        if visual.get("identity", {}).get("real_person_likeness_forbidden") is not True:
            errors.append(f"real-person likeness guardrail missing for {fighter_id}")

    queue_batches = queue.get("batches", [])
    batch_map = {row.get("id"): row for row in queue_batches if isinstance(row, dict)}
    required_batches = contract.get("legacy_queue_contract", {}).get("required_batches", {})
    for batch_id, expected_count in required_batches.items():
        batch = batch_map.get(batch_id)
        if not batch:
            errors.append(f"missing legacy P1 batch: {batch_id}")
            continue
        actual = len(batch.get("commands", []))
        if actual != expected_count:
            errors.append(f"legacy P1 batch count mismatch {batch_id}: expected {expected_count}, got {actual}")

    all_commands: list[dict[str, Any]] = []
    for batch in queue_batches:
        commands = batch.get("commands", []) if isinstance(batch, dict) else []
        all_commands.extend([row for row in commands if isinstance(row, dict)])
    command_ids = [row.get("id") for row in all_commands]
    if len(command_ids) != len(set(command_ids)):
        errors.append("duplicate command ids in legacy P1 queue")

    output_root = contract.get("legacy_queue_contract", {}).get("all_outputs_must_live_under")
    for cmd in all_commands:
        cid = str(cmd.get("id", "<unknown>"))
        if cmd.get("shipping") is not False:
            errors.append(f"{cid}: command must remain shipping=false")
        out = str(cmd.get("out", ""))
        if output_root and not out.startswith(output_root):
            errors.append(f"{cid}: candidate output escaped P1 candidate root: {out}")
        if not cmd.get("auth"):
            errors.append(f"{cid}: missing authority references")

    char_batch = batch_map.get("P1-CHAR-01", {})
    char_sources = {row.get("source_id") for row in char_batch.get("commands", [])}
    if char_sources != fighters:
        errors.append(f"P1 character batch must cover exactly {sorted(fighters)}, got {sorted(x for x in char_sources if x)}")

    tech_batch = batch_map.get("P1-TECH-01", {})
    tech_commands = tech_batch.get("commands", [])
    tech_sources = {row.get("source_id") for row in tech_commands}
    if tech_sources != executable:
        errors.append(f"P1 technique batch diverges from executable slice: expected={sorted(executable)} got={sorted(x for x in tech_sources if x)}")
    for cmd in tech_commands:
        if cmd.get("attacker_id") not in fighters or cmd.get("defender_id") not in fighters:
            errors.append(f"{cmd.get('id')}: paired P1 technique must use P1 fighters")
        if cmd.get("kind") != "PAIRED_TECHNIQUE":
            errors.append(f"{cmd.get('id')}: P1 technique must remain PAIRED_TECHNIQUE")

    arena_batch = batch_map.get("P1-ARENA-01", {})
    normalized_sources = {
        normalized_location(str(row.get("source_id", "")), aliases)
        for row in arena_batch.get("commands", [])
    }
    if normalized_sources != canonical_locations:
        errors.append(
            f"P1 arena batch must resolve to canonical locations {sorted(canonical_locations)}, got {sorted(normalized_sources)}"
        )

    queue_phases = queue.get("global_rules", {}).get("paired_phases", [])
    forge_phases = forge.get("paired_bjj_animation", {}).get("required_phases", [])
    if queue_phases != forge_phases:
        errors.append("legacy P1 paired phases diverge from Sprite Forge V2")

    if "slice_heel_hook" in tech_sources:
        errors.append("legality-only heel-hook fixture cannot create a P1 art command")

    result = {
        "ok": not errors,
        "fighters": sorted(fighters),
        "canonical_locations": sorted(canonical_locations),
        "aliases": aliases,
        "executable_techniques": sorted(executable),
        "commands": len(all_commands),
        "errors": errors,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
