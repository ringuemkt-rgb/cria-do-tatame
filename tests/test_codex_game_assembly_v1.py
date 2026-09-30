import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools/production/build_codex_game_assembly_queue_v1.py"
SPEC = importlib.util.spec_from_file_location("codex_assembly", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class CodexGameAssemblyV1Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contract = MODULE.read_json(
            ROOT / "data/production/codex_game_assembly_v1.json"
        )
        cls.intake = MODULE.read_json(
            ROOT / cls.contract["visual_intake"]
        )

    def test_all_43_audited_assets_are_covered(self):
        errors = MODULE.validate_contract_and_intake(self.contract, self.intake)
        self.assertEqual([], errors)
        queue = MODULE.build_queue(self.contract, self.intake)
        self.assertEqual(43, queue["asset_count"])
        self.assertEqual(
            {item["asset_id"] for item in self.intake["assets"]},
            {item["asset_id"] for item in queue["tasks"]},
        )

    def test_blocked_and_hold_material_cannot_become_shipping(self):
        queue = MODULE.build_queue(self.contract, self.intake)
        for task in queue["tasks"]:
            self.assertFalse(task["shipping"])
            self.assertFalse(task["runtime_authority"])
            if task["category"] == "private_likeness":
                self.assertEqual("BLOCKED_PRIVATE", task["disposition"])
            if task["category"] == "map_expansion":
                self.assertEqual("HOLD_EXPANSION", task["disposition"])

    def test_preferred_identity_candidates_are_promotion_candidates(self):
        queue = MODULE.build_queue(self.contract, self.intake)
        by_id = {task["asset_id"]: task for task in queue["tasks"]}
        self.assertEqual(
            "PROMOTION_CANDIDATE",
            by_id["ruan_turnaround_v2_beard_pixel"]["disposition"],
        )
        self.assertEqual(
            "PROMOTION_CANDIDATE",
            by_id["davi_identity_action_sheet_v1"]["disposition"],
        )

    def test_wrong_ale_text_stays_rejected_reference(self):
        queue = MODULE.build_queue(self.contract, self.intake)
        by_id = {task["asset_id"]: task for task in queue["tasks"]}
        self.assertEqual(
            "REFERENCE_REJECTED",
            by_id["faction_banner_ale_light_v1"]["disposition"],
        )
        self.assertIn(
            "wrong_display_name",
            by_id["faction_banner_ale_light_v1"]["blocker"],
        )

    def test_archive_hash_gate_rejects_wrong_bytes(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = Path(tmp) / "cria_visual_master_pack_2026-09-29.zip"
            archive.write_bytes(b"not-the-real-archive")
            with self.assertRaises(ValueError):
                MODULE.verify_archive(self.contract, archive, True)

    def test_archive_may_be_absent_for_metadata_only_work(self):
        MODULE.verify_archive(self.contract, None, False)


if __name__ == "__main__":
    unittest.main()
