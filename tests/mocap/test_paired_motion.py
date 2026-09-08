import copy
import importlib.util
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools" / "mocap"
FIXTURE = ROOT / "tests" / "fixtures" / "mocap" / "armlock_montada_synthetic.json"
MANIFEST = ROOT / "data" / "manifest" / "mocap_stack_v1.json"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


validator = load_module("validate_paired_motion", TOOLS / "validate_paired_motion.py")
biomech = load_module("biomechanics_qa", TOOLS / "biomechanics_qa.py")


class PairedMotionTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(FIXTURE.read_text(encoding="utf-8"))
        self.thresholds = biomech.load_thresholds(MANIFEST)

    def test_synthetic_fixture_passes_structural_contract(self):
        self.assertEqual([], validator.validate(self.data))

    def test_restricted_component_cannot_be_shipping_eligible(self):
        data = copy.deepcopy(self.data)
        data["provenance"]["restricted_components_used"] = ["smplx"]
        data["provenance"]["shipping_eligible"] = True
        errors = validator.validate(data)
        self.assertTrue(any("cannot be marked shipping_eligible" in item for item in errors))

    def test_missing_mandatory_phase_fails(self):
        data = copy.deepcopy(self.data)
        data["events"] = [event for event in data["events"] if event["id"] != "stabilize"]
        errors = validator.validate(data)
        self.assertIn("mandatory event missing: stabilize", errors)

    def test_fixture_passes_automated_geometry_qa_but_stays_human_pending(self):
        report = biomech.evaluate(self.data, self.thresholds)
        self.assertEqual("PASS_AUTOMATED_PENDING_HUMAN", report["status"])
        self.assertTrue(report["human_review_required"])
        self.assertFalse(report["provenance"]["shipping_eligible"])

    def test_broken_contact_fails_geometry_qa(self):
        data = copy.deepcopy(self.data)
        for frame in data["frames"]:
            if 2 <= frame["frame"] <= 4:
                frame["attacker"]["joints"]["wrist_right"] = [0.9, 0.9, 0.9]
        report = biomech.evaluate(data, self.thresholds)
        self.assertEqual("FAIL", report["status"])
        self.assertFalse(report["paired_contacts"]["pass"])


if __name__ == "__main__":
    unittest.main()
