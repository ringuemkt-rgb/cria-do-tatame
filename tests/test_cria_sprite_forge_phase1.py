from __future__ import annotations

import json
import pathlib
import sys
import tempfile
import unittest

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools" / "art"
sys.path.insert(0, str(TOOLS))

import cria_canon_adapter as adapter  # noqa: E402
import identity_lock  # noqa: E402
import validate_sprite_forge_phase1 as phase1  # noqa: E402


class SpriteForgePhase1Tests(unittest.TestCase):
    def test_every_canonical_character_action_has_a_qa_profile(self):
        profiles = json.loads(
            (ROOT / "data/visual/sprite_qa_profiles_v1.json").read_text(encoding="utf-8")
        )["action_profile_registry"]

        missing = []
        for path in sorted((ROOT / "data/chars/canon").glob("*.json")):
            character = json.loads(path.read_text(encoding="utf-8"))
            for action_set in character.get("action_sets", {}).values():
                if not isinstance(action_set, list):
                    continue
                for action in action_set:
                    if isinstance(action, str) and action not in profiles:
                        missing.append(f"{character['character_id']}:{action}")

        self.assertEqual(missing, [])

    def test_profiles_are_14_automatic_plus_2_authority(self) -> None:
        data = json.loads((ROOT / "data/visual/sprite_qa_profiles_v1.json").read_text(encoding="utf-8"))
        self.assertEqual(phase1.validate_profiles(data), [])
        self.assertEqual(len(data["gate_classes"]["technical_automatic"]), 14)
        self.assertEqual(set(data["gate_classes"]["authority"]), {"human_approval", "rights_status"})

    def test_ruan_adapter_preserves_gameplay_authority_boundary(self) -> None:
        spec = adapter.compile_spec(ROOT, "ruan_macacao", ["idle", "baiana_entry", "jab"])
        jobs = {item["action"]: item for item in spec["jobs"]}
        self.assertEqual(jobs["idle"]["authority_status"], "canonical_visual_action")
        self.assertEqual(jobs["baiana_entry"]["authority_status"], "canonical_visual_action")
        self.assertIs(jobs["jab"]["gameplay_authority"], False)
        self.assertEqual(jobs["jab"]["authority_status"], "tooling_capability")
        self.assertFalse(spec["shipping"])

    def test_ruan_identity_lock_is_honestly_pending(self) -> None:
        state = identity_lock.reference_status(ROOT, "ruan_macacao")
        self.assertEqual(state["reference_status"], "pending_ingestion_and_human_approval")
        self.assertFalse(state["lock_ready"])

    def test_identity_lock_hash_detects_reference_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            ref = root / "assets/chars/ref/test.png"
            ref.parent.mkdir(parents=True)
            image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
            image.paste((10, 20, 30, 255), (2, 2, 14, 14))
            image.save(ref)
            lock_path = ref.with_suffix(".identity_lock.json")
            lock = {
                "$schema": "cria.identity_lock.v1",
                "version": "1.0.0",
                "character_id": "test",
                "reference": "assets/chars/ref/test.png",
                "reference_sha256": identity_lock.sha256_file(ref),
                "reference_size": [16, 16],
                "reference_mode": "RGBA",
                "regions": [
                    {
                        "id": "face",
                        "required": True,
                        "bbox": [2, 2, 8, 8],
                        "sha256_rgba": identity_lock._region_hash(image, [2, 2, 8, 8]),
                    }
                ],
                "identity_match_authority": "supporting_evidence_only",
                "human_reference_approval_required": True,
                "shipping": False,
            }
            lock_path.write_text(json.dumps(lock), encoding="utf-8")
            self.assertEqual(identity_lock.verify_lock(root, lock_path), [])
            changed = Image.new("RGBA", (16, 16), (99, 20, 30, 255))
            changed.save(ref)
            self.assertIn("reference_sha256 mismatch", identity_lock.verify_lock(root, lock_path))


if __name__ == "__main__":
    unittest.main()
