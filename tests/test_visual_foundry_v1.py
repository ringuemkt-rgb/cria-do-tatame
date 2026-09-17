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


class VisualFoundryV1Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(
            (ROOT / "data/visual/production_manifest_v02.json").read_text(encoding="utf-8")
        )
        cls.profile = json.loads(
            (ROOT / "data/visual/visual_foundry_profile_v1.json").read_text(encoding="utf-8")
        )
        cls.builder = load_module(
            ROOT / "tools/visual_foundry/build_foundry_queue.py", "visual_foundry_queue"
        )

    def test_queue_covers_full_canonical_graphic_scope(self):
        queue = self.builder.build_queue(self.manifest, self.profile)
        char_jobs = [job for job in queue if job["kind"] == "character_master_to_sprite"]
        pair_jobs = [job for job in queue if job["kind"] == "paired_technique"]
        arena_jobs = [job for job in queue if job["kind"] == "arena_visual_pack"]
        ui_jobs = [job for job in queue if job["kind"] == "ui_screen_pack"]

        self.assertEqual(len(char_jobs), len(self.manifest["characters"]))
        self.assertEqual(len(pair_jobs), len(self.manifest["paired_techniques"]))
        self.assertEqual(len(arena_jobs), len(self.manifest["arenas"]))
        self.assertEqual(len(ui_jobs), len(self.manifest["ui_screens"]))
        self.assertEqual(
            len(queue),
            len(char_jobs) + len(pair_jobs) + len(arena_jobs) + len(ui_jobs),
        )

    def test_character_jobs_are_sprite_shipping_jobs(self):
        for job in self.builder.build_character_jobs(self.manifest, self.profile):
            self.assertEqual(job["shipping_target"], "2d_sprite")
            self.assertTrue(job["requires_provenance"])
            self.assertIn("sprite_forge_qa", job["stages"])
            self.assertIn("godot_integration", job["stages"])
            self.assertIn("portrait", job["secondary_outputs"])
            self.assertIn("ui_icon", job["secondary_outputs"])

    def test_actions_are_deterministic_and_unique(self):
        for job in self.builder.build_character_jobs(self.manifest, self.profile):
            self.assertEqual(job["actions"], list(dict.fromkeys(job["actions"])))

    def test_arena_jobs_preserve_variants_and_mobile_integration(self):
        by_id = {item["id"]: item for item in self.manifest["arenas"]}
        for job in self.builder.build_arena_jobs(self.manifest, self.profile):
            source = by_id[job["arena_id"]]
            self.assertEqual(job["variants"], source.get("variants", []))
            self.assertIn("parallax_layers", job["stages"])
            self.assertIn("godot_scene_integration", job["stages"])

    def test_ui_jobs_require_mobile_legibility(self):
        for job in self.builder.build_ui_jobs(self.manifest, self.profile):
            self.assertIn("mobile_legibility_qa", job["stages"])
            self.assertEqual(job["shipping_target"], "godot_ui_assets")

    def test_profile_preserves_mobile_sprite_contract(self):
        style = self.manifest["visual_style"]
        sprite = self.profile["sprite"]
        self.assertEqual(sprite["combat_height_px"], style["combat_sprite_height_px"])
        self.assertEqual(sprite["hub_cell_px"], style["hub_sprite_cell_px"])
        self.assertEqual(sprite["hub_directions"], style["hub_directions"])
        self.assertEqual(sprite["grid_px"], style["grid_px"])
        self.assertEqual(sprite["texture_filter"], "nearest")
        self.assertEqual(sprite["outline_px"], 1)

    def test_external_ai_tools_are_not_marked_preinstalled(self):
        tools = self.profile["tool_policy"]
        for name in ("triposg", "triposr", "trellis2", "unirig", "instant_meshes", "quadriflow"):
            self.assertIn(tools[name]["status"], {"candidate", "approved"})


if __name__ == "__main__":
    unittest.main()
