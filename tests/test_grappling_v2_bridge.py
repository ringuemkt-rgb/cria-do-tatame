from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(rel: str) -> dict:
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


class GrapplingV2BridgeTests(unittest.TestCase):
    def test_bridge_does_not_replace_combat_manager(self) -> None:
        bridge = load("data/combat/grappling_v2_combat_manager_bridge_v1.json")
        self.assertEqual(bridge["authorities"]["scene"], "CombatManager")
        self.assertEqual(bridge["authorities"]["graph"], "BJJGraphReducerV2")
        self.assertFalse(bridge["shipping"])

    def test_baiana_deny_maps_to_sprawl(self) -> None:
        hints = load("data/combat/grappling_v2_combat_manager_bridge_v1.json")["slice_ouro_hints"]
        self.assertEqual(hints["baiana"]["deny_reaction"], "sprawl")

    def test_contract_lists_scene_authority(self) -> None:
        contract = load("data/combat/grappling_engine_v2_contract.json")
        self.assertEqual(
            contract["authorities"]["scene_authority"],
            "src/autoloads/CombatManager.gd",
        )
        self.assertFalse(contract["authority_firewall"]["motion_clip_may_change_outcome"])

    def test_bridge_script_is_refcounted(self) -> None:
        text = (ROOT / "src/combat/GrapplingV2CombatBridge.gd").read_text(encoding="utf-8")
        self.assertIn("extends RefCounted", text)
        self.assertNotIn("extends Node", text)


if __name__ == "__main__":
    unittest.main()
