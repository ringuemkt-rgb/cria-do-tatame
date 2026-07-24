from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CANONICAL = {"LEM", "NTM", "ALE"}


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_exactly_three_active_factions_have_complete_identity() -> None:
    data = load("data/factions/faction_director_v3.json")
    factions = data["factions"]
    assert set(factions) == CANONICAL
    assert data["faction_ids"] == ["LEM", "NTM", "ALE"]
    dimensions = set(data["power_dimensions"])
    for faction_id, faction in factions.items():
        assert faction["desire"], faction_id
        assert faction["fear"], faction_id
        assert faction["taboo"], faction_id
        assert faction["public_face"], faction_id
        assert faction["hidden_face"], faction_id
        assert set(faction["initial_power"]) == dimensions
        assert all(0 <= float(value) <= 100 for value in faction["initial_power"].values())
        assert faction["leader"]
        assert faction["succession_candidates"]
        assert faction["combat_doctrine"]["preferred_actions"]
        assert faction["color"] in {"#D92323", "#2D5016", "#4B0082"}


def test_operation_weights_reference_existing_templates() -> None:
    director = load("data/factions/faction_director_v3.json")
    operations = load("data/factions/faction_operations_v02.json")["operations"]
    categories = {operation["category"] for operation in operations}
    ids = [operation["id"] for operation in operations]
    assert len(ids) == len(set(ids))
    for faction_id, faction in director["factions"].items():
        missing = set(faction["operation_weights"]) - categories
        assert not missing, (faction_id, missing)
    for operation in operations:
        assert int(operation["duration_weeks"]) >= 1
        assert float(operation["base_cost"]) >= 0
        assert operation["target_type"] in {
            "self",
            "owned_territory",
            "neutral_territory",
            "contested_territory",
            "event_territory",
            "rival_faction",
            "hostile_faction",
        }


def test_v3_territories_reference_only_canonical_factions() -> None:
    world = load("data/world/faction_territories_v3.json")
    territories = world["territories"]
    assert len(territories) == 15
    for territory_id, territory in territories.items():
        assert territory["owner"] in CANONICAL | {"neutral"}, territory_id
        assert set(territory.get("challengers", [])).issubset(CANONICAL), territory_id
        assert 0 <= float(territory["control"]) <= 100
        assert 0 <= float(territory["apoio_popular"]) <= 100
        assert 0 <= float(territory["seguranca"]) <= 100
        assert 0 <= float(territory["renda"]) <= 100
    for rivalry in world["initial_rivalries"]:
        assert rivalry["a"] in CANONICAL
        assert rivalry["b"] in CANONICAL
        assert rivalry["a"] != rivalry["b"]


def test_retired_groups_and_axes_are_not_active_factions() -> None:
    manager = (ROOT / "src/autoloads/FactionManager.gd").read_text(encoding="utf-8")
    director = (ROOT / "src/autoloads/FactionDirectorV3.gd").read_text(encoding="utf-8")
    assert 'const ALL_FACTIONS := ["LEM", "NTM", "ALE"]' in manager
    assert 'const CANONICAL_IDS := ["LEM", "NTM", "ALE"]' in director
    assert 'const NON_FACTION_AXES := ["terreiro", "raiz", "cria_live", "circuito_oficial"]' in manager
    assert 'const RETIRED_IDS := ["dragao_vermelho", "fantasma"]' in manager
    for forbidden in ("terreiro", "raiz", "dragao_vermelho", "fantasma"):
        assert forbidden not in load("data/factions/faction_director_v3.json")["factions"]


def test_runtime_contracts_are_registered() -> None:
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    signal_bus = (ROOT / "src/autoloads/SignalBus.gd").read_text(encoding="utf-8")
    save_manager = (ROOT / "src/autoloads/SaveManager.gd").read_text(encoding="utf-8")
    live = (ROOT / "src/autoloads/CriaLiveManager.gd").read_text(encoding="utf-8")
    assert 'FactionDirectorManager="*res://src/autoloads/FactionDirectorV3.gd"' in project
    assert 'FactionAIPlanBridge="*res://src/autoloads/FactionAIPlanBridge.gd"' in project
    assert "signal faction_operation_started" in signal_bus
    assert "signal faction_leadership_changed" in signal_bus
    assert 'data["faction_director_state"]' in save_manager
    assert "const SAVE_VERSION := 5" in save_manager
    assert "FactionSaveMigrationV3Script.migrate" in save_manager
    assert 'data["cria_live_state"]' in save_manager
    assert "func create_faction_post" in live


def test_no_secret_or_pay_to_win_contract_was_added() -> None:
    paths = [
        ROOT / "data/factions/faction_director_v3.json",
        ROOT / "data/factions/faction_operations_v02.json",
        ROOT / "src/autoloads/FactionDirectorV3.gd",
    ]
    combined = "\n".join(path.read_text(encoding="utf-8").lower() for path in paths)
    assert "openrouter_api_key=" not in combined
    assert "hf_token=" not in combined
    assert "private_key" not in combined
    assert "nft_damage" not in combined
