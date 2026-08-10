#!/usr/bin/env python3
"""Run a pinned Agent Sprite Forge postprocessor as a candidate-only tool.

The upstream repository is never imported into the Godot runtime and is not
vendored here. This adapter verifies the reviewed commit and file hashes,
constrains output to production/candidates, and records that every result still
needs Cria-specific manifest, art, runtime and human review.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
PROFILE_PATH = ROOT / "data" / "production" / "agent_sprite_forge_profile_v01.json"
SAFE_ID = re.compile(r"^[a-z0-9][a-z0-9_]{0,63}$")

PROCESS_PROFILES: dict[str, dict[str, Any]] = {
    "character_idle": {
        "target": "asset",
        "mode": "idle",
        "align": "feet",
        "max_body_scale_cv": 0.08,
        "max_anchor_y_std": 0.05,
    },
    "character_walk": {
        "target": "asset",
        "mode": "walk",
        "align": "feet",
        "max_body_scale_cv": 0.08,
        "max_anchor_y_std": 0.05,
    },
    "effect_impact": {
        "target": "asset",
        "mode": "impact",
        "align": "center",
    },
    "effect_projectile": {
        "target": "asset",
        "mode": "projectile",
        "align": "center",
    },
    "paired_composite_preview": {
        "target": "asset",
        "mode": "paired_composite_preview",
        "align": "center",
        "rows": 2,
        "cols": 3,
        "label_prefix": "pair_preview",
        "max_body_scale_cv": 0.12,
        "max_anchor_y_std": 0.08,
    },
}


class AdapterError(RuntimeError):
    """Raised when the external tool does not satisfy the pinned contract."""


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AdapterError(f"{path} must contain an object")
    return value


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _git_head(checkout: Path) -> str:
    try:
        completed = subprocess.run(
            ["git", "-C", str(checkout), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        raise AdapterError(f"cannot resolve external checkout commit: {exc}") from exc
    return completed.stdout.strip()


def verify_checkout(checkout: Path, profile: dict[str, Any] | None = None) -> dict[str, Any]:
    selected = profile or load_json(PROFILE_PATH)
    source = dict(selected.get("source", {}))
    checkout = checkout.resolve()
    required = {
        "LICENSE": source.get("license_sha256", ""),
        "requirements.txt": source.get("requirements_sha256", ""),
        str(source.get("entrypoint", "")): source.get("entrypoint_sha256", ""),
    }
    failures: list[str] = []
    for relative, expected_hash in required.items():
        path = checkout / relative
        if not path.is_file():
            failures.append(f"missing {relative}")
            continue
        actual_hash = file_sha256(path)
        if actual_hash != expected_hash:
            failures.append(f"hash mismatch for {relative}: {actual_hash}")
    actual_commit = _git_head(checkout)
    expected_commit = str(source.get("pinned_commit", ""))
    if actual_commit != expected_commit:
        failures.append(f"commit mismatch: {actual_commit} != {expected_commit}")
    if failures:
        raise AdapterError("external checkout rejected: " + "; ".join(failures))
    return {
        "ok": True,
        "repository": source.get("repository"),
        "commit": actual_commit,
        "license": source.get("license"),
        "entrypoint": str(checkout / str(source.get("entrypoint"))),
    }


def _safe_identifier(value: str, label: str) -> str:
    if not SAFE_ID.fullmatch(value):
        raise AdapterError(f"{label} must match {SAFE_ID.pattern}")
    return value


def candidate_output_dir(batch_id: str, asset_id: str) -> Path:
    batch = _safe_identifier(batch_id, "batch_id")
    asset = _safe_identifier(asset_id, "asset_id")
    profile = load_json(PROFILE_PATH)
    root = (ROOT / str(profile["execution"]["candidate_output_root"])).resolve()
    output = (root / batch / asset).resolve()
    if output != root and root not in output.parents:
        raise AdapterError("candidate output escaped the approved root")
    return output


def build_process_command(
    checkout: Path,
    input_path: Path,
    output_dir: Path,
    process_profile: str,
) -> list[str]:
    if process_profile not in PROCESS_PROFILES:
        raise AdapterError(f"unsupported process profile: {process_profile}")
    profile = load_json(PROFILE_PATH)
    verify_checkout(checkout, profile)
    source = dict(profile["source"])
    policy = PROCESS_PROFILES[process_profile]
    command = [
        sys.executable,
        str(checkout.resolve() / str(source["entrypoint"])),
        "process",
        "--input",
        str(input_path.resolve()),
        "--target",
        str(policy["target"]),
        "--mode",
        str(policy["mode"]),
        "--output-dir",
        str(output_dir.resolve()),
        "--duration",
        "83",
        "--shared-scale",
        "--scale-strategy",
        "preserve",
        "--component-mode",
        "all",
        "--strict-qc",
        "--reject-edge-touch",
    ]
    if policy.get("rows") is not None:
        command.extend(["--rows", str(policy["rows"]), "--cols", str(policy["cols"])])
    if policy.get("label_prefix"):
        command.extend(["--label-prefix", str(policy["label_prefix"])])
    command.extend(["--align", str(policy["align"])])
    if policy.get("max_body_scale_cv") is not None:
        command.extend(["--max-body-scale-cv", str(policy["max_body_scale_cv"])])
    if policy.get("max_anchor_y_std") is not None:
        command.extend(["--max-anchor-y-std", str(policy["max_anchor_y_std"])])
    return command


def intake_payload(
    process_profile: str,
    input_path: Path,
    output_dir: Path,
    checkout_report: dict[str, Any],
) -> dict[str, Any]:
    is_pair_preview = process_profile == "paired_composite_preview"
    return {
        "$schema": "cria_candidate_intake_v1",
        "tool": "agent_sprite_forge",
        "tool_commit": checkout_report["commit"],
        "tool_license": checkout_report["license"],
        "process_profile": process_profile,
        "input": str(input_path.resolve()),
        "output": str(output_dir.resolve()),
        "artifact_state": "candidate",
        "promotion_allowed": False,
        "paired_grappling_shipping_supported": False,
        "composite_preview_only": is_pair_preview,
        "required_reviews": [
            "provenance_and_license",
            "visual_reference_comparison",
            "manual_pixel_cleanup",
            "cria_manifest_and_source_notes",
            "godot_runtime_integration",
            "mobile_readability",
            "human_approval",
        ]
        + (["human_bjj_review", "attacker_defender_split", "shared_pivot_and_sync_map"] if is_pair_preview else []),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify_parser = subparsers.add_parser("verify", help="Verify the pinned external checkout")
    verify_parser.add_argument("--forge-root", required=True, type=Path)

    for command_name in ["plan", "run"]:
        command_parser = subparsers.add_parser(command_name)
        command_parser.add_argument("--forge-root", required=True, type=Path)
        command_parser.add_argument("--input", required=True, type=Path)
        command_parser.add_argument("--batch-id", required=True)
        command_parser.add_argument("--asset-id", required=True)
        command_parser.add_argument("--profile", required=True, choices=sorted(PROCESS_PROFILES))
        if command_name == "run":
            command_parser.add_argument("--source-rights-confirmed", action="store_true")
            command_parser.add_argument("--acknowledge-candidate-only", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    profile = load_json(PROFILE_PATH)
    if args.command == "verify":
        print(json.dumps(verify_checkout(args.forge_root, profile), ensure_ascii=False, indent=2))
        return 0

    if not args.input.is_file():
        raise AdapterError(f"input does not exist: {args.input}")
    output_dir = candidate_output_dir(args.batch_id, args.asset_id)
    command = build_process_command(args.forge_root, args.input, output_dir, args.profile)
    checkout_report = verify_checkout(args.forge_root, profile)
    if args.command == "plan":
        print(
            json.dumps(
                {
                    "command": command,
                    "output": str(output_dir),
                    "artifact_state": "candidate",
                    "promotion_allowed": False,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0

    if not args.source_rights_confirmed:
        raise AdapterError("--source-rights-confirmed is required")
    if not args.acknowledge_candidate_only:
        raise AdapterError("--acknowledge-candidate-only is required")
    output_dir.mkdir(parents=True, exist_ok=False)
    try:
        subprocess.run(command, check=True)
        required_outputs = [
            "raw-sheet.png",
            "raw-sheet-clean.png",
            "sheet-transparent.png",
            "animation.gif",
            "pipeline-meta.json",
        ]
        missing = [name for name in required_outputs if not (output_dir / name).is_file()]
        if missing:
            raise AdapterError("upstream processor omitted outputs: " + ", ".join(missing))
        payload = intake_payload(args.profile, args.input, output_dir, checkout_report)
        (output_dir / "cria-intake.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    except Exception:
        # Preserve failed output for inspection; never reinterpret it as a valid candidate.
        failure = {
            "artifact_state": "rejected_or_incomplete",
            "promotion_allowed": False,
        }
        (output_dir / "cria-intake-failed.json").write_text(
            json.dumps(failure, indent=2) + "\n",
            encoding="utf-8",
        )
        raise
    print(json.dumps({"ok": True, "output": str(output_dir), "state": "candidate"}))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AdapterError as exc:
        print(f"[agent-sprite-forge-adapter] {exc}", file=sys.stderr)
        raise SystemExit(2) from exc
