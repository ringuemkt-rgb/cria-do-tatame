from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR_PATH = ROOT / "tools/audit/validate_p0_canon_baixo_sul.py"


def load_validator():
    spec = importlib.util.spec_from_file_location("validate_p0_canon_baixo_sul", VALIDATOR_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_p0_canon_contracts_are_consistent() -> None:
    module = load_validator()
    assert module.validate() == ["ale_display", "baixo_sul_world", "vertical_slice_gold"]


def test_vertical_slice_has_exactly_eight_paired_techniques() -> None:
    module = load_validator()
    contract = module.load_json(module.VERTICAL_SLICE_PATH)
    technique_ids = contract["combat"]["paired_technique_ids"]
    assert len(technique_ids) == 8
    assert set(technique_ids) == module.EXPECTED_VERTICAL_SLICE_TECHNIQUES


def test_world_has_exactly_fifteen_arenas_inside_baixo_sul() -> None:
    module = load_validator()
    world = module.load_json(module.WORLD_MAP_PATH)
    municipalities = {item["id"] for item in world["municipalities"]}
    arenas = world["arenas"]
    assert len(arenas) == 15
    assert {item["id"] for item in arenas} == module.EXPECTED_ARENAS
    assert all(item["municipality_id"] in municipalities for item in arenas)
    assert not (module.FORBIDDEN_PLAYABLE_NODES & municipalities)
