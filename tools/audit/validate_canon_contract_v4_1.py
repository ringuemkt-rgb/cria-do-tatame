#!/usr/bin/env python3
"""Validate the V4.1 canon/contract batch without migrating runtime systems."""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data" / "production" / "canon_contract_v4_1.json"
FACTIONS_PATH = ROOT / "data" / "factions.json"
DECISIONS_PATH = ROOT / "docs" / "DECISIONS.md"
INDEX_PATH = ROOT / "docs" / "INDEX.md"
AGENTS_PATH = ROOT / "AGENTS.md"
PROJECT_PATH = ROOT / "project.godot"

EXPECTED_IDS = ["LEM", "NTM", "ALE"]
EXPECTED_DISPLAY = "Os Aleluiado"
LEGACY_ID = "os_aleluia"


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise AssertionError(f"arquivo ausente: {path.relative_to(ROOT)}") from exc
    except json.JSONDecodeError as exc:
        raise AssertionError(f"JSON invalido em {path.relative_to(ROOT)}: {exc}") from exc
    assert isinstance(value, dict), f"objeto raiz deve ser dicionario: {path.relative_to(ROOT)}"
    return value


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise AssertionError(f"arquivo ausente: {path.relative_to(ROOT)}") from exc


def validate_contract() -> None:
    contract = load_json(CONTRACT_PATH)
    assert contract.get("contract_id") == "cria_do_tatame_canon_v4_1"
    assert contract.get("status") == "canonical_contract"
    assert contract.get("integration_source_pr") == 32

    policy = contract.get("integration_policy", {})
    assert policy.get("monolithic_merge_forbidden") is True
    assert policy.get("port_in_small_batches") is True
    assert policy.get("stable_runtime_must_remain_bootable") is True

    authorities = contract.get("runtime_authorities", {})
    assert authorities.get("combat") == "CombatManager"
    assert authorities.get("deck") == "DeckManager"
    assert authorities.get("audio") == "AudioManager"

    factions = contract.get("active_factions_future_domain", [])
    ids = [str(item.get("id", "")) for item in factions]
    assert ids == EXPECTED_IDS, f"dominio futuro deve ser exatamente {EXPECTED_IDS}, recebido {ids}"
    assert len(set(ids)) == 3, "IDs de faccao duplicados"

    ale = next(item for item in factions if item.get("id") == "ALE")
    assert ale.get("display_name") == EXPECTED_DISPLAY
    assert LEGACY_ID in ale.get("legacy_ids", [])

    d10 = contract.get("d10", {})
    assert d10.get("canonical_display_name") == EXPECTED_DISPLAY
    assert d10.get("canonical_future_id") == "ALE"
    assert d10.get("preserved_legacy_id") == LEGACY_ID
    assert d10.get("religious_context_must_not_be_rewritten") is True
    assert d10.get("ambiguous_occurrences_require_human_review") is True

    legacy_policy = contract.get("legacy_domain_policy", {})
    assert legacy_policy.get("stable_ids_must_not_be_renamed_in_place") is True
    assert legacy_policy.get("runtime_three_faction_migration_deferred_to_v4_2") is True


def validate_legacy_catalog_display_only() -> None:
    data = load_json(FACTIONS_PATH)
    entries = [item for item in data.get("factions", []) if item.get("id") == LEGACY_ID]
    assert len(entries) == 1, f"esperada uma entrada legada {LEGACY_ID}, recebidas {len(entries)}"
    entry = entries[0]
    assert entry.get("id") == LEGACY_ID, "D10 nao pode renomear o ID legado"
    assert entry.get("name") == EXPECTED_DISPLAY, "display D10 incorreto"

    serialized = json.dumps(data, ensure_ascii=False)
    assert '"id": "ALE"' not in serialized, "V4.1 nao deve migrar o catalogo legado para ALE"


def validate_document_authority() -> None:
    decisions = read_text(DECISIONS_PATH)
    for decision in range(1, 12):
        assert f"## D{decision} —" in decisions, f"D{decision} ausente em docs/DECISIONS.md"
    assert EXPECTED_DISPLAY in decisions
    assert "PR #32" in decisions
    assert "não deve ser mesclado monoliticamente" in decisions

    index = read_text(INDEX_PATH)
    agents = read_text(AGENTS_PATH)
    assert "DECISIONS.md" in index, "docs/INDEX.md nao referencia DECISIONS.md"
    assert "canon_contract_v4_1.json" in index, "docs/INDEX.md nao referencia o contrato v4.1"
    assert "DECISIONS.md" in agents, "AGENTS.md nao referencia DECISIONS.md"


def validate_runtime_untouched_contract() -> None:
    project = read_text(PROJECT_PATH)
    assert 'run/main_scene="res://scenes/main_menu/MainMenu.tscn"' in project
    assert 'CombatManager="*res://src/autoloads/CombatManager.gd"' in project
    assert 'DeckManager="*res://src/autoloads/DeckManager.gd"' in project
    assert 'AudioManager="*res://src/autoloads/AudioManager.gd"' in project
    assert "TransitionManager=" not in project, "V4.1 nao deve adicionar TransitionManager como autoload"


def main() -> int:
    checks = [
        validate_contract,
        validate_legacy_catalog_display_only,
        validate_document_authority,
        validate_runtime_untouched_contract,
    ]
    errors: list[str] = []
    for check in checks:
        try:
            check()
        except (AssertionError, OSError, ValueError, KeyError) as exc:
            errors.append(f"{check.__name__}: {exc}")

    if errors:
        print("Canon contract V4.1 validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Canon contract V4.1 validation passed.")
    print("- future active faction IDs: LEM, NTM, ALE")
    print(f"- ALE display: {EXPECTED_DISPLAY}")
    print(f"- preserved legacy ID: {LEGACY_ID}")
    print("- runtime/autoload migration: deferred to V4.2+")
    return 0


if __name__ == "__main__":
    sys.exit(main())
