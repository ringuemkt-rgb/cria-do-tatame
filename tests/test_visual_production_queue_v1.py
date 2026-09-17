from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class VisualQueueTests(unittest.TestCase):
    def test_queue_is_candidate_only(self) -> None:
        q = json.loads((ROOT / "data/visual/visual_production_queue_v1.json").read_text(encoding="utf-8"))
        self.assertFalse(q["shipping"])
        self.assertEqual(q["lotes"][0]["id"], "L01_identity_and_hub")
        self.assertEqual(len(q["lotes"][0]["files"]), 10)
        self.assertEqual(q["authorities"]["scene_combat"], "CombatManager")

    def test_sidecar_exists(self) -> None:
        data = json.loads((ROOT / "assets/sidecar.template.json").read_text(encoding="utf-8"))
        self.assertFalse(data["shipping"])
        self.assertFalse(data["bake_hud"])


if __name__ == "__main__":
    unittest.main()
