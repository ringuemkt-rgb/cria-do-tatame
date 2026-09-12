from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "tools/research/validate_public_video_intelligence_v1.py"
PLANNER = ROOT / "tools/research/plan_public_video_research_v1.py"
YOUTUBE = ROOT / "tools/research/youtube_public_discovery_v1.py"
REPORTER = ROOT / "tools/research/report_public_video_project_status_v1.py"
DIRECTOR = ROOT / "data/research/public_video_analysis_director_v1.json"


class PublicVideoIntelligenceV1Tests(unittest.TestCase):
    def test_validator_passes(self) -> None:
        proc = subprocess.run([sys.executable, str(VALIDATOR)], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        report = json.loads(proc.stdout)
        self.assertTrue(report["ok"])
        self.assertEqual(report["cycle_stages"], 14)
        self.assertEqual(report["youtube_adapter"], "OFFICIAL_METADATA_ONLY")
        self.assertTrue(report["project_status_reporter"])
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
        by_id = {row["technique_id"]: row for row in report["next_targets"]}
        for expected in ("t001", "slice_sprawl", "t025", "t049", "slice_side_to_mount", "t057", "t005"):
            self.assertIn(expected, by_id)
        self.assertEqual(by_id["t001"]["name_pt"], "Baiana Double-Leg")
        self.assertEqual(by_id["t025"]["name_pt"], "Body-Lock Pass")
        self.assertTrue(any("Baiana Double-Leg" in q for q in by_id["t001"]["queries"]))
        self.assertTrue(any("Body-Lock Pass" in q for q in by_id["t025"]["queries"]))
        for row in report["next_targets"]:
            self.assertGreaterEqual(len(row["queries"]), 3)

    def test_youtube_adapter_dry_run_is_metadata_only(self) -> None:
        proc = subprocess.run(
            [sys.executable, str(YOUTUBE), "--query", "BJJ side control mount competition", "--max-results", "3", "--dry-run"],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        report = json.loads(proc.stdout)
        self.assertTrue(report["ok"])
        self.assertEqual(report["mode"], "DRY_RUN_OFFICIAL_API_ONLY")
        self.assertFalse(report["downloads_media"])
        self.assertFalse(report["downloads_captions"])
        self.assertFalse(report["visual_observation_claimed"])
        request = report["search_requests"][0]
        self.assertEqual(request["type"], "video")
        self.assertEqual(request["videoEmbeddable"], "true")

    def test_status_report_is_project_facing_and_autonomous(self) -> None:
        proc = subprocess.run(
            [sys.executable, str(REPORTER), "--next", "5", "--json"],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        report = json.loads(proc.stdout)
        self.assertTrue(report["ok"])
        self.assertEqual(report["project_assessment"], "INFRASTRUCTURE_READY_EVIDENCE_COLLECTION_NOT_STARTED")
        self.assertFalse(report["user_action_required_now"])
        self.assertEqual(report["motion_factory"]["units_total"], 7)
        self.assertEqual(report["motion_factory"]["capture_pending"], 7)
        names = {row["name"] for row in report["next_autonomous_targets"]}
        self.assertIn("Baiana Double-Leg", names)
        self.assertGreaterEqual(len(report["true_blockers"]), 1)


if __name__ == "__main__":
    unittest.main()
