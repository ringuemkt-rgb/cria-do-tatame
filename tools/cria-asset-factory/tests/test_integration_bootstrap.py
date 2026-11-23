"""No network, GPU, model downloads, or persistent local filesystem changes."""
from __future__ import annotations
import importlib.util
import json
import tempfile
import sys
import unittest
from pathlib import Path

FACTORY = Path(__file__).resolve().parents[1]
# Standalone scripts intentionally support imports from their script directory.
if str(FACTORY / "scripts") not in sys.path:
    sys.path.insert(0, str(FACTORY / "scripts"))


def load(name: str):
    path = FACTORY / "scripts" / f"{name}.py"
    spec = importlib.util.spec_from_file_location("cria_test_" + name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class IntegrationBootstrapTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.bootstrap = load("bootstrap")
        cls.jobs = load("prepare_candidate_job")
        cls.comfy = load("comfyui_adapter")

    def test_registry_and_profile_agree(self):
        manifest = self.bootstrap.load_config()
        self.assertFalse(manifest["shipping"])
        self.assertEqual(manifest["status"], "CANDIDATE_AUTHORING_ONLY")

    def test_doctor_is_read_only(self):
        before = self.bootstrap.ENV.exists()
        result = self.bootstrap.check()
        self.assertFalse(result["shipping"])
        self.assertEqual(result["gpu_jobs"], "NOT_STARTED")
        self.assertEqual(result["godot_runtime_modified"], False)
        self.assertEqual(before, self.bootstrap.ENV.exists())

    def test_prepare_job_is_canonical_and_pending(self):
        result = self.jobs.make_job(
            "baiana", "ruan_macacao", "gi_white", "anticipation", "character_combat_pose_concept",
        )
        self.assertEqual((result["entry_state"], result["exit_state"]),
                         ("PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_GUARD"))
        self.assertEqual(result["target_frame"], [128, 128])
        self.assertEqual(result["pivot"], [64, 96])
        self.assertFalse(result["shipping"])
        self.assertEqual(result["qa_status"], "pending")
        self.assertEqual(result["output_status"], "NOT_GENERATED")
        self.assertIn("Qwen-Image-2512", result["model_id"])

    def test_unknown_id_fails_closed(self):
        with self.assertRaises(ValueError):
            self.jobs.make_job("hypothetical_sweep", "ruan_macacao", "gi_white",
                               "anticipation", "character_combat_pose_concept")

    def test_reference_must_exist(self):
        with self.assertRaises(FileNotFoundError):
            self.jobs.make_job("baiana", "ruan_macacao", "gi_white", "entry",
                               "character_combat_pose_concept", Path("/__missing_reference__.png"))

    def test_job_write_is_create_only(self):
        result = self.jobs.make_job("baiana", "ruan_macacao", "nogi", "entry",
                                    "character_combat_pose_concept")
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp) / "job.json"
            self.jobs.save_job(dest, result)
            self.assertFalse(json.loads(dest.read_text())["shipping"])
            with self.assertRaises(FileExistsError):
                self.jobs.save_job(dest, result)

    def test_comfy_rejects_remote_and_redirect_paths(self):
        for host in ("https://localhost:8188", "http://example.com:8188",
                     "http://127.0.0.1:8188/foo", "http://127.0.0.1",
                     "http://127.0.0.1:8188@evil.com:8188"):
            with self.subTest(host=host), self.assertRaises(ValueError):
                self.comfy.validate_local_url(host)

    def test_comfy_dry_run_payload(self):
        job = self.jobs.make_job("baiana", "ruan_macacao", "gi_white", "anticipation",
                                 "character_combat_pose_concept")
        workflow = {"6": {"class_type": "CLIPTextEncode", "inputs": {"text": "placeholder", "clip": ["4", 1]}},
                    "7": {"class_type": "KSampler", "inputs": {"seed": 1}}}
        payload = self.comfy.build_payload(job, workflow, "6")
        self.assertFalse(payload["extra_data"]["extra_pnginfo"]["cria_candidate"]["shipping"])
        self.assertEqual(payload["prompt"]["6"]["inputs"]["text"], job["prompt"])
        self.assertEqual(workflow["6"]["inputs"]["text"], "placeholder")

    def test_comfy_unapproved_reference_fails_closed(self):
        job = self.jobs.make_job("baiana", "ruan_macacao", "gi_white", "entry",
                                 "character_combat_pose_concept")
        job["reference_path"] = "/tmp/image.png"
        with self.assertRaises(ValueError):
            self.comfy.build_payload(
                job, {"6": {"class_type": "CLIPTextEncode", "inputs": {"text": ""}}}, "6"
            )


if __name__ == "__main__":
    unittest.main()
