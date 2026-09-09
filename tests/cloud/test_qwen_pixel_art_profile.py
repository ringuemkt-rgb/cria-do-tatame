import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILE = ROOT / "data/ai/qwen_pixel_art_profile_v1.json"
REGISTRY = ROOT / "data/ai/model_registry_v02.json"
VALIDATOR = ROOT / "tools/ai_asset_pipeline/cloud/validate_qwen_pixel_art_profile.py"


class QwenPixelArtProfileTests(unittest.TestCase):
    def test_validator_passes(self):
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        payload = json.loads(result.stdout)
        self.assertTrue(payload["ok"])
        self.assertFalse(payload["shipping"])

    def test_model_stack_is_registered_and_pinned(self):
        profile = json.loads(PROFILE.read_text(encoding="utf-8"))
        registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
        models = {row["id"]: row for row in registry["models"]}
        for key in ("base_model", "lora"):
            descriptor = profile[key]
            entry = models[descriptor["id"]]
            self.assertEqual(entry["requested_ref"], descriptor["revision"])
            self.assertEqual(entry["license"], "apache-2.0")
            self.assertEqual(entry["adoption_status"], "candidate_generation_allowed")

    def test_training_data_provenance_risk_is_not_hidden(self):
        profile = json.loads(PROFILE.read_text(encoding="utf-8"))
        self.assertEqual(
            profile["lora"]["training_dataset_provenance"],
            "NOT_DISCLOSED_IN_MODEL_CARD",
        )
        self.assertFalse(profile["promotion_guards"]["model_license_implies_training_dataset_provenance"])
        self.assertFalse(profile["promotion_guards"]["generation_implies_shipping"])

    def test_bjj_and_runtime_sprite_roles_remain_non_authoritative(self):
        profile = json.loads(PROFILE.read_text(encoding="utf-8"))
        blocked = set(profile["routing"]["not_authoritative_alone"])
        self.assertIn("paired_bjj_technique", blocked)
        self.assertIn("fighter_ground_spritesheet", blocked)
        self.assertIn("identity_from_real_person_reference", blocked)


if __name__ == "__main__":
    unittest.main()
