from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "data/production/agent_production_contract_v1.json"
VALIDATOR = ROOT / "tools/ci/validate_agent_production_os_v1.py"
DETECTOR = ROOT / "tools/agents/detect_capabilities.py"


class AgentProductionOSV1Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))

    def test_contract_is_not_shipping_authority(self) -> None:
        self.assertEqual(self.contract["status"], "ACTIVE_ORCHESTRATION_CONTRACT")
        self.assertFalse(self.contract["authority"]["shipping_authority"])
        self.assertEqual(self.contract["authority"]["runtime"], "Godot")

    def test_tiers_are_capability_based_and_complete(self) -> None:
        ids = [row["id"] for row in self.contract["execution_tiers"]]
        self.assertEqual(
            ids,
            [
                "T0_OBSERVER",
                "T1_AUTHOR",
                "T2_ASSET_AUTHOR",
                "T3_RUNTIME_INTEGRATOR",
                "T4_MOTION_PRODUCER",
                "T5_RELEASE_OPERATOR",
            ],
        )
        capabilities = {row["id"] for row in self.contract["capabilities"]}
        for tier in self.contract["execution_tiers"]:
            for req in tier.get("requires_all", []):
                self.assertIn(req, capabilities)
            for group in tier.get("requires_any", []):
                for req in group:
                    self.assertIn(req, capabilities)

    def test_domain_routes_exist(self) -> None:
        for route in self.contract["domain_routes"].values():
            self.assertTrue((ROOT / route["skill"]).is_file(), route["skill"])
            for rel in route["authorities"]:
                self.assertTrue((ROOT / rel.rstrip("/")).exists(), rel)

    def test_vertical_workflows_exist(self) -> None:
        for rel in self.contract["workflow_files"]:
            self.assertTrue((ROOT / rel).is_file(), rel)

    def test_validator_passes(self) -> None:
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(json.loads(result.stdout)["ok"])

    def test_detector_never_needs_secrets_and_reports_tier(self) -> None:
        result = subprocess.run(
            [sys.executable, str(DETECTOR), "--declare", "github_remote,web_research"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        report = json.loads(result.stdout)
        self.assertTrue(report["ok"])
        self.assertIn("active_capabilities", report)
        self.assertIn("highest_safe_tier", report)
        serialized = json.dumps(report).lower()
        self.assertNotIn("api_key", serialized)
        self.assertNotIn("token_value", serialized)

    def test_detector_rejects_unknown_capability(self) -> None:
        result = subprocess.run(
            [sys.executable, str(DETECTOR), "--declare", "imaginary_superpower"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        report = json.loads(result.stdout)
        self.assertEqual(report["error"], "unknown_capability")


if __name__ == "__main__":
    unittest.main()
