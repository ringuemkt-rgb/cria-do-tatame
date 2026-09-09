import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "data/production/external_tool_registry_v1.json"
VALIDATOR = ROOT / "tools/ci/validate_external_tool_registry_v1.py"


class ExternalToolRegistryV1Tests(unittest.TestCase):
    def setUp(self):
        self.registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
        self.sources = {row["id"]: row for row in self.registry["sources"]}

    def test_validator_passes(self):
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(json.loads(result.stdout)["ok"])

    def test_only_clear_source_allows_direct_code_reuse(self):
        direct = [row for row in self.registry["sources"] if row["direct_code_reuse"]]
        self.assertEqual([row["id"] for row in direct], ["claude_code_game_studios"])
        self.assertEqual(direct[0]["license_status"], "CLEAR_MIT")

    def test_noncommercial_and_unknown_sources_are_no_copy(self):
        for sid in (
            "sprite_animator",
            "blendi_sprite_sheet_creator",
            "cline_qwen_snes_engine",
            "pixel_life_simulator",
            "mia_deepseek_v4_1_html_100",
            "mia_gpt6_astra_html_100",
        ):
            self.assertFalse(self.sources[sid]["direct_code_reuse"], sid)
            self.assertFalse(self.sources[sid]["direct_asset_reuse"], sid)

    def test_blendi_sprite_creator_is_pinned_reference_only(self):
        source = self.sources["blendi_sprite_sheet_creator"]
        self.assertEqual(source["revision"], "4e0eeb413fc0ee1b3650957f47eb187dd4bdbf2d")
        self.assertEqual(source["license_status"], "NO_LICENSE_FOUND")
        self.assertEqual(source["adoption"], "STUDY_AND_REIMPLEMENT_CONCEPTS_ONLY")

    def test_pixelsrpg_assets_never_enter_directly(self):
        source = self.sources["pixelsrpg_forge"]
        self.assertFalse(source["direct_asset_reuse"])
        self.assertEqual(source["adoption"], "TAXONOMY_AND_TOOL_REFERENCE_ONLY")

    def test_wolfcha_license_discrepancy_remains_explicit(self):
        source = self.sources["wolfcha"]
        self.assertEqual(source["license_status"], "CONFLICT_README_MIT_LICENSE_FILE_APACHE_2_0")
        self.assertFalse(source["direct_code_reuse"])
        self.assertEqual(source["adoption"], "REIMPLEMENT_CONCEPTS_PENDING_LICENSE_REVIEW")

    def test_deactivated_old_repo_has_no_role(self):
        source = self.sources["old_cria_android_repo"]
        self.assertEqual(source["adoption"], "BLOCKED_DEACTIVATED")
        self.assertEqual(source["cria_roles"], [])


if __name__ == "__main__":
    unittest.main()
