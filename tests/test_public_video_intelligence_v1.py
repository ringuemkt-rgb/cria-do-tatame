from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "tools/research/validate_public_video_intelligence_v1.py"
PLANNER = ROOT / "tools/research/plan_public_video_research_v1.py"
DIRECTOR = ROOT / "data/research/public_video_analysis_director_v1.json"


class PublicVideoIntelligenceV1Tests(unittest.TestCase):
    def test_validator_passes(self) -> None:
        proc = subprocess.run([sys.executable, str(VALIDATOR)], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        report = json.loads(proc.stdout)
        self.assertTrue(report["ok"])
        self.assertEqual(report["cycle_stages"], 14)
        self.assertFalse(report["shipping"])

    def test_director_is_fail_closed(self) -> None:
        director = json.loads(DIRECTOR.read_text(encoding="utf-8"))
        platform = director["platform_policy"]
        self.assertFalse(platform["youtube_public_url_is_permission"])
        self.assertFalse(platform["automated_scraping_or_download_default"])
        self.assertFalse(platform["third_party_caption_download_via_youtube_data_api_default"])
        self.assertTrue(platform["caption_download_requires_video_edit_permission"])
        self.assertTrue(director["fail_closed"]["metadata_never_implies_visual_observation"])
        self.assertTrue(director["fail_closed"]["source_failure_auto_selects_next_candidate"])
        self.assertTrue(director["fail_closed"]["user_not_required_to_select_next_query"])

    def test_planner_generates_autonomous_targets(self) -> None:
        proc = subprocess.run(
            [sys.executable, str(PLANNER), "--limit", "50", "--json"],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        report = json.loads(proc.stdout)
        self.assertTrue(report["ok"])
        self.assertFalse(report["user_selection_required"])
        ids = {row["technique_id"] for row in report["next_targets"]}
        for expected in ("t001", "slice_sprawl", "t025", "t049", "slice_side_to_mount", "t057", "t005"):
            self.assertIn(expected, ids)
        for row in report["next_targets"]:
            self.assertGreaterEqual(len(row["queries"]), 3)


if __name__ == "__main__":
    unittest.main()
