from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read_json(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


class WorldNarrativeV3Tests(unittest.TestCase):
    def test_validator_passes(self) -> None:
        result = subprocess.run(
            [sys.executable, "tools/audit/validate_world_narrative_v3.py"],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_campaign_has_no_cover_deadlock_or_tap_penalty(self) -> None:
        data = read_json("data/missions/campaign_missions_v1.json")
        self.assertFalse(data["runtime_active"])
        self.assertEqual([item["id"] for item in data["missions"]], [f"M{i:02d}" for i in range(1, 41)])
        m05 = next(item for item in data["missions"] if item["id"] == "M05")
        for choice in m05["choices"]:
            if "tap" in choice["id"]:
                self.assertGreaterEqual(choice["effects"].get("honor", 0), 0)
        m36 = next(item for item in data["missions"] if item["id"] == "M36")
        self.assertTrue(m36["hidden_objective"]["fallback"])
        self.assertEqual(m36["gates"]["conditions"], [])

    def test_world_edges_and_arena_refs_are_closed(self) -> None:
        world = read_json("data/world/mapa_v3.json")
        arenas = read_json("data/arenas/arenas_12_v3.json")
        node_ids = {item["id"] for item in world["nodes"]}
        arena_ids = {item["id"] for item in arenas["arenas"]}
        for edge in world["edges"]:
            self.assertIn(edge["from"], node_ids)
            self.assertIn(edge["to"], node_ids)
        for node in world["nodes"]:
            self.assertTrue(set(node["arenas"]).issubset(arena_ids))

    def test_roster_preserves_18_playable_boundary(self) -> None:
        roster = read_json("data/characters/elenco_23_v3.json")
        self.assertEqual(len(roster["combatants"]), 23)
        self.assertEqual(sum(item["playable_proposed"] for item in roster["combatants"]), 18)
        oni = next(item for item in roster["combatants"] if item["id"] == "oni_da_lapa")
        self.assertIn("oni_do_sul", oni["aliases"])


if __name__ == "__main__":
    unittest.main()
