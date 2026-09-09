import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "tools/combat/validate_combat_intelligence_v1.py"

spec = importlib.util.spec_from_file_location("combat_intelligence_validator", VALIDATOR)
module = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(module)


def load(path: str):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


class CombatIntelligenceV1Tests(unittest.TestCase):
    def test_full_validator_passes(self):
        result = module.validate()
        self.assertTrue(result["ok"], result["errors"])

    def test_bjj_target_is_not_weakened(self):
        completion = load("data/combat/bjj_completion_gate_v1.json")
        self.assertEqual(completion["minimum_targets"], {"positions": 40, "techniques": 120, "chains": 10})

    def test_ml_cannot_define_rules_or_score(self):
        contract = load("data/combat/combat_intelligence_contract_v1.json")
        authority = contract["authority"]
        self.assertFalse(authority["video_or_ml_may_define_legality"])
        self.assertFalse(authority["video_or_ml_may_define_scoring"])
        self.assertFalse(authority["llm_may_run_inner_combat_loop"])
        self.assertEqual(authority["runtime_state_authority"], "src/combat/BJJGraphReducerV2.gd")

    def test_video_corpus_is_rights_blocked_by_default(self):
        corpus = load("data/research/grappling_video_corpus_contract_v1.json")
        rights = corpus["rights_policy"]
        self.assertEqual(rights["default_status"], "BLOCKED_UNTIL_RIGHTS_CLASSIFIED")
        self.assertTrue(rights["public_url_is_not_permission"])
        self.assertFalse(rights["broadcast_or_instructional_video_may_be_used_automatically_for_commercial_training"])
        self.assertEqual(rights["preferred_corpus"], "CRIA_OWN_CAPTURE_WITH_RELEASES")

    def test_vicos_never_becomes_commercial_training_source_by_default(self):
        corpus = load("data/research/grappling_video_corpus_contract_v1.json")
        benchmarks = {x["id"]: x for x in corpus["external_benchmarks"]}
        self.assertEqual(benchmarks["vicos_bjj_positions"]["license_status"], "CC_BY_NC_SA_4_0_NONCOMMERCIAL")
        self.assertFalse(benchmarks["vicos_bjj_positions"]["commercial_training_default"])

    def test_observation_schema_preserves_uncertainty(self):
        schema = load("assets/schemas/grappling_observation_v1.schema.json")
        status = schema["properties"]["review"]["properties"]["status"]["enum"]
        self.assertIn("UNCERTAIN", status)
        self.assertIn("confidence", schema["required"])

    def test_engine_upgrade_is_separate_and_replay_safe(self):
        plan = load("data/production/godot_migration_plan_v1.json")
        self.assertEqual(plan["target_engine"], "4.7.2-stable")
        self.assertEqual(plan["status"], "PLANNED_SEPARATE_BRANCH")
        self.assertTrue(plan["success_policy"]["deterministic_bjj_replays_must_match"])


if __name__ == "__main__":
    unittest.main()
