from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def test_v4_factions_are_exactly_three() -> None:
    payload = load("data/factions/factions_v3.json")
    assert set(payload["faccoes"]) == {"LEM", "NTM", "ALE"}
    assert all(n["faccao_pai"] in {"LEM", "NTM", "ALE"} for n in payload["nucleos"].values())


def test_v4_cards_positions_and_rulesets_are_complete() -> None:
    cards = load("data/combat/cards.json")["cartas"]
    positions = load("data/combat/position_data.json")["posicoes"]
    rulesets = load("data/combat/rulesets.json")["rulesets"]
    assert len(cards) == 20
    assert len({card["id"] for card in cards}) == 20
    assert set(positions) == {
        "STANDING", "CLINCH", "GUARD", "HALF",
        "SIDE_CONTROL", "MOUNT", "BACK_CONTROL", "SUBMISSION",
    }
    assert set(rulesets) == {"OFICIAL", "CLANDESTINA", "RITO", "FESTIVAL", "DOJO", "MORAL"}
    for card in cards:
        assert card["origem"]
        assert set(card["origem"]).issubset(set(positions))
        assert card["destino"] in set(positions) | {"keep"}
        assert card["lado"] in {"top", "bottom", "any"}
        assert card["set_side"] in {"top", "bottom", "keep", "invert", "any"}
        assert card["moral"] in {"limpa", "cinza", "suja"}
        assert set(card["custo"]).issuperset({"grip", "gas", "foco"})


def test_no_molho_pay_to_win() -> None:
    cards_text = (ROOT / "data/combat/cards.json").read_text(encoding="utf-8").lower()
    hub_text = (ROOT / "src/hub/SkillHubLoadoutV41.gd").read_text(encoding="utf-8").lower()
    assert "compravel com molho" in cards_text
    assert "available_molho" not in hub_text
    assert "loot_box" not in hub_text
    assert "gacha" not in hub_text


def test_runtime_uses_final_portuguese_schema() -> None:
    source = (ROOT / "src/combat/PositionalCardCombatV41.gd").read_text(encoding="utf-8")
    for key in ("origem", "destino", "custo", "janela", "vs_defesa", "dano_pos", "set_side"):
        assert f'"{key}"' in source
    assert '"from"' not in source
    assert '"to"' not in source
    assert '"cost"' not in source


def test_legacy_adapter_covers_all_v4_positions() -> None:
    source = (ROOT / "src/compat/PositionalCombatAdapter.gd").read_text(encoding="utf-8")
    for position in ("STANDING", "CLINCH", "GUARD", "HALF", "SIDE_CONTROL", "MOUNT", "BACK_CONTROL", "SUBMISSION"):
        assert position in source


def test_repository_has_single_canonical_game_marker() -> None:
    policy = (ROOT / "docs/production/REPOSITORY_CONSOLIDATION.md").read_text(encoding="utf-8")
    assert "ringuemkt-rgb/cria-do-tatame" in policy
    assert "único repositório canônico" in policy.lower()
