#!/usr/bin/env python3
"""Build a deterministic evidence manifest without promoting any artifact."""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STATES = ("created", "validated_automatic", "pending_human", "integrated", "device_validated")


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def build(root: Path, paths: list[Path], state: str) -> dict:
    if state not in STATES:
        raise ValueError(f"estado inválido: {state}")
    entries = []
    for supplied in paths:
        path = supplied if supplied.is_absolute() else root / supplied
        path = path.resolve()
        try:
            relative = path.relative_to(root)
        except ValueError as exc:
            raise ValueError(f"evidência fora do repositório: {path}") from exc
        if not path.is_file():
            raise FileNotFoundError(relative)
        entries.append({"path": relative.as_posix(), "sha256": digest(path), "bytes": path.stat().st_size, "state": state})
    return {
        "schema_version": "1.0.0",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "promotion": "forbidden",
        "state_separation": "created != validated != integrated",
        "entries": entries,
    }


def self_test() -> None:
    with tempfile.TemporaryDirectory(prefix="evidence-pack-") as temp:
        root = Path(temp)
        sample = root / "sample.txt"
        sample.write_text("cria", encoding="utf-8")
        report = build(root, [Path("sample.txt")], "created")
        assert report["entries"][0]["sha256"] == hashlib.sha256(b"cria").hexdigest()
        assert report["promotion"] == "forbidden"
    print(json.dumps({"tool": "evidence_pack", "self_test": "PASS"}))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--state", choices=STATES, default="created")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if not args.paths:
        parser.error("informe ao menos um caminho de evidência")
    report = build(args.root.resolve(), args.paths, args.state)
    serialized = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(serialized, encoding="utf-8")
    print(serialized, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
