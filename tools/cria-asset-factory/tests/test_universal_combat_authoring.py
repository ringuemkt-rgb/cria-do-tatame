"""Offline multi-fighter authoring coverage: does not prove gameplay readiness."""
from __future__ import annotations
import importlib.util
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

FACTORY = Path(__file__).resolve().parents[1]
SCRIPTS = FACTORY / "scripts"
sys.path.insert(0, str(SCRIPTS))

def load(name):
    spec = importlib.util.spec_from_file_location("universal_" + name, SCRIPTS / (name + ".py"))
    assert spec and spec.loader
    obj = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(obj)
    return obj

class UniversalCombatAuthoringTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.roster = load("fighter_roster")
        cls.planner = load("plan_combat_matchups")
        cls.jobs = load("prepare_candidate_job")
        cls.paired = load("build_paired_technique")

    def test_all_roster_ids_source_driven(self):
        actual = self.roster.load_fighters()
        source = json.loads((self.roster.ROOT / "data/combat/roster_v3.json").read_text())
        self.assertEqual(set(actual), {row["id"] for row in source["fighters"]})
        self.assertEqual(len(actual), source["count"])
        self.assertIn("leoa", actual)
        self.assertIn("galvao", actual)

    def test_complete_pair_coverage(self):
        result = self.planner.plan()
        n = result["character_count"]
        self.assertEqual(result["matchup_count"], n * (n - 1) // 2)
        self.assertEqual(result["directed_role_count"], n * (n - 1))
        self.assertEqual({row["attacker_id"] for pair in result["matchups"] for row in pair["directed_roles"]},
                         set(self.roster.load_fighters()))
        self.assertFalse(result["shipping"])
        self.assertFalse(result["gameplay_authority"])
        self.assertTrue(all(not row["match_playable"] for row in result["matchups"]))

    def test_non_ruan_davi_roles_and_technique(self):
        plan = self.planner.plan(first="leoa", second="jacare_do_mangue", selected_technique="baiana")
        self.assertEqual(plan["matchup_count"], 1)
        self.assertEqual(plan["directed_role_count"], 2)
        self.assertEqual(plan["technique_candidate_count"], 1)
        roles = plan["matchups"][0]["directed_roles"]
        self.assertEqual({r["attacker_id"] for r in roles}, {"leoa", "jacare_do_mangue"})

    def test_concept_job_for_every_fighter(self):
        for fighter_id in self.roster.load_fighters():
            item = self.jobs.make_job("baiana", fighter_id, "gi_white",
                                      "anticipation", "character_combat_pose_concept")
            self.assertEqual(item["character_id"], fighter_id)
            self.assertFalse(item["match_playable"])
        pair = self.jobs.make_job("baiana", "leoa", "nogi", "entry",
                                  "character_combat_pose_concept",
                                  opponent_id="jacare_do_mangue")
        self.assertEqual(pair["opponent_id"], "jacare_do_mangue")
        self.assertEqual(pair["fighter_technique_eligibility"], "UNVERIFIED")

    def test_invalid_fighters_and_technique_blocked(self):
        with self.assertRaises(ValueError):
            self.planner.plan(first="leoa", second="leoa")
        with self.assertRaises(ValueError):
            self.planner.plan(first="invented_person")
        with self.assertRaises(ValueError):
            self.planner.plan(selected_technique="invented_move")
        with self.assertRaises(ValueError):
            self.jobs.make_job("baiana", "leoa", "gi_white",
                               "entry", "character_combat_pose_concept",
                               opponent_id="leoa")

    def test_roster_can_grow_from_real_source_without_code_change(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            (folder / "data/combat").mkdir(parents=True)
            (folder / "data/transitions").mkdir(parents=True)
            base = self.roster.ROOT
            shutil.copy2(base / "data/techniques.json", folder / "data/techniques.json")
            for f in (base / "data/transitions").glob("*.json"):
                shutil.copy2(f, folder / "data/transitions" / f.name)
            roster = json.loads((base / "data/combat/roster_v3.json").read_text())
            roster["fighters"].append({
                "id": "test_future_fighter", "display_name": "Fixture only",
                "role": "opponent", "signature_trigger": "none",
            })
            roster["count"] = len(roster["fighters"])
            (folder / "data/combat/roster_v3.json").write_text(json.dumps(roster))
            result = self.planner.plan(root=folder)
            n = roster["count"]
            self.assertEqual(result["character_count"], n)
            self.assertEqual(result["matchup_count"], n * (n - 1) // 2)
            self.assertTrue(any("test_future_fighter" in (m["fighter_a"], m["fighter_b"])
                                for m in result["matchups"]))

    def test_saved_plan_is_nonshipping_create_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "out.json"
            item = self.planner.plan(first="leoa", second="jacare_do_mangue")
            self.planner.save_plan(item, out)
            self.assertFalse(json.loads(out.read_text())["shipping"])
            with self.assertRaises(FileExistsError):
                self.planner.save_plan(item, out)
        with self.assertRaises(ValueError):
            self.planner.save_plan(item, self.planner.ROOT / "data/forbidden.json")

    def test_real_candidate_packaging_for_new_pair_synthetic_frames(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            a, b = folder / "a", folder / "b"
            a.mkdir()
            b.mkdir()
            counts = [2, 2, 2, 3, 2, 2]
            for i in range(sum(counts)):
                Image.new("RGBA", (128, 128), "#C9971C").save(a / f"{i:04d}.png")
                Image.new("RGBA", (128, 128), "#EDE6D6").save(b / f"{i:04d}.png")
            result = self.paired.run("baiana", "leoa", "jacare_do_mangue",
                                     a, b, folder / "output", counts, 8, "gi_white", None)
            self.assertEqual(result["attacker_id"], "leoa")
            self.assertEqual(result["defender_id"], "jacare_do_mangue")
            self.assertFalse(result["fight_runtime_ready"])
            self.assertTrue((folder / "output/attacker/spritesheet.png").is_file())
            self.assertTrue((folder / "output/defender/spritesheet.png").is_file())
            self.assertTrue((folder / "output/sync_map.json").is_file())

if __name__ == "__main__":
    unittest.main()
