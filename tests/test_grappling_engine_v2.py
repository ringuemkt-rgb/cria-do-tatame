import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


class GrapplingEngineV2Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contract = json.loads((ROOT / "data/combat/grappling_engine_v2_contract.json").read_text(encoding="utf-8"))
        cls.grips = json.loads((ROOT / "data/combat/grip_topology_v1.json").read_text(encoding="utf-8"))
        cls.reactions = json.loads((ROOT / "data/combat/grappling_reaction_policy_v1.json").read_text(encoding="utf-8"))
        cls.motion = json.loads((ROOT / "data/animation/grappling_motion_matching_profile_v1.json").read_text(encoding="utf-8"))
        cls.compiler = load_module(
            ROOT / "tools/motion_factory/compile_grappling_motion_db_v1.py",
            "compile_grappling_motion_db_v1",
        )

    def test_authority_firewall_is_fail_closed(self):
        firewall = self.contract["authority_firewall"]
        self.assertFalse(firewall["shadow_runtime_may_change_score"])
        self.assertFalse(firewall["shadow_runtime_may_change_winner"])
        self.assertFalse(firewall["motion_clip_may_change_outcome"])
        self.assertFalse(firewall["reaction_selector_may_execute_defense"])
        self.assertEqual(self.contract["authorities"]["combat_truth"], "src/combat/BJJGraphReducerV2.gd")

    def test_gi_only_grips_exist_and_shared_controls_exist(self):
        specs = {row["id"]: row for row in self.grips["grip_types"]}
        self.assertEqual(specs["cross_collar"]["modes"], ["gi"])
        self.assertEqual(specs["sleeve_grip"]["modes"], ["gi"])
        self.assertEqual(set(specs["underhook"]["modes"]), {"gi", "nogi"})
        self.assertEqual(set(specs["wrist_control"]["modes"]), {"gi", "nogi"})
        self.assertEqual(self.grips["principles"]["maximum_active_hand_grips_per_player"], 2)

    def test_reaction_selector_is_visual_only_by_contract(self):
        hard = self.reactions["hard_rules"]
        self.assertFalse(hard["selector_executes_combat_action"])
        self.assertFalse(hard["selector_changes_score"])
        self.assertTrue(hard["selector_may_drive_animation_variant"])

    def test_motion_matching_is_mobile_deterministic(self):
        runtime = self.motion["runtime"]
        self.assertFalse(runtime["ml_inference"])
        self.assertFalse(runtime["native_extension_required"])
        self.assertTrue(runtime["deterministic"])
        self.assertEqual(runtime["shipping_target"], "paired_2d_sprite_clips")

    def test_compiler_filters_unapproved_or_noncommercial_variants(self):
        good = self._variant("gclip_good", shipping=True)
        research = self._variant("gclip_research", shipping=True)
        research["rights_status"] = "RESEARCH_ONLY"
        candidate = self._variant("gclip_candidate", shipping=False)
        candidate["asset_status"] = "CANDIDATE"
        compiled = self.compiler.compile_rows([research, good, candidate], shipping_only=True)
        self.assertEqual([row["clip_id"] for row in compiled["clips"]], ["gclip_good"])
        self.assertEqual(compiled["rejected"], [])

    def test_compiler_order_and_duplicate_rejection_are_deterministic(self):
        a = self._variant("gclip_a", shipping=True)
        b = self._variant("gclip_b", shipping=True)
        duplicate = self._variant("gclip_a", shipping=True)
        compiled = self.compiler.compile_rows([b, a, duplicate], shipping_only=True)
        self.assertEqual([row["clip_id"] for row in compiled["clips"]], ["gclip_a", "gclip_b"])
        self.assertEqual(compiled["rejected"], [{"clip_id": "gclip_a", "errors": ["duplicate_clip_id"]}])

    def test_compiler_normalizes_signatures(self):
        row = self._variant("gclip_norm", shipping=True)
        row["features"]["self_grip_signature"] = ["underhook", "wrist_control", "underhook"]
        row["contact_signature"] = ["hip_contact", "chest_contact", "hip_contact"]
        compiled = self.compiler.compile_rows([row], shipping_only=True)
        clip = compiled["clips"][0]
        self.assertEqual(clip["features"]["self_grip_signature"], ["underhook", "wrist_control"])
        self.assertEqual(clip["contact_signature"], ["chest_contact", "hip_contact"])

    def _variant(self, clip_id: str, shipping: bool):
        return {
            "version": "1.0.0",
            "clip_id": clip_id,
            "features": {
                "technique_id": "t001",
                "attack_type": "takedown",
                "position_id": "standing_neutral",
                "top_role": "neutral",
                "mode": "nogi",
                "phase": "entry",
                "reaction_id": "sprawl_frame",
                "gas_bucket": "fresh",
                "self_grip_signature": [],
                "opponent_grip_signature": [],
                "reviewed_connection_signature": [],
                "previous_clip_id": "",
            },
            "attacker_animation": "ruan/t001/attacker",
            "defender_animation": "davi/t001/defender",
            "sync_map_ref": "sync/t001.json",
            "contact_signature": [],
            "source_ref": "owned_capture/session_001",
            "rights_status": "COMMERCIAL_DERIVATION_ALLOWED",
            "human_approval": True,
            "asset_status": "APPROVED_FINAL" if shipping else "CANDIDATE",
            "shipping": shipping,
        }


if __name__ == "__main__":
    unittest.main()
