from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.sprite_forge.build_m4_queue import build, main


class M4QueueTests(unittest.TestCase):
    def test_queue_contains_canonical_icons_and_guarded_arena_packs(self) -> None:
        root = Path(__file__).resolve().parents[2]
        manifest = json.loads((root / "data/visual/production_manifest_v02.json").read_text(encoding="utf-8"))
        catalog = json.loads((root / "data/visual/graphic_asset_catalog_v01.json").read_text(encoding="utf-8"))
        rows = build(manifest, catalog)

        self.assertEqual(len(rows), 14)
        self.assertTrue(any(row["task_id"] == "m4::technique_icon::baiana" for row in rows))
        self.assertTrue(any(row["task_id"] == "m4::ui_icons::combat_hud_mobile" for row in rows))
        arena_rows = [row for row in rows if row["kind"].startswith("arena_")]
        self.assertEqual(len(arena_rows), 4)
        self.assertTrue(all(row["status"] == "needs_item_specification" for row in arena_rows))
        self.assertTrue(all(row["promotion"] == "forbidden_without_human_review" for row in rows))
        self.assertTrue(all("item_id" in row.get("required_before_generation", []) for row in arena_rows))

    def test_cli_writes_jsonl(self) -> None:
        root = Path(__file__).resolve().parents[2]
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "m4.jsonl"
            argv = [
                "build_m4_queue.py",
                "--manifest",
                str(root / "data/visual/production_manifest_v02.json"),
                "--catalog",
                str(root / "data/visual/graphic_asset_catalog_v01.json"),
                "--output",
                str(output),
            ]
            import sys

            previous = sys.argv
            try:
                sys.argv = argv
                self.assertEqual(main(), 0)
            finally:
                sys.argv = previous
            self.assertEqual(len(output.read_text(encoding="utf-8").splitlines()), 14)


if __name__ == "__main__":
    unittest.main()
