#!/usr/bin/env python3
"""Validate repository governance and single-source invariants."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data" / "production" / "repository_governance_v01.json"


def fail(message: str, errors: list[str]) -> None:
    errors.append(message)


def main() -> int:
    errors: list[str] = []

    if not CONTRACT.is_file():
        print(f"ERROR: missing governance contract: {CONTRACT.relative_to(ROOT)}")
        return 1

    try:
        contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: invalid governance contract: {exc}")
        return 1

    for relative in contract.get("required_root_files", []):
        path = ROOT / relative
        if not path.is_file():
            fail(f"missing required root file: {relative}", errors)

    for relative in contract.get("required_governance_files", []):
        path = ROOT / relative
        if not path.is_file():
            fail(f"missing governance file: {relative}", errors)

    for relative in contract.get("canonical_directories", []):
        path = ROOT / relative
        if not path.is_dir():
            fail(f"missing canonical directory: {relative}", errors)

    for relative in contract.get("forbidden_parallel_runtime_paths", []):
        path = ROOT / relative
        if path.exists():
            fail(f"parallel runtime path is forbidden: {relative}", errors)

    project_path = ROOT / "project.godot"
    if project_path.is_file():
        project_text = project_path.read_text(encoding="utf-8")
        expected_scene = contract.get("protected_invariants", {}).get("main_scene", "")
        expected_line = f'run/main_scene="{expected_scene}"'
        if expected_scene and expected_line not in project_text:
            fail(f"main scene must remain {expected_scene}", errors)

    pr_template = ROOT / ".github" / "pull_request_template.md"
    if pr_template.is_file():
        body = pr_template.read_text(encoding="utf-8").lower()
        required_terms = {
            "objective": "objetivo",
            "scope": "escopo",
            "integration_consumer": "integração",
            "tests": "testes",
            "risks": "riscos",
            "rollback": "rollback",
        }
        for field in contract.get("required_pull_request_evidence", []):
            term = required_terms.get(field, field.lower())
            if term not in body:
                fail(f"pull request template lacks required evidence field: {field}", errors)

    if errors:
        print("Repository governance validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Repository governance validation passed.")
    print(f"- repository: {contract.get('repository')}")
    print(f"- source of truth: {contract.get('single_source_of_truth')}")
    print(f"- required files: {len(contract.get('required_root_files', []))}")
    print(f"- governance files: {len(contract.get('required_governance_files', []))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
