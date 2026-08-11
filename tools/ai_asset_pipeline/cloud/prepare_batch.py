#!/usr/bin/env python3
"""Build a deterministic candidate job bundle from the canonical JSONL queue.

This command packages specifications and provenance. It does not claim to have
rendered assets and it cannot promote a candidate to the approved Drive folder.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[3]
DEFAULT_QUEUE = (
    ROOT
    / "tools"
    / "ai_asset_pipeline"
    / "generated_queue"
    / "production_queue_v02.jsonl"
)
DEFAULT_REGISTRY = ROOT / "data" / "ai" / "model_registry_v02.json"
FIXED_ZIP_TIMESTAMP = (2020, 1, 1, 0, 0, 0)


class BatchError(RuntimeError):
    """Raised when a production queue cannot produce a safe batch."""


def canonical_json(value: Any) -> str:
    """Serialize JSON deterministically for hashing and bundle contents."""

    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def sha256_bytes(value: bytes) -> str:
    """Return a hexadecimal SHA-256 digest."""

    return hashlib.sha256(value).hexdigest()


def read_json(path: Path) -> dict[str, Any]:
    """Read a top-level JSON object."""

    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise BatchError(f"JSON root must be an object: {path}")
    return value


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    """Read and validate a JSONL production queue."""

    if not path.is_file():
        raise BatchError(f"Queue not found: {path}")
    tasks: list[dict[str, Any]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        try:
            value = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise BatchError(f"Invalid JSONL at {path}:{line_number}: {exc}") from exc
        if not isinstance(value, dict):
            raise BatchError(f"Task at {path}:{line_number} is not an object")
        validate_task(value, line_number)
        tasks.append(value)
    if not tasks:
        raise BatchError(f"Queue is empty: {path}")
    task_ids = [str(task["task_id"]) for task in tasks]
    if len(task_ids) != len(set(task_ids)):
        raise BatchError("Queue contains duplicate task_id values")
    return tasks


def validate_task(task: dict[str, Any], line_number: int) -> None:
    """Reject missing IDs, unsafe outputs and already-promoted queue rows."""

    for key in ("task_id", "kind", "target", "output_dir", "status"):
        if not isinstance(task.get(key), str) or not task[key].strip():
            raise BatchError(f"Task on line {line_number} has invalid {key!r}")
    output = PurePosixPath(task["output_dir"])
    if (
        output.is_absolute()
        or not output.parts
        or output.parts[0] != "assets"
        or any(part in {"", ".", ".."} for part in output.parts)
    ):
        raise BatchError(
            f"Task {task['task_id']} has unsafe output_dir: {task['output_dir']}"
        )
    if task["status"] not in {"todo", "retry"}:
        raise BatchError(
            f"Task {task['task_id']} cannot enter a new batch from status {task['status']!r}"
        )


def resolve_source_commit() -> str:
    """Resolve the Git commit without failing outside a checkout."""

    explicit = os.environ.get("GIT_COMMIT_SHA", "").strip()
    if explicit:
        return explicit
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else "unresolved"


def select_tasks(
    tasks: list[dict[str, Any]],
    kinds: set[str],
    targets: set[str],
    limit: int,
) -> list[dict[str, Any]]:
    """Select a stable subset in task_id order."""

    if limit < 1 or limit > 100:
        raise BatchError("--limit must be between 1 and 100")
    selected = [
        task
        for task in tasks
        if (not kinds or task["kind"] in kinds)
        and (not targets or task["target"] in targets)
    ]
    selected.sort(key=lambda item: item["task_id"])
    selected = selected[:limit]
    if not selected:
        raise BatchError("No queue tasks matched the requested filters")
    return selected


def _zip_info(name: str) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, date_time=FIXED_ZIP_TIMESTAMP)
    info.compress_type = zipfile.ZIP_STORED
    info.external_attr = 0o100644 << 16
    return info


def write_deterministic_zip(path: Path, files: dict[str, bytes]) -> None:
    """Write a stable ZIP and atomically move it into place."""

    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    os.close(fd)
    temporary = Path(temporary_name)
    try:
        with zipfile.ZipFile(temporary, "w") as archive:
            for name in sorted(files):
                archive.writestr(_zip_info(name), files[name])
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def prepare_batch(
    queue: Path,
    registry: Path,
    output_dir: Path,
    kinds: set[str],
    targets: set[str],
    limit: int,
    source_commit: str,
) -> dict[str, Any]:
    """Create a deterministic bundle and return its portable receipt."""

    tasks = select_tasks(read_jsonl(queue), kinds, targets, limit)
    model_registry = read_json(registry)
    registry_bytes = (json.dumps(model_registry, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()
    task_bytes = ("\n".join(canonical_json(task) for task in tasks) + "\n").encode()
    identity = {
        "queue_sha256": sha256_bytes(queue.read_bytes()),
        "model_registry_sha256": sha256_bytes(registry_bytes),
        "source_commit": source_commit,
        "task_ids": [task["task_id"] for task in tasks],
    }
    batch_id = sha256_bytes(canonical_json(identity).encode())[:20]
    metadata = {
        "schema_version": 1,
        "batch_id": batch_id,
        "state": "prepared_for_candidate_generation",
        "task_count": len(tasks),
        "identity": identity,
        "human_approval_required": True,
        "automatic_promotion_forbidden": True,
        "destination": "assets/candidatos",
    }
    metadata_bytes = (json.dumps(metadata, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()
    checksums = {
        "batch.json": sha256_bytes(metadata_bytes),
        "model_registry.json": sha256_bytes(registry_bytes),
        "tasks.jsonl": sha256_bytes(task_bytes),
    }
    checksum_bytes = "".join(
        f"{digest}  {name}\n" for name, digest in sorted(checksums.items())
    ).encode()
    output = output_dir / f"candidate_batch_{batch_id}.zip"
    write_deterministic_zip(
        output,
        {
            "SHA256SUMS": checksum_bytes,
            "batch.json": metadata_bytes,
            "model_registry.json": registry_bytes,
            "tasks.jsonl": task_bytes,
        },
    )
    return {
        "ok": True,
        "batch_id": batch_id,
        "bundle": str(output),
        "bundle_sha256": sha256_bytes(output.read_bytes()),
        "task_count": len(tasks),
        "state": metadata["state"],
    }


def build_parser() -> argparse.ArgumentParser:
    """Build command-line arguments."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--queue", type=Path, default=DEFAULT_QUEUE)
    parser.add_argument("--model-registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--kind", action="append", default=[])
    parser.add_argument("--target", action="append", default=[])
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--source-commit", default=None)
    return parser


def run(argv: Iterable[str] | None = None) -> int:
    """Execute the batch builder."""

    args = build_parser().parse_args(list(argv) if argv is not None else None)
    receipt = prepare_batch(
        queue=args.queue,
        registry=args.model_registry,
        output_dir=args.output_dir,
        kinds=set(args.kind),
        targets=set(args.target),
        limit=args.limit,
        source_commit=args.source_commit or resolve_source_commit(),
    )
    print(json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


def main() -> int:
    """CLI entrypoint."""

    try:
        return run()
    except (BatchError, OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"batch preparation error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
