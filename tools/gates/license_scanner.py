#!/usr/bin/env python3
"""Fail-closed scanner for binary asset license sidecars in supplied paths."""
from __future__ import annotations

import argparse
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BINARY_SUFFIXES = {".png", ".gif", ".webp", ".wav", ".ogg", ".mp3", ".mp4"}
REQUIRED_FIELDS = {"source", "license", "status", "commercial_use_allowed"}


def asset_paths(root: Path, supplied: list[Path]):
    for raw in supplied:
        target = raw if raw.is_absolute() else root / raw
        target = target.resolve()
        try:
            target.relative_to(root)
        except ValueError as exc:
            raise ValueError(f"caminho fora do repositório: {target}") from exc
        if not target.exists():
            raise FileNotFoundError(target)
        candidates = [target] if target.is_file() else sorted(target.rglob("*"))
        for path in candidates:
            if path.is_file() and path.suffix.casefold() in BINARY_SUFFIXES:
                yield path


def validate_sidecar(asset: Path) -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    sidecar = asset.with_name(asset.name + ".license.json")
    if not sidecar.is_file():
        return [{"code": "LICENSE_SIDECAR_MISSING", "asset": str(asset)}]
    try:
        data = json.loads(sidecar.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        return [{"code": "LICENSE_SIDECAR_INVALID", "asset": str(asset), "detail": str(exc)}]
    missing = sorted(REQUIRED_FIELDS - set(data)) if isinstance(data, dict) else sorted(REQUIRED_FIELDS)
    if missing:
        findings.append({"code": "LICENSE_FIELDS_MISSING", "asset": str(asset), "fields": ",".join(missing)})
    if isinstance(data, dict):
        for field in ("source", "license", "status"):
            if not isinstance(data.get(field), str) or not data[field].strip():
                findings.append({"code": "LICENSE_FIELD_EMPTY", "asset": str(asset), "field": field})
    if isinstance(data, dict) and data.get("commercial_use_allowed") is not True:
        findings.append({"code": "COMMERCIAL_USE_BLOCKED", "asset": str(asset)})
    return findings


def scan(root: Path, supplied: list[Path]) -> tuple[int, list[dict[str, str]]]:
    assets = list(asset_paths(root, supplied))
    findings = [finding for asset in assets for finding in validate_sidecar(asset)]
    return len(assets), findings


def self_test() -> None:
    with tempfile.TemporaryDirectory(prefix="license-scan-") as temp:
        root = Path(temp)
        asset = root / "candidate.png"
        asset.write_bytes(b"not-an-image-needed-for-static-test")
        count, findings = scan(root, [asset])
        assert count == 1 and findings[0]["code"] == "LICENSE_SIDECAR_MISSING"
        sidecar = asset.with_name(asset.name + ".license.json")
        sidecar.write_text(json.dumps({"source": "capture", "license": "consent", "status": "candidate", "commercial_use_allowed": True}), encoding="utf-8")
        assert scan(root, [asset]) == (1, [])
    print(json.dumps({"tool": "license_scanner", "self_test": "PASS"}))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if not args.paths:
        parser.error("informe ao menos um caminho de lote")
    count, findings = scan(args.root.resolve(), args.paths)
    report = {"gate": "ASSET_LICENSE", "status": "PASS" if not findings else "BLOCKED", "assets_scanned": count, "findings": findings}
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not findings else 1


if __name__ == "__main__":
    sys.exit(main())
