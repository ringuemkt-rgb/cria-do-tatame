from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "src/combat/PositionalCardCombat.gd"
HUB = ROOT / "src/hub/SkillHubLoadout.gd"
LEGACY_DATA = ROOT / "data/combat/hub_skill_cards_v1.json"


def test_runtime_exposes_jiu_jitsu_victory_and_position_contracts() -> None:
    source = SCRIPT.read_text(encoding="utf-8")
    assert "enum Position" in source
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


def test_legacy_catalog_is_explicitly_deprecated() -> None:
    source = LEGACY_DATA.read_text(encoding="utf-8")
    assert '"deprecated": true' in source
    assert '"replacement": "res://data/combat/cards.json"' in source
