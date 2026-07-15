from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_world_director_policy_is_offline_first() -> None:
    config = load("data/world/world_director_config_v01.json")
    policy = config["runtime_policy"]
    assert policy["offline_first"] is True
    assert policy["remote_ai_enabled_by_default"] is False
    assert policy["combat_llm_allowed"] is False
    assert policy["direct_frame_control_allowed"] is False
    assert policy["canonical_mutation_allowed"] is False
    assert policy["fallback_required"] is True


def test_climate_transitions_reference_known_weather() -> None:
    climate = load("data/world/climate_regions_v01.json")
    known = set(climate["weather_states"])
    assert known
    for region in climate["regions"].values():
        assert region["initial"] in known
        for current, transitions in region["transitions"].items():
            assert current in known
            assert set(transitions).issubset(known)
            assert sum(float(value) for value in transitions.values()) > 0.0


def test_events_have_unique_ids_and_valid_effects() -> None:
    events = load("data/world/dynamic_events_v01.json")["events"]
    ids = [event["id"] for event in events]
    assert len(ids) == len(set(ids))
    allowed_effects = {
        "honra", "hype", "sombra", "legado", "moral", "raiz", "money", "energy",
        "os_aleluia_heat", "la_ele_mil_vezes_heat", "nos_tem_um_molho_heat",
    }
    for event in events:
        assert 0.0 <= float(event["chance"]) <= 1.0
        assert set(event.get("effects", {})).issubset(allowed_effects)


def test_npc_routines_cover_all_time_blocks() -> None:
    routines = load("data/world/npc_routines_v01.json")["npcs"]
    expected = {"manha", "tarde", "noite", "madrugada"}
    for profile in routines.values():
        assert set(profile["schedule"]) == expected


def test_nft_catalog_is_optional_and_cosmetic_only() -> None:
    catalog = load("data/nft/nft_catalog_v01.json")
    policy = catalog["policy"]
    assert policy["optional"] is True
    assert policy["pay_to_win_forbidden"] is True
    assert policy["private_keys_in_client_forbidden"] is True
    assert policy["game_runs_without_wallet"] is True
    for item in catalog["items"]:
        assert item["cosmetic_only"] is True
        assert item["gameplay_effects"] == []


def test_runtime_files_exist() -> None:
    required = [
        "src/autoloads/WorldDirectorManager.gd",
        "src/autoloads/NFTManager.gd",
        "tools/world_director_server/app.py",
    ]
    for relative in required:
        assert (ROOT / relative).is_file(), relative
