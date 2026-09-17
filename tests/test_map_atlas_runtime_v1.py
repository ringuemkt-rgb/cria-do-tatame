from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(rel: str) -> dict:
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


class MapAtlasRuntimeTests(unittest.TestCase):
    def test_ten_pages_match_world_map(self) -> None:
        atlas = load("data/maps/map_atlas_runtime_v1.json")
        world = load("data/world/world_map_v4.json")
        self.assertEqual(len(atlas["pages"]), 10)
        self.assertEqual(
            [p["id"] for p in atlas["pages"]],
            [p["id"] for p in world["pages"]],
        )

    def test_offline_and_no_second_manager(self) -> None:
        atlas = load("data/maps/map_atlas_runtime_v1.json")
        self.assertFalse(atlas["shipping"])
        text = " ".join(atlas["forbidden"])
        self.assertIn("CombatManager", text)
        self.assertIn("autoload", text)

    def test_moon_formula_covers_avesso_pair(self) -> None:
        moon = load("data/world/moon_tide_v01.json")
        self.assertEqual(moon["phases"][4]["id"], "cheia")
        self.assertEqual(moon["phases"][0]["id"], "nova")
        locks = moon["gameplay_locks"]["pratigi_do_avesso"]["need"]
        self.assertIn("lua_cheia", locks)
        self.assertIn("mare_baixa", locks)

    def test_itubera_life_respects_weather_hide(self) -> None:
        page = load("data/maps/pages/map_02_itubera.json")
        boats = [a for a in page["life"] if a["type"] == "boat"]
        self.assertTrue(boats)
        self.assertIn("temporal_tropical", boats[0]["hide_if_weather"])

    def test_presenter_and_shaders_exist(self) -> None:
        required = [
            "src/world/MapAtlasPresenter.gd",
            "assets/maps/shaders/map_water_shimmer.gdshader",
            "assets/maps/shaders/map_foam_edge.gdshader",
            "assets/maps/shaders/map_secret_mist.gdshader",
            "assets/maps/shaders/map_weather_grade.gdshader",
            "docs/world/MAP_ATLAS_RUNTIME.md",
        ]
        for rel in required:
            self.assertTrue((ROOT / rel).is_file(), rel)


if __name__ == "__main__":
    unittest.main()
