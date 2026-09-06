import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VALIDATOR = ROOT / "tools" / "bjj" / "validate_bjj_intelligence.py"

spec = importlib.util.spec_from_file_location("validate_bjj_intelligence", VALIDATOR)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class BJJIntelligenceFailClosedTests(unittest.TestCase):
    def test_repository_contract_is_fail_closed(self):
        self.assertEqual(module.validate(), [])

    def test_human_gate_is_not_ai_signed(self):
        gate = module.load("data/bjj/dossiers/001_baiana_single_leg_human_gate.json")
        self.assertTrue(gate["assistant_may_recommend_but_not_sign"])
        self.assertEqual(gate["human_decision"], "PENDING")
        self.assertFalse(gate["shipping"])

    def test_unknown_license_blocks_video_stages(self):
        corpus = module.load("data/bjj/corpus/baiana_single_leg_v1.json")
        self.assertEqual(corpus["custody"]["license_status"], "UNKNOWN")
        self.assertEqual(corpus["custody"]["status"], "CUSTODY_BLOCKED")
        self.assertEqual(corpus["stages"]["V2_event_annotation"]["status"], "NOT_STARTED_BLOCKED_BY_V1")
        self.assertEqual(corpus["stages"]["V3_pose_keypoints"]["status"], "NOT_STARTED_BLOCKED_BY_V1")


if __name__ == "__main__":
    unittest.main()
