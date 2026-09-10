from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
BUILDER_PATH = ROOT / "tools/data/build_bjj_reconstruction_v1.py"
VALIDATOR_PATH = ROOT / "tools/data/validate_bjj_authority_reconstruction_v1.py"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


builder = load_module("build_bjj_reconstruction_v1_tests", BUILDER_PATH)
validator = load_module("validate_bjj_authority_reconstruction_v1_tests", VALIDATOR_PATH)


def temp_json(value: dict):
    tmp = tempfile.TemporaryDirectory()
    path = Path(tmp.name) / "fixture.json"
    path.write_text(json.dumps(value), encoding="utf-8")
    return tmp, path


class BJJAuthorityReconstructionTests(unittest.TestCase):
    def test_repository_candidate_is_exact_but_not_promoted(self) -> None:
        report = builder.build()
        self.assertTrue(report["ok"], report["errors"])
        self.assertEqual(report["counts"], {"positions": 40, "techniques": 120, "chains": 10})
        self.assertTrue(report["structural_candidate_complete"])
        self.assertFalse(report["promotion_ready"])
        self.assertFalse(report["authoritative_full_graph_created"])
        self.assertEqual(len(report["known_gold_mappings"]), 7)
        self.assertEqual(report["expert_pending_techniques"], 120)
        self.assertEqual(report["rules_pending_techniques"], 120)

    def test_repository_validator_preserves_authoritative_blocker(self) -> None:
        report = validator.validate()
        self.assertTrue(report["ok"])
        self.assertTrue(report["candidate_structural_complete"])
        self.assertFalse(report["promotion_ready"])
        self.assertFalse(report["shipping"])

    def test_non_null_empirical_success_is_rejected(self) -> None:
        manifest = json.loads(builder.TECHNIQUE_MANIFEST_PATH.read_text(encoding="utf-8"))
        family_path = ROOT / manifest["family_files"][0]
        family = json.loads(family_path.read_text(encoding="utf-8"))
        family["techniques"][0]["empirical_success"] = 0.75
        tmp, path = temp_json(family)
        try:
            original = builder.load_families

            def patched_load_families(value):
                files = list(value["family_files"])
                techniques = []
                used = []
                for index, raw in enumerate(files):
                    current = path if index == 0 else ROOT / raw
                    doc = builder.load(current)
                    techniques.extend(doc["techniques"])
                    used.append(str(raw))
                return techniques, used

            with mock.patch.object(builder, "load_families", patched_load_families):
                report = builder.build()
            self.assertFalse(report["ok"])
            self.assertTrue(any("candidate_empirical_success_must_be_null" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_unknown_position_is_rejected(self) -> None:
        manifest = json.loads(builder.TECHNIQUE_MANIFEST_PATH.read_text(encoding="utf-8"))
        family_path = ROOT / manifest["family_files"][1]
        family = json.loads(family_path.read_text(encoding="utf-8"))
        family["techniques"][0]["to"] = "invented_position"
        tmp, path = temp_json(family)
        try:
            def patched_load_families(value):
                techniques = []
                used = []
                for index, raw in enumerate(value["family_files"]):
                    current = path if index == 1 else ROOT / raw
                    doc = builder.load(current)
                    techniques.extend(doc["techniques"])
                    used.append(str(raw))
                return techniques, used

            with mock.patch.object(builder, "load_families", patched_load_families):
                report = builder.build()
            self.assertFalse(report["ok"])
            self.assertTrue(any("technique_unknown_to" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_historical_t_id_reassignment_is_rejected(self) -> None:
        manifest = json.loads(builder.TECHNIQUE_MANIFEST_PATH.read_text(encoding="utf-8"))
        family_path = ROOT / manifest["family_files"][2]
        family = json.loads(family_path.read_text(encoding="utf-8"))
        family["techniques"][1]["id"] = "t093"
        tmp, path = temp_json(family)
        try:
            def patched_load_families(value):
                techniques = []
                used = []
                for index, raw in enumerate(value["family_files"]):
                    current = path if index == 2 else ROOT / raw
                    doc = builder.load(current)
                    techniques.extend(doc["techniques"])
                    used.append(str(raw))
                return techniques, used

            with mock.patch.object(builder, "load_families", patched_load_families):
                report = builder.build()
            self.assertFalse(report["ok"])
            self.assertTrue(any("candidate_technique_id_must_use_rec_prefix:t093" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_gold_mapping_transition_drift_is_rejected(self) -> None:
        manifest = json.loads(builder.TECHNIQUE_MANIFEST_PATH.read_text(encoding="utf-8"))
        family_path = ROOT / manifest["family_files"][0]
        family = json.loads(family_path.read_text(encoding="utf-8"))
        family["techniques"][0]["to"] = "side_control"
        tmp, path = temp_json(family)
        try:
            def patched_load_families(value):
                techniques = []
                used = []
                for index, raw in enumerate(value["family_files"]):
                    current = path if index == 0 else ROOT / raw
                    doc = builder.load(current)
                    techniques.extend(doc["techniques"])
                    used.append(str(raw))
                return techniques, used

            with mock.patch.object(builder, "load_families", patched_load_families):
                report = builder.build()
            self.assertFalse(report["ok"])
            self.assertTrue(any("canonical_mapping_transition_drift:rec_double_leg:t001" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_chain_discontinuity_is_rejected(self) -> None:
        chains = json.loads(builder.CHAINS_PATH.read_text(encoding="utf-8"))
        chains["chains"][0]["steps"][1] = "rec_knee_cut_pass"
        tmp, path = temp_json(chains)
        try:
            with mock.patch.object(builder, "CHAINS_PATH", path):
                report = builder.build()
            self.assertFalse(report["ok"])
            self.assertTrue(any("chain_discontinuity" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_dangerous_directional_detail_is_rejected(self) -> None:
        manifest = json.loads(builder.TECHNIQUE_MANIFEST_PATH.read_text(encoding="utf-8"))
        family_path = ROOT / manifest["family_files"][10]
        family = json.loads(family_path.read_text(encoding="utf-8"))
        family["techniques"][0]["torque_direction"] = "forbidden_test_value"
        tmp, path = temp_json(family)
        try:
            def patched_load_families(value):
                techniques = []
                used = []
                for index, raw in enumerate(value["family_files"]):
                    current = path if index == 10 else ROOT / raw
                    doc = builder.load(current)
                    techniques.extend(doc["techniques"])
                    used.append(str(raw))
                return techniques, used

            with mock.patch.object(builder, "load_families", patched_load_families):
                report = builder.build()
            self.assertFalse(report["ok"])
            self.assertTrue(any("dangerous_directional_detail_forbidden" in error for error in report["errors"]))
        finally:
            tmp.cleanup()


if __name__ == "__main__":
    unittest.main()
