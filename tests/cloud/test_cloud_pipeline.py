from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.ai_asset_pipeline.cloud.drive_client import (
    DrivePipelineError,
    _escape_drive_query,
    _validate_logical_path,
    sha256_file,
)
from tools.ai_asset_pipeline.cloud.prepare_batch import BatchError, prepare_batch, read_jsonl


class DriveHelpersTest(unittest.TestCase):
    def test_drive_query_escape(self) -> None:
        self.assertEqual(_escape_drive_query("Ruan's\\batch"), "Ruan\\'s\\\\batch")

    def test_logical_path_rejects_traversal(self) -> None:
        for value in ("/assets/candidatos", "assets/../aprovados", "../assets"):
            with self.subTest(value=value), self.assertRaises(DrivePipelineError):
                _validate_logical_path(value)

    def test_sha256_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "value.bin"
            path.write_bytes(b"cria-do-tatame")
            self.assertEqual(sha256_file(path), hashlib.sha256(path.read_bytes()).hexdigest())


class DeterministicBatchTest(unittest.TestCase):
    def _task(self, task_id: str, target: str) -> dict[str, object]:
        return {
            "task_id": task_id,
            "kind": "paired_technique_animation",
            "target": target,
            "output_dir": f"assets/graphics/techniques/{target}",
            "status": "todo",
            "required_outputs": ["attacker", "defender", "sync_map.json"],
        }

    def test_batch_is_byte_for_byte_reproducible(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            queue = root / "queue.jsonl"
            queue.write_text(
                "\n".join(
                    json.dumps(task, sort_keys=True)
                    for task in [
                        self._task("technique::triangle", "triangle"),
                        self._task("technique::baiana_single_leg", "baiana_single_leg"),
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            registry = root / "registry.json"
            registry.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "models": [
                            {
                                "id": "example/model",
                                "resolved_revision": "a" * 40,
                                "license": "apache-2.0",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            receipt_a = prepare_batch(
                queue,
                registry,
                root / "a",
                {"paired_technique_animation"},
                {"baiana_single_leg"},
                1,
                "b" * 40,
            )
            receipt_b = prepare_batch(
                queue,
                registry,
                root / "b",
                {"paired_technique_animation"},
                {"baiana_single_leg"},
                1,
                "b" * 40,
            )
            self.assertEqual(receipt_a["batch_id"], receipt_b["batch_id"])
            self.assertEqual(receipt_a["bundle_sha256"], receipt_b["bundle_sha256"])
            bundle = Path(str(receipt_a["bundle"]))
            with zipfile.ZipFile(bundle) as archive:
                self.assertEqual(
                    set(archive.namelist()),
                    {"SHA256SUMS", "batch.json", "model_registry.json", "tasks.jsonl"},
                )
                metadata = json.loads(archive.read("batch.json"))
                self.assertTrue(all(info.compress_type == zipfile.ZIP_STORED for info in archive.infolist()))
                self.assertTrue(metadata["human_approval_required"])
                self.assertTrue(metadata["automatic_promotion_forbidden"])
                self.assertEqual(metadata["identity"]["task_ids"], ["technique::baiana_single_leg"])

    def test_unsafe_queue_output_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            queue = Path(directory) / "queue.jsonl"
            task = self._task("technique::bad", "bad")
            task["output_dir"] = "../shipping"
            queue.write_text(json.dumps(task) + "\n", encoding="utf-8")
            with self.assertRaises(BatchError):
                read_jsonl(queue)


if __name__ == "__main__":
    unittest.main()
