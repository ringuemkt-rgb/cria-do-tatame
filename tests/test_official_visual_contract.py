from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "data/visual/official_visual_contract_v1.json"
VALIDATOR = ROOT / "tools/validate_official_visual_contract.py"


def test_official_logo_contract_is_canonical() -> None:
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    assert data["status"] == "canonical"
    assert data["product"]["official_title"] == "Cria do Tatame – Pressão"
    assert data["official_logo"]["id"] == "cdt_primary_silverback_lockup_v1"
    assert data["official_logo"]["declaration"] == "Esta é a logo oficial completa do jogo."
    assert set(data["canon_corrections"]["factions_exact"]) == {"LEM", "NTM", "ALE"}


def test_visual_references_are_not_runtime_assets() -> None:
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    classes = data["reference_classification"]
    assert classes["generated_dense_boards"] == "not_runtime_assets"
    assert classes["world_and_roster_boards"] == "composition_reference_only"


def test_visual_contract_validator_passes() -> None:
    result = subprocess.run(
        [sys.executable, str(VALIDATOR)],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    report = json.loads(result.stdout)
    assert result.returncode == 0, report
    assert report["ok"] is True
    assert report["official_logo"] == "cdt_primary_silverback_lockup_v1"
