from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/combat/hub_skill_cards_v1.json"
SCRIPT = ROOT / "src/combat/PositionalCardCombat.gd"
HUB = ROOT / "src/hub/SkillHubLoadout.gd"


def load() -> dict:
    return json.loads(DATA.read_text(encoding="utf-8"))


def test_canonical_cards_have_complete_positional_contract() -> None:
    data = load()
    cards = data["cards"]
    assert len(cards) == 10
    ids = [card["id"] for card in cards]
    assert len(ids) == len(set(ids))
    required = {
        "id", "name", "technique_id", "from", "to", "side", "cost",
        "window", "vs_defense", "positional_damage", "guard_damage",
        "pressure_gain", "score_event", "moral", "rarity", "hub_branch",
        "animation_id",
    }
    valid_positions = {
        "any", "standing", "clinch_neutral", "clinch_dominant",
        "guard_top", "guard_bottom", "half_top", "half_bottom",
        "side_control", "mount", "back_control", "submission",
    }
    for card in cards:
        assert required.issubset(card), card["id"]
        assert card["from"], card["id"]
        assert set(card["from"]).issubset(valid_positions), card["id"]
        assert card["to"] in valid_positions, card["id"]
        assert card["side"] in {"any", "top", "bottom"}
        assert card["moral"] in {"clean", "gray", "dirty"}
        assert card["rarity"] in {"base", "advanced", "master"}
        assert card["hub_branch"] in {"disciplina", "foco", "respeito", "evolucao"}
        assert 0.15 <= float(card["window"]) <= 1.2
        for resource in ("grip", "gas", "focus", "pressure"):
            assert resource in card["cost"]
            assert float(card["cost"][resource]) >= 0


def test_starter_decks_are_12_cards_and_never_use_gacha() -> None:
    data = load()
    card_ids = {card["id"] for card in data["cards"]}
    for owner_id, deck in data["starter_decks"].items():
        assert len(deck) == 12, owner_id
        assert set(deck).issubset(card_ids), owner_id
        assert max(deck.count(card_id) for card_id in set(deck)) <= 2
    forbidden = " ".join(data["deck_rules"]["forbidden_monetization"]).lower()
    assert "gacha" in forbidden
    assert "loot_box" in forbidden


def test_runtime_exposes_jiu_jitsu_victory_and_position_contracts() -> None:
    source = SCRIPT.read_text(encoding="utf-8")
    assert "enum Position" in source
    assert "GUARD_TOP" in source
    assert "SIDE_CONTROL" in source
    assert "BACK_CONTROL" in source
    assert "SUBMISSION" in source
    assert '"submission"' in source
    assert '"points"' in source
    assert '"desistance"' in source
    assert "func play_card" in source
    assert "func defend" in source
    assert "func resolve_submission" in source


def test_hub_loadout_has_no_pay_to_win_path() -> None:
    source = HUB.read_text(encoding="utf-8").lower()
    assert "deck_size := 12" in source
    assert "max_duplicates := 2" in source
    assert "func unlock" in source
    assert "func train" in source
    assert "func set_loadout" in source
    assert "gacha" not in source
    assert "loot_box" not in source
    assert "molho" not in source
