import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "data/visual/p1_visual_build_contract_v2.json"
QUEUE = ROOT / "production/p1/cria_art_p1_commands_v1.json"
SLICE = ROOT / "data/bjj/bjj_kg_slice_ruan_davi_v1.json"
VALIDATOR = ROOT / "tools/art/validate_p1_visual_build_v2.py"


class P1VisualBuildV2Tests(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self.queue = json.loads(QUEUE.read_text(encoding="utf-8"))
        self.slice = json.loads(SLICE.read_text(encoding="utf-8"))
        self.batches = {row["id"]: row for row in self.queue["batches"]}

    def test_validator_passes(self):
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)], cwd=ROOT, capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(json.loads(result.stdout)["ok"])

    def test_executable_set_excludes_only_legality_fixture(self):
        all_ids = {row["id"] for row in self.slice["techniques"]}
        executable = set(self.contract["scope"]["executable_bjj_techniques"])
        excluded = set(self.contract["scope"]["excluded_legality_fixture_techniques"])
        self.assertEqual(executable, all_ids - excluded)
        self.assertEqual(excluded, {"slice_heel_hook"})

    def test_terreiro_alias_resolves_to_one_canonical_location(self):
        aliases = self.contract["scope"]["location_aliases"]
        self.assertEqual(aliases["terreiro_da_luta"], "terreiro")
        self.assertEqual(
            set(self.contract["scope"]["canonical_world_locations"]),
            {"terreiro", "arena_do_dique"},
        )

    def test_davi_has_visual_canon_but_reference_remains_pending(self):
        davi = json.loads((ROOT / "data/chars/canon/davi_relampago.json").read_text(encoding="utf-8"))
        self.assertEqual(davi["identity"]["combat_style"], "speed_scramble_counter")
        self.assertEqual(davi["identity"]["mechanical_signature"], "counter_whiff")
        self.assertIsNone(davi["reference_contract"]["master_reference"])
        self.assertFalse(davi["reference_contract"]["blue_gi_is_canon_by_this_file"])
        self.assertFalse(davi["shipping"])

    def test_every_p1_command_is_candidate_only(self):
        commands = [cmd for batch in self.queue["batches"] for cmd in batch["commands"]]
        self.assertTrue(commands)
        self.assertTrue(all(cmd["shipping"] is False for cmd in commands))
        self.assertTrue(all(cmd["out"].startswith("production/candidates/p1/") for cmd in commands))


if __name__ == "__main__":
    unittest.main()
