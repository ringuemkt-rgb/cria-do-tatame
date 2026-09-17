from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOOL_PATH = ROOT / "tools/mocap/validate_capture_plan.py"
PLAN_PATH = ROOT / "production/mocap/vertical_slice_capture_plan_v1.json"


def load_tool():
    spec = importlib.util.spec_from_file_location("validate_capture_plan", TOOL_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load capture-plan validator")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class CapturePlanTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = load_tool()

    def test_canonical_plan_passes(self) -> None:
        self.assertEqual(self.tool.validate(PLAN_PATH), [])

    def test_duplicate_technique_fails(self) -> None:
        plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
        plan["techniques"][7]["technique_id"] = "grip_de_ferro"
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "plan.json"
            path.write_text(json.dumps(plan), encoding="utf-8")
            errors = self.tool.validate(path)
        self.assertTrue(any("technique IDs must be unique" in error for error in errors))

    def test_capture_cannot_claim_shipping_before_owned_capture(self) -> None:
        plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
        plan["techniques"][0]["status"] = "SHIPPING_READY"
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "plan.json"
            path.write_text(json.dumps(plan), encoding="utf-8")
            errors = self.tool.validate(path)
        self.assertTrue(any("AWAITING_OWNED_CAPTURE" in error for error in errors))

    def test_required_outputs_are_fail_closed(self) -> None:
        plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
        plan["global_rules"]["required_outputs"].remove("human_review.json")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "plan.json"
            path.write_text(json.dumps(plan), encoding="utf-8")
            errors = self.tool.validate(path)
        self.assertTrue(any("required_outputs missing" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
