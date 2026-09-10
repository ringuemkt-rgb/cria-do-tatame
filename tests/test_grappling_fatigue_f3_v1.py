from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR_PATH = ROOT / "tools/combat/validate_grappling_fatigue_f3_v1.py"
CALIBRATOR_PATH = ROOT / "tools/combat/f3_calibrate_bjj_v1.py"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load_module("validate_grappling_fatigue_f3_v1", VALIDATOR_PATH)
calibrator = load_module("f3_calibrate_bjj_v1_tests", CALIBRATOR_PATH)


def temp_json(value: dict):
    tmp = tempfile.TemporaryDirectory()
    path = Path(tmp.name) / "fixture.json"
    path.write_text(json.dumps(value), encoding="utf-8")
    return tmp, path


def observation(
    observation_id: str,
    *,
    outcome: str = "SUCCESS",
    split: str = "train",
    source_event_id: str | None = None,
    athlete_pair_group: str | None = None,
    expert: str = "APPROVED",
    rules: str = "APPROVED",
    rights: bool = True,
) -> dict:
    return {
        "observation_id": observation_id,
        "source_id": f"source_{observation_id}",
        "source_event_id": source_event_id or f"event_{observation_id}",
        "clip_id": f"clip_{observation_id}",
        "athlete_pair_group": athlete_pair_group or f"pair_{observation_id}",
        "technique_id": "t001",
        "from_position": "standing_neutral",
        "to_position_observed": "half_guard_top",
        "attempt_outcome": outcome,
        "ruleset": "ibjjf_v6",
        "modality": "gi",
        "skill_band": "adult_black",
        "phase_timing_ms": {},
        "fatigue_context": {},
        "expert_review_status": expert,
        "rules_review_status": rules,
        "rights_eligible_for_calibration": rights,
        "split": split,
        "provenance_sha256": "a" * 64,
    }


class GrapplingFatigueF3Tests(unittest.TestCase):
    def test_repository_contract_passes_without_runtime_effect(self) -> None:
        report = validator.validate()
        self.assertTrue(report["ok"])
        self.assertFalse(report["runtime_effect_active"])
        self.assertFalse(report["shipping"])
        self.assertEqual(report["F3_status"], "DATA_PENDING")
        self.assertGreaterEqual(report["golden_profiles"], 7)

    def test_fatigue_cannot_modify_success_before_f3(self) -> None:
        value = json.loads(validator.FATIGUE_CONTRACT.read_text(encoding="utf-8"))
        value["authority"]["fatigue_may_modify_success_before_f3_approval"] = True
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "FATIGUE_CONTRACT", path):
                with self.assertRaises(SystemExit):
                    validator.validate()
        finally:
            tmp.cleanup()

    def test_authoring_profile_cannot_claim_empirical_measurement(self) -> None:
        value = json.loads(validator.FATIGUE_PROFILES.read_text(encoding="utf-8"))
        value["policy"]["levels_are_empirical_measurements"] = True
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "FATIGUE_PROFILES", path):
                with self.assertRaises(SystemExit):
                    validator.validate()
        finally:
            tmp.cleanup()

    def test_profile_dimension_cannot_disappear(self) -> None:
        value = json.loads(validator.FATIGUE_PROFILES.read_text(encoding="utf-8"))
        del value["profiles"][0]["performer_load"]["forearm_grip"]
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "FATIGUE_PROFILES", path):
                with self.assertRaises(SystemExit):
                    validator.validate()
        finally:
            tmp.cleanup()

    def test_f3_video_frequency_cannot_become_success_probability(self) -> None:
        value = json.loads(validator.F3_CONTRACT.read_text(encoding="utf-8"))
        value["hard_boundaries"]["video_frequency_is_success_probability"] = True
        tmp, path = temp_json(value)
        try:
            with mock.patch.object(validator, "F3_CONTRACT", path):
                with self.assertRaises(SystemExit):
                    validator.validate()
        finally:
            tmp.cleanup()

    def test_empty_ledger_is_data_pending_not_zero_success(self) -> None:
        ledger = {"observations": []}
        contract = json.loads(calibrator.CONTRACT_PATH.read_text(encoding="utf-8"))
        report = calibrator.calibrate(ledger=ledger, contract=contract)
        self.assertTrue(report["ok"])
        self.assertEqual(report["status"], "DATA_PENDING")
        self.assertEqual(report["eligible_observations"], 0)
        self.assertEqual(report["groups"], [])
        self.assertFalse(report["runtime_effect_active"])

    def test_calibrator_builds_reproducible_candidate_group(self) -> None:
        ledger = {
            "observations": [
                observation("001", outcome="SUCCESS", split="train"),
                observation("002", outcome="FAILURE", split="train"),
                observation("003", outcome="COUNTERED", split="validation"),
                observation("004", outcome="SUCCESS", split="holdout"),
            ]
        }
        contract = json.loads(calibrator.CONTRACT_PATH.read_text(encoding="utf-8"))
        report_a = calibrator.calibrate(ledger=ledger, contract=contract)
        report_b = calibrator.calibrate(ledger=ledger, contract=contract)
        self.assertTrue(report_a["ok"])
        self.assertEqual(report_a["status"], "CANDIDATE_REPORT_PENDING_HUMAN_APPROVAL")
        self.assertEqual(report_a["eligible_observations"], 4)
        self.assertEqual(report_a["split_counts"], {"train": 2, "validation": 1, "holdout": 1})
        self.assertEqual(len(report_a["groups"]), 1)
        group = report_a["groups"][0]
        self.assertEqual(group["n"], 4)
        self.assertEqual(group["successes"], 2)
        self.assertEqual(group["failures"], 2)
        self.assertAlmostEqual(group["empirical_success_candidate"], 0.5)
        self.assertLess(group["wilson_95"][0], 0.5)
        self.assertGreater(group["wilson_95"][1], 0.5)
        self.assertEqual(report_a["snapshot_sha256"], report_b["snapshot_sha256"])

    def test_split_leakage_is_rejected(self) -> None:
        ledger = {
            "observations": [
                observation("001", split="train", source_event_id="same_event"),
                observation("002", split="holdout", source_event_id="same_event"),
            ]
        }
        contract = json.loads(calibrator.CONTRACT_PATH.read_text(encoding="utf-8"))
        report = calibrator.calibrate(ledger=ledger, contract=contract)
        self.assertFalse(report["ok"])
        self.assertEqual(report["status"], "INVALID_SPLIT_LEAKAGE")
        self.assertTrue(any(error.startswith("split_leakage:source_event_id") for error in report["errors"]))

    def test_unreviewed_or_rights_blocked_rows_are_excluded(self) -> None:
        ledger = {
            "observations": [
                observation("001", expert="PENDING"),
                observation("002", rights=False),
                observation("003", outcome="UNCERTAIN"),
            ]
        }
        contract = json.loads(calibrator.CONTRACT_PATH.read_text(encoding="utf-8"))
        report = calibrator.calibrate(ledger=ledger, contract=contract)
        self.assertEqual(report["eligible_observations"], 0)
        self.assertEqual(report["excluded_observations"], 3)
        self.assertEqual(report["status"], "DATA_PENDING")


if __name__ == "__main__":
    unittest.main()
