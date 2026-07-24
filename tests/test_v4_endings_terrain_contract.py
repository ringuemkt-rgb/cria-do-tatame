from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_five_endings_are_complete_and_unique() -> None:
    data = load("data/narrative/endings_v4.json")
    endings = data["endings"]
    assert set(endings) == {
        "cria_de_verdade",
        "campeao_oco",
        "martir_do_tatame",
        "sombra",
        "ponte",
    }
    assert set(data["priority"]) == set(endings)
    for ending_id, ending in endings.items():
        assert ending["name"], ending_id
        assert ending["boss"], ending_id
        assert ending["ceremony_giver"], ending_id
        assert ending["result"], ending_id
    assert data["moral_boss"]["id"] == "irmao_calebe"
    assert data["moral_boss"]["terrain_tag"] == "manto_olhar"


def test_ending_resolver_uses_canonical_flags_and_economy() -> None:
    source = (ROOT / "src/autoloads/EndingResolverV4.gd").read_text(encoding="utf-8")
    for token in (
        "honra", "raiz", "sombra", "mangue_estado", "tupa200_resolucao",
        "informant_status", "provas_joaquim", "leoa_vinculo", "MOLHO",
    ):
        assert token in source
    for ending_id in load("data/narrative/endings_v4.json")["endings"]:
        assert ending_id in source
    assert "func get_belt_ceremony" in source
    assert "func get_boss_contract" in source


def test_all_canonical_terrain_tags_have_runtime_effects() -> None:
    source = (ROOT / "src/combat/TerrainModifiersV4.gd").read_text(encoding="utf-8")
    required = {
        "areia_fofa", "mobilidade_instavel", "plateia", "por_do_sol",
        "strobo", "batida_bpm", "manto_olhar", "lama", "entulho",
        "estreito_vento", "silencio_eco",
    }
    for tag in required:
        assert f'"{tag}"' in source
    assert "gas_cost_mult" in source
    assert "defense_threshold_add" in source
    assert "focus_drain_per_sec" in source
    assert "dirty_roxo_mult" in source
    assert "reduced_flash" in source


def test_terrain_extension_preserves_base_combat_api() -> None:
    terrain_runtime = (ROOT / "src/combat/PositionalCardCombatTerrainV41.gd").read_text(encoding="utf-8")
    manager = (ROOT / "src/autoloads/CombatManagerV42.gd").read_text(encoding="utf-8")
    assert 'extends "res://src/combat/PositionalCardCombatV41.gd"' in terrain_runtime
    assert "super.play_card" in terrain_runtime
    assert "super.generic_transition" in terrain_runtime
    assert "super.defend" in terrain_runtime
    assert "super.tick" in terrain_runtime
    assert 'extends "res://src/autoloads/CombatManagerV41.gd"' in manager
    assert "func set_terrain_tags_v41" in manager
    assert "func get_terrain_contract_v41" in manager
