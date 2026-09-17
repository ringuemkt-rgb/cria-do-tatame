import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools" / "agents" / "prime_agent_adapter.py"
spec = importlib.util.spec_from_file_location("prime_agent_adapter", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec and spec.loader
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class PrimeAgentAdapterTests(unittest.TestCase):
    def test_build_command_is_bounded_json_mode(self):
        cmd = module.build_command("fix one bug", ["npm run quality"])
        joined = " ".join(cmd)
        self.assertIn("--mode json", joined)
        self.assertIn("--offline", cmd)
        self.assertIn("--autonomous", cmd)
        self.assertIn("npm run quality", cmd)
        self.assertIn("--autonomous-max-turns", cmd)
        self.assertNotIn("--api-key", cmd)

    def test_detects_git_push(self):
        event = {"type": "tool_execution_start", "args": {"code": "git push origin candidate"}}
        self.assertEqual(module.event_violation(event), "git_push")

    def test_detects_approved_asset_write(self):
        event = {"type": "tool_execution_start", "args": {"path": "assets/aprovados/x.png"}}
        self.assertEqual(module.event_violation(event), "approved_assets")

    def test_detects_main_switch(self):
        event = {"type": "tool_execution_start", "args": {"code": "git switch main"}}
        self.assertEqual(module.event_violation(event), "switch_main")

    def test_quality_command_is_not_violation(self):
        event = {"type": "tool_execution_start", "args": {"code": "npm run quality"}}
        self.assertIsNone(module.event_violation(event))

    def test_summary_tracks_agent_end_and_tool_errors(self):
        events = [
            {"type": "agent_start"},
            {"type": "tool_execution_end", "isError": True},
            {"type": "agent_end", "messages": []},
        ]
        summary = module.summarize_events(events)
        self.assertTrue(summary["agent_end_seen"])
        self.assertEqual(summary["tool_errors"], 1)
        self.assertEqual(summary["event_counts"]["agent_end"], 1)


if __name__ == "__main__":
    unittest.main()
