import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADAPTER = ROOT / "data/visual/godmode_sprite_adapter_v1.json"
VALIDATOR = ROOT / "tools/art/validate_godmode_sprite_adapter_v1.py"


class GodModeSpriteAdapterV1Tests(unittest.TestCase):
    def setUp(self):
        self.adapter = json.loads(ADAPTER.read_text(encoding="utf-8"))

    def test_validator_passes(self):
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(json.loads(result.stdout)["ok"])

    def test_provider_is_authoring_only(self):
        self.assertFalse(self.adapter["runtime_dependency"])
        self.assertFalse(self.adapter["shipping"])
        self.assertFalse(self.adapter["canon_authority"])
        self.assertFalse(self.adapter["combat_authority"])
        self.assertFalse(self.adapter["generation_policy"]["remote_service_required_for_gameplay"])

    def test_bjj_cannot_be_defined_by_generic_generation(self):
        gate = self.adapter["input_gate"]
        self.assertFalse(gate["generic_attack_prompt_may_define_bjj_motion"])
        self.assertTrue(gate["bjj_transition_id_required_for_bjj_animation"])
        self.assertTrue(gate["paired_bjj_spec_must_define_attacker_defender_sync"])

    def test_raw_outputs_never_ship_directly(self):
        generation = self.adapter["generation_policy"]
        promotion = self.adapter["promotion_gate"]
        self.assertEqual(generation["raw_provider_output_status"], "CANDIDATE")
        self.assertFalse(generation["raw_provider_output_may_enter_runtime_paths"])
        self.assertFalse(promotion["default_shipping"])
        self.assertTrue(promotion["requires_sprite_forge_v2_pass"])
        self.assertTrue(promotion["requires_human_rights_review"])

    def test_cria_normalization_contract_is_preserved(self):
        handoff = self.adapter["normalization_handoff"]
        self.assertEqual(handoff["frame_px"], [128, 128])
        self.assertEqual(handoff["upright_pivot_px"], [64, 96])
        self.assertEqual(handoff["resampling"], "nearest")
        self.assertTrue(handoff["shared_scale_per_strip"])
        self.assertTrue(handoff["shared_anchor_per_strip"])

    def test_secret_name_is_reference_only(self):
        auth = self.adapter["provider"]["authentication"]
        self.assertEqual(auth["environment_variable"], "GODMODEAI_API_TOKEN")
        self.assertTrue(auth["must_not_be_committed"])
        self.assertTrue(auth["must_not_be_written_to_sidecars"])


if __name__ == "__main__":
    unittest.main()
