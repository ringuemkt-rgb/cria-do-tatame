import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "data/production/godot_ai_mcp_eval_v1.json"
VALIDATOR = ROOT / "tools/experiments/validate_godot_ai_mcp_eval_v1.py"


class GodotAiMcpEvalV1Tests(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))

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

    def test_experiment_cannot_authorize_main_migration(self):
        self.assertEqual(self.contract["status"], "EXPERIMENT_ONLY")
        self.assertFalse(self.contract["main_engine_version_change_authorized"])
        self.assertFalse(self.contract["runtime_dependency"])
        self.assertFalse(self.contract["shipping"])

    def test_candidate_is_pinned_to_godot_4_7_and_godot_ai_4_1(self):
        candidate = self.contract["candidate"]
        self.assertEqual(candidate["engine_version"], "4.7")
        self.assertEqual(candidate["godot_ai_version"], "4.1.0")
        self.assertEqual(candidate["godot_ai_release_tag"], "v4.1.0")
        self.assertEqual(candidate["godot_ai_archive_sha256"], "535d8a7541871af8d991b07fe5031550dd6121a31b844400476b334a70612831")

    def test_current_v3_does_not_claim_4_3_compatibility(self):
        candidate = self.contract["candidate"]
        self.assertEqual(candidate["godot_ai_v3_2_5_minimum_engine"], "4.5")
        self.assertNotEqual(candidate["godot_ai_v3_2_5_minimum_engine"], "4.3")

    def test_critical_regressions_are_explicit_gates(self):
        names = {gate["name"] for gate in self.contract["gates"]}
        for name in (
            "forty_mission_data_and_reference_regression",
            "world_map_routes_nodes_and_travel_regression",
            "save_load_roundtrip_and_migration_regression",
            "ruan_davi_combat_determinism_regression",
            "android_physical_install_touch_full_flow_save_restart",
            "plugin_removal_restores_clean_project",
        ):
            self.assertIn(name, names)

    def test_every_gate_starts_pending(self):
        self.assertTrue(all(gate["status"] == "PENDING" for gate in self.contract["gates"]))


if __name__ == "__main__":
    unittest.main()
