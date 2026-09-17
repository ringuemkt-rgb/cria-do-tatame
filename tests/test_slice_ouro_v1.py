#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools/combat/validate_slice_ouro_v1.py"
spec = importlib.util.spec_from_file_location("validate_slice_ouro_v1", MODULE_PATH)
assert spec and spec.loader
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class SliceOuroContractTests(unittest.TestCase):
    def test_repository_contract_passes_without_shipping_claim(self) -> None:
        report = validator.validate()
        self.assertTrue(report["ok"])
        self.assertFalse(report["shipping"])
        self.assertGreaterEqual(report["overlay_techniques"], 7)
        self.assertGreaterEqual(report["davi_nodes"], 7)
        self.assertEqual(report["state_to"], "PLAYER_TOP_CLINCH")

    def test_baiana_vs_sprawl_in_window_is_denied(self) -> None:
        overlay = json.loads(validator.OVERLAY_PATH.read_text(encoding="utf-8"))
        baiana = next(row for row in overlay["techniques"] if row["id"] == "baiana")
        result = validator.resolve_python(
            baiana,
            {"state": "PLAYER_STANDING_NEUTRAL", "frame": 1, "defense_input": "sprawl"},
        )
        self.assertTrue(result["denied"])
        self.assertFalse(result["success"])
        self.assertEqual(result["state_to"], "PLAYER_TOP_CLINCH")

    def test_fake_before_commit_keeps_state(self) -> None:
        overlay = json.loads(validator.OVERLAY_PATH.read_text(encoding="utf-8"))
        baiana = next(row for row in overlay["techniques"] if row["id"] == "baiana")
        result = validator.resolve_python(
            baiana,
            {
                "state": "PLAYER_STANDING_NEUTRAL",
                "frame": 3,
                "released_before_commit": True,
            },
        )
        self.assertTrue(result["faked"])
        self.assertEqual(result["state_to"], "PLAYER_STANDING_NEUTRAL")

    def test_shipping_claim_fails_closed(self) -> None:
        source = json.loads(validator.OVERLAY_PATH.read_text(encoding="utf-8"))
        source["shipping"] = True
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "overlay.json"
            path.write_text(json.dumps(source), encoding="utf-8")
            with mock.patch.object(validator, "OVERLAY_PATH", path):
                with self.assertRaises(SystemExit):
                    validator.validate()

    def test_missing_baiana_fails_closed(self) -> None:
        source = json.loads(validator.OVERLAY_PATH.read_text(encoding="utf-8"))
        source["techniques"] = [row for row in source["techniques"] if row.get("id") != "baiana"]
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "overlay.json"
            path.write_text(json.dumps(source), encoding="utf-8")
            with mock.patch.object(validator, "OVERLAY_PATH", path):
                with self.assertRaises(SystemExit):
                    validator.validate()


if __name__ == "__main__":
    unittest.main()
