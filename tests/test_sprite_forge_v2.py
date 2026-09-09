import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "tools" / "art"
if str(ART) not in sys.path:
    sys.path.insert(0, str(ART))

import derive_sprite_forge_v2_requirements as derivator  # noqa: E402

CONTRACT = ROOT / "data/visual/sprite_forge_contract_v2.json"
POLICY = ROOT / "data/visual/sprite_forge_requirements_v2.json"
VALIDATOR = ART / "validate_sprite_forge_v2.py"
ROSTER = ROOT / "data/combat/roster_v3.json"
ARENAS = ROOT / "data/world/arena_info_v1.json"


class SpriteForgeV2Tests(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self.policy = json.loads(POLICY.read_text(encoding="utf-8"))
        self.roster = json.loads(ROSTER.read_text(encoding="utf-8"))
        self.arenas = json.loads(ARENAS.read_text(encoding="utf-8"))
        self.output = derivator.derive(ROOT)

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

    def test_full_roster_is_derived(self):
        self.assertEqual(self.output["summary"]["fighters"], len(self.roster["fighters"]))
        character_ids = {row["source_id"] for row in self.output["requirements"] if row["category"] == "character"}
        self.assertEqual(character_ids, {row["id"] for row in self.roster["fighters"]})

    def test_all_world_locations_are_derived(self):
        self.assertEqual(self.output["summary"]["world_locations"], len(self.arenas["arenas"]))
        derived = {row["source_id"] for row in self.output["requirements"] if row["category"] == "world"}
        self.assertEqual(derived, {row["id"] for row in self.arenas["arenas"]})

    def test_every_requirement_is_non_shipping(self):
        self.assertGreater(self.output["summary"]["requirements_total"], 1000)
        self.assertTrue(all(row["shipping"] is False for row in self.output["requirements"]))

    def test_p1_fighters_and_locations_are_priority_one(self):
        required_ids = set(self.policy["priority"]["p1_fighters"] + self.policy["priority"]["p1_locations"])
        for source_id in required_ids:
            rows = [row for row in self.output["requirements"] if row["source_id"] == source_id]
            self.assertTrue(rows, source_id)
            self.assertTrue(all(row["priority"] == 1 for row in rows), source_id)

    def test_incomplete_bjj_source_stays_blocked(self):
        self.assertTrue(self.output["source_blockers"])
        technique_rows = [row for row in self.output["requirements"] if row["category"] == "technique"]
        self.assertTrue(technique_rows)
        self.assertTrue(all(row["blockers"] for row in technique_rows))
        self.assertTrue(all(row["scope"] != "FULL_GAME" for row in technique_rows))

    def test_bjj_phases_match_completion_gate(self):
        gate = json.loads((ROOT / "data/combat/bjj_completion_gate_v1.json").read_text(encoding="utf-8"))
        self.assertEqual(
            self.contract["paired_bjj_animation"]["required_phases"],
            gate["paired_animation_contract"]["required_phases"],
        )

    def test_generated_flat_world_map_never_counts_as_shipping(self):
        self.assertTrue(self.contract["world_art"]["generated_single_flat_map_is_not_shipping_ready"])
        self.assertTrue(self.policy["world_location"]["runtime_collision_and_navigation_must_be_authored_separately"])


if __name__ == "__main__":
    unittest.main()
