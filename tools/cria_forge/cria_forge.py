#!/usr/bin/env python3
"""Small CLI front door for CRIA Game Forge v1.

This intentionally remains thin. Domain authority lives in executable contracts,
validators, skills and Godot — not in this convenience wrapper.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
REPORTS = ROOT / "reports" / "cria_forge"
CONTRACT = DATA / "production" / "agent_production_contract_v1.json"
DETECTOR = ROOT / "tools" / "agents" / "detect_capabilities.py"
AGENT_VALIDATOR = ROOT / "tools" / "ci" / "validate_agent_production_os_v1.py"
EXTERNAL_VALIDATOR = ROOT / "tools" / "ci" / "validate_external_tool_registry_v1.py"

REQUIRED = ["id", "name_ptbr", "family", "state_from", "state_to_success", "state_to_defended"]


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def validate() -> int:
    errors = []
    for path in DATA.rglob("*.json"):
        try:
            read_json(path)
        except Exception as exc:  # validation report should collect all broken JSON
            errors.append(f"JSON invalido: {path}: {exc}")
    catalog = DATA / "techniques" / "technique_catalog_v05.json"
    if catalog.exists():
        for item in read_json(catalog).get("techniques", []):
            for field in REQUIRED:
                if field not in item:
                    errors.append(f"{item.get('id', 'sem_id')} sem campo {field}")
    else:
        errors.append("catalogo de tecnicas nao encontrado")

    for validator in (EXTERNAL_VALIDATOR, AGENT_VALIDATOR):
        result = subprocess.run(
            [sys.executable, str(validator)], cwd=ROOT, capture_output=True, text=True, check=False
        )
        if result.returncode != 0:
            errors.append(f"{validator.name} falhou: {result.stdout.strip() or result.stderr.strip()}")

    REPORTS.mkdir(parents=True, exist_ok=True)
    report = REPORTS / "validation_report.md"
    if errors:
        report.write_text("# Validation Report\n\n" + "\n".join(f"- {e}" for e in errors) + "\n", encoding="utf-8")
        return 1
    report.write_text("# Validation Report\n\nVALIDATION OK\n", encoding="utf-8")
    return 0


def capabilities(declare: str, write: str) -> int:
    command = [sys.executable, str(DETECTOR)]
    if declare:
        command += ["--declare", declare]
    if write:
        command += ["--write", write]
    return subprocess.run(command, cwd=ROOT, check=False).returncode


def doctor() -> int:
    contract = read_json(CONTRACT)
    required_paths = [
        ROOT / "AGENTS.md",
        CONTRACT,
        ROOT / ".agents/skills/cria-universal-producer/SKILL.md",
        ROOT / ".criaforge/config.yaml",
        ROOT / ".criaforge/quality_gates.yaml",
    ]
    missing = [str(path.relative_to(ROOT)) for path in required_paths if not path.exists()]
    payload = {
        "schema": "cria.game_forge_doctor.v1",
        "version": contract.get("version"),
        "runtime": contract.get("authority", {}).get("runtime"),
        "shipping_authority": contract.get("authority", {}).get("shipping_authority"),
        "workflows": contract.get("workflow_files", []),
        "missing": missing,
        "ok": not missing,
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0 if not missing else 1


def technique_pack(technique_id: str) -> None:
    catalog = read_json(DATA / "techniques" / "technique_catalog_v05.json")
    match = next((item for item in catalog.get("techniques", []) if item.get("id") == technique_id), None)
    if match is None:
        raise SystemExit(f"Tecnica nao encontrada: {technique_id}")
    out = REPORTS / "techniques" / technique_id
    out.mkdir(parents=True, exist_ok=True)
    sprite_request = {
        "status": "candidate_requirement_only",
        "shipping": False,
        "character_id": "ruan_macacao",
        "technique_id": technique_id,
        "name_ptbr": match.get("name_ptbr"),
        "style": "HD Pixel Art 2.5D Regional Premium",
        "workflow": ".criaforge/workflows/paired_bjj_to_runtime.yaml",
        "actions": ["anticipation", "entry", "establish", "stabilize", "response", "recovery"],
        "requirements": [
            "canonical transition",
            "attacker and defender",
            "shared origin",
            "sync_map",
            "contact_map",
            "identity lock",
            "biomechanical review",
            "128x128 RGBA sprite handoff",
            "Godot consumer evidence before completion",
        ],
    }
    write_json(out / "sprite_request.json", sprite_request)
    (out / "qa_report.md").write_text(
        "# QA Report\n\n"
        "- Canon: pending\n"
        "- Combat semantics: pending\n"
        "- Motion/contacts: pending\n"
        "- Art/Sprite Forge: pending\n"
        "- Rights: pending\n"
        "- Godot: pending\n"
        "- Android: pending\n",
        encoding="utf-8",
    )
    print(str(out))


def main() -> None:
    parser = argparse.ArgumentParser(description="CRIA Game Forge v1")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("validate", help="Validate JSON plus universal/external agent contracts")
    sub.add_parser("doctor", help="Check v1 orchestration files and authority boundary")
    cap = sub.add_parser("capabilities", help="Detect local capabilities")
    cap.add_argument("--declare", default="")
    cap.add_argument("--write", default="reports/agent_bootstrap/capabilities.json")
    tech = sub.add_parser("technique", help="Create a fail-closed technique production requirement")
    tech.add_argument("technique_id")
    args = parser.parse_args()

    if args.cmd == "validate":
        raise SystemExit(validate())
    if args.cmd == "doctor":
        raise SystemExit(doctor())
    if args.cmd == "capabilities":
        raise SystemExit(capabilities(args.declare, args.write))
    if args.cmd == "technique":
        technique_pack(args.technique_id)


if __name__ == "__main__":
    main()
