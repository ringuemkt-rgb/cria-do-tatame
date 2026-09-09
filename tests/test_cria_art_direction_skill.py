import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / ".agents/skills/cria-art-direction/SKILL.md"
P1 = ROOT / "production/p1/cria_art_p1_commands_v1.json"


class CriaArtDirectionSkillTests(unittest.TestCase):
    def test_validator_passes(self):
        proc = subprocess.run(
            [sys.executable, str(ROOT / ".agents/skills/cria-art-direction/scripts/validate_skill.py")],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, msg=proc.stdout + proc.stderr)
        self.assertIn("ART_DIRECTION_OK", proc.stdout)

    def test_skill_keeps_d10_and_shipping_default(self):
        text = SKILL.read_text(encoding="utf-8")
        self.assertIn("Os Aleluiado", text)
        self.assertNotIn("Os Aleluiados", text)
        self.assertIn("shipping=false", text)
        self.assertIn("data/production/canon_contract_v4_1.json", text)

    def test_p1_queue_is_vertical_and_nonshipping(self):
        data = json.loads(P1.read_text(encoding="utf-8"))
        self.assertEqual(data["status"], "AUTHORING_QUEUE")
        self.assertFalse(data["shipping"])
        self.assertEqual(data["source_fixture"], "data/bjj/bjj_kg_slice_ruan_davi_v1.json")
        self.assertEqual(data["summary"]["total_commands"], 32)
        self.assertEqual(data["summary"]["validation_only_fixture_excluded"], ["slice_heel_hook"])

        batch_counts = {b["id"]: len(b["commands"]) for b in data["batches"]}
        self.assertEqual(batch_counts["P1-CHAR-01"], 10)
        self.assertEqual(batch_counts["P1-TECH-01"], 7)
        self.assertEqual(batch_counts["P1-ARENA-01"], 10)
        self.assertEqual(batch_counts["P1-UI-01"], 5)
        self.assertTrue(all(count <= 10 for count in batch_counts.values()))

        generated_source_ids = {
            c["source_id"]
            for batch in data["batches"]
            for c in batch["commands"]
        }
        self.assertNotIn("slice_heel_hook", generated_source_ids)

    def test_p1_outputs_stay_in_candidate_paths(self):
        data = json.loads(P1.read_text(encoding="utf-8"))
        for batch in data["batches"]:
            for command in batch["commands"]:
                self.assertTrue(command["out"].startswith("production/candidates/p1/"))
                self.assertFalse(command["shipping"])


if __name__ == "__main__":
    unittest.main()
