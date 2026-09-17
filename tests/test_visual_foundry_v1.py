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

    def test_queue_covers_every_character_and_paired_technique(self):
        queue = self.builder.build_queue(self.manifest, self.profile)
        char_jobs = [job for job in queue if job["kind"] == "character_master_to_sprite"]
        pair_jobs = [job for job in queue if job["kind"] == "paired_technique"]
        self.assertEqual(len(char_jobs), len(self.manifest["characters"]))
        self.assertEqual(len(pair_jobs), len(self.manifest["paired_techniques"]))

    def test_character_jobs_are_sprite_shipping_jobs(self):
        for job in self.builder.build_character_jobs(self.manifest, self.profile):
            self.assertEqual(job["shipping_target"], "2d_sprite")
            self.assertTrue(job["requires_provenance"])
            self.assertIn("sprite_forge_qa", job["stages"])
            self.assertIn("godot_integration", job["stages"])

    def test_actions_are_deterministic_and_unique(self):
        for job in self.builder.build_character_jobs(self.manifest, self.profile):
            self.assertEqual(job["actions"], list(dict.fromkeys(job["actions"])))

    def test_profile_preserves_mobile_sprite_contract(self):
        style = self.manifest["visual_style"]
        sprite = self.profile["sprite"]
        self.assertEqual(sprite["combat_height_px"], style["combat_sprite_height_px"])
        self.assertEqual(sprite["grid_px"], style["grid_px"])
        self.assertEqual(sprite["texture_filter"], "nearest")
        self.assertEqual(sprite["outline_px"], 1)

    def test_external_ai_tools_are_not_marked_preinstalled(self):
        tools = self.profile["tool_policy"]
        for name in ("triposg", "triposr", "trellis2", "unirig", "instant_meshes", "quadriflow"):
            self.assertIn(tools[name]["status"], {"candidate", "approved"})


if __name__ == "__main__":
    unittest.main()
