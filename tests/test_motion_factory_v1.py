from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class MotionFactoryV1Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.validator = load_module(
            "validate_motion_factory_v1",
            ROOT / "tools/motion_factory/validate_motion_factory_v1.py",
        )
        cls.adapter = load_module(
            "run_mixamo_llm_mocap",
            ROOT / "tools/motion_factory/run_mixamo_llm_mocap.py",
        )

    def test_contract_validator_is_green(self) -> None:
        report = self.validator.validate()
        self.assertTrue(report["ok"], report["errors"])
        self.assertFalse(report["shipping"])
        self.assertEqual(report["pinned_revision"], "00dfd5385506022d533c84f6737a09f5f4392623")
        self.assertGreaterEqual(report["units"], 7)

    def test_adapter_pin_matches_contract(self) -> None:
        contract = json.loads((ROOT / "data/production/motion_factory_v1.json").read_text(encoding="utf-8"))
        self.assertEqual(self.adapter.PINNED_SOURCE, contract["upstream"]["source"])
        self.assertEqual(self.adapter.PINNED_REVISION, contract["upstream"]["revision"])

    def test_adapter_rejects_incomplete_action_spec(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.json"
            path.write_text(json.dumps({"name": "incomplete"}), encoding="utf-8")
            with self.assertRaises(SystemExit):
                self.adapter.validate_spec(path)

    def test_adapter_accepts_minimum_reviewed_action_spec_shape(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "ok.json"
            path.write_text(
                json.dumps(
                    {
                        "name": "candidate",
                        "action_name": "Candidate",
                        "landmarks": "external/landmarks.json",
                        "joints_out": "external/joints.json",
                        "armature": "Armature_Ruan",
                        "rig_profile": "external/ruan.json",
                        "src_fps": 60,
                        "dst_fps": 30,
                    }
                ),
                encoding="utf-8",
            )
            self.adapter.validate_spec(path)


if __name__ == "__main__":
    unittest.main()
