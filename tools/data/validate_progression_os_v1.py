#!/usr/bin/env python3
"""Fail-closed structural validator for CRIA PROGRESSION OS v1."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def _read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def validate_progression_os() -> list[str]:
    errors: list[str] = []

    progression = json.loads(_read("data/progression.json"))
    runtime = progression.get("runtime_progression")
    if not isinstance(runtime, dict):
        return ["data/progression.json sem runtime_progression"]

    authority = runtime.get("authority", {})
    expected_authority = {
        "ledger": "ProgressionOS",
        "technique_mastery": "ProgressionOS",
        "money": "WorldState.money",
        "reputation": "WorldState.reputation",
        "training_compatibility": "TrainingManager",
    }
    for key, expected in expected_authority.items():
        if authority.get(key) != expected:
            errors.append(f"authority.{key} deve ser {expected!r}")

    domains = runtime.get("domains", [])
    required_domains = {"combat", "training", "exploration", "story", "social"}
    if not required_domains.issubset(set(domains)):
        errors.append("runtime_progression.domains incompleto")

    thresholds = runtime.get("mastery_thresholds", [])
    expected_stages = ["discovered", "learned", "practiced", "mastered", "signature"]
    actual_stages = [item.get("stage") for item in thresholds if isinstance(item, dict)]
    if actual_stages != expected_stages:
        errors.append(f"mastery_thresholds deve manter ordem canonica {expected_stages}")
    points = [float(item.get("points", -1)) for item in thresholds if isinstance(item, dict)]
    if len(points) != len(expected_stages) or points[0] != 0 or any(b <= a for a, b in zip(points, points[1:])):
        errors.append("mastery_thresholds precisa iniciar em zero e crescer estritamente")

    required_rules = {
        "combat_win",
        "combat_loss",
        "technique_attempt",
        "physical_training",
        "technical_training",
        "mission_complete",
        "travel_first_visit",
        "travel_repeat",
    }
    rules = runtime.get("event_rules", {})
    if not required_rules.issubset(set(rules)):
        errors.append("event_rules incompleto")
    for rule_id, rule in rules.items():
        if not isinstance(rule, dict):
            errors.append(f"event_rules.{rule_id} invalido")
            continue
        if float(rule.get("domain_xp", 0)) < 0:
            errors.append(f"event_rules.{rule_id}.domain_xp nao pode ser negativo")

    achievements = runtime.get("achievements", [])
    ids = [str(item.get("id", "")) for item in achievements if isinstance(item, dict)]
    if "" in ids or len(ids) != len(set(ids)):
        errors.append("achievements possui id vazio ou duplicado")
    for item in achievements:
        if not isinstance(item, dict):
            errors.append("achievement invalido")
            continue
        if not item.get("metric") or item.get("op") not in {">=", ">", "<=", "<", "=="}:
            errors.append(f"achievement {item.get('id', '<sem-id>')} sem metrica/op valido")

    project = _read("project.godot")
    autoload = 'ProgressionOS="*res://src/autoloads/ProgressionOS.gd"'
    if autoload not in project:
        errors.append("ProgressionOS nao registrado em project.godot")
    else:
        world_index = project.find('WorldState="*res://src/autoloads/WorldState.gd"')
        progression_index = project.find(autoload)
        save_index = project.find('SaveManager="*res://src/autoloads/SaveManager.gd"')
        if not (world_index < progression_index < save_index):
            errors.append("ordem de autoload deve ser WorldState -> ProgressionOS -> SaveManager")

    progression_os = _read("src/autoloads/ProgressionOS.gd")
    for contract in (
        "func record_event(",
        "func rebuild_projections_from_ledger()",
        "func import_legacy_training_mastery(",
        "func import_legacy_learned_techniques(",
        "func get_codex_entry(",
        "func get_mastery_stage(",
    ):
        if contract not in progression_os:
            errors.append(f"ProgressionOS sem contrato {contract}")

    save_manager = _read("src/autoloads/SaveManager.gd")
    if "const SAVE_VERSION := 6" not in save_manager:
        errors.append("SaveManager precisa declarar SAVE_VERSION 6")
    for contract in ('data["progression_state"]', 'parsed.get("progression_state", {})'):
        if contract not in save_manager:
            errors.append(f"SaveManager sem persistencia {contract}")

    training = _read("src/autoloads/TrainingManager.gd")
    if "ProgressionOS.get_mastery_points_map()" not in training:
        errors.append("TrainingManager ainda nao espelha a autoridade ProgressionOS")
    if 'mastery[technique_id] = float(mastery.get(technique_id, 0.0)) + xp' in training:
        # O fallback e permitido somente no ramo sem ProgressionOS.
        fallback_guard = 'else:\n\t\tmastery[technique_id] = float(mastery.get(technique_id, 0.0)) + xp'
        if fallback_guard not in training:
            errors.append("TrainingManager escreve maestria fora do fallback de compatibilidade")

    signal_bus = _read("src/autoloads/SignalBus.gd")
    for signal_name in (
        "progress_event_recorded",
        "progression_changed",
        "technique_mastery_changed",
        "achievement_unlocked",
        "training_completed",
        "world_travel_completed",
    ):
        if f"signal {signal_name}(" not in signal_bus:
            errors.append(f"SignalBus sem signal {signal_name}")

    return errors


def main() -> int:
    errors = validate_progression_os()
    if errors:
        print("[progression-os] FAIL")
        for error in errors:
            print(f"- {error}")
        return 1
    print("[progression-os] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
