import importlib.util
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "data" / "validate_narrative_v4_candidate.py"

spec = importlib.util.spec_from_file_location("validate_narrative_v4_candidate", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


class NarrativeV4CandidateTests(unittest.TestCase):
    def load(self, name: str):
        return json.loads((ROOT / "data" / "narrative" / name).read_text(encoding="utf-8"))

    def test_validator_passes_candidate(self):
        self.assertEqual(module.validate(), [])

    def test_v3_remains_runtime_authority(self):
        canon = self.load("canon_v4.json")
        self.assertEqual(canon["status"], "CANON_CANDIDATE_NOT_RUNTIME_AUTHORITY")
        self.assertEqual(canon["current_runtime_authority"], "data/narrative/canon_v3.json")

    def test_act_ids_stay_stable(self):
        acts = self.load("acts_v4.json")
        self.assertEqual([a["id"] for a in acts["acts"]], module.EXPECTED_ACT_IDS)

    def test_truth_is_overlay_not_third_main_ending(self):
        endings = self.load("endings_v3.json")
        self.assertEqual(len(endings["main_endings"]), 2)
        self.assertFalse(endings["truth_overlay"]["main_ending"])
        self.assertEqual(endings["truth_overlay"]["required_fragments"], 8)

    def test_teruko_spoken_only_behind_truth_gate(self):
        dialogues = self.load("dialogues_v4.json")
        ungated = json.dumps(dialogues["prologue_dialogues"] + dialogues["act_dialogues"], ensure_ascii=False)
        self.assertNotIn("Teruko Nishiuchi", ungated)
        gated = dialogues["truth_dialogues"]
        self.assertTrue(any("Teruko Nishiuchi" in json.dumps(x, ensure_ascii=False) for x in gated))
        self.assertTrue(all(x.get("requires_truth_fragments", 0) >= 8 for x in gated))

    def test_chupeta_climax_encodes_restraint(self):
        acts = self.load("acts_v4.json")
        found = module._find_beat(acts, "ruan_vs_chupeta")
        self.assertIsNotNone(found)
        self.assertEqual(found[1]["finish_rule"], "release_submission_then_stabilize_control")

    def test_prologue_has_five_scenes_and_choice_not_fake_third_choice(self):
        prologue = self.load("prologue_v1.json")
        self.assertEqual(len(prologue["scenes"]), 5)
        choice = next(s for s in prologue["scenes"] if s["id"] == "c0_2_a_cobranca")
        self.assertEqual([c["id"] for c in choice["choices"]], ["resistir", "recuar"])
        self.assertEqual(choice["mandatory_exit"], "dende_intervem")


if __name__ == "__main__":
    unittest.main()
