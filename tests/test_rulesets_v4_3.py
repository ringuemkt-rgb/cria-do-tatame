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


def test_fabric_template_is_gi_only_and_projection_uses_source_ids() -> None:
    projection = load("data/combat/technique_rulesets_v01.json")
    fabric = projection["fabric_technique_template"]
    assert fabric["rulesets"] == ["GI"]
    assert fabric["requires_fabric"] is True
    assert "tecido" in fabric["blocked_reason"].lower()

    source = load("data/techniques.json")
    source_ids = {item["id"] for item in source["techniques"]}
    policies = projection["techniques"]
    assert set(policies).issubset(source_ids)

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
    assert contract["master_tracking_issue"] == 46
    assert contract["source_contract"] == "data/production/combat_master_contract_v2.json"
    assert batches["v4_3a"]["playable_no_gi"] is False
    assert batches["v4_3b"]["playable_no_gi"] is True
    assert contract["vertical_slice"]["ruleset"] == "NO_GI"
    assert "claiming_no_gi_playable_before_v4_3b" in contract["forbidden_in_v4_3a"]


def test_master_contract_freezes_clamp_and_grapplemap_limits() -> None:
    contract = load("data/production/combat_master_contract_v2.json")
    invariants = contract["combat_invariants"]
    assert invariants["technique_source"] == "data/techniques.json"
    assert invariants["instant_finish"] is False
    assert invariants["clash_modifier_min"] == -0.3
    assert invariants["clash_modifier_max"] == 0.35
    assert "authoritative_real_world_timing" in contract["grapplemap"]["forbidden_claims"]
    assert "gi_specific_coverage" in contract["grapplemap"]["forbidden_claims"]


def test_validator_cli_passes() -> None:
    result = subprocess.run(
        [sys.executable, "tools/audit/validate_rulesets_v4_3.py"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
