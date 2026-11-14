#!/usr/bin/env python3
"""Install the *lightweight* CRIA factory in a local venv or inspect dependencies.

Never downloads model weights, clones external repos, starts paid jobs, or edits Godot.
Run from official repo root:
  python tools/cria-asset-factory/scripts/bootstrap.py --check
  python tools/cria-asset-factory/scripts/bootstrap.py --install-core
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import platform
import shutil
import subprocess
import sys
import venv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FACTORY = Path(__file__).resolve().parents[1]
CONFIG = FACTORY / "config/integrations.json"
ENV = FACTORY / ".venv"


def load_config(root: Path = ROOT) -> dict:
    config = json.loads((root / "tools/cria-asset-factory/config/integrations.json").read_text(encoding="utf-8"))
    if config.get("shipping") is not False or config.get("runtime_authority") is not False:
        raise ValueError("factory integrations cannot become shipping/runtime authority")
    backends = config.get("backends")
    if not isinstance(backends, list) or len(backends) != len({x.get("id") for x in backends}):
        raise ValueError("invalid or duplicate integrations")
    profile = json.loads((root / "data/ai/qwen_pixel_art_profile_v1.json").read_text(encoding="utf-8"))
    qwen = next((x for x in backends if x.get("id") == "qwen_pixel_art"), None)
    if (not qwen or profile.get("shipping") is not False
            or qwen["base"] != profile["base_model"]["id"]
            or qwen["adapter"] != profile["lora"]["id"]):
        raise ValueError("model IDs or shipping conflict with canonical Qwen profile")
    motion = next((x for x in backends if x.get("id") == "motion_factory"), None)
    if not motion or not (root / motion["path"]).is_file():
        raise ValueError("existing Motion Factory adapter not found; do not duplicate it")
    return config


def python_in_env(env: Path) -> Path:
    return env / ("Scripts/python.exe" if os.name == "nt" else "bin/python")


def check(root: Path = ROOT, env: Path = ENV) -> dict:
    config = load_config(root)
    executable = python_in_env(env)
    detected = {
        "python_version": platform.python_version(),
        "python_ok": sys.version_info >= (3, 10),
        "git": bool(shutil.which("git")),
        "ffmpeg": bool(shutil.which("ffmpeg")),
        "pixelorama": bool(shutil.which("pixelorama") or shutil.which("Pixelorama")),
        "nvidia_smi": bool(shutil.which("nvidia-smi")),
        "core_venv": executable.is_file(),
        "pillow_current_python": importlib.util.find_spec("PIL") is not None,
        "comfyui_local_server": "NOT_PROBED",
        "huggingface_weights": "NOT_DOWNLOADED_BY_BOOTSTRAP",
        "gpu_jobs": "NOT_STARTED",
        "godot_runtime_modified": False,
        "shipping": False,
        "backends_registered": [b["id"] for b in config["backends"]],
    }
    return detected


def install_core(factory: Path = FACTORY, env: Path = ENV) -> None:
    """Create dedicated local venv and install *only* the core Python package."""
    if sys.version_info < (3, 10):
        raise RuntimeError("Python >=3.10 required")
    if factory.resolve() != FACTORY.resolve():
        raise ValueError("only the official factory directory may be installed")
    env = env.resolve()
    if env != ENV.resolve():
        raise ValueError("custom external venv disabled to avoid modifying unintended paths")
    if not env.exists():
        venv.EnvBuilder(with_pip=True, clear=False).create(env)
    exe = python_in_env(env)
    if not exe.is_file():
        raise RuntimeError("venv Python missing; repair environment manually")
    # No --upgrade, no global or user-site changes. No optional GPU dependencies.
    subprocess.run([str(exe), "-m", "pip", "install",
                    "--disable-pip-version-check", "-e", str(factory)], check=True)
    subprocess.run([str(exe), "-c", "from PIL import Image; print('Core Pillow ready:',Image.__version__)"], check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--check", action="store_true", help="Print safe dependency diagnostic (default)")
    action.add_argument("--install-core", action="store_true", help="Install core Python package into factory/.venv")
    args = parser.parse_args()
    try:
        load_config()
        if args.install_core:
            install_core()
        print(json.dumps(check(), indent=2))
        return 0
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        print("FAIL:", exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
