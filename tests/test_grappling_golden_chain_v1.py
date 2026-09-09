from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools/combat/validate_grappling_golden_chain_v1.py"
spec = importlib.util.spec_from_file_location("validate_grappling_golden_chain_v1", MODULE_PATH)
assert spec and spec.loader
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class GrapplingGoldenChainContractTests(unittest.TestCase):
    def test_repository_contract_passes_without_shipping_claim(self) -> None:
        report = validator.validate()
        self.assertTrue(report["ok"])
        self.assertFalse(report["shipping"])
        self.assertFalse(report["full_graph_claim"])
        self.assertGreaterEqual(report["golden_techniques"], 7)
        self.assertEqual(report["approved_physical_bindings"], 0)

    def test_invented_technique_fails_closed(self) -> None:
        source = json.loads(validator.GOLDEN_PATH.read_text(encoding="utf-8"))
        source["success_chain"][0]["technique_id"] = "invented_double_leg"
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "golden.json"
            path.write_text(json.dumps(source), encoding="utf-8")
            with mock.patch.object(validator, "GOLDEN_PATH", path):
                with self.assertRaises(SystemExit):
                    validator.validate()

    def test_motion_ledger_cannot_claim_shipping(self) -> None:
        source = json.loads(validator.MOTION_PATH.read_text(encoding="utf-8"))
        source["shipping"] = True
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "motion.json"
            path.write_text(json.dumps(source), encoding="utf-8")
            with mock.patch.object(validator, "MOTION_PATH", path):
                with self.assertRaises(SystemExit):
                    validator.validate()

    def test_approved_physical_binding_requires_evidence(self) -> None:
        source = json.loads(validator.BINDINGS_PATH.read_text(encoding="utf-8"))
        source["bindings"][0]["review_status"] = "APPROVED"
        source["bindings"][0]["evidence_refs"] = []
        source["bindings"][0]["reviewer"] = ""
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "bindings.json"
            path.write_text(json.dumps(source), encoding="utf-8")
            with mock.patch.object(validator, "BINDINGS_PATH", path):
                with self.assertRaises(SystemExit):
                    validator.validate()


if __name__ == "__main__":
    unittest.main()
