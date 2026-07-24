from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def test_cards_v41_contract() -> None:
    data = load("data/combat/cards.json")
    cards = data["cartas"]
    assert len(cards) == 20
    ids = [card["id"] for card in cards]
    assert len(ids) == len(set(ids))
    valid_positions = {
        "STANDING", "CLINCH", "GUARD", "HALF",
        "SIDE_CONTROL", "MOUNT", "BACK_CONTROL", "SUBMISSION",
    }
    for card in cards:
        assert card["origem"]
        assert set(card["origem"]).issubset(valid_positions)
        assert card["lado"] in {"top", "bottom", "any"}
        assert card["set_side"] in {"top", "bottom", "keep", "invert", "any"}
        assert card["moral"] in {"limpa", "cinza", "suja"}
        assert card["tipo"] in {"transicao", "defesa", "controle", "especial"}
        assert float(card["janela"]) >= 0
        assert int(card["deck_cost"]) >= 0
        assert "molho" not in json.dumps(card, ensure_ascii=False).lower()


def test_exact_symmetric_position_model() -> None:
    data = load("data/combat/position_data.json")
    positions = data["posicoes"]
    assert set(positions) == {
        "STANDING", "CLINCH", "GUARD", "HALF",
        "SIDE_CONTROL", "MOUNT", "BACK_CONTROL", "SUBMISSION",
    }
    for name, position in positions.items():
        assert 0.0 <= float(position["ameaca"]) <= 1.0, name
        assert position["op_side_rule"] in {"any", "invert"}
        assert position["lados"], name


def test_rulesets_cover_required_game_modes() -> None:
    data = load("data/combat/rulesets.json")
    rulesets = data["rulesets"]
    assert set(rulesets) == {"OFICIAL", "CLANDESTINA", "RITO", "FESTIVAL", "DOJO", "MORAL"}
    dirty_modes = {"banida_desclassifica", "livre", "incentivada", "falha_rito"}
    for ruleset in rulesets.values():
        assert ruleset["cartas_sujas"] in dirty_modes
        assert int(ruleset["timer_seg"]) >= 0
        assert isinstance(ruleset["caminhos_vitoria"], list)


def test_dirty_cards_are_not_normal_progression_power() -> None:
    cards = load("data/combat/cards.json")["cartas"]
    dirty = [card for card in cards if card["moral"] == "suja"]
    assert len(dirty) == 6
    assert all(int(card["deck_cost"]) == 0 for card in dirty)
    assert all(card["raridade"] == "suja" for card in dirty)


def test_root_cards_require_story_flags() -> None:
    cards = load("data/combat/cards.json")["cartas"]
    root = [card for card in cards if card["raridade"] == "raiz"]
    assert len(root) == 4
    assert all(card["requisito_flag"] for card in root)
