from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools/combat/validate_bjj_shadow_runtime_v1.py"
spec = importlib.util.spec_from_file_location("validate_bjj_shadow_runtime_v1", MODULE_PATH)
assert spec and spec.loader
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class BJJShadowRuntimeContractTests(unittest.TestCase):
    def test_repository_shadow_contract_passes(self) -> None:
        report = validator.validate()
        self.assertTrue(report["ok"])
        self.assertFalse(report["authoritative"])
        self.assertFalse(report["shipping"])
        self.assertGreaterEqual(report["mapped_actions"], 3)
        self.assertGreaterEqual(report["semantic_deltas"], 1)

    def test_ambiguous_state_cannot_guess_canonical_state(self) -> None:
        source = json.loads(validator.MAP_PATH.read_text(encoding="utf-8"))
        source["legacy_state_map"]["PLAYER_TOP_GUARD"]["canonical"] = "closed_guard"
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_path = Path(tmpdir) / "map.json"
            bad_path.write_text(json.dumps(source), encoding="utf-8")
            with mock.patch.object(validator, "MAP_PATH", bad_path):
                with self.assertRaises(SystemExit):
                    validator.validate()

    def test_shadow_authority_escalation_fails(self) -> None:
        source = json.loads(validator.MAP_PATH.read_text(encoding="utf-8"))
        source["authority"]["shadow_may_award_score"] = True
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_path = Path(tmpdir) / "map.json"
            bad_path.write_text(json.dumps(source), encoding="utf-8")
            with mock.patch.object(validator, "MAP_PATH", bad_path):
                with self.assertRaises(SystemExit):
                    validator.validate()


if __name__ == "__main__":
    unittest.main()
