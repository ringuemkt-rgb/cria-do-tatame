#!/usr/bin/env python3
"""Validate CRIA Production OS v03 coverage against explicit asset links.

Normal mode reports real coverage and rejects false approval/shipping claims.
Shipping mode additionally requires 100% shipping coverage and zero source blockers.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from derive_production_manifest_v03 import CONTRACT_PATH, Derivator, load_json

ROOT = Path(__file__).resolve().parents[2]
ASSET_REGISTRY = ROOT / "assets/manifest_v2.json"
LINK_LEDGER = ROOT / "production/coverage/asset_links_v1.json"
DEFAULT_REPORT = ROOT / "production/generated/production_coverage_v03.json"


def registry_index(registry: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {row["path"]: row for row in registry.get("assets", []) if row.get("path")}


def gate_bool(link: dict[str, Any], key: str) -> bool:
    value = link.get(key)
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.lower() in {"pass", "passed", "approved", "clear", "cleared", "integrated", "true"}
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--shipping", action="store_true", help="Enforce full shipping readiness")
    parser.add_argument("--report", default=str(DEFAULT_REPORT))
    args = parser.parse_args()

    contract = load_json(CONTRACT_PATH)
    derived = Derivator(ROOT, contract).run()
    requirements = {r["requirement_id"]: r for r in derived["requirements"]}
    registry = load_json(ASSET_REGISTRY)
    by_path = registry_index(registry)
    ledger = load_json(LINK_LEDGER)

    errors: list[str] = []
    state_by_req: dict[str, str] = {rid: "pending" for rid in requirements}
    linked_assets: dict[str, list[str]] = {rid: [] for rid in requirements}

    for link in ledger.get("links", []):
        rid = link.get("requirement_id")
        if rid not in requirements:
            errors.append(f"unknown requirement link: {rid}")
            continue
        paths = link.get("asset_paths", [])
        if not paths:
            errors.append(f"{rid}: link has no asset_paths")
            continue
        missing = [p for p in paths if p not in by_path]
        if missing:
            errors.append(f"{rid}: asset paths missing from assets/manifest_v2.json: {missing}")
            continue
        linked_assets[rid] = list(paths)

        qa = gate_bool(link, "qa_passed")
        human = gate_bool(link, "human_approved")
        rights = gate_bool(link, "rights_cleared")
        integrated = gate_bool(link, "godot_integrated")
        shipping = bool(link.get("shipping", False))

        if shipping and not (qa and human and rights and integrated):
            errors.append(f"{rid}: shipping=true without qa+human+rights+godot gates")
        if integrated and not (qa and human and rights):
            errors.append(f"{rid}: godot_integrated before qa+human+rights")
        if human and not qa:
            errors.append(f"{rid}: human_approved before qa_passed")

        # Binary registry is authoritative for binary-level shipping.
        registry_shipping = all(bool(by_path[p].get("shipping", False)) for p in paths)
        if shipping and not registry_shipping:
            errors.append(f"{rid}: coverage ledger says shipping but binary registry does not")

        if shipping:
            state_by_req[rid] = "shipping"
        elif integrated:
            state_by_req[rid] = "integrated"
        elif human and rights and qa:
            state_by_req[rid] = "human_approved"
        elif qa:
            state_by_req[rid] = "qa_passed"
        else:
            state_by_req[rid] = "generated"

    totals = {"pending": 0, "generated": 0, "qa_passed": 0, "human_approved": 0, "integrated": 0, "shipping": 0}
    for state in state_by_req.values():
        totals[state] += 1
    total = len(requirements)
    shipping_count = totals["shipping"]
    integrated_count = totals["integrated"] + shipping_count
    approved_count = totals["human_approved"] + integrated_count

    def pct(n: int) -> float:
        return round((100.0 * n / total), 2) if total else 0.0

    report = {
        "$schema": "cria.production_coverage.report.v03",
        "version": contract["version"],
        "shipping_mode": args.shipping,
        "requirements_total": total,
        "states": totals,
        "coverage_percent": {
            "human_approved_or_better": pct(approved_count),
            "integrated_or_better": pct(integrated_count),
            "shipping": pct(shipping_count)
        },
        "source_blockers": derived["source_blockers"],
        "validation_errors": errors,
        "shipping_ready": not errors and not derived["source_blockers"] and total > 0 and shipping_count == total,
    }
    out = Path(args.report)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(
        "PRODUCTION_COVERAGE_V03 "
        f"total={total} approved={approved_count} integrated={integrated_count} "
        f"shipping={shipping_count} blockers={len(derived['source_blockers'])} errors={len(errors)}"
    )
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    if args.shipping:
        if derived["source_blockers"]:
            print("ERROR: shipping blocked by unresolved source blockers")
            return 2
        if total == 0 or shipping_count != total:
            print(f"ERROR: shipping coverage {shipping_count}/{total}; 100% required")
            return 3
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
