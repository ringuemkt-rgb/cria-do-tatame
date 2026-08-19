#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PLAN = ROOT / "production/mocap/vertical_slice_capture_plan_v1.json"
TECHNIQUES_PATH = ROOT / "data/techniques.json"

EXPECTED_TECHNIQUES = [
    "grip_de_ferro",
    "baiana",
    "sprawl",
    "puxada_guarda",
    "corte_joelho",
    "montada_pesada",
    "saida_montada",
    "mata_leao",
]
EXPECTED_ACTORS = {"ruan_macacao", "davi_relampago"}
REQUIRED_OUTPUTS = {
    "capture_manifest.json",
    "paired_motion.ctt.json",
    "biomechanics_qa.json",
    "human_review.json",
    "visual_qa_v2.json",
    "sync_map.json",
    "preview.gif",
}


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ValueError(f"missing file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid JSON in {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValueError(f"expected JSON object in {path}")
    return payload


def catalog_ids(payload: dict[str, Any]) -> set[str]:
    raw = payload.get("techniques", [])
    if not isinstance(raw, list):
        raise ValueError("data/techniques.json: techniques must be an array")
    result: set[str] = set()
    for item in raw:
        if isinstance(item, dict) and isinstance(item.get("id"), str):
            result.add(item["id"])
    return result


def validate(plan_path: Path) -> list[str]:
    errors: list[str] = []
    plan = load_json(plan_path)

    if plan.get("schema_version") != "1.0.0":
        errors.append("schema_version must be 1.0.0")
    if plan.get("plan_id") != "ctt_vertical_slice_capture_plan_v1":
        errors.append("unexpected plan_id")
    if plan.get("status") != "CAPTURE_PLANNING_ONLY":
        errors.append("capture plan must remain CAPTURE_PLANNING_ONLY")

    source = plan.get("source", {})
    if not isinstance(source, dict):
        errors.append("source must be an object")
        source = {}
    contract_path_value = source.get("vertical_slice_contract")
    if contract_path_value != "data/production/vertical_slice_gold_v1.json":
        errors.append("source.vertical_slice_contract must point to the P0 contract path")
    if source.get("source_pr") != 54:
        errors.append("source.source_pr must remain 54 until the P0 contract is integrated")

    actors = plan.get("actors", {})
    if not isinstance(actors, dict):
        errors.append("actors must be an object")
        actors = {}
    actor_ids = {actors.get("attacker_default"), actors.get("defender_default")}
    if actor_ids != EXPECTED_ACTORS:
        errors.append("capture plan must target Ruan Macacao and Davi Relampago")

    rules = plan.get("global_rules", {})
    if not isinstance(rules, dict):
        errors.append("global_rules must be an object")
        rules = {}
    required_true = [
        "owned_or_explicitly_licensed_capture_required",
        "consent_recorded_required",
        "automatic_asset_promotion_forbidden",
        "synthetic_fixture_shipping_forbidden",
        "runtime_ml_forbidden",
        "human_biomechanical_review_required",
    ]
    for key in required_true:
        if rules.get(key) is not True:
            errors.append(f"global_rules.{key} must be true")

    outputs = rules.get("required_outputs", [])
    if not isinstance(outputs, list) or not REQUIRED_OUTPUTS.issubset(set(outputs)):
        missing = sorted(REQUIRED_OUTPUTS.difference(set(outputs) if isinstance(outputs, list) else set()))
        errors.append(f"required_outputs missing: {missing}")

    raw_techniques = plan.get("techniques", [])
    if not isinstance(raw_techniques, list):
        errors.append("techniques must be an array")
        raw_techniques = []

    planned_ids: list[str] = []
    for index, item in enumerate(raw_techniques):
        if not isinstance(item, dict):
            errors.append(f"techniques[{index}] must be an object")
            continue
        technique_id = item.get("technique_id")
        if not isinstance(technique_id, str) or not technique_id:
            errors.append(f"techniques[{index}].technique_id must be a non-empty string")
            continue
        planned_ids.append(technique_id)
        if item.get("status") != "AWAITING_OWNED_CAPTURE":
            errors.append(f"{technique_id}: status must remain AWAITING_OWNED_CAPTURE before real capture")
        takes = item.get("required_takes", [])
        if not isinstance(takes, list) or len(takes) < 4 or len(set(takes)) != len(takes):
            errors.append(f"{technique_id}: required_takes must contain at least four unique entries")
        profile = item.get("capture_profile")
        if not isinstance(profile, str) or not profile:
            errors.append(f"{technique_id}: capture_profile is required")

    if planned_ids != EXPECTED_TECHNIQUES:
        errors.append(
            "technique order/content must match the P0 eight-technique slice: "
            + ", ".join(EXPECTED_TECHNIQUES)
        )
    if len(planned_ids) != len(set(planned_ids)):
        errors.append("technique IDs must be unique")

    catalog = catalog_ids(load_json(TECHNIQUES_PATH))
    missing_catalog = [technique_id for technique_id in EXPECTED_TECHNIQUES if technique_id not in catalog]
    if missing_catalog:
        errors.append(f"P0 capture techniques missing from data/techniques.json: {missing_catalog}")

    if isinstance(contract_path_value, str):
        contract_path = ROOT / contract_path_value
        if contract_path.exists():
            contract = load_json(contract_path)
            combat = contract.get("combat", {})
            contract_ids = combat.get("paired_technique_ids", []) if isinstance(combat, dict) else []
            if contract_ids != EXPECTED_TECHNIQUES:
                errors.append("capture plan drifted from data/production/vertical_slice_gold_v1.json")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the Cria do Tatame P0 mocap capture plan.")
    parser.add_argument("plan", nargs="?", default=str(DEFAULT_PLAN))
    args = parser.parse_args()

    plan_path = Path(args.plan)
    if not plan_path.is_absolute():
        plan_path = ROOT / plan_path

    try:
        errors = validate(plan_path)
    except ValueError as exc:
        print(json.dumps({"ok": False, "errors": [str(exc)]}, ensure_ascii=False, indent=2))
        return 1

    report = {
        "ok": not errors,
        "plan": str(plan_path.relative_to(ROOT)) if plan_path.is_relative_to(ROOT) else str(plan_path),
        "techniques": EXPECTED_TECHNIQUES,
        "errors": errors,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
