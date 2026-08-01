#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RULESET_IDS = ["GI", "NO_GI"]


def read_text(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"arquivo obrigatório ausente: {relative}")
    return path.read_text(encoding="utf-8")


def load_json(relative: str) -> dict:
    return json.loads(read_text(relative))


def validate_rulesets() -> None:
    data = load_json("data/combat/rulesets_v01.json")
    assert data["default_ruleset_id"] == "GI"
    rulesets = data["rulesets"]
    assert [item["id"] for item in rulesets] == RULESET_IDS
    by_id = {item["id"]: item for item in rulesets}
    assert by_id["GI"]["grip_model"]["fabric_grips_allowed"] is True
    assert by_id["NO_GI"]["grip_model"]["fabric_grips_allowed"] is False
    assert "kimono" in by_id["NO_GI"]["attire"]["forbidden"]
    assert "rashguard" in by_id["NO_GI"]["attire"]["required"]
    assert "body_lock" in by_id["NO_GI"]["grip_model"]["allowed_types"]
    assert by_id["GI"]["runtime_policy"]["offline_required"] is True
    assert by_id["NO_GI"]["runtime_policy"]["offline_required"] is True
    assert by_id["GI"]["runtime_policy"]["automatic_submission_forbidden"] is True
    assert by_id["NO_GI"]["runtime_policy"]["automatic_submission_forbidden"] is True


def validate_technique_projection() -> None:
    projection = load_json("data/combat/technique_rulesets_v01.json")
    default = projection["default_policy"]
    assert default["rulesets"] == RULESET_IDS
    assert default["requires_fabric"] is False

    fabric = projection["fabric_technique_template"]
    assert fabric["rulesets"] == ["GI"]
    assert fabric["requires_fabric"] is True
    assert "tecido" in fabric["blocked_reason"].lower()

    techniques = projection["techniques"]
    source = load_json("data/techniques.json")
    source_ids = {item["id"] for item in source["techniques"]}
    assert set(techniques).issubset(source_ids), sorted(set(techniques) - source_ids)
    assert projection["policy"]["projection_ids_must_exist_in_source_catalog"] is True

    grip = techniques["grip_de_ferro"]
    assert grip["rulesets"] == RULESET_IDS
    assert grip["visual_variants"]["GI"] != grip["visual_variants"]["NO_GI"]
    assert grip["contact_anchors"]["GI"] != grip["contact_anchors"]["NO_GI"]

    initial_deck = load_json("data/ruan_deck_inicial.json")
    card_techniques = {
        card["technique_id"]
        for card in initial_deck["cards"]
        if card.get("technique_id")
    }
    missing = card_techniques - set(techniques)
    assert not missing, f"cartas sem política explícita de ruleset: {sorted(missing)}"
    for technique_id in card_techniques:
        assert techniques[technique_id]["rulesets"] == RULESET_IDS, technique_id
        assert techniques[technique_id]["requires_fabric"] is False, technique_id


def validate_ruleset_contract() -> None:
    contract = load_json("data/production/ruleset_contract_v4_3.json")
    assert contract["tracking_issue"] == 44
    assert contract["master_tracking_issue"] == 46
    assert contract["source_contract"] == "data/production/combat_master_contract_v2.json"
    assert contract["ruleset_ids"] == RULESET_IDS
    assert contract["default_ruleset_id"] == "GI"
    assert contract["product_decisions"]["gi_and_no_gi_are_canonical"] is True
    assert contract["product_decisions"]["no_gi_is_not_cosmetic_only"] is True
    assert contract["compatibility_policy"]["equipped_cards_must_not_be_deleted"] is True
    assert contract["compatibility_policy"]["incompatible_cards_must_not_enter_combat_hand"] is True
    assert "real_world_timing" in contract["reference_policy"]["grapplemap_not_authoritative_for"]
    assert "gi_specific_grips" in contract["reference_policy"]["grapplemap_not_authoritative_for"]
    batches = {item["id"]: item for item in contract["delivery_batches"]}
    assert batches["v4_3a"]["playable_no_gi"] is False
    assert batches["v4_3b"]["playable_no_gi"] is True
    assert contract["vertical_slice"]["ruleset"] == "NO_GI"
    assert contract["vertical_slice"]["player"] == "ruan_macacao"
    assert contract["vertical_slice"]["opponent"] == "davi_relampago"


def validate_master_contract_and_clash() -> None:
    contract = load_json("data/production/combat_master_contract_v2.json")
    invariants = contract["combat_invariants"]
    assert contract["tracking_issue"] == 46
    assert contract["runtime"]["generative_ai_allowed"] is False
    assert contract["runtime"]["critical_loop_network_dependency_allowed"] is False
    assert invariants["technique_source"] == "data/techniques.json"
    assert invariants["position_before_submission"] is True
    assert invariants["instant_finish"] is False
    assert invariants["clash_modifier_min"] == -0.3
    assert invariants["clash_modifier_max"] == 0.35
    assert invariants["submission_end_states"] == [
        "tap",
        "escape",
        "technical_intervention",
    ]
    assert contract["grapplemap"]["declared_license"] == "public_domain"
    assert "authoritative_real_world_timing" in contract["grapplemap"]["forbidden_claims"]
    assert "gi_specific_coverage" in contract["grapplemap"]["forbidden_claims"]
    assert contract["delivery"]["golden_vertical_slice_before_scale"] is True

    resolver = read_text("src/combat/TechniqueClashResolver.gd")
    assert '"instant_finish": false' in resolver
    assert "clampf(chance_modifier, -0.30, 0.35)" in resolver
    assert "chance_modifier = 0.25" in resolver
    assert "chance_modifier = 0.12" in resolver
    assert "var chance_modifier := 0.03" in resolver
    assert "chance_modifier = -0.18" in resolver

    project = read_text("project.godot")
    assert 'CombatManager="*res://src/autoloads/CombatManager.gd"' in project
    assert 'DeckManager="*res://src/autoloads/DeckManager.gd"' in project
    assert 'DataRegistry="*res://src/autoloads/DataRegistry.gd"' in project
    assert 'SaveManager="*res://src/autoloads/SaveManager.gd"' in project
    assert 'AudioManager="*res://src/autoloads/AudioManager.gd"' in project


def validate_registry_and_deck() -> None:
    registry = read_text("src/autoloads/DataRegistry.gd")
    deck = read_text("src/autoloads/DeckManager.gd")
    project = read_text("project.godot")

    for token in [
        '"combat_rulesets": "res://data/combat/rulesets_v01.json"',
        '"technique_rulesets": "res://data/combat/technique_rulesets_v01.json"',
        "func normalize_ruleset_id",
        "func technique_allowed_in_ruleset",
        "func get_technique_ruleset_block_reason",
        "func get_technique_visual_variant",
        "projecao de ruleset referencia tecnica fora de data/techniques.json",
    ]:
        assert token in registry, token

    for token in [
        'const DEFAULT_RULESET := "GI"',
        "var current_ruleset",
        "func set_ruleset",
        "func get_card_ruleset_status",
        "func get_blocked_equipped_cards",
        "func _compatible_active_deck",
        "func _normalize_ruleset(ruleset_id: String, allow_default: bool)",
        '"current_ruleset": current_ruleset',
        '"error": "ruleset_invalid"',
    ]:
        assert token in deck, token

    assert "RulesetManager=" not in project
    assert project.count('DeckManager="*res://src/autoloads/DeckManager.gd"') == 1
    assert project.count('CombatManager="*res://src/autoloads/CombatManager.gd"') == 1


def validate_tests_and_quality_gate() -> None:
    smoke = read_text("tests/ruleset_smoke.gd")
    package = load_json("package.json")
    workflow = read_text(".github/workflows/full-game-hardening.yml")
    assert "test_fabric_grip" in smoke
    assert "ruleset_invalid" in smoke
    assert "Troca de ruleset apagou carta da coleção" in smoke
    assert "validate:rulesets" in package["scripts"]
    assert "validate:rulesets" in package["scripts"]["quality"]
    assert "res://tests/ruleset_smoke.gd" in workflow


def main() -> int:
    checks = [
        validate_rulesets,
        validate_technique_projection,
        validate_ruleset_contract,
        validate_master_contract_and_clash,
        validate_registry_and_deck,
        validate_tests_and_quality_gate,
    ]
    errors: list[str] = []
    for check in checks:
        try:
            check()
        except Exception as exc:  # noqa: BLE001 - CLI agrega todas as falhas
            errors.append(f"{check.__name__}: {exc}")
    if errors:
        print("[RulesetsV4.3] FALHOU")
        for error in errors:
            print(f" - {error}")
        return 1
    print("[RulesetsV4.3] OK - GI, No-Gi, fonte única, clamp e deck validados")
    return 0


if __name__ == "__main__":
    sys.exit(main())
