#!/usr/bin/env python3
"""Fail-closed validator for CRIA Sprite Forge v1 packages.

The gate validates the tooling contract on every run. Production sprite packages
are validated when present. Zero production packages is reported explicitly as
TOOLING_ONLY and is never described as asset readiness.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from typing import Any

try:
    from build_sprite_forge_profile import measure_action
except ImportError:  # pragma: no cover - import path used by unit tests
    from tools.art.build_sprite_forge_profile import measure_action

CONTRACT_REL = pathlib.Path("data/visual/sprite_forge_contract_v1.json")
SCHEMA_REL = pathlib.Path("assets/schemas/sprite_forge.manifest.schema.json")
MANIFEST_NAME = "sprite_forge_manifest.json"
EXPECTED_VERSION = "1.0.0"
EXPECTED_FRAME_SIZE = [128, 128]
EXPECTED_PIVOT = [64, 96]
SHA40 = re.compile(r"^[0-9a-f]{40}$")


def _read_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def validate_contract(contract: dict[str, Any], repo_root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    if contract.get("version") != EXPECTED_VERSION:
        errors.append(f"contract.version must be {EXPECTED_VERSION}")

    upstream = contract.get("upstream_research", {})
    if upstream.get("repository") != "https://github.com/0x0funky/agent-sprite-forge":
        errors.append("upstream repository mismatch")
    pinned = str(upstream.get("pinned_commit", ""))
    if not SHA40.fullmatch(pinned):
        errors.append("upstream pinned_commit must be a full 40-char SHA")
    if upstream.get("license") != "MIT":
        errors.append("upstream license must remain MIT in provenance metadata")

    scope = contract.get("scope", {})
    if scope.get("runtime_dependency") is not False:
        errors.append("Sprite Forge must not become a runtime dependency")
    if scope.get("automatic_asset_promotion") is not False:
        errors.append("automatic asset promotion must remain disabled")

    frame = contract.get("frame_contract", {})
    if frame.get("size_px") != EXPECTED_FRAME_SIZE:
        errors.append(f"frame size must remain {EXPECTED_FRAME_SIZE}")
    if frame.get("pivot_px") != EXPECTED_PIVOT:
        errors.append(f"pivot must remain {EXPECTED_PIVOT}")
    if frame.get("resampling") != "nearest":
        errors.append("resampling must remain nearest")
    if frame.get("integer_scale_only") is not True:
        errors.append("integer_scale_only must remain true")
    if frame.get("grounded_anchor") != "feet":
        errors.append("grounded anchor must remain feet")

    thresholds = contract.get("qc_thresholds", {})
    expected_thresholds = {
        "body_scale_cv_max": 0.08,
        "anchor_y_std_max": 0.05,
        "profile_body_scale_drift_max": 0.08,
        "edge_touch_frames_max": 0,
        "empty_frames_max": 0,
        "paste_clamped_frames_max": 0,
    }
    for key, expected in expected_thresholds.items():
        if thresholds.get(key) != expected:
            errors.append(f"qc threshold {key} must remain {expected}")

    promotion = contract.get("promotion", {})
    if promotion.get("default_shipping") is not False:
        errors.append("default_shipping must remain false")
    if promotion.get("this_contract_may_set_shipping_true") is not False:
        errors.append("Sprite Forge contract cannot authorize shipping")

    if not (repo_root / SCHEMA_REL).exists():
        errors.append(f"missing schema: {SCHEMA_REL.as_posix()}")
    return errors


def _safe_child(path: pathlib.Path, parent: pathlib.Path) -> bool:
    try:
        path.resolve().relative_to(parent.resolve())
        return True
    except ValueError:
        return False


def _metric_close(actual: float, stored: Any, tolerance: float = 1e-5) -> bool:
    try:
        return abs(actual - float(stored)) <= tolerance
    except (TypeError, ValueError):
        return False


def validate_package(path: pathlib.Path, contract: dict[str, Any], repo_root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    try:
        package = _read_json(path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return [f"{path}: invalid JSON: {exc}"]

    if package.get("version") != 1:
        errors.append("version must be 1")
    if package.get("protocol_version") != contract.get("version"):
        errors.append("protocol_version does not match active Sprite Forge contract")

    character_id = str(package.get("character_id", ""))
    expected_char_dir = repo_root / "assets" / "chars" / "frames" / character_id
    if path.parent.resolve() != expected_char_dir.resolve():
        errors.append("manifest location must match character_id")

    if package.get("shipping") is not False:
        errors.append("shipping must remain false; this tooling cannot authorize release")

    profile = package.get("scale_profile")
    actions = package.get("actions")
    master_action = package.get("master_action")
    if not isinstance(profile, dict):
        errors.append("scale_profile must be an object")
        return errors
    if not isinstance(actions, dict) or not actions:
        errors.append("actions must be a non-empty object")
        return errors
    if master_action not in actions:
        errors.append("master_action must exist in actions")

    if profile.get("source_action") != master_action:
        errors.append("scale_profile.source_action must equal master_action")
    if profile.get("frame_size") != EXPECTED_FRAME_SIZE:
        errors.append(f"scale_profile.frame_size must be {EXPECTED_FRAME_SIZE}")
    if profile.get("pivot") != EXPECTED_PIVOT:
        errors.append(f"scale_profile.pivot must be {EXPECTED_PIVOT}")
    if profile.get("align") != "feet":
        errors.append("scale_profile.align must be feet")

    thresholds = contract["qc_thresholds"]
    master_scale = profile.get("body_scale_mean")
    try:
        master_scale_float = float(master_scale)
    except (TypeError, ValueError):
        master_scale_float = 0.0
        errors.append("scale_profile.body_scale_mean must be numeric")

    for action, entry in sorted(actions.items()):
        if not isinstance(entry, dict):
            errors.append(f"{action}: entry must be an object")
            continue
        frames_rel = entry.get("frames_dir")
        if not isinstance(frames_rel, str):
            errors.append(f"{action}: frames_dir must be a string")
            continue
        frames_dir = repo_root / frames_rel
        if not _safe_child(frames_dir, expected_char_dir):
            errors.append(f"{action}: frames_dir escapes character directory")
            continue
        if not frames_dir.is_dir():
            errors.append(f"{action}: missing frames_dir {frames_rel}")
            continue
        pngs = sorted(frames_dir.glob("*.png"))
        if entry.get("frame_count") != len(pngs):
            errors.append(f"{action}: frame_count does not match PNG count")

        try:
            measured = measure_action(frames_dir)
        except (OSError, ValueError) as exc:
            errors.append(f"{action}: measurement failed: {exc}")
            continue
        qc = entry.get("qc")
        if not isinstance(qc, dict):
            errors.append(f"{action}: qc must be an object")
            continue

        for key in ("body_scale_mean", "body_scale_cv", "anchor_y_mean", "anchor_y_std"):
            if not _metric_close(float(measured[key]), qc.get(key)):
                errors.append(f"{action}: stored {key} differs from measured frames")

        drift = abs(float(measured["body_scale_mean"]) - master_scale_float) / master_scale_float if master_scale_float > 0 else 1.0
        if not _metric_close(drift, qc.get("profile_body_scale_drift")):
            errors.append(f"{action}: stored profile_body_scale_drift differs from measured frames")

        if float(measured["body_scale_cv"]) > float(thresholds["body_scale_cv_max"]):
            errors.append(f"{action}: body_scale_cv exceeds threshold")
        if float(measured["anchor_y_std"]) > float(thresholds["anchor_y_std_max"]):
            errors.append(f"{action}: anchor_y_std exceeds threshold")
        if drift > float(thresholds["profile_body_scale_drift_max"]):
            errors.append(f"{action}: profile_body_scale_drift exceeds threshold")
        if int(measured["edge_touch_frames"]) > int(thresholds["edge_touch_frames_max"]):
            errors.append(f"{action}: edge_touch_frames exceeds threshold")
        if int(measured["empty_frames"]) > int(thresholds["empty_frames_max"]):
            errors.append(f"{action}: empty_frames exceeds threshold")
        if int(qc.get("paste_clamped_frames", 0)) > int(thresholds["paste_clamped_frames_max"]):
            errors.append(f"{action}: paste_clamped_frames exceeds threshold")

    return errors


def discover_packages(repo_root: pathlib.Path) -> list[pathlib.Path]:
    root = repo_root / "assets" / "chars" / "frames"
    return sorted(root.glob(f"*/{MANIFEST_NAME}")) if root.exists() else []


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--manifest", action="append", default=[])
    parser.add_argument("--require-package", action="store_true")
    args = parser.parse_args()

    repo_root = pathlib.Path(args.root).resolve()
    contract_path = repo_root / CONTRACT_REL
    try:
        contract = _read_json(contract_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL Sprite Forge contract: {exc}")
        return 1

    failures = validate_contract(contract, repo_root)
    packages = [repo_root / item for item in args.manifest] if args.manifest else discover_packages(repo_root)
    if args.require_package and not packages:
        failures.append("no production Sprite Forge package found")

    for package in packages:
        for error in validate_package(package, contract, repo_root):
            failures.append(f"{package.relative_to(repo_root)}: {error}")

    if failures:
        for failure in failures:
            print("FAIL", failure)
        print(f"Sprite Forge validation failed: {len(failures)} failure(s)")
        return 1

    if packages:
        print(f"Sprite Forge PASS: contract + {len(packages)} production package(s) validated; shipping authority unchanged")
    else:
        print("Sprite Forge PASS: tooling contract validated; production_packages=0; readiness=TOOLING_ONLY")
    return 0


if __name__ == "__main__":
    sys.exit(main())
