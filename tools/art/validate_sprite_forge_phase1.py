#!/usr/bin/env python3
"""Validate CRIA Sprite Forge Phase 1A-1C contracts.

This validator checks gate taxonomy, action-profile authority boundaries,
character visual-canon alignment, Canon Adapter compilation and honest Identity
Lock readiness. Missing pending reference art is allowed; approved-but-missing art
is a failure.
"""
from __future__ import annotations

import json
import pathlib
import sys
from typing import Any

TOOLS = pathlib.Path(__file__).resolve().parent
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

import cria_canon_adapter  # noqa: E402
import identity_lock  # noqa: E402

PROFILES_REL = pathlib.Path("data/visual/sprite_qa_profiles_v1.json")
CANON_DIR_REL = pathlib.Path("data/chars/canon")


def _read_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def validate_profiles(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    classes = data.get("gate_classes", {})
    automatic = classes.get("technical_automatic", []) if isinstance(classes, dict) else []
    authority = classes.get("authority", []) if isinstance(classes, dict) else []
    gates = list(automatic) + list(authority)
    if len(automatic) != 14:
        errors.append(f"technical gate count={len(automatic)}, expected=14")
    if len(authority) != 2:
        errors.append(f"authority gate count={len(authority)}, expected=2")
    if len(gates) != 16 or len(set(gates)) != 16:
        errors.append("promotion gates must be exactly 16 unique gates")
    if data.get("promotion_gate_count") != 16:
        errors.append("promotion_gate_count must be 16")
    if set(authority) != {"human_approval", "rights_status"}:
        errors.append("authority gates must be human_approval and rights_status")

    profiles = data.get("profiles", {})
    registry = data.get("action_profile_registry", {})
    if not isinstance(profiles, dict) or not profiles:
        errors.append("profiles must be a non-empty object")
    if not isinstance(registry, dict) or not registry:
        errors.append("action_profile_registry must be a non-empty object")
    else:
        for action, profile_id in registry.items():
            if profile_id not in profiles:
                errors.append(f"action {action} references missing profile {profile_id}")

    upright = profiles.get("upright_grounded", {}) if isinstance(profiles, dict) else {}
    ground = profiles.get("ground_transition", {}) if isinstance(profiles, dict) else {}
    if upright.get("body_height_drift_max") == ground.get("body_height_drift_max"):
        errors.append("upright and ground-transition body-height thresholds must differ")
    guards = data.get("authority_guards", {})
    if guards.get("striking_actions_are_gameplay_authority") is not False:
        errors.append("striking actions must remain tooling-only until gameplay contract reconciliation")
    if guards.get("shipping_requires_all_16_gates") is not True:
        errors.append("shipping_requires_all_16_gates must be true")
    if guards.get("automatic_gate_may_set_human_approval") is not False:
        errors.append("automation cannot set human approval")
    if guards.get("automatic_gate_may_set_rights_status") is not False:
        errors.append("automation cannot originate rights clearance")
    return errors


def validate_character(repo_root: pathlib.Path, canon_path: pathlib.Path) -> list[str]:
    errors: list[str] = []
    try:
        canon = _read_json(canon_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return [f"{canon_path}: {exc}"]
    character_id = str(canon.get("character_id", ""))
    if canon_path.name != f"{character_id}.json":
        errors.append(f"{canon_path}: filename must match character_id")
    if canon.get("shipping") is not False:
        errors.append(f"{character_id}: visual canon cannot authorize shipping")
    ref = canon.get("reference_contract", {})
    status = ref.get("master_reference_status") if isinstance(ref, dict) else None
    ref_rel = ref.get("master_reference") if isinstance(ref, dict) else None
    if status == "approved" and (not isinstance(ref_rel, str) or not (repo_root / ref_rel).is_file()):
        errors.append(f"{character_id}: approved reference missing from repository")
    try:
        spec = cria_canon_adapter.compile_spec(repo_root, character_id)
        if spec.get("shipping") is not False:
            errors.append(f"{character_id}: Canon Adapter output cannot authorize shipping")
        for job in spec.get("jobs", []):
            if job.get("action") in set(canon.get("action_sets", {}).get("striking_candidates", [])):
                if job.get("gameplay_authority") is not False:
                    errors.append(f"{character_id}:{job.get('action')}: striking candidate leaked gameplay authority")
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        errors.append(f"{character_id}: Canon Adapter failed: {exc}")
    try:
        state = identity_lock.reference_status(repo_root, character_id)
        if status != "approved" and state.get("lock_ready") is True:
            errors.append(f"{character_id}: pending reference cannot be lock_ready")
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        errors.append(f"{character_id}: Identity Lock status failed: {exc}")
    return errors


def main() -> int:
    repo_root = pathlib.Path.cwd()
    failures: list[str] = []
    try:
        profiles = _read_json(repo_root / PROFILES_REL)
        failures.extend(validate_profiles(profiles))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        failures.append(f"profiles: {exc}")

    canon_dir = repo_root / CANON_DIR_REL
    canon_files = sorted(canon_dir.glob("*.json")) if canon_dir.exists() else []
    if not canon_files:
        failures.append("no character visual canon files found")
    for canon_path in canon_files:
        failures.extend(validate_character(repo_root, canon_path))

    if failures:
        for failure in failures:
            print("FAIL", failure)
        print(f"Sprite Forge Phase 1 validation failed: {len(failures)} failure(s)")
        return 1
    pending = []
    for canon_path in canon_files:
        character_id = canon_path.stem
        state = identity_lock.reference_status(repo_root, character_id)
        if not state.get("lock_ready"):
            pending.append(character_id)
    print(
        f"Sprite Forge Phase 1 PASS: {len(canon_files)} visual canon record(s); "
        f"identity_lock_pending={','.join(pending) if pending else 'none'}; shipping_authority=unchanged"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
