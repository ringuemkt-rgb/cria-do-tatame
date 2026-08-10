#!/usr/bin/env python3
"""Run a pinned Neplex Vectorizer CLI as a vector-source candidate tool.

The adapter deliberately excludes fighters, animation frames, tiles and arena
art. It verifies the isolated npm package, constrains output to the production
candidate tree, and rejects active or unexpectedly complex SVG before writing
the Cria intake record. SVG remains an authoring source; shipping textures are
size-specific PNG bakes reviewed in Godot and on a physical Android device.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
PROFILE_PATH = ROOT / "data" / "production" / "neplex_vectorizer_profile_v01.json"
SAFE_ID = re.compile(r"^[a-z0-9][a-z0-9_]{0,63}$")
HEX_COLOR = re.compile(r"^#[0-9a-fA-F]{6}$")
PATH_DATA = re.compile(r"^[MmZzLlHhVvCcSsQqTtAa0-9eE+.,\-\s]+$")
ACTIVE_SVG = re.compile(
    r"<!DOCTYPE|<!ENTITY|<\s*(?:script|foreignObject|image|use|iframe|object|embed|style|text)\b|"
    r"\b(?:href|xlink:href|on[a-z]+|style)\s*=|javascript:|data:|url\s*\(|@import",
    re.IGNORECASE,
)
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

VECTOR_PROFILES: dict[str, dict[str, Any]] = {
    "faction_emblem": {
        "mode": "polygon",
        "filter_speckle": 4,
        "color_precision": 6,
        "layer_difference": 8,
        "path_precision": 2,
        "max_colors": 12,
        "max_paths": 256,
    },
    "style_emblem": {
        "mode": "polygon",
        "filter_speckle": 4,
        "color_precision": 6,
        "layer_difference": 8,
        "path_precision": 2,
        "max_colors": 12,
        "max_paths": 256,
    },
    "ui_icon": {
        "mode": "polygon",
        "filter_speckle": 2,
        "color_precision": 5,
        "layer_difference": 10,
        "path_precision": 2,
        "max_colors": 8,
        "max_paths": 128,
    },
    "logo_mark": {
        "mode": "spline",
        "filter_speckle": 4,
        "color_precision": 6,
        "layer_difference": 8,
        "path_precision": 2,
        "max_colors": 16,
        "max_paths": 512,
    },
    "accessibility_diagram": {
        "mode": "polygon",
        "filter_speckle": 2,
        "color_precision": 6,
        "layer_difference": 8,
        "path_precision": 2,
        "max_colors": 16,
        "max_paths": 512,
    },
}


class AdapterError(RuntimeError):
    """Raised when vectorization violates the reviewed production contract."""


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


def _safe_identifier(value: str, label: str) -> str:
    if not SAFE_ID.fullmatch(value):
        raise AdapterError(f"{label} must match {SAFE_ID.pattern}")
    return value


def _display_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return str(resolved.relative_to(ROOT))
    except ValueError:
        return str(resolved)


def verify_package(
    package_root: Path,
    cli_path: Path,
    profile: dict[str, Any] | None = None,
) -> dict[str, Any]:
    selected = profile or load_json(PROFILE_PATH)
    source = dict(selected["source"])
    package_root = package_root.resolve()
    cli_path = cli_path.resolve()
    expected_cli = (package_root / "cli" / "index.mjs").resolve()
    if cli_path != expected_cli:
        raise AdapterError(f"CLI must resolve to {expected_cli}, got {cli_path}")

    required_hashes = {
        "LICENSE": source["license_sha256"],
        "package.json": source["package_json_sha256"],
        "cli/index.mjs": source["cli_sha256"],
        "index.js": source["index_sha256"],
        "js-bindings.js": source["bindings_sha256"],
    }
    failures: list[str] = []
    for relative, expected in required_hashes.items():
        candidate = package_root / relative
        if not candidate.is_file():
            failures.append(f"missing {relative}")
            continue
        actual = file_sha256(candidate)
        if actual != expected:
            failures.append(f"hash mismatch for {relative}: {actual}")

    package_data = load_json(package_root / "package.json") if (package_root / "package.json").is_file() else {}
    if package_data.get("name") != source["package"]:
        failures.append(f"package name mismatch: {package_data.get('name')}")
    if package_data.get("version") != source["package_version"]:
        failures.append(f"package version mismatch: {package_data.get('version')}")
    # npm records gitHead in registry metadata, but strips it from the packed
    # package.json. If a package manager preserves the field it must match;
    # otherwise the reviewed file hashes remain the executable identity gate.
    if package_data.get("gitHead") is not None and package_data.get("gitHead") != source["package_git_head"]:
        failures.append(f"package gitHead mismatch: {package_data.get('gitHead')}")

    if not failures:
        try:
            completed = subprocess.run(
                [str(cli_path), "--version"],
                check=True,
                capture_output=True,
                text=True,
                timeout=15,
            )
        except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
            failures.append(f"CLI version check failed: {exc}")
        else:
            if completed.stdout.strip() != source["package_version"]:
                failures.append(f"CLI version mismatch: {completed.stdout.strip()}")

    if failures:
        raise AdapterError("external package rejected: " + "; ".join(failures))
    return {
        "ok": True,
        "package": source["package"],
        "version": source["package_version"],
        "git_head": source["package_git_head"],
        "license": source["license"],
        "cli": str(cli_path),
    }


def read_png_dimensions(path: Path, profile: dict[str, Any] | None = None) -> tuple[int, int]:
    selected = profile or load_json(PROFILE_PATH)
    execution = dict(selected["execution"])
    if path.suffix.lower() not in execution["input_extensions"]:
        raise AdapterError("only rights-cleared PNG input is accepted")
    size = path.stat().st_size
    if size <= 0 or size > int(execution["max_input_bytes"]):
        raise AdapterError(f"PNG byte size outside contract: {size}")
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        raise AdapterError("input is not a valid PNG header")
    width, height = struct.unpack(">II", header[16:24])
    maximum = int(execution["max_dimension"])
    if width <= 0 or height <= 0 or width > maximum or height > maximum:
        raise AdapterError(f"PNG dimensions outside contract: {width}x{height}")
    return width, height


def candidate_output_dir(batch_id: str, asset_id: str) -> Path:
    batch = _safe_identifier(batch_id, "batch_id")
    asset = _safe_identifier(asset_id, "asset_id")
    profile = load_json(PROFILE_PATH)
    root = (ROOT / str(profile["execution"]["candidate_output_root"])).resolve()
    output = (root / batch / asset).resolve()
    if output != root and root not in output.parents:
        raise AdapterError("candidate output escaped the approved root")
    return output


def build_vectorize_command(
    cli_path: Path,
    input_path: Path,
    output_path: Path,
    vector_profile: str,
) -> list[str]:
    if vector_profile not in VECTOR_PROFILES:
        raise AdapterError(f"unsupported vector profile: {vector_profile}")
    policy = VECTOR_PROFILES[vector_profile]
    return [
        str(cli_path.resolve()),
        str(input_path.resolve()),
        str(output_path.resolve()),
        "--preset",
        "poster",
        "--mode",
        str(policy["mode"]),
        "--filter-speckle",
        str(policy["filter_speckle"]),
        "--color-precision",
        str(policy["color_precision"]),
        "--layer-difference",
        str(policy["layer_difference"]),
        "--path-precision",
        str(policy["path_precision"]),
        "--optimize",
        "--optimize-preset",
        "safe",
        "--multipass",
        "--multipass-iterations",
        "3",
    ]


def _local_name(name: str) -> str:
    return name.rsplit("}", 1)[-1]


def _number(value: str, label: str) -> float:
    normalized = value.strip()
    if normalized.endswith("px"):
        normalized = normalized[:-2]
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)?", normalized):
        raise AdapterError(f"unsafe or unsupported {label}: {value}")
    result = float(normalized)
    if not math.isfinite(result) or result <= 0:
        raise AdapterError(f"invalid {label}: {value}")
    return result


def audit_svg_text(
    svg: str,
    vector_profile: str,
    expected_dimensions: tuple[int, int] | None = None,
    profile: dict[str, Any] | None = None,
) -> dict[str, Any]:
    selected = profile or load_json(PROFILE_PATH)
    execution = dict(selected["execution"])
    if vector_profile not in VECTOR_PROFILES:
        raise AdapterError(f"unsupported vector profile: {vector_profile}")
    policy = VECTOR_PROFILES[vector_profile]
    encoded = svg.encode("utf-8")
    if len(encoded) <= 0 or len(encoded) > int(execution["max_output_bytes"]):
        raise AdapterError(f"SVG byte size outside contract: {len(encoded)}")
    active = ACTIVE_SVG.search(svg)
    if active:
        raise AdapterError(f"active or external SVG construct rejected: {active.group(0)}")
    try:
        root = ET.fromstring(svg)
    except ET.ParseError as exc:
        raise AdapterError(f"invalid SVG XML: {exc}") from exc
    if _local_name(root.tag) != "svg":
        raise AdapterError("root element must be svg")

    allowed_elements = set(execution["allowed_svg_elements"])
    allowed_attributes = {
        "svg": {"width", "height", "viewBox", "version"},
        "g": {"fill", "fill-rule", "clip-rule", "transform"},
        "path": {"d", "fill", "fill-rule", "clip-rule", "transform"},
    }
    fills: set[str] = set()
    path_count = 0
    for element in root.iter():
        tag = _local_name(element.tag)
        if tag not in allowed_elements:
            raise AdapterError(f"unsupported SVG element: {tag}")
        for raw_name, value in element.attrib.items():
            name = _local_name(raw_name)
            lowered = name.lower()
            if lowered.startswith("on") or lowered.endswith("href") or lowered == "style":
                raise AdapterError(f"active SVG attribute rejected: {name}")
            if name not in allowed_attributes[tag]:
                raise AdapterError(f"unsupported attribute on {tag}: {name}")
            if any(token in value.lower() for token in ["javascript:", "data:", "url("]):
                raise AdapterError(f"external value rejected in {name}")
        if tag == "path":
            path_count += 1
            data = element.attrib.get("d", "")
            if not data or not PATH_DATA.fullmatch(data):
                raise AdapterError("path data contains unsupported syntax")
        fill = element.attrib.get("fill")
        if fill and fill != "none":
            if not HEX_COLOR.fullmatch(fill):
                raise AdapterError(f"unsupported fill color: {fill}")
            fills.add(fill.lower())

    if path_count <= 0 or path_count > int(policy["max_paths"]):
        raise AdapterError(f"SVG path count outside profile budget: {path_count}")
    if len(fills) > int(policy["max_colors"]):
        raise AdapterError(f"SVG color count outside profile budget: {len(fills)}")
    width = _number(root.attrib.get("width", ""), "width")
    height = _number(root.attrib.get("height", ""), "height")
    if expected_dimensions and (int(width), int(height)) != expected_dimensions:
        raise AdapterError(
            f"SVG dimensions {int(width)}x{int(height)} do not match PNG "
            f"{expected_dimensions[0]}x{expected_dimensions[1]}"
        )
    return {
        "bytes": len(encoded),
        "width": int(width),
        "height": int(height),
        "paths": path_count,
        "colors": sorted(fills),
        "active_constructs": False,
    }


def audit_svg_file(
    path: Path,
    vector_profile: str,
    expected_dimensions: tuple[int, int] | None = None,
) -> dict[str, Any]:
    if not path.is_file() or path.suffix.lower() != ".svg":
        raise AdapterError(f"SVG candidate missing: {path}")
    return audit_svg_text(path.read_text(encoding="utf-8"), vector_profile, expected_dimensions)


def intake_payload(
    vector_profile: str,
    input_path: Path,
    output_path: Path,
    package_report: dict[str, Any],
    command: list[str],
    metrics: dict[str, Any],
) -> dict[str, Any]:
    return {
        "$schema": "cria_vector_candidate_intake_v1",
        "tool": "neplex_vectorizer",
        "package": package_report["package"],
        "package_version": package_report["version"],
        "package_git_head": package_report["git_head"],
        "tool_license": package_report["license"],
        "vector_profile": vector_profile,
        "input": _display_path(input_path),
        "input_sha256": file_sha256(input_path),
        "output": _display_path(output_path),
        "output_sha256": file_sha256(output_path),
        "command": command,
        "metrics": metrics,
        "artifact_state": "candidate_vector_source",
        "promotion_allowed": False,
        "runtime_asset": False,
        "size_specific_png_bake_required": True,
        "required_reviews": [
            "provenance_and_license",
            "source_png_rights",
            "silhouette_and_palette",
            "small_size_readability",
            "size_specific_png_bake",
            "godot_import",
            "android_physical_device",
            "human_approval",
        ],
    }


def _add_package_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--package-root", required=True, type=Path)
    parser.add_argument("--vectorizer-cli", required=True, type=Path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify_parser = subparsers.add_parser("verify", help="Verify the pinned isolated npm package")
    _add_package_arguments(verify_parser)

    audit_parser = subparsers.add_parser("audit", help="Audit an existing SVG candidate")
    audit_parser.add_argument("--svg", required=True, type=Path)
    audit_parser.add_argument("--profile", required=True, choices=sorted(VECTOR_PROFILES))
    audit_parser.add_argument("--expected-width", type=int)
    audit_parser.add_argument("--expected-height", type=int)

    for command_name in ["plan", "run"]:
        command_parser = subparsers.add_parser(command_name)
        _add_package_arguments(command_parser)
        command_parser.add_argument("--input", required=True, type=Path)
        command_parser.add_argument("--batch-id", required=True)
        command_parser.add_argument("--asset-id", required=True)
        command_parser.add_argument("--profile", required=True, choices=sorted(VECTOR_PROFILES))
        if command_name == "run":
            command_parser.add_argument("--source-rights-confirmed", action="store_true")
            command_parser.add_argument("--acknowledge-vector-source-only", action="store_true")
            command_parser.add_argument("--acknowledge-local-cli-only", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    profile = load_json(PROFILE_PATH)
    if args.command == "verify":
        print(json.dumps(verify_package(args.package_root, args.vectorizer_cli, profile), indent=2))
        return 0
    if args.command == "audit":
        expected = None
        if args.expected_width is not None or args.expected_height is not None:
            if args.expected_width is None or args.expected_height is None:
                raise AdapterError("expected width and height must be supplied together")
            expected = (args.expected_width, args.expected_height)
        print(json.dumps(audit_svg_file(args.svg, args.profile, expected), indent=2))
        return 0

    if not args.input.is_file():
        raise AdapterError(f"input does not exist: {args.input}")
    dimensions = read_png_dimensions(args.input, profile)
    package_report = verify_package(args.package_root, args.vectorizer_cli, profile)
    output_dir = candidate_output_dir(args.batch_id, args.asset_id)
    output_path = output_dir / f"{_safe_identifier(args.asset_id, 'asset_id')}.svg"
    command = build_vectorize_command(args.vectorizer_cli, args.input, output_path, args.profile)
    if args.command == "plan":
        print(
            json.dumps(
                {
                    "command": command,
                    "input_dimensions": list(dimensions),
                    "output": str(output_path),
                    "artifact_state": "candidate_vector_source",
                    "promotion_allowed": False,
                },
                indent=2,
            )
        )
        return 0

    if not args.source_rights_confirmed:
        raise AdapterError("--source-rights-confirmed is required")
    if not args.acknowledge_vector_source_only:
        raise AdapterError("--acknowledge-vector-source-only is required")
    if not args.acknowledge_local_cli_only:
        raise AdapterError("--acknowledge-local-cli-only is required")
    output_dir.mkdir(parents=True, exist_ok=False)
    try:
        completed = subprocess.run(command, check=True, capture_output=True, text=True, timeout=120)
        metrics = audit_svg_file(output_path, args.profile, dimensions)
        payload = intake_payload(
            args.profile,
            args.input,
            output_path,
            package_report,
            command,
            metrics,
        )
        payload["tool_stderr"] = completed.stderr.strip()
        (output_dir / "cria-vector-intake.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    except Exception as exc:
        failure = {
            "artifact_state": "rejected_or_incomplete",
            "promotion_allowed": False,
            "reason": str(exc),
        }
        (output_dir / "cria-vector-intake-failed.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        raise
    print(
        json.dumps(
            {
                "ok": True,
                "output": str(output_path),
                "state": "candidate_vector_source",
                "metrics": metrics,
            }
        )
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AdapterError as exc:
        print(f"[neplex-vectorizer-adapter] {exc}", file=sys.stderr)
        raise SystemExit(2) from exc
