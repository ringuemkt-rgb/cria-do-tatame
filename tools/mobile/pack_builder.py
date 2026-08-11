#!/usr/bin/env python3
"""Build deterministic mobile packs from GATE-L1-approved assets.

Publishing is opt-in. The builder refuses empty packs, unapproved sidecars,
reserved delegated promotions, budget overruns and an existing release tag.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = ROOT / "data" / "mobile" / "asset_packs_v1.json"
DEFAULT_APPROVED = ROOT / "assets" / "aprovados"
DEFAULT_OUTPUT = ROOT / "builds" / "packs"
DEFAULT_RUNTIME_MANIFEST = ROOT / "data" / "mobile" / "packs_runtime.json"
DEFAULT_REPOSITORY = "ringuemkt-rgb/cria-do-tatame"
FIXED_ZIP_TIME = (2020, 1, 1, 0, 0, 0)


class PackBuildError(RuntimeError):
    """Raised when a pack would violate provenance, safety or size gates."""


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode()


def read_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise PackBuildError(f"JSON root must be an object: {path}")
    return value


def atomic_write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def validate_config(config: dict[str, Any]) -> list[dict[str, Any]]:
    packs = config.get("packs")
    if not isinstance(packs, list) or not packs:
        raise PackBuildError("asset pack config has no packs")
    ids = [pack.get("id") for pack in packs if isinstance(pack, dict)]
    if len(ids) != len(packs) or len(ids) != len(set(ids)) or not all(
        isinstance(value, str) and re.fullmatch(r"[a-z0-9_]+", value) for value in ids
    ):
        raise PackBuildError("asset pack IDs must be unique non-empty strings")
    if "base" not in ids:
        raise PackBuildError("asset pack config must contain base")
    by_id = {str(pack["id"]): pack for pack in packs}
    if by_id["base"].get("obrigatorio") is not True:
        raise PackBuildError("base pack must be mandatory")
    for pack in packs:
        for dependency in pack.get("deps", []):
            if dependency not in by_id or dependency == pack["id"]:
                raise PackBuildError(f"invalid dependency {dependency!r} for {pack['id']}")
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(pack_id: str) -> None:
        if pack_id in visiting:
            raise PackBuildError(f"dependency cycle contains {pack_id}")
        if pack_id in visited:
            return
        visiting.add(pack_id)
        for dependency in by_id[pack_id].get("deps", []):
            visit(str(dependency))
        visiting.remove(pack_id)
        visited.add(pack_id)

    for pack_id in ids:
        visit(str(pack_id))
    for key in ("base_max_mb", "pack_max_mb", "max_unpacked_ratio"):
        if not isinstance(config.get(key), (int, float)) or config[key] <= 0:
            raise PackBuildError(f"invalid positive budget: {key}")
    return packs


def _safe_relative(path: Path, root: Path) -> PurePosixPath:
    relative = PurePosixPath(path.relative_to(root).as_posix())
    if not relative.parts or any(part in {"", ".", ".."} for part in relative.parts):
        raise PackBuildError(f"unsafe approved asset path: {path}")
    return relative


def _matches(relative: PurePosixPath, selectors: list[dict[str, Any]]) -> bool:
    text = relative.as_posix()
    filename = relative.name
    for selector in selectors:
        mode = selector.get("mode")
        values = selector.get("values", [])
        if not isinstance(values, list) or not all(isinstance(value, str) and value for value in values):
            raise PackBuildError(f"invalid selector values for {text}")
        if mode == "prefix" and any(filename.startswith(value) for value in values):
            return True
        if mode == "contains" and any(value in text for value in values):
            return True
        if mode == "path_prefix" and any(text.startswith(value) for value in values):
            return True
        if mode not in {"prefix", "contains", "path_prefix"}:
            raise PackBuildError(f"unsupported selector mode: {mode!r}")
    return False


def _sidecar_path(payload: Path) -> Path:
    return payload.with_name(payload.name + ".license.json")


def validate_approval(payload: Path) -> tuple[Path, dict[str, Any]]:
    sidecar = _sidecar_path(payload)
    if not sidecar.is_file():
        raise PackBuildError(f"missing approval sidecar: {sidecar}")
    document = read_object(sidecar)
    expected = document.get("sha256")
    actual = sha256_file(payload)
    if expected != actual:
        raise PackBuildError(f"sidecar hash mismatch: {payload}")
    license_info = document.get("license", {})
    promotion = document.get("promotion", {})
    qa = document.get("qa", {})
    if not isinstance(license_info, dict) or license_info.get("status") != "LIBERADO":
        raise PackBuildError(f"license is not LIBERADO: {payload}")
    if not isinstance(promotion, dict) or promotion.get("status") != "approved":
        raise PackBuildError(f"asset has no approved promotion: {payload}")
    method = promotion.get("method")
    if method not in {"human", "delegated"}:
        raise PackBuildError(f"invalid promotion method for {payload}")
    if promotion.get("reserved") is True and method != "human":
        raise PackBuildError(f"reserved asset cannot use delegated promotion: {payload}")
    if not isinstance(qa, dict):
        raise PackBuildError(f"invalid QA object: {payload}")
    visual = qa.get("visual", {})
    biomechanical = qa.get("biomechanical", {})
    if visual.get("applicable", True) and visual.get("pass") is not True:
        raise PackBuildError(f"visual QA did not pass: {payload}")
    if biomechanical.get("applicable", False):
        confidence = biomechanical.get("confidence")
        if biomechanical.get("pass") is not True or not isinstance(confidence, (int, float)) or confidence < 0.75:
            raise PackBuildError(f"biomechanical QA below 0.75: {payload}")
    return sidecar, document


def select_payloads(approved_root: Path, pack: dict[str, Any]) -> list[Path]:
    if not approved_root.is_dir():
        raise PackBuildError(f"approved asset root does not exist: {approved_root}")
    selectors = pack.get("selectors")
    if not isinstance(selectors, list) or not selectors:
        raise PackBuildError(f"pack has no selectors: {pack.get('id')}")
    selected: list[Path] = []
    for path in sorted(approved_root.rglob("*"), key=lambda item: item.as_posix()):
        if path.is_symlink():
            raise PackBuildError(f"symlinks are forbidden in approved assets: {path}")
        if not path.is_file() or path.name.endswith(".license.json"):
            continue
        relative = _safe_relative(path, approved_root)
        if _matches(relative, selectors):
            selected.append(path)
    if not selected:
        raise PackBuildError(f"pack {pack.get('id')} selected no approved files")
    return selected


def _zip_info(name: str) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, date_time=FIXED_ZIP_TIME)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    info.create_system = 3
    return info


def build_one_pack(
    approved_root: Path,
    output_dir: Path,
    pack: dict[str, Any],
    budget_mb: float,
    max_unpacked_ratio: float,
) -> dict[str, Any]:
    payloads = select_payloads(approved_root, pack)
    members: dict[str, bytes] = {}
    file_manifest: list[dict[str, Any]] = []
    for payload in payloads:
        sidecar, _ = validate_approval(payload)
        for source in (payload, sidecar):
            relative = _safe_relative(source, approved_root).as_posix()
            data = source.read_bytes()
            members[relative] = data
            file_manifest.append({"path": relative, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
    file_manifest.sort(key=lambda entry: entry["path"])
    embedded = {
        "schema_version": 1,
        "pack_id": pack["id"],
        "deps": pack.get("deps", []),
        "files": file_manifest,
    }
    members["PACK_MANIFEST.json"] = canonical_json(embedded)
    output_dir.mkdir(parents=True, exist_ok=True)
    target = output_dir / f"{pack['id']}.zip"
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{target.name}.", dir=output_dir)
    os.close(descriptor)
    temporary = Path(temporary_name)
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name in sorted(members):
                archive.writestr(_zip_info(name), members[name], compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        compressed_bytes = temporary.stat().st_size
        unpacked_bytes = sum(len(data) for data in members.values())
        if compressed_bytes > int(budget_mb * 1_000_000):
            raise PackBuildError(f"{pack['id']} exceeds {budget_mb:g} MB budget ({compressed_bytes / 1_000_000:.2f} MB)")
        if unpacked_bytes > compressed_bytes * max_unpacked_ratio:
            raise PackBuildError(f"{pack['id']} exceeds unpacked ratio {max_unpacked_ratio:g}x")
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)
    return {
        "id": pack["id"],
        "sha256": sha256_file(target),
        "bytes": target.stat().st_size,
        "mb": round(target.stat().st_size / 1_000_000, 3),
        "unpacked_bytes": unpacked_bytes,
        "file_count": len(payloads),
        "deps": pack.get("deps", []),
        "filename": target.name,
    }


def build_packs(
    config_path: Path,
    approved_root: Path,
    output_dir: Path,
    runtime_manifest: Path,
    repository: str,
) -> dict[str, Any]:
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise PackBuildError("repository must use owner/name format")
    config = read_object(config_path)
    packs = validate_config(config)
    release_tag = str(config.get("release_tag") or "packs-v1")
    if not re.fullmatch(r"[A-Za-z0-9._-]+", release_tag):
        raise PackBuildError("release_tag contains unsafe characters")
    results: list[dict[str, Any]] = []
    for pack in packs:
        budget = float(config["base_max_mb"] if pack["id"] == "base" else config["pack_max_mb"])
        result = build_one_pack(
            approved_root,
            output_dir,
            pack,
            budget,
            float(config["max_unpacked_ratio"]),
        )
        result["url"] = f"https://github.com/{repository}/releases/download/{release_tag}/{result['filename']}"
        results.append(result)
    manifest = {
        "versao": config["versao"],
        "status": "built_not_published",
        "release_tag": release_tag,
        "source": "dvc+drive-approved",
        "packs": results,
    }
    atomic_write_json(runtime_manifest, manifest)
    return manifest


def publish_release(manifest: dict[str, Any], output_dir: Path, repository: str) -> None:
    tag = str(manifest["release_tag"])
    existing = subprocess.run(
        ["gh", "release", "view", tag, "--repo", repository],
        check=False,
        capture_output=True,
        text=True,
    )
    if existing.returncode == 0:
        raise PackBuildError(f"release tag already exists and will not be overwritten: {tag}")
    assets = [str(output_dir / entry["filename"]) for entry in manifest["packs"]]
    subprocess.run(
        ["gh", "release", "create", tag, *assets, "--repo", repository,
         "--title", "Asset Packs v1", "--notes", "Packs auditados GATE-L1-B"],
        check=True,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--approved-root", type=Path, default=DEFAULT_APPROVED)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--runtime-manifest", type=Path, default=DEFAULT_RUNTIME_MANIFEST)
    parser.add_argument("--repository", default=DEFAULT_REPOSITORY)
    parser.add_argument("--publish", action="store_true", help="Create the immutable GitHub release after a successful build")
    return parser


def run(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(list(argv) if argv is not None else None)
    manifest = build_packs(args.config, args.approved_root, args.output_dir, args.runtime_manifest, args.repository)
    if args.publish:
        publish_release(manifest, args.output_dir, args.repository)
        manifest["status"] = "published"
        atomic_write_json(args.runtime_manifest, manifest)
    print(json.dumps({"ok": True, "status": manifest["status"], "packs": len(manifest["packs"])}, ensure_ascii=False))
    return 0


def main() -> int:
    try:
        return run()
    except (PackBuildError, OSError, ValueError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        print(f"mobile pack error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
