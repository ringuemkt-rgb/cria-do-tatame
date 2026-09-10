from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools/combat/validate_grappling_motion_lab_v1.py"
spec = importlib.util.spec_from_file_location("validate_grappling_motion_lab_v1", MODULE_PATH)
assert spec and spec.loader
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def temp_json(value: dict) -> tuple[tempfile.TemporaryDirectory, Path]:
    tmp = tempfile.TemporaryDirectory()
    path = Path(tmp.name) / "candidate.json"
    path.write_text(json.dumps(value), encoding="utf-8")
    return tmp, path


class GrapplingMotionLabTests(unittest.TestCase):
    def test_repository_motion_lab_contract_passes(self) -> None:
        report = validator.validate()
        self.assertTrue(report["ok"], report["errors"])
        self.assertFalse(report["shipping"])
        self.assertEqual(report["canonical_phases"], validator.CANONICAL_PHASES)
        self.assertEqual(report["videos_ingested_claim"], 0)

    def test_public_url_cannot_become_permission(self) -> None:
        value = json.loads(validator.CORPUS.read_text(encoding="utf-8"))
        value["rights_policy"]["public_url_is_not_permission"] = False
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "CORPUS", path):
                report = validator.validate()
            self.assertFalse(report["ok"])
            self.assertTrue(any("public URL" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_noncommercial_motion_tool_cannot_default_to_commercial(self) -> None:
        value = json.loads(validator.TOOL_REGISTRY.read_text(encoding="utf-8"))
        for row in value["restricted_or_reference_only"]:
            if row.get("id") == "blendanything":
                row["commercial_use_default"] = True
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "TOOL_REGISTRY", path):
                report = validator.validate()
            self.assertFalse(report["ok"])
            self.assertTrue(any("BlendAnything" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_own_capture_cannot_drop_athlete_release_requirement(self) -> None:
        value = json.loads(validator.MOTION_LAB.read_text(encoding="utf-8"))
        requirements = value["source_tiers"]["A_CRIA_OWN_MULTIVIEW"]["requirements"]
        requirements.remove("athlete_release_refs")
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "MOTION_LAB", path):
                report = validator.validate()
            self.assertFalse(report["ok"])
            self.assertTrue(any("athlete_release_refs" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_gold_capture_cannot_drop_below_four_views(self) -> None:
        value = json.loads(validator.MOTION_LAB.read_text(encoding="utf-8"))
        value["capture_protocol"]["minimum_for_gold_multiview"] = 2
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "MOTION_LAB", path):
                report = validator.validate()
            self.assertFalse(report["ok"])
            self.assertTrue(any("four cameras" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_motion_phases_cannot_diverge_from_combat_contract(self) -> None:
        value = json.loads(validator.MOTION_LAB.read_text(encoding="utf-8"))
        value["six_phase_motion_contract"] = ["entry", "recovery"]
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "MOTION_LAB", path):
                report = validator.validate()
            self.assertFalse(report["ok"])
            self.assertTrue(any("six-phase" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_blank_capture_template_cannot_contain_fake_release(self) -> None:
        value = json.loads(validator.CAPTURE_TEMPLATE.read_text(encoding="utf-8"))
        value["participants"][0]["athlete_release_ref"] = "release_fake_001"
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "CAPTURE_TEMPLATE", path):
                report = validator.validate()
            self.assertFalse(report["ok"])
            self.assertTrue(any("fabricated athlete release" in error for error in report["errors"]))
        finally:
            tmp.cleanup()

    def test_contact_continuity_policy_cannot_be_relaxed(self) -> None:
        value = json.loads(validator.PHYSICAL_BINDINGS.read_text(encoding="utf-8"))
        value["policy"]["runtime_may_infer_contact_continuity_from_edge_presence"] = True
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "PHYSICAL_BINDINGS", path):
                report = validator.validate()
            self.assertFalse(report["ok"])
            self.assertTrue(any("continuity from edge" in error for error in report["errors"]))
        finally:
            tmp.cleanup()


if __name__ == "__main__":
    unittest.main()
