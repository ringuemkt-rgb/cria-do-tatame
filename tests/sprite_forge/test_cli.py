from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from tools.sprite_forge.cli import build_parser


class SpriteForgeCliTests(unittest.TestCase):
    def _run(self, argv: list[str]) -> int:
        args = build_parser().parse_args(argv)
        return int(args.handler(args))

    def test_generate2dsprite_creates_clean_package(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "candidate.png"
            output = root / "package"
            image = Image.new("RGBA", (8, 4), (255, 0, 255, 255))
            image.putpixel((2, 3), (255, 255, 255, 255))
            image.putpixel((6, 3), (255, 255, 255, 255))
            image.save(source)

            result = self._run(
                [
                    "generate2dsprite",
                    "--input",
                    str(source),
                    "--output-dir",
                    str(output),
                    "--asset-id",
                    "m4_test_prop",
                    "--frame-width",
                    "4",
                    "--frame-height",
                    "4",
                ]
            )

            self.assertEqual(result, 0)
            for filename in [
                "raw_sheet.png",
                "clean_sheet.png",
                "spritesheet.png",
                "preview.gif",
                "contact_sheet.png",
                "metadata.json",
                "license.json",
                "import_notes.md",
                "qa_report.md",
            ]:
                self.assertTrue((output / filename).exists(), filename)
            self.assertEqual(len(list((output / "frames").glob("frame_*.png"))), 2)
            metadata = json.loads((output / "metadata.json").read_text(encoding="utf-8"))
            self.assertEqual(metadata["frame_count"], 2)
            self.assertEqual(metadata["state"], "automated_qa_pass_pending_human")
            with Image.open(output / "clean_sheet.png") as clean:
                self.assertEqual(clean.getpixel((0, 0))[3], 0)
                self.assertEqual(clean.getpixel((2, 3))[3], 255)

            self.assertEqual(self._run(["validate", "--package-dir", str(output)]), 0)

    def test_map_writes_labeled_regions_and_hash(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "sheet.png"
            destination = root / "sync_map.json"
            Image.new("RGBA", (8, 4), (0, 0, 0, 0)).save(source)

            result = self._run(
                [
                    "map",
                    "--input",
                    str(source),
                    "--output",
                    str(destination),
                    "--frame-width",
                    "4",
                    "--frame-height",
                    "4",
                    "--labels",
                    "anticipation,contact",
                ]
            )

            self.assertEqual(result, 0)
            mapping = json.loads(destination.read_text(encoding="utf-8"))
            self.assertEqual([item["name"] for item in mapping["regions"]], ["anticipation", "contact"])
            self.assertEqual(mapping["regions"][1]["rect"]["x"], 4)
            self.assertEqual(len(mapping["source"]["sha256"]), 64)


if __name__ == "__main__":
    unittest.main()
