#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ACTIVE = ["ALE", "LEM", "NTM"]
ACTIVE_SET = set(ACTIVE)
ALIASES = {
    "os_aleluia": "ALE",
    "la_ele_mil_vezes": "LEM",
    "nos_tem_um_molho": "NTM",
}
NON_FACTION = {
    "terreiro",
    "raiz",
    "circuito_oficial",
    "cria_live",
    "atalhos",
    "dragao_vermelho",
    "fantasma",
}


def read_text(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"arquivo obrigatório ausente: {relative}")
    return path.read_text(encoding="utf-8")


def load_json(relative: str) -> dict:
    return json.loads(read_text(relative))


def validate_contract() -> None:
    contract = load_json("data/production/faction_migration_v4_2.json")
    assert contract["active_faction_ids"] == ACTIVE
    assert contract["save_migration"]["previous_version"] == 4
    assert contract["save_migration"]["current_version"] == 5
    assert contract["save_migration"]["legacy_archive_required"] is True
    assert contract["next_batch"]["tracking_issue"] == 44
    factions = contract["active_factions"]
    assert set(factions) == ACTIVE_SET
    assert factions["ALE"]["display_name"] == "Os Aleluiado"
    flattened_aliases = {
        legacy: canonical
        for canonical, data in factions.items()
        for legacy in data["legacy_ids"]
    }
    assert flattened_aliases == ALIASES


def validate_runtime_sources() -> None:
    mapper = read_text("src/factions/FactionIdentityV4.gd")
    faction_manager = read_text("src/autoloads/FactionManager.gd")
    save_manager = read_text("src/autoloads/SaveManager.gd")
    bridge = read_text("src/autoloads/FactionAIPlanBridge.gd")
    project = read_text("project.godot")

    for canonical in ACTIVE:
        assert f'"{canonical}"' in mapper
    for legacy, canonical in ALIASES.items():
        assert f'"{legacy}": "{canonical}"' in mapper
    assert '"ALE": "Os Aleluiado"' in mapper
    assert "static func migrate_director_state" in mapper
    assert 'const ACTIVE_FACTIONS := ["ALE", "LEM", "NTM"]' in faction_manager
    assert "legacy_archive" in faction_manager
    assert "func canonicalize_faction_id" in faction_manager
    assert "const SAVE_VERSION := 5" in save_manager
    assert "_persist_migrated_save" in save_manager
    assert "migrate_director_state" in save_manager
    assert "FactionManager.canonicalize_faction_id" in bridge

    assert 'FactionManager="*res://src/autoloads/FactionManager.gd"' in project
    assert 'FactionDirectorManager="*res://src/autoloads/FactionDirectorManager.gd"' in project
    assert 'SaveManager="*res://src/autoloads/SaveManager.gd"' in project
    assert project.count('FactionManager="*res://src/autoloads/FactionManager.gd"') == 1
    assert project.count('FactionDirectorManager="*res://src/autoloads/FactionDirectorManager.gd"') == 1
    assert project.count('SaveManager="*res://src/autoloads/SaveManager.gd"') == 1


def validate_director_data() -> None:
    director = load_json("data/factions/faction_director_v02.json")
    assert director["active_faction_ids"] == ACTIVE
    assert director["legacy_aliases"] == ALIASES
    assert set(director["factions"]) == ACTIVE_SET
    assert director["factions"]["ALE"]["name"] == "Os Aleluiado"
    for faction_id, data in director["factions"].items():
        assert data["id"] == faction_id
        assert ALIASES[data["legacy_id"]] == faction_id
        assert data["leader"]
        assert data["combat_doctrine"]["preferred_actions"]
        assert data["operation_weights"]


def validate_territories() -> None:
    world = load_json("data/world/faction_territories_v02.json")
    assert world["active_faction_ids"] == ACTIVE
    assert len(world["territories"]) >= 15
    for territory_id, territory in world["territories"].items():
        assert territory["owner"] in ACTIVE_SET | {"neutral"}, territory_id
        assert set(territory.get("challengers", [])).issubset(ACTIVE_SET), territory_id
        if territory["owner"] == "neutral" and "legacy_owner" in territory:
            assert territory["legacy_owner"] in NON_FACTION, territory_id
    pairs: set[tuple[str, str]] = set()
    for rivalry in world["initial_rivalries"]:
        assert rivalry["a"] in ACTIVE_SET
        assert rivalry["b"] in ACTIVE_SET
        assert rivalry["a"] != rivalry["b"]
        pair = tuple(sorted((rivalry["a"], rivalry["b"])))
        assert pair not in pairs
        pairs.add(pair)
    assert pairs == {("ALE", "LEM"), ("ALE", "NTM"), ("LEM", "NTM")}


def validate_catalog_classification() -> None:
    catalog = load_json("data/factions.json")
    active = [item for item in catalog["factions"] if item.get("active_faction") is True]
    assert {item["canonical_id"] for item in active} == ACTIVE_SET
    assert {item["id"] for item in active} == set(ALIASES)
    ale = next(item for item in active if item["canonical_id"] == "ALE")
    assert ale["name"] == "Os Aleluiado"
    classified_non_factions = {
        item["id"]
        for item in catalog["factions"]
        if item.get("active_faction") is False
    }
    assert classified_non_factions == NON_FACTION
    assert {
        item["id"]
        for item in catalog["factions"]
        if item.get("domain_type") == "retired_lore"
    } == {"dragao_vermelho", "fantasma"}


def validate_tests_and_scope() -> None:
    smoke = read_text("tests/faction_director_smoke.gd")
    package = load_json("package.json")
    assert "initial_factions.size() == 3" in smoke
    assert "legacy_archive" in smoke
    assert "migrate_director_state" in smoke
    assert "validate:factions-v4" in package["scripts"]
    assert "validate:factions-v4" in package["scripts"]["quality"]

    forbidden_runtime_files = [
        ROOT / "src/autoloads/TransitionManager.gd",
        ROOT / "src/autoloads/FactionManagerV4.gd",
        ROOT / "src/autoloads/SaveManagerV5.gd",
    ]
    assert not any(path.exists() for path in forbidden_runtime_files)


def main() -> int:
    validators = [
        validate_contract,
        validate_runtime_sources,
        validate_director_data,
        validate_territories,
        validate_catalog_classification,
        validate_tests_and_scope,
    ]
    failures: list[str] = []
    for validator in validators:
        try:
            validator()
        except Exception as exc:  # noqa: BLE001 - CLI precisa agregar falhas
            failures.append(f"{validator.__name__}: {exc}")
    if failures:
        print("[FactionMigrationV4.2] FALHOU")
        for failure in failures:
            print(f" - {failure}")
        return 1
    print("[FactionMigrationV4.2] OK - 3 facções, aliases e save v5 validados")
    return 0


if __name__ == "__main__":
    sys.exit(main())
