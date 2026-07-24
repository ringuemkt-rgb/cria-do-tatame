#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "data" / "production" / "supreme_build_contract_v01.json"
GATE_STATUS_PATH = ROOT / "data" / "production" / "release_gate_status_v01.json"
SPEC_PATH = ROOT / "docs" / "CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md"
VALID_GATE_STATUSES = {"pending", "passed", "failed", "blocked"}

MINIMUM_TARGETS = {
    "characters": 18,
    "arenas": 15,
    "paired_bjj_techniques": 50,
    "career_acts": 5,
    "career_endings": 5,
    "missions": 40,
    "ui_screens": 18,
    "sfx": 100,
    "music_cues": 20,
    "ambience_loops": 12,
}

REQUIRED_FLOW = {
    "main_menu",
    "terreiro",
    "combat",
    "result",
    "save",
    "career_week_advance",
    "return_to_terreiro",
}

REQUIRED_PAIRED_PHASES = {
    "anticipation",
    "entry",
    "establish",
    "stabilize",
    "response",
    "recovery",
}

REQUIRED_GATES = {
    "npm_run_quality",
    "vertical_slice_smoke",
    "save_load_roundtrip",
    "android_arm64_export",
    "android_physical_device_playtest",
    "asset_license_audit",
    "canon_review",
}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def version_tuple(value: str) -> tuple[int, ...]:
    parts: list[int] = []
    for token in value.split("."):
        digits = "".join(character for character in token if character.isdigit())
        if not digits:
            break
        parts.append(int(digits))
    return tuple(parts)


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    if not CONTRACT_PATH.exists():
        errors.append(f"contrato ausente: {CONTRACT_PATH.relative_to(ROOT)}")
        print(json.dumps({"ok": False, "errors": errors}, ensure_ascii=False, indent=2))
        return 1

    if not SPEC_PATH.exists():
        errors.append(f"especificação ausente: {SPEC_PATH.relative_to(ROOT)}")
    if not GATE_STATUS_PATH.exists():
        errors.append(f"ledger de release ausente: {GATE_STATUS_PATH.relative_to(ROOT)}")

    contract = load_json(CONTRACT_PATH)
    canon = contract.get("canon", {})
    runtime = contract.get("runtime", {})
    targets = contract.get("content_targets", {})
    combat = contract.get("combat_contract", {})

    if canon.get("protagonist_id") != "ruan_macacao":
        errors.append("protagonista canônico deve ser ruan_macacao")
    if canon.get("symbol") != "gorila_silverback":
        errors.append("símbolo canônico deve ser gorila_silverback")

    if runtime.get("engine") != "Godot":
        errors.append("Godot deve ser a única engine de runtime")
    if version_tuple(str(runtime.get("minimum_version", "0"))) < (4, 2):
        errors.append("versão mínima de Godot não pode ser inferior a 4.2")
    if runtime.get("offline_gameplay_required") is not True:
        errors.append("gameplay offline é obrigatório")
    if runtime.get("secondary_runtime_forbidden") is not True:
        errors.append("o contrato deve proibir segundo runtime")

    for key, minimum in MINIMUM_TARGETS.items():
        value = targets.get(key)
        if not isinstance(value, int) or value < minimum:
            errors.append(f"meta {key} deve ser inteira e >= {minimum}; recebido: {value}")

    missing_flow = sorted(REQUIRED_FLOW - set(contract.get("mandatory_flow", [])))
    if missing_flow:
        errors.append(f"fluxo obrigatório incompleto: {', '.join(missing_flow)}")

    missing_phases = sorted(REQUIRED_PAIRED_PHASES - set(combat.get("paired_animation_phases", [])))
    if missing_phases:
        errors.append(f"animação pareada sem fases: {', '.join(missing_phases)}")
    if combat.get("deterministic_core") is not True:
        errors.append("combate crítico deve ser determinístico")
    if combat.get("generic_striking_core_forbidden") is not True:
        errors.append("contrato deve proibir striking genérico como núcleo")

    missing_gates = sorted(REQUIRED_GATES - set(contract.get("release_gates", [])))
    if missing_gates:
        errors.append(f"release gates ausentes: {', '.join(missing_gates)}")

    gate_statuses: dict[str, Any] = {}
    if GATE_STATUS_PATH.exists():
        ledger = load_json(GATE_STATUS_PATH)
        gate_statuses = ledger.get("gates", {})
        contract_gates = set(contract.get("release_gates", []))
        ledger_gates = set(gate_statuses)
        missing_statuses = sorted(contract_gates - ledger_gates)
        unexpected_statuses = sorted(ledger_gates - contract_gates)
        if missing_statuses:
            errors.append(f"release gates sem status: {', '.join(missing_statuses)}")
        if unexpected_statuses:
            errors.append(f"status sem gate no contrato: {', '.join(unexpected_statuses)}")
        for gate_id, gate in gate_statuses.items():
            status = gate.get("status")
            if status not in VALID_GATE_STATUSES:
                errors.append(f"status inválido para {gate_id}: {status}")
            if status != "passed":
                continue
            evidence = gate.get("evidence")
            if not isinstance(evidence, dict):
                errors.append(f"gate aprovado sem evidência estruturada: {gate_id}")
                continue
            missing_evidence = [
                field
                for field in ("commit_sha", "checked_at")
                if not evidence.get(field)
            ]
            if not evidence.get("url") and not evidence.get("artifact"):
                missing_evidence.append("url|artifact")
            if missing_evidence:
                errors.append(
                    f"gate aprovado com evidência incompleta ({', '.join(missing_evidence)}): {gate_id}"
                )

    phases = contract.get("production_phases", [])
    phase_ids = [phase.get("id") for phase in phases]
    if len(phases) < 6 or len(set(phase_ids)) != len(phase_ids):
        errors.append("plano deve possuir pelo menos seis fases com IDs únicos")

    claim = contract.get("completion_claim", {})
    if claim.get("allowed_only_when_all_release_gates_pass") is not True:
        errors.append("declaração de conclusão deve depender de todos os release gates")

    passed_gates = sorted(
        gate_id
        for gate_id, gate in gate_statuses.items()
        if gate.get("status") == "passed"
    )
    non_passing_gates = sorted(
        gate_id
        for gate_id, gate in gate_statuses.items()
        if gate.get("status") != "passed"
    )
    completion_ready = bool(gate_statuses) and not non_passing_gates and not errors
    if non_passing_gates:
        warnings.append(
            "declaração de conclusão bloqueada; gates não aprovados: "
            + ", ".join(non_passing_gates)
        )

    catalog = contract.get("approved_research_catalog", [])
    for item in catalog:
        if not item.get("license") or not item.get("decision") or not item.get("url"):
            errors.append(f"ferramenta pesquisada sem licença/decisão/URL: {item.get('name', 'sem nome')}")
    if len(catalog) < 4:
        warnings.append("catálogo de ferramentas possui menos de quatro candidatos auditados")

    result = {
        "ok": not errors,
        "contract": str(CONTRACT_PATH.relative_to(ROOT)),
        "errors": errors,
        "warnings": warnings,
        "targets": targets,
        "release_gate_count": len(contract.get("release_gates", [])),
        "release_gates_passed": len(passed_gates),
        "release_gates_pending_or_blocked": non_passing_gates,
        "completion_ready": completion_ready,
        "research_tool_count": len(catalog),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
