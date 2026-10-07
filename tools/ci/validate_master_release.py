#!/usr/bin/env python3
"""Derive release readiness from existing authorities, never from structural PASS."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def release_readiness_report(root: Path = ROOT) -> dict:
    blockers: list[str] = []
    def read(relative: str) -> dict:
        try:
            value = json.loads((root / relative).read_text(encoding="utf-8"))
            if not isinstance(value, dict):
                raise ValueError("root must be an object")
            return value
        except (OSError, ValueError) as exc:
            blockers.append(f"invalid_or_missing:{relative}:{exc}")
            return {}

    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    if subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"], cwd=root, text=True).strip():
        blockers.append("tracked_working_tree_dirty")
    contract = read("data/production/supreme_build_contract_v01.json")
    ledger = read("data/production/release_gate_status_v01.json")
    for name in contract.get("release_gates", []):
        gate = ledger.get("gates", {}).get(name, {})
        if gate.get("status") != "passed":
            blockers.append(f"gate_not_passed:{name}")
        elif gate.get("commit_sha") != head:
            blockers.append(f"stale_evidence:{name}")
        elif not gate.get("checked_at") or not gate.get("evidence"):
            blockers.append(f"missing_evidence:{name}")
    if not contract.get("release_gates"):
        blockers.append("release_gate_contract_empty")

    # Recompute coverage rather than trusting an old generated JSON report.
    with tempfile.TemporaryDirectory(prefix="cria-release-coverage-") as temporary:
        report_path = Path(temporary) / "coverage.json"
        result = subprocess.run([sys.executable, str(root / "tools/ci/validate_production_coverage_v03.py"),
                                 "--shipping", "--report", str(report_path)], cwd=root,
                                capture_output=True, text=True)
        coverage = json.loads(report_path.read_text()) if report_path.exists() else {}
        if result.returncode or coverage.get("shipping_ready") is not True:
            blockers.append("production_coverage_not_shipping_ready")
        blockers.extend(f"production_source:{item['code']}" for item in coverage.get("source_blockers", []))

    sys.path.insert(0, str(root / "tools/ci"))
    from validate_qa_evidence_v1 import validate_android, validate_visual
    qa = read("data/production/qa_evidence_contract_v1.json")
    for section, validate in (("visual_runtime", validate_visual), ("android_physical", validate_android)):
        relative = qa.get(section, {}).get("evidence_path", "")
        evidence = read(relative) if relative else {}
        if evidence.get("status") != "PASS":
            blockers.append(f"qa_not_passed:{section}")
        elif evidence.get("commit_sha") != head:
            blockers.append(f"stale_qa:{section}")
        errors = validate(evidence, qa) if section == "visual_runtime" and qa else validate_android(evidence)
        blockers.extend(f"qa:{section}:{error}" for error in errors)

    migration = read("data/combat/combat_core_v2_contract.json").get("migration", {})
    if migration.get("reducer_flip_allowed") is not True:
        blockers.append("reducer_authority_migration_not_approved")
    return {"source_commit": head, "release_ready": not blockers,
            "production_requirements": coverage.get("requirements_total", 0),
            "production_shipping": coverage.get("states", {}).get("shipping", 0),
            "blockers": sorted(set(blockers))}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", action="store_true", help="Exit 2 while any release gate is blocked")
    args = parser.parse_args()
    report = release_readiness_report()
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 2 if args.release and not report["release_ready"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
