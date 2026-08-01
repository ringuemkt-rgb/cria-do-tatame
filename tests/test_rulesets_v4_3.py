from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_rulesets_define_distinct_grip_and_attire_models() -> None:
    data = load("data/combat/rulesets_v01.json")
    assert data["default_ruleset_id"] == "GI"
    by_id = {item["id"]: item for item in data["rulesets"]}
    assert set(by_id) == {"GI", "NO_GI"}
    assert by_id["GI"]["grip_model"]["fabric_grips_allowed"] is True
    assert by_id["NO_GI"]["grip_model"]["fabric_grips_allowed"] is False
    assert by_id["GI"]["attire"]["visual_variant"] == "gi"
    assert by_id["NO_GI"]["attire"]["visual_variant"] == "no_gi"
    assert by_id["GI"]["audio_profile"] != by_id["NO_GI"]["audio_profile"]


def test_lapel_is_blocked_but_initial_deck_survives_no_gi() -> None:
    projection = load("data/combat/technique_rulesets_v01.json")
    policies = projection["techniques"]
    assert policies["pegada_lapela_manga"]["rulesets"] == ["GI"]
    assert policies["pegada_lapela_manga"]["requires_fabric"] is True

    deck = load("data/ruan_deck_inicial.json")
    technique_ids = {
        card["technique_id"] for card in deck["cards"] if card.get("technique_id")
    }
    assert technique_ids
    assert technique_ids.issubset(policies)
    for technique_id in technique_ids:
        assert policies[technique_id]["rulesets"] == ["GI", "NO_GI"]
        assert policies[technique_id]["requires_fabric"] is False


def test_contract_does_not_claim_no_gi_playable_in_first_batch() -> None:
    contract = load("data/production/ruleset_contract_v4_3.json")
    batches = {item["id"]: item for item in contract["delivery_batches"]}
    assert batches["v4_3a"]["playable_no_gi"] is False
    assert batches["v4_3b"]["playable_no_gi"] is True
    assert contract["vertical_slice"]["ruleset"] == "NO_GI"
    assert "claiming_no_gi_playable_before_v4_3b" in contract["forbidden_in_v4_3a"]


def test_validator_cli_passes() -> None:
    result = subprocess.run(
        [sys.executable, "tools/audit/validate_rulesets_v4_3.py"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
