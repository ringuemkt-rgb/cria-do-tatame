from __future__ import annotations

import json
import pathlib
import sys
import tempfile
import unittest

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools" / "art"
sys.path.insert(0, str(TOOLS))

import build_sprite_forge_profile as builder  # noqa: E402
import validate_sprite_forge as validator  # noqa: E402


class SpriteForgeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads((ROOT / "data/visual/sprite_forge_contract_v1.json").read_text(encoding="utf-8"))

    def _make_frame(self, path: pathlib.Path, bbox: tuple[int, int, int, int]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        image = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        image.paste((11, 11, 13, 255), bbox)
        image.save(path)

    def _make_repo(self, root: pathlib.Path, walk_boxes: list[tuple[int, int, int, int]] | None = None) -> pathlib.Path:
        char = root / "assets/chars/frames/ruan_macacao"
        idle = char / "idle"
        walk = char / "walk"
        for index in range(4):
            self._make_frame(idle / f"{index:02d}.png", (48, 40, 80, 100))
        boxes = walk_boxes or [
            (48, 40, 80, 100),
            (48, 39, 80, 100),
            (48, 40, 80, 100),
            (48, 39, 80, 100),
        ]
        for index, bbox in enumerate(boxes):
            self._make_frame(walk / f"{index:02d}.png", bbox)
        return char

    def test_contract_matches_asset_pipeline_v2(self) -> None:
        errors = validator.validate_contract(self.contract, ROOT)
        self.assertEqual(errors, [])
        self.assertEqual(self.contract["frame_contract"]["size_px"], [128, 128])
        self.assertEqual(self.contract["frame_contract"]["pivot_px"], [64, 96])
        self.assertFalse(self.contract["promotion"]["this_contract_may_set_shipping_true"])

    def test_builder_and_validator_accept_stable_actions(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = pathlib.Path(temp)
            char = self._make_repo(repo)
            package = builder.build_manifest(repo, "ruan_macacao", "idle")
            manifest = char / "sprite_forge_manifest.json"
            manifest.write_text(json.dumps(package), encoding="utf-8")
            self.assertFalse(package["shipping"])
            self.assertEqual(validator.validate_package(manifest, self.contract, repo), [])

    def test_validator_rejects_body_scale_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = pathlib.Path(temp)
            char = self._make_repo(repo)
            package = builder.build_manifest(repo, "ruan_macacao", "idle")
            manifest = char / "sprite_forge_manifest.json"
            manifest.write_text(json.dumps(package), encoding="utf-8")
            # Make the walk body much smaller after the profile was generated.
            self._make_frame(char / "walk/00.png", (54, 65, 74, 95))
            errors = validator.validate_package(manifest, self.contract, repo)
            self.assertTrue(any("body_scale" in error or "profile_body_scale_drift" in error for error in errors))

    def test_validator_rejects_anchor_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = pathlib.Path(temp)
            char = self._make_repo(
                repo,
                walk_boxes=[
                    (48, 30, 80, 90),
                    (48, 45, 80, 105),
                    (48, 55, 80, 115),
                    (48, 35, 80, 95),
                ],
            )
            package = builder.build_manifest(repo, "ruan_macacao", "idle")
            manifest = char / "sprite_forge_manifest.json"
            manifest.write_text(json.dumps(package), encoding="utf-8")
            errors = validator.validate_package(manifest, self.contract, repo)
            self.assertTrue(any("anchor_y_std exceeds threshold" in error for error in errors))

    def test_validator_rejects_path_escape_and_shipping(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = pathlib.Path(temp)
            char = self._make_repo(repo)
            package = builder.build_manifest(repo, "ruan_macacao", "idle")
            package["actions"]["walk"]["frames_dir"] = "../../outside"
            package["shipping"] = True
            manifest = char / "sprite_forge_manifest.json"
            manifest.write_text(json.dumps(package), encoding="utf-8")
            errors = validator.validate_package(manifest, self.contract, repo)
            self.assertTrue(any("escapes character directory" in error for error in errors))
            self.assertTrue(any("shipping must remain false" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
