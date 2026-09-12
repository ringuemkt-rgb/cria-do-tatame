from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "tools/ai/validate_local_ai_nex_v1.py"
PROFILE = ROOT / "data/ai/nex_n25_dialogue_profile_v1.json"
CONFIG = ROOT / "data/ai/local_ai_config_v01.json"


class LocalAINexContractTests(unittest.TestCase):
    def test_validator_passes(self) -> None:
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_nex_is_optional_and_bounded(self) -> None:
        profile = json.loads(PROFILE.read_text(encoding="utf-8"))
        config = json.loads(CONFIG.read_text(encoding="utf-8"))
        backend = config["backends"]["nex_n25_ollama"]

        self.assertFalse(profile["shipping"])
        self.assertFalse(profile["runtime_authority"])
        self.assertFalse(profile["critical_gameplay_dependency"])
        self.assertTrue(backend["supports_tools"])
        self.assertLessEqual(backend["max_tool_rounds"], 4)
        self.assertLessEqual(backend["num_ctx"], 32768)

    def test_tool_allowlist_is_read_only_slice(self) -> None:
        profile = json.loads(PROFILE.read_text(encoding="utf-8"))
        self.assertEqual(
            profile["integration"]["allowed_tools"],
            ["canon_lookup", "scene_state_get", "progression_summary_get"],
        )
        self.assertFalse(profile["integration"]["state_mutation_by_model"])
        self.assertFalse(profile["integration"]["combat_use"])


if __name__ == "__main__":
    unittest.main()
