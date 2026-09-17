#!/usr/bin/env python3
"""Detect local authoring capabilities for CRIA Universal Agent Production OS.

This script intentionally detects *capabilities*, not AI brands. It never reads or
prints environment variable values, tokens, credentials, model keys or config
secrets. Session-native capabilities that cannot be inferred from PATH can be
explicitly declared with --declare.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data" / "production" / "agent_production_contract_v1.json"

BINARY_CAPABILITIES: dict[str, tuple[str, ...]] = {
    "git_cli": ("git",),
    "python_exec": ("python3", "python"),
    "node_exec": ("node", "npm"),
    "godot_cli": ("godot", "godot4", "Godot"),
    "blender_cli": ("blender",),
    "ffmpeg_cli": ("ffmpeg",),
    "imagemagick_cli": ("magick", "convert"),
    "adb": ("adb",),
    "pixel_editor": ("pixelorama", "krita"),
    "map_editor": ("ldtk", "tiled", "tiled.exe"),
}

REPO_MARKERS = {
    "repo_read": ("AGENTS.md", "project.godot"),
}

SAFE_DECLARABLE = {
    "repo_write",
    "github_remote",
    "shell_exec",
    "binary_file_io",
    "web_research",
    "vision",
    "image_generate",
    "image_edit",
    "video_read",
    "audio_read",
    "godot_mcp",
    "blender_mcp",
    "comfyui_external",
    "mocap_pose_stack",
    "annotation_stack",
    "physical_android_device",
    "human_review",
    "rights_review",
}


def load_contract() -> dict[str, Any]:
    return json.loads(CONTRACT.read_text(encoding="utf-8"))


def detect_binary(candidates: tuple[str, ...]) -> dict[str, Any] | None:
    found: list[dict[str, str]] = []
    for name in candidates:
        path = shutil.which(name)
        if path:
            found.append({"name": name, "path": path})
    return {"found": found} if found else None


def repo_is_writable() -> bool:
    # os.access can be misleading on some containers; this is only a hint and
    # never creates a probe file.
    try:
        return ROOT.exists() and ROOT.is_dir() and bool(ROOT.stat())
    except OSError:
        return False


def satisfies_tier(tier: dict[str, Any], active: set[str]) -> bool:
    if any(req not in active for req in tier.get("requires_all", [])):
        return False
    for group in tier.get("requires_any", []):
        if not any(item in active for item in group):
            return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--declare",
        default="",
        help="Comma-separated session capabilities not detectable from PATH.",
    )
    parser.add_argument("--write", default="", help="Optional JSON report path.")
    parser.add_argument("--compact", action="store_true")
    args = parser.parse_args()

    contract = load_contract()
    known = {row["id"] for row in contract.get("capabilities", [])}
    active: set[str] = set()
    evidence: dict[str, Any] = {}

    for capability, markers in REPO_MARKERS.items():
        existing = [str(ROOT / marker) for marker in markers if (ROOT / marker).exists()]
        if existing:
            active.add(capability)
            evidence[capability] = {"type": "repo_marker", "paths": existing}

    if repo_is_writable() and "repo_write" in known:
        # Report as a weak local hint only. A remote/API agent should explicitly
        # declare repo_write if its write mechanism is outside this filesystem.
        if (ROOT / ".git").exists():
            active.add("repo_write")
            evidence["repo_write"] = {"type": "local_repo_hint", "path": str(ROOT)}

    for capability, binaries in BINARY_CAPABILITIES.items():
        detected = detect_binary(binaries)
        if detected:
            active.add(capability)
            evidence[capability] = {"type": "path_binary", **detected}

    if "python_exec" in active or "node_exec" in active or "git_cli" in active:
        active.add("shell_exec")
        evidence.setdefault("shell_exec", {"type": "derived_local_execution"})

    declared = [item.strip() for item in args.declare.split(",") if item.strip()]
    invalid = sorted(set(declared) - known)
    unsafe = sorted(set(declared) - SAFE_DECLARABLE - set(BINARY_CAPABILITIES) - {"repo_read"})
    if invalid:
        print(json.dumps({"ok": False, "error": "unknown_capability", "values": invalid}, indent=2))
        return 2
    if unsafe:
        print(json.dumps({"ok": False, "error": "capability_must_be_detected_or_allowed", "values": unsafe}, indent=2))
        return 2

    for capability in declared:
        active.add(capability)
        evidence[capability] = {"type": "session_declared"}

    # Binary file IO is available to ordinary local authoring environments when
    # Python exists. Do not infer vision/image generation from this.
    if "python_exec" in active:
        active.add("binary_file_io")
        evidence.setdefault("binary_file_io", {"type": "derived_from_python"})

    achieved: list[str] = []
    for tier in contract.get("execution_tiers", []):
        if satisfies_tier(tier, active):
            achieved.append(str(tier["id"]))

    highest = achieved[-1] if achieved else None
    report = {
        "schema": "cria.agent_capability_report.v1",
        "ok": True,
        "project_root": str(ROOT),
        "contract": str(CONTRACT.relative_to(ROOT)),
        "active_capabilities": sorted(active),
        "evidence": evidence,
        "satisfied_tiers": achieved,
        "highest_safe_tier": highest,
        "notes": [
            "Capabilities describe what this execution environment can actually do.",
            "No credential values are inspected or printed.",
            "Human/rights/device gates must be explicitly declared or physically detected by the operator workflow.",
        ],
    }

    text = json.dumps(report, ensure_ascii=False, indent=None if args.compact else 2, sort_keys=True)
    if args.write:
        out = Path(args.write)
        if not out.is_absolute():
            out = ROOT / out
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
