from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_visual_contract_freezes_canon_and_pixel_pipeline() -> None:
    contract = load("data/visual/visual_production_director_v1.json")
    assert contract["canon"]["protagonist"]["id"] == "ruan_macacao"
    assert contract["canon"]["protagonist"]["nickname"] == "Macacão"
    factions = {item["id"]: item for item in contract["canon"]["active_factions"]}
    assert factions["ALE"]["display_name"] == "Os Aleluiados"
    assert contract["visual_style"]["dimension"] == "2D_with_2_5D_depth"
    assert contract["visual_style"]["texture_filter"] == "nearest"
    assert contract["surfaces"]["paired_technique"]["attacker_and_defender_required"] is True
    assert contract["quality_score"]["minimum_total"] == 90


def test_skill_has_runtime_and_art_bible_separation() -> None:
    skill = (ROOT / ".agents/skills/cria-visual-production-director/SKILL.md").read_text(
        encoding="utf-8"
    )
    assert "Concept art, mockup, prompt antigo e imagem isolada" in skill
    assert "pranchas 1536×1536" in skill.lower()
    assert "Não gere cada frame isoladamente" in skill
    assert "HUD runtime deve proteger a luta" in skill
    assert "Ruan “Macacão” Silva" in skill
    assert "Os Aleluiados" in skill


def test_visual_validator_cli_passes() -> None:
    result = subprocess.run(
        [sys.executable, "tools/audit/validate_visual_production_director_v1.py"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
