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
    techniques = projection["techniques"]
    lapel = techniques["pegada_lapela_manga"]
    assert lapel["rulesets"] == ["GI"]
    assert lapel["requires_fabric"] is True
    assert "lapela" in lapel["blocked_reason"].lower()
    assert "NO_GI" not in lapel.get("visual_variants", {})

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


def validate_contract() -> None:
    contract = load_json("data/production/ruleset_contract_v4_3.json")
    assert contract["tracking_issue"] == 44
    assert contract["ruleset_ids"] == RULESET_IDS
    assert contract["default_ruleset_id"] == "GI"
    assert contract["product_decisions"]["gi_and_no_gi_are_canonical"] is True
    assert contract["product_decisions"]["no_gi_is_not_cosmetic_only"] is True
    assert contract["compatibility_policy"]["equipped_cards_must_not_be_deleted"] is True
    assert contract["compatibility_policy"]["incompatible_cards_must_not_enter_combat_hand"] is True
    batches = {item["id"]: item for item in contract["delivery_batches"]}
    assert batches["v4_3a"]["playable_no_gi"] is False
    assert batches["v4_3b"]["playable_no_gi"] is True
    assert contract["vertical_slice"]["ruleset"] == "NO_GI"
    assert contract["vertical_slice"]["player"] == "ruan_macacao"
    assert contract["vertical_slice"]["opponent"] == "davi_relampago"


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
    ]:
        assert token in registry, token

    for token in [
        'const DEFAULT_RULESET := "GI"',
        "var current_ruleset",
        "func set_ruleset",
        "func get_card_ruleset_status",
        "func get_blocked_equipped_cards",
        "func _compatible_active_deck",
        '"current_ruleset": current_ruleset',
    ]:
        assert token in deck, token

    assert "RulesetManager=" not in project
    assert project.count('DeckManager="*res://src/autoloads/DeckManager.gd"') == 1
    assert project.count('CombatManager="*res://src/autoloads/CombatManager.gd"') == 1


def validate_tests_and_quality_gate() -> None:
    smoke = read_text("tests/ruleset_smoke.gd")
    package = load_json("package.json")
    assert "pegada_lapela_manga" in smoke
    assert "set_ruleset" in smoke
    assert "Troca de ruleset apagou carta da coleção" in smoke
    assert "validate:rulesets" in package["scripts"]
    assert "validate:rulesets" in package["scripts"]["quality"]


def main() -> int:
    checks = [
        validate_rulesets,
        validate_technique_projection,
        validate_contract,
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
    print("[RulesetsV4.3] OK - GI e No-Gi, projeção e filtro de deck validados")
    return 0


if __name__ == "__main__":
    sys.exit(main())
