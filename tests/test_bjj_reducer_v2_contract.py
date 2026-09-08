from __future__ import annotations

import copy
import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools/data/validate_bjj_reducer_v2_slice.py"
spec = importlib.util.spec_from_file_location("validate_bjj_reducer_v2_slice", MODULE_PATH)
assert spec and spec.loader
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


class BJJReducerV2ContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = load_json(ROOT / "data/bjj/bjj_kg_slice_ruan_davi_v1.json")
        self.authoring = load_json(ROOT / "data/combat/bjj_kg_authoring_contract_v1.json")
        self.rules = load_json(ROOT / "data/combat/bjj_rulesets_verified_v1.json")
        self.position_values = load_json(ROOT / "data/combat/bjj_position_values_v1.json")
        self.timing = load_json(ROOT / "data/combat/bjj_timing_windows_v1.json")

    def test_current_fixture_passes(self) -> None:
        self.assertEqual(
            validator.validate_fixture(self.fixture, self.authoring, self.rules, self.timing),
            [],
        )
        self.assertEqual(validator.validate_p1_tuning(self.position_values, self.timing), [])

    def test_rejects_raw_base_and_static_pts_authority(self) -> None:
        fixture = copy.deepcopy(self.fixture)
        fixture["techniques"][0]["base"] = 0.55
        fixture["techniques"][0]["pts"] = [2, 2]
        errors = validator.validate_fixture(fixture, self.authoring, self.rules, self.timing)
        self.assertTrue(any("raw base field forbidden" in item for item in errors))
        self.assertTrue(any("static pts tuple forbidden" in item for item in errors))

    def test_rejects_empirical_success_before_f3(self) -> None:
        fixture = copy.deepcopy(self.fixture)
        fixture["techniques"][0]["empirical_success"] = 0.42
        errors = validator.validate_fixture(fixture, self.authoring, self.rules, self.timing)
        self.assertTrue(any("empirical_success must be null before F3" in item for item in errors))

    def test_rejects_counter_without_outcome(self) -> None:
        fixture = copy.deepcopy(self.fixture)
        fixture["techniques"][0]["counters"][0].pop("outcome")
        errors = validator.validate_fixture(fixture, self.authoring, self.rules, self.timing)
        self.assertTrue(any("invalid counter outcome" in item for item in errors))

    def test_rejects_counter_without_timing_tier(self) -> None:
        fixture = copy.deepcopy(self.fixture)
        fixture["techniques"][0]["counters"][0].pop("timing_tier")
        errors = validator.validate_fixture(fixture, self.authoring, self.rules, self.timing)
        self.assertTrue(any("requires timing_tier" in item for item in errors))

    def test_rejects_unknown_timing_tier(self) -> None:
        fixture = copy.deepcopy(self.fixture)
        fixture["techniques"][0]["counters"][0]["timing_tier"] = "impossible"
        errors = validator.validate_fixture(fixture, self.authoring, self.rules, self.timing)
        self.assertTrue(any("unknown timing tier" in item for item in errors))

    def test_rejects_touch_window_below_250ms(self) -> None:
        timing = copy.deepcopy(self.timing)
        timing["input_profiles"]["touch"]["minimum_counter_window_ms"] = 249
        timing["tiers"]["tight"]["window_ms"] = 249
        errors = validator.validate_p1_tuning(self.position_values, timing)
        self.assertTrue(any("touch counter floor must be >=250ms" in item for item in errors))

    def test_rejects_positional_value_drift(self) -> None:
        values = copy.deepcopy(self.position_values)
        values["bands"]["mount"] = 0.99
        errors = validator.validate_p1_tuning(values, self.timing)
        self.assertTrue(any("position band mount" in item for item in errors))

    def test_pass_band_remains_transient(self) -> None:
        values = copy.deepcopy(self.position_values)
        for row in values["hud_ladder"]:
            if row.get("id") == "pass_in_progress":
                row["transient_only"] = False
        errors = validator.validate_p1_tuning(values, self.timing)
        self.assertIn("pass_in_progress must remain an explicitly transient HUD band", errors)

    def test_rejects_incomplete_legality_dimensions(self) -> None:
        fixture = copy.deepcopy(self.fixture)
        fixture["techniques"][0]["legality"]["ibjjf_v6"].pop("age_division")
        errors = validator.validate_fixture(fixture, self.authoring, self.rules, self.timing)
        self.assertTrue(any("incomplete legality for ibjjf_v6" in item for item in errors))

    def test_rejects_false_full_graph_claim(self) -> None:
        fixture = copy.deepcopy(self.fixture)
        fixture["full_graph_claim"] = True
        errors = validator.validate_fixture(fixture, self.authoring, self.rules, self.timing)
        self.assertTrue(any("cannot claim to be the full graph" in item for item in errors))

    def test_adcc_authority_is_not_four_four(self) -> None:
        bad_rules = copy.deepcopy(self.rules)
        points = bad_rules["rulesets"]["adcc_championship_current"]["points"]
        points["mount"] = 4
        points["back_mount_hooks_or_body_triangle"] = 4
        errors = validator.validate_fixture(self.fixture, self.authoring, bad_rules, self.timing)
        self.assertIn("versioned ADCC authority regressed", errors)


if __name__ == "__main__":
    unittest.main()
