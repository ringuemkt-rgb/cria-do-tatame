#!/usr/bin/env python3
"""Install the pinned Godot AI v4 plugin for the isolated CRIA experiment.

This is developer tooling only. It refuses to install unless the selected Godot
binary reports 4.7+ and the downloaded official release archive matches the
pinned SHA-256 from the reviewed release.
"""
from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
import tempfile
import urllib.request
import zipfile
from pathlib import Path, PurePosixPath

VERSION = "4.1.0"
TAG = "v4.1.0"
ARCHIVE_NAME = "godot-ai-v4-plugin.zip"
ARCHIVE_URL = f"https://github.com/hi-godot/godot-ai/releases/download/{TAG}/{ARCHIVE_NAME}"
ARCHIVE_SHA256 = "535d8a7541871af8d991b07fe5031550dd6121a31b844400476b334a70612831"
MIN_GODOT = (4, 7)


def parse_version(text: str) -> tuple[int, int]:
    match = re.search(r"(\d+)\.(\d+)", text)
    if not match:
        raise RuntimeError(f"could not parse Godot version from: {text!r}")
    return int(match.group(1)), int(match.group(2))


def godot_version(godot_bin: str) -> tuple[int, int, str]:
    result = subprocess.run(
        [godot_bin, "--version"],
        capture_output=True,
        text=True,
        check=False,
    )
    output = (result.stdout or result.stderr).strip()
    if result.returncode != 0:
        raise RuntimeError(f"{godot_bin} --version failed ({result.returncode}): {output}")
    major_minor = parse_version(output)
    return major_minor[0], major_minor[1], output


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_member(member: str) -> bool:
    path = PurePosixPath(member)
    return not path.is_absolute() and ".." not in path.parts


def install_archive(archive: Path, project_root: Path, replace: bool) -> Path:
    target = project_root / "addons" / "godot_ai"
    if target.exists():
        if not replace:
            raise RuntimeError(f"{target} already exists; pass --replace to overwrite the local experiment plugin")
        shutil.rmtree(target)

    with zipfile.ZipFile(archive) as zf:
        members = [name for name in zf.namelist() if name and not name.endswith("/")]
        if any(not safe_member(name) for name in members):
            raise RuntimeError("archive contains unsafe path traversal entry")

        plugin_candidates = [name for name in members if name.endswith("addons/godot_ai/plugin.cfg")]
        if len(plugin_candidates) != 1:
            raise RuntimeError(f"expected exactly one addons/godot_ai/plugin.cfg, found {plugin_candidates}")

        plugin_cfg = PurePosixPath(plugin_candidates[0])
        prefix_parts = plugin_cfg.parts[:-3]
        prefix = "/".join(prefix_parts)
        source_prefix = f"{prefix}/addons/godot_ai/" if prefix else "addons/godot_ai/"

        target.mkdir(parents=True, exist_ok=True)
        extracted = 0
        for name in members:
            if not name.startswith(source_prefix):
                continue
            relative = name[len(source_prefix):]
            if not relative:
                continue
            out = target / PurePosixPath(relative)
            out.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(name) as src, out.open("wb") as dst:
                shutil.copyfileobj(src, dst)
            extracted += 1

    if extracted == 0 or not (target / "plugin.cfg").exists():
        raise RuntimeError("plugin extraction produced no valid Godot AI tree")
    return target


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot-bin", default="godot")
    parser.add_argument("--project-root", default=str(Path(__file__).resolve().parents[2]))
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--archive", help="Use an already downloaded official archive instead of network download")
    parser.add_argument("--check-only", action="store_true", help="Validate Godot version and pin metadata without downloading")
    args = parser.parse_args()

    major, minor, raw = godot_version(args.godot_bin)
    if (major, minor) < MIN_GODOT:
        raise SystemExit(f"BLOCKED: Godot AI v4 requires Godot {MIN_GODOT[0]}.{MIN_GODOT[1]}+; found {raw}")

    print(f"Godot OK: {raw}")
    print(f"Godot AI pin: {TAG} ({ARCHIVE_SHA256})")
    if args.check_only:
        return 0

    project_root = Path(args.project_root).resolve()
    if not (project_root / "project.godot").exists():
        raise SystemExit(f"BLOCKED: no project.godot under {project_root}")

    if args.archive:
        archive = Path(args.archive).resolve()
        if not archive.exists():
            raise SystemExit(f"BLOCKED: archive not found: {archive}")
        actual = sha256(archive)
        if actual != ARCHIVE_SHA256:
            raise SystemExit(f"BLOCKED: archive SHA-256 mismatch: {actual}")
        installed = install_archive(archive, project_root, args.replace)
    else:
        with tempfile.TemporaryDirectory(prefix="cria-godot-ai-") as temp_dir:
            archive = Path(temp_dir) / ARCHIVE_NAME
            print(f"Downloading pinned official release: {ARCHIVE_URL}")
            urllib.request.urlretrieve(ARCHIVE_URL, archive)
            actual = sha256(archive)
            if actual != ARCHIVE_SHA256:
                raise SystemExit(f"BLOCKED: downloaded archive SHA-256 mismatch: {actual}")
            installed = install_archive(archive, project_root, args.replace)

    print(f"Installed developer-only plugin at {installed}")
    print("Next: open this branch with Godot 4.7+, enable Godot AI, keep MCP configuration local, and execute G47-01..G47-14.")
    print("Recommended privacy setting for local private project work: GODOT_AI_DISABLE_TELEMETRY=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
