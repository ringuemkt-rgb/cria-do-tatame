from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR_PATH = ROOT / "tools/validate_art_protocol.py"


def load_validator():
    spec = importlib.util.spec_from_file_location("validate_art_protocol", VALIDATOR_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_repository_art_protocol_passes() -> None:
    module = load_validator()
    report = module.run()
    assert report.errors == []


def test_protocol_and_tokens_versions_match() -> None:
    module = load_validator()
    tokens = json.loads((ROOT / "data/art_tokens.json").read_text(encoding="utf-8"))
    protocol = (ROOT / "docs/ART_PROTOCOL.md").read_text(encoding="utf-8")
    metadata = module.parse_protocol_metadata(protocol)
    assert metadata["version"] == tokens["protocol_version"]
    assert tokens["changelog"][-1]["version"] == tokens["protocol_version"]


def test_hud_has_exactly_four_fixed_bars() -> None:
    tokens = json.loads((ROOT / "data/art_tokens.json").read_text(encoding="utf-8"))
    bars = [item["id"] for item in tokens["combat_hud"]["fixed_bars"]]
    assert bars == ["gas", "positional_control", "grip", "flow"]


def test_palette_has_only_master_tokens() -> None:
    module = load_validator()
    tokens = json.loads((ROOT / "data/art_tokens.json").read_text(encoding="utf-8"))
    assert {name: item["hex"] for name, item in tokens["palette"]["tokens"].items()} == module.EXPECTED_PALETTE
