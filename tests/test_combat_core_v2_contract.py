import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class CombatCoreV2ContractTests(unittest.TestCase):
    def load(self, path):
        return json.loads((ROOT / path).read_text(encoding="utf-8"))

    def test_ruleset_profiles_are_gameplay_not_official_claim(self):
        data = self.load("data/combat/ruleset_timers_v1.json")
        self.assertFalse(data["official_rules_claim"])
        self.assertEqual(data["profiles"]["ibjjf"]["rules_authority_id"], "ibjjf_v6")
        self.assertEqual(data["profiles"]["adcc"]["rules_authority_id"], "adcc_championship_current")

    def test_comeback_is_resource_only(self):
        data = self.load("data/combat/combat_core_v2_contract.json")
        self.assertEqual(data["comeback"]["uses_per_fight"], 1)
        self.assertFalse(data["comeback"]["outcome_authority"])
        self.assertTrue(data["comeback"]["resource_recovery_only"])

    def test_true_parity_gate_is_not_faked(self):
        data = self.load("data/combat/combat_core_v2_contract.json")
        self.assertFalse(data["migration"]["reducer_flip_allowed"])
        self.assertIn("explicit_parity_harness_available", data["migration"]["required_before_flip"])

    def test_touch_floor(self):
        data = self.load("data/combat/bjj_timing_windows_v1.json")
        floor = data["input_profiles"]["touch"]["minimum_counter_window_ms"]
        self.assertGreaterEqual(floor, 250)
        for tier in data["tiers"].values():
            self.assertGreaterEqual(tier["window_ms"], floor)

if __name__ == "__main__":
    unittest.main()
