"""Universal combat contract checks; no GPU, network, inference or Godot editor."""
from __future__ import annotations

import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "cria_universal_validator", ROOT / "tools/ci/validate_universal_combat_v1.py"
)
assert spec and spec.loader
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class UniversalCombatContractTests(unittest.TestCase):
    def test_all_profiles_and_bridge_match_canon(self):
        self.assertEqual(validator.audit(), [])

    def test_roster_coverage_is_not_ruan_davi_only(self):
        roster = json.loads((ROOT / "data/combat/roster_v3.json").read_text(encoding="utf-8"))
        profiles = json.loads((ROOT / "data/combat/fighter_profiles_universal_v1.json").read_text(encoding="utf-8"))
        ids = {row["id"] for row in roster["fighters"]}
        self.assertEqual(set(profiles["profiles"]), ids)
        self.assertEqual(len(ids), roster["count"])
        self.assertIn("leoa", ids)
        self.assertIn("miyao", ids)

    def test_bjj_semantic_deltas_remain_explicit(self):
        bridge = json.loads((ROOT / "data/combat/technique_identity_bridge_universal_v1.json").read_text(encoding="utf-8"))
        master = json.loads((ROOT / "data/techniques.json").read_text(encoding="utf-8"))
        self.assertEqual(set(bridge["techniques"]), {x["id"] for x in master["techniques"]})
        self.assertFalse(bridge["shipping"])
        self.assertTrue(bridge["policy"]["semantic_delta_blocks_promotion"])
        self.assertEqual(bridge["techniques"]["baiana"]["bjj_kg_id"], "t001")
        self.assertEqual(bridge["techniques"]["sprawl"]["bjj_kg_id"], "slice_sprawl")
        for value in bridge["techniques"].values():
            self.assertFalse(value["graph_mapping_reviewed"])
            self.assertFalse(value["shipping"])

    def test_canon_and_nonshipping(self):
        roster = json.loads((ROOT / "data/combat/roster_v3.json").read_text(encoding="utf-8"))
        profiles = json.loads((ROOT / "data/combat/fighter_profiles_universal_v1.json").read_text(encoding="utf-8"))
        self.assertTrue(roster["guardrails"]["fictional_archetypes_only"])
        self.assertTrue(roster["guardrails"]["no_real_person_likeness"])
        self.assertFalse(profiles["shipping"])
        for profile in profiles["profiles"].values():
            self.assertFalse(profile["shipping"])
            self.assertFalse(profile["human_approved"])
            self.assertEqual(profile["gameplay_eligibility"], "EXHIBITION_PREVIEW_ONLY")

    def test_one_godot_project_and_sources_exist(self):
        for path in [
            "src/combat/FighterCombatProfileRegistryV1.gd",
            "src/combat/TechniqueIdentityBridgeUniversalV1.gd",
            "scenes/combat/ExhibitionSelection.gd",
            "scenes/combat/ExhibitionSelection.tscn",
            "tests/universal_exhibition_smoke.gd",
        ]:
            self.assertTrue((ROOT / path).is_file(), path)
        self.assertEqual(len(list(ROOT.glob("**/project.godot"))), 1)


if __name__ == "__main__":
    unittest.main()
