import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class FourCriticalGatesV1Tests(unittest.TestCase):
    def run_script(self, relative_path, *args):
        return subprocess.run(
            [sys.executable, str(ROOT / relative_path), *args],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )

    def test_tool_registry_is_machine_valid(self):
        proc = self.run_script("tools/ci/validate_tool_registry_v1.py")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        registry = json.loads((ROOT / "data/production/tool_registry_v1.json").read_text(encoding="utf-8"))
        by_id = {row["id"]: row for row in registry["tools"]}
        self.assertEqual(by_id["sprite_animator_poirotw66"]["status"], "BLOCKED_LICENSE")
        self.assertEqual(by_id["pixel_srpg_forge"]["status"], "BLOCKED_PROVENANCE")
        self.assertEqual(by_id["qwen_image_2512_pixel_art_lora"]["status"], "APPROVED_CANDIDATE_GENERATOR")
        self.assertFalse(any(row["shipping_bypass_allowed"] for row in registry["tools"]))

    def test_bjj_gate_reports_missing_source_but_full_mode_fails(self):
        with tempfile.TemporaryDirectory() as td:
            report = Path(td) / "bjj.json"
            normal = self.run_script("tools/data/validate_bjj_completion_gate_v1.py", "--report", str(report))
            self.assertEqual(normal.returncode, 0, normal.stdout + normal.stderr)
            payload = json.loads(report.read_text(encoding="utf-8"))
            self.assertFalse(payload["full_ready"])
            self.assertIn("full_bjj_kg_missing", {row["code"] for row in payload["blockers"]})
            full = self.run_script("tools/data/validate_bjj_completion_gate_v1.py", "--full")
            self.assertNotEqual(full.returncode, 0)

    def test_npc_ecology_runtime_foundation_matches_world_authority(self):
        proc = self.run_script("tools/data/validate_npc_ecology_v1.py")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        contract = json.loads((ROOT / "data/world/npc_ecology_contract_v1.json").read_text(encoding="utf-8"))
        self.assertFalse(contract["core_policy"]["llm_may_mutate_world_directly"])
        self.assertTrue(contract["core_policy"]["same_seed_and_actions_require_same_state"])

    def test_visual_and_android_ledgers_cannot_fake_release(self):
        normal = self.run_script("tools/ci/validate_qa_evidence_v1.py")
        self.assertEqual(normal.returncode, 0, normal.stdout + normal.stderr)
        release = self.run_script("tools/ci/validate_qa_evidence_v1.py", "--release")
        self.assertNotEqual(release.returncode, 0)
        visual = json.loads((ROOT / "production/evidence/visual_runtime_qa_v1.json").read_text(encoding="utf-8"))
        android = json.loads((ROOT / "production/evidence/android_physical_device_v1.json").read_text(encoding="utf-8"))
        self.assertEqual(visual["frames_checked"], 0)
        self.assertEqual(visual["status"], "PENDING")
        self.assertEqual(android["status"], "PENDING")


if __name__ == "__main__":
    unittest.main()
