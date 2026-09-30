#!/usr/bin/env python3
"""Build the Codex game-assembly work queue from audited repository contracts.

This tool deliberately operates on metadata only. Binary art remains external until
rights, human approval and the normal asset pipeline allow promotion.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = ROOT / "data/production/codex_game_assembly_v1.json"


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be a JSON object")
    return value


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _material_policy(contract: dict[str, Any]) -> dict[str, dict[str, Any]]:
    policies: dict[str, dict[str, Any]] = {}
    for row in contract.get("material_coverage", []):
        if not isinstance(row, dict) or not row.get("category"):
            raise ValueError("material_coverage rows must define category")
        category = str(row["category"])
        if category in policies:
            raise ValueError(f"duplicate category policy: {category}")
        policies[category] = row
    return policies


def validate_contract_and_intake(
    contract: dict[str, Any], intake: dict[str, Any]
) -> list[str]:
    errors: list[str] = []
    assets = intake.get("assets", [])
    if not isinstance(assets, list):
        return ["visual intake assets must be a list"]

    policies = _material_policy(contract)
    counts = Counter(str(item.get("category")) for item in assets if isinstance(item, dict))

    if len(assets) != int(intake.get("archive", {}).get("constructed_unique_assets", -1)):
        errors.append("asset count does not match intake archive.constructed_unique_assets")

    for category, policy in policies.items():
        actual = counts.get(category, 0)
        expected = int(policy.get("expected_count", -1))
        if actual != expected:
            errors.append(f"{category}: expected {expected}, found {actual}")

    unknown = sorted(set(counts) - set(policies))
    if unknown:
        errors.append(f"categories without assembly policy: {', '.join(unknown)}")

    ids = [str(item.get("asset_id", "")) for item in assets if isinstance(item, dict)]
    if len(ids) != len(set(ids)):
        errors.append("duplicate asset_id in visual intake")
    if any(not asset_id for asset_id in ids):
        errors.append("every visual intake asset requires asset_id")

    if intake.get("shipping") is True or intake.get("runtime_authority") is True:
        errors.append("audited session intake must remain non-shipping and non-runtime-authoritative")

    return errors


def disposition_for(asset: dict[str, Any], policy: dict[str, Any]) -> str:
    status = str(asset.get("review_status", ""))
    blocker = str(asset.get("primary_blocker", ""))

    if asset.get("category") == "private_likeness":
        return "BLOCKED_PRIVATE"
    if asset.get("category") == "map_expansion":
        return "HOLD_EXPANSION"
    if "REJECTED" in status:
        return "REFERENCE_REJECTED"
    if "PREFERRED_IDENTITY_MASTER_CANDIDATE" in status:
        return "PROMOTION_CANDIDATE"
    if status == "CARD_ART_CANDIDATE_T057":
        return "PROMOTION_CANDIDATE"
    if blocker.startswith("runtime_rebuild") or blocker == "runtime_blocked_flattened_ui":
        return "REBUILD_FROM_REFERENCE"
    return "REFERENCE_ONLY"


def build_queue(contract: dict[str, Any], intake: dict[str, Any]) -> dict[str, Any]:
    errors = validate_contract_and_intake(contract, intake)
    if errors:
        raise ValueError("; ".join(errors))

    policies = _material_policy(contract)
    tasks: list[dict[str, Any]] = []
    for asset in intake["assets"]:
        category = str(asset["category"])
        policy = policies[category]
        tasks.append(
            {
                "asset_id": asset["asset_id"],
                "category": category,
                "priority": int(policy["priority"]),
                "disposition": disposition_for(asset, policy),
                "review_status": asset["review_status"],
                "blocker": asset["primary_blocker"],
                "intended_use": policy["use"],
                "promotion_rule": policy["promotion"],
                "shipping": False,
                "runtime_authority": False,
            }
        )

    tasks.sort(key=lambda item: (item["priority"], item["category"], item["asset_id"]))
    return {
        "$schema": "cria.codex_game_assembly.queue.v1",
        "version": contract["version"],
        "status": "DERIVED_WORK_QUEUE",
        "shipping": False,
        "runtime_authority": False,
        "source_contract": "data/production/codex_game_assembly_v1.json",
        "source_intake": contract["visual_intake"],
        "asset_count": len(tasks),
        "milestones": contract["milestones"],
        "tasks": tasks,
    }


def verify_archive(contract: dict[str, Any], archive: Path | None, require: bool) -> None:
    gate = contract["external_material_gate"]
    if archive is None:
        if require:
            raise FileNotFoundError(
                f"required visual archive not provided: {gate['archive_filename']}"
            )
        return
    if not archive.is_file():
        raise FileNotFoundError(str(archive))
    actual = sha256_file(archive)
    expected = str(gate["sha256"])
    if actual != expected:
        raise ValueError(f"archive sha256 mismatch: expected {expected}, got {actual}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--require-archive", action="store_true")
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "production/generated/codex_game_assembly_queue_v1.json",
    )
    args = parser.parse_args()

    contract = read_json(args.contract)
    intake = read_json(ROOT / contract["visual_intake"])
    verify_archive(contract, args.archive, args.require_archive)
    queue = build_queue(contract, intake)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(queue, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"Codex assembly queue: {queue['asset_count']} audited assets -> {args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
