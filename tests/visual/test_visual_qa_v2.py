from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

try:
    from PIL import Image, ImageFont
except ImportError:  # pragma: no cover - Full Game Hardening does not install asset dependencies
    Image = None
    ImageFont = None

ROOT = Path(__file__).resolve().parents[2]
TOOL_PATH = ROOT / "tools/audit/visual_qa_v2.py"


def load_tool():
    spec = importlib.util.spec_from_file_location("visual_qa_v2", TOOL_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load visual_qa_v2")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@unittest.skipUnless(Image is not None, "Pillow asset dependency is not installed")
class VisualQAV2Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = load_tool()
        cls.constitution = json.loads(
            (ROOT / "data/visual/visual_constitution_v2.json").read_text(encoding="utf-8")
        )

    def test_ciede2000_matches_reference_pair(self) -> None:
        first = (50.0, 2.6772, -79.7751)
        second = (50.0, 0.0, -82.7485)
        self.assertAlmostEqual(self.tool.delta_e_ciede2000(first, second), 2.0425, places=4)

    def test_exact_palette_passes_and_wrong_size_fails_without_resize(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            correct = root / "correct.png"
            wrong = root / "wrong.png"
            Image.new("RGB", (480, 270), "#5A4632").save(correct)
            Image.new("RGB", (960, 540), "#5A4632").save(wrong)
            spec = {"biome": "terreiro", "outline": {"required": False}}
            passed = self.tool.audit_image(correct, spec, self.constitution)
            failed = self.tool.audit_image(wrong, spec, self.constitution)
            self.assertTrue(passed["pass"], passed)
            self.assertFalse(failed["pass"])
            self.assertIn("resolution_mismatch", failed["corrections"])
            self.assertEqual(failed["asset"]["size"], [960, 540])

    def test_interpolated_edge_pixels_are_flagged_as_aa_candidates(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "interpolated-edges.png"
            image = Image.new("RGB", (480, 270))
            levels = (0, 128, 255)
            image.putdata([(levels[x % 3],) * 3 for _y in range(270) for x in range(480)])
            image.save(path)
            result = self.tool.audit_image(
                path,
                {"biome": "terreiro", "outline": {"required": False}},
                self.constitution,
            )
            self.assertFalse(result["pass"])
            self.assertIn("anti_alias_candidate_ratio_exceeded", result["corrections"])
            self.assertEqual(result["metrics"]["palette_metric"], "CIEDE2000")

    def test_dither_requires_an_approved_region(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "dither.png"
            colors = ((90, 70, 50), (126, 211, 33))
            image = Image.new("RGB", (480, 270))
            image.putdata([colors[(x + y) % 2] for y in range(270) for x in range(480)])
            image.save(path)
            base_spec = {"biome": "terreiro", "outline": {"required": False}}
            rejected = self.tool.audit_image(path, base_spec, self.constitution)
            approved = self.tool.audit_image(
                path,
                {**base_spec, "dithering_regions": [[0, 0, 480, 270]]},
                self.constitution,
            )
            self.assertIn("dithering_detected_outside_approved_regions", rejected["corrections"])
            self.assertNotIn("dithering_detected_outside_approved_regions", approved["corrections"])

    def test_masked_outline_is_measured_as_one_pixel(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            image_path = root / "outlined.png"
            mask_path = root / "mask.png"
            image = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
            mask = Image.new("L", (480, 270), 0)
            for y in range(50, 100):
                for x in range(50, 100):
                    mask.putpixel((x, y), 255)
                    boundary = x in (50, 99) or y in (50, 99)
                    image.putpixel((x, y), (0, 0, 0, 255) if boundary else (255, 255, 255, 255))
            image.save(image_path)
            mask.save(mask_path)
            spec = {
                "biome": "custom",
                "palette": ["#000000", "#FFFFFF"],
                "outline": {"required": True, "mask_path": str(mask_path)},
            }
            result = self.tool.audit_image(image_path, spec, self.constitution)
            self.assertTrue(result["pass"], result)
            self.assertEqual(result["metrics"]["outline"]["status"], "measured")
            self.assertEqual(result["metrics"]["outline"]["inner_spill"], 0.0)

    def test_label_injection_requires_license_and_binary_mask(self) -> None:
        font = ImageFont.truetype("DejaVuSans.ttf", 12)
        font_path = Path(font.path)
        if not font_path.is_file():
            self.skipTest("Pillow test font path is unavailable")
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            image_path = root / "base.png"
            output_path = root / "labeled.png"
            license_path = root / "font-license.txt"
            Image.new("RGB", (480, 270), "#0B0B0F").save(image_path)
            license_path.write_text("Test fixture only", encoding="utf-8")
            result = self.tool.inject_labels(
                image_path,
                [{"text": "Itacaré", "x": 8, "y": 8}],
                output_path,
                font_path,
                license_path,
                12,
            )
            self.assertTrue(result["ok"])
            self.assertFalse(result["anti_aliased_glyph_mask"])
            self.assertTrue(output_path.is_file())


if __name__ == "__main__":
    unittest.main()
