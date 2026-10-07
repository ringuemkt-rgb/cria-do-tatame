import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools/qa/validate_gold_slice_professional_v1.py"
SPEC = importlib.util.spec_from_file_location("gold_slice_validator", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class GoldSliceProfessionalContractTests(unittest.TestCase):
    def test_contract_is_non_shipping_and_physical_device_gated(self):
        data = MODULE.load("data/production/gold_slice_professional_v1.json")
        self.assertFalse(data["shipping"])
        self.assertTrue(data["android_acceptance"]["physical_device_required"])
        self.assertFalse(data["android_acceptance"]["release_ready_default"])

    def test_gold_fight_is_intentionally_only_seven_techniques(self):
        data = MODULE.load("data/production/gold_slice_professional_v1.json")
        self.assertEqual(7, len(data["fight_acceptance"]["required_techniques"]))

    def test_feedback_profiles_exactly_cover_gold_techniques(self):
        data = MODULE.load("data/production/gold_slice_professional_v1.json")
        feedback = MODULE.load("data/combat/combat_feedback_v1.json")
        self.assertEqual(
            set(data["fight_acceptance"]["required_techniques"]),
            set(feedback["profiles"]),
        )

    def test_manual_android_template_fails_closed(self):
        data = MODULE.load("data/qa/android_gold_slice_manual_checklist_v1.json")
        self.assertTrue(data["checks"])
        self.assertFalse(any(data["checks"].values()))


if __name__ == "__main__":
    unittest.main()
