import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CI = ROOT / "tools/ci"
sys.path.insert(0, str(CI))

from derive_production_manifest_v03 import CONTRACT_PATH, Derivator, canonical_json, load_json  # noqa: E402


class ProductionOSV03Tests(unittest.TestCase):
    def derive(self):
        return Derivator(ROOT, load_json(CONTRACT_PATH)).run()

    def test_derivation_is_deterministic(self):
        a = self.derive()
        b = self.derive()
        self.assertEqual(canonical_json(a), canonical_json(b))
        self.assertEqual(a["derivation_sha256"], b["derivation_sha256"])

    def test_current_sources_are_reported_truthfully(self):
        out = self.derive()
        self.assertEqual(out["source_snapshot"]["p1_commands"], 32)
        self.assertEqual(out["source_snapshot"]["roster_fighters"], 17)
        self.assertEqual(out["source_snapshot"]["world_locations"], 40)
        codes = {b["code"] for b in out["source_blockers"]}
        self.assertIn("full_bjj_kg_missing", codes)
        self.assertIn("cards_source_missing", codes)
        self.assertIn("missions_source_missing", codes)

    def test_fixture_legality_edge_never_enters_production_requirements(self):
        out = self.derive()
        source_ids = {r["source_id"] for r in out["requirements"]}
        self.assertNotIn("slice_heel_hook", source_ids)

    def test_derivation_never_approves_or_ships(self):
        out = self.derive()
        self.assertGreater(out["counts"]["total"], 100)
        for req in out["requirements"]:
            self.assertEqual(req["status"], "pending")
            self.assertFalse(req["shipping"])

    def test_game_build_matrix_covers_all_nine_domains(self):
        matrix = load_json(ROOT / "data/production/game_build_matrix_v1.json")
        ids = [row["id"] for row in matrix["domains"]]
        self.assertEqual(ids, [
            "G0_production_os",
            "G1_gold_vertical_slice",
            "G2_characters",
            "G3_bjj_content",
            "G4_world",
            "G5_narrative",
            "G6_progression_economy",
            "G7_audio",
            "G8_qa_release",
        ])
        self.assertTrue(matrix["completion_claim_policy"]["android_release_requires_physical_device_evidence"])

    def test_coverage_normal_reports_but_shipping_fails_closed(self):
        script = ROOT / "tools/ci/validate_production_coverage_v03.py"
        with tempfile.TemporaryDirectory() as td:
            report = Path(td) / "coverage.json"
            normal = subprocess.run([sys.executable, str(script), "--report", str(report)], cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(normal.returncode, 0, normal.stdout + normal.stderr)
            payload = json.loads(report.read_text(encoding="utf-8"))
            self.assertFalse(payload["shipping_ready"])
            self.assertEqual(payload["coverage_percent"]["shipping"], 0.0)

            shipping = subprocess.run([sys.executable, str(script), "--shipping", "--report", str(report)], cwd=ROOT, capture_output=True, text=True)
            self.assertNotEqual(shipping.returncode, 0)


if __name__ == "__main__":
    unittest.main()
