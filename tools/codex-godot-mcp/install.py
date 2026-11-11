#!/usr/bin/env python3
"""Pinned, opt-in local installer for Codex ↔ Open Godot MCP.

--check is read-only. --install uses Git+Cargo to build pinned upstream.
No changes to project.godot, gameplay, autoloads or release assets.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
UPSTREAM_URL = "https://github.com/OneStepAt4time/open-godot-mcp.git"
UPSTREAM_SHA = "afbf1ed18efc268dca003c692bc3331e98125ba2"
BINARY = HERE / ".local" / "bin" / ("open-godot-mcp-server.exe" if os.name == "nt" else "open-godot-mcp-server")
ADDON = ROOT / "addons" / "open_godot_mcp"
CONFIG = ROOT / ".codex" / "config.toml"


def read_status() -> dict:
    cfg = CONFIG.read_text(encoding="utf-8") if CONFIG.is_file() else ""
    settings = (ROOT / "project.godot").read_text(encoding="utf-8") if (ROOT / "project.godot").is_file() else ""
    return {
        "project": str(ROOT),
        "godot_project_found": (ROOT / "project.godot").is_file(),
        "codex_project_config": "[mcp_servers.cria_godot]" in cfg,
        "codex_binary_on_path": bool(shutil.which("codex")),
        "godot_binary_on_path": bool(shutil.which("godot") or shutil.which("godot4")),
        "rust_cargo_on_path": bool(shutil.which("cargo")),
        "git_on_path": bool(shutil.which("git")),
        "local_server_installed": BINARY.is_file(),
        "godot_addon_installed": (ADDON / "plugin.cfg").is_file(),
        "editor_plugin_enabled": "res://addons/open_godot_mcp/plugin.cfg" in settings,
        "server_bind": "localhost:6505",
        "upstream_sha": UPSTREAM_SHA,
        "godot_runtime_modified_by_installer": False,
        "shipping": False,
    }


def run_checked(command: list[str], *, cwd: Path | None = None) -> None:
    subprocess.run(command, cwd=str(cwd) if cwd else None, check=True)


def validate_upstream(source: Path) -> Path:
    p = subprocess.run(["git", "rev-parse", "HEAD"], cwd=source,
                       capture_output=True, text=True, check=True)
    if p.stdout.strip() != UPSTREAM_SHA:
        raise ValueError("Upstream revision is not the audited SHA; refuse install")
    addon_src = source / "godot_plugin" / "addons" / "open_godot_mcp"
    plugin = addon_src / "plugin.cfg"
    if not plugin.is_file() or "Open Godot MCP" not in plugin.read_text(encoding="utf-8"):
        raise ValueError("Pinned addon absent")
    if not (source / "Cargo.toml").is_file():
        raise ValueError("Pinned Cargo.toml absent")
    return addon_src


def install(source: Path, replace: bool = False) -> dict:
    if not (ROOT / "project.godot").is_file() or not CONFIG.is_file():
        raise ValueError("Not in official CRIA Codex checkout")
    if not shutil.which("cargo") or not shutil.which("git"):
        raise RuntimeError("Git and Cargo are required for the pinned build")
    if ADDON.is_symlink() or BINARY.is_symlink():
        raise ValueError("Refusing symlink target")
    if (ADDON.exists() or BINARY.exists()) and not replace:
        raise FileExistsError("Existing local installation; inspect with --check or pass --replace")
    addon_src = validate_upstream(source)
    run_checked(["cargo", "build", "--release"], cwd=source)
    compiled = source / "target" / "release" / BINARY.name
    if not compiled.is_file():
        raise RuntimeError("Expected binary missing after Cargo build")
    BINARY.parent.mkdir(parents=True, exist_ok=True)
    if replace and BINARY.exists():
        BINARY.unlink()
    shutil.copy2(compiled, BINARY)
    if os.name != "nt":
        BINARY.chmod(BINARY.stat().st_mode | 0o111)
    ADDON.parent.mkdir(parents=True, exist_ok=True)
    if ADDON.exists():
        shutil.rmtree(ADDON)
    shutil.copytree(addon_src, ADDON, symlinks=False)
    return read_status()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--check", action="store_true", help="Read-only diagnostics (default)")
    actions.add_argument("--install", action="store_true", help="Opt in to pinned clone, build and copy")
    parser.add_argument("--source", type=Path, help="Pre-existing clone checked out at pinned SHA")
    parser.add_argument("--replace", action="store_true", help="Replace existing local addon/binary")
    args = parser.parse_args()
    try:
        if not args.install:
            result = read_status()
        elif args.source is not None:
            result = install(args.source.resolve(), args.replace)
        else:
            with tempfile.TemporaryDirectory(prefix="cria-godot-mcp-") as tmp:
                src = Path(tmp) / "upstream"
                run_checked(["git", "clone", UPSTREAM_URL, str(src)])
                run_checked(["git", "checkout", "--detach", UPSTREAM_SHA], cwd=src)
                result = install(src, args.replace)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"CRIA MCP install FAILED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
