from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACTIVE = {"ALE", "LEM", "NTM"}


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_contract_freezes_three_factions_and_save_v5() -> None:
    contract = load("data/production/faction_migration_v4_2.json")
    assert set(contract["active_faction_ids"]) == ACTIVE
    assert contract["active_factions"]["ALE"]["display_name"] == "Os Aleluiado"
    assert contract["save_migration"]["previous_version"] == 4
    assert contract["save_migration"]["current_version"] == 5
    assert contract["save_migration"]["legacy_archive_required"] is True
    assert contract["next_batch"] == {
        "id": "v4_3",
        "scope": "cartas_posicoes_rulesets_gi_no_gi",
        "tracking_issue": 44,
    }


def test_runtime_writes_canonical_ids_and_keeps_aliases() -> None:
    mapper = (ROOT / "src/factions/FactionIdentityV4.gd").read_text(encoding="utf-8")
    manager = (ROOT / "src/autoloads/FactionManager.gd").read_text(encoding="utf-8")
    save = (ROOT / "src/autoloads/SaveManager.gd").read_text(encoding="utf-8")
    assert '"os_aleluia": "ALE"' in mapper
    assert '"la_ele_mil_vezes": "LEM"' in mapper
    assert '"nos_tem_um_molho": "NTM"' in mapper
    assert '"ALE": "Os Aleluiado"' in mapper
    assert 'const ACTIVE_FACTIONS := ["ALE", "LEM", "NTM"]' in manager
    assert '"legacy_archive": legacy_archive.duplicate(true)' in manager
    assert "const SAVE_VERSION := 5" in save
    assert "_persist_migrated_save" in save


def test_director_and_territories_use_only_active_ids() -> None:
    director = load("data/factions/faction_director_v02.json")
    territories = load("data/world/faction_territories_v02.json")
    assert set(director["factions"]) == ACTIVE
    assert director["factions"]["ALE"]["name"] == "Os Aleluiado"
    for territory in territories["territories"].values():
        assert territory["owner"] in ACTIVE | {"neutral"}
        assert set(territory.get("challengers", [])).issubset(ACTIVE)


def test_validator_cli_passes() -> None:
    result = subprocess.run(
        [sys.executable, "tools/audit/validate_faction_migration_v4_2.py"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
