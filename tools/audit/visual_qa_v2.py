#!/usr/bin/env python3
"""Deterministic pixel-art QA: exact size, CIEDE2000, AA, dither and masked outline.

This tool never resizes an input before validation. Outline thickness is only
claimed when the asset spec supplies a binary foreground/outline mask.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
import sys
import unicodedata
from pathlib import Path
from typing import Any, Iterable, Sequence

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:  # pragma: no cover - exercised by dependency diagnostics
    raise SystemExit("visual_qa_v2 requires Pillow>=10.2 (pip install -r requirements.txt)") from exc

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONSTITUTION = ROOT / "data/visual/visual_constitution_v2.json"
VERSION = "2.0.0"

RGB = tuple[int, int, int]
LAB = tuple[float, float, float]


class VisualQAError(ValueError):
    """Raised for invalid audit specifications or deterministic label inputs."""


def pixel_data(image: Image.Image) -> list[Any]:
    """Return flattened pixels across supported Pillow versions."""

    flattened = getattr(image, "get_flattened_data", None)
    if callable(flattened):
        return list(flattened())
    return list(image.getdata())  # pragma: no cover - Pillow < 12 compatibility


def read_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise VisualQAError(f"expected JSON object: {path}")
    return value


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def parse_hex_color(value: str) -> RGB:
    text = str(value).strip().lstrip("#")
    if len(text) != 6 or any(character not in "0123456789abcdefABCDEF" for character in text):
        raise VisualQAError(f"invalid RGB hex color: {value}")
    return tuple(int(text[index:index + 2], 16) for index in (0, 2, 4))  # type: ignore[return-value]


def rgb_to_lab(rgb: RGB) -> LAB:
    def linearize(channel: int) -> float:
        value = channel / 255.0
        return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4

    red, green, blue = (linearize(channel) for channel in rgb)
    x = (red * 0.4124564 + green * 0.3575761 + blue * 0.1804375) / 0.95047
    y = red * 0.2126729 + green * 0.7151522 + blue * 0.0721750
    z = (red * 0.0193339 + green * 0.1191920 + blue * 0.9503041) / 1.08883

    delta = 6 / 29

    def pivot(value: float) -> float:
        return value ** (1 / 3) if value > delta ** 3 else value / (3 * delta ** 2) + 4 / 29

    fx, fy, fz = pivot(x), pivot(y), pivot(z)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)


def delta_e_ciede2000(first: LAB, second: LAB) -> float:
    """CIEDE2000 implementation for D65/2° Lab values."""

    l1, a1, b1 = first
    l2, a2, b2 = second
    c1 = math.hypot(a1, b1)
    c2 = math.hypot(a2, b2)
    mean_c = (c1 + c2) / 2
    g = 0.5 * (1 - math.sqrt((mean_c ** 7) / (mean_c ** 7 + 25 ** 7)))
    a1_prime = (1 + g) * a1
    a2_prime = (1 + g) * a2
    c1_prime = math.hypot(a1_prime, b1)
    c2_prime = math.hypot(a2_prime, b2)

    def hue(a_value: float, b_value: float) -> float:
        if a_value == 0 and b_value == 0:
            return 0.0
        angle = math.degrees(math.atan2(b_value, a_value))
        return angle + 360 if angle < 0 else angle

    h1_prime = hue(a1_prime, b1)
    h2_prime = hue(a2_prime, b2)
    delta_l = l2 - l1
    delta_c = c2_prime - c1_prime
    if c1_prime * c2_prime == 0:
        delta_h_angle = 0.0
    elif abs(h2_prime - h1_prime) <= 180:
        delta_h_angle = h2_prime - h1_prime
    elif h2_prime <= h1_prime:
        delta_h_angle = h2_prime - h1_prime + 360
    else:
        delta_h_angle = h2_prime - h1_prime - 360
    delta_h = 2 * math.sqrt(c1_prime * c2_prime) * math.sin(math.radians(delta_h_angle / 2))

    mean_l = (l1 + l2) / 2
    mean_c_prime = (c1_prime + c2_prime) / 2
    if c1_prime * c2_prime == 0:
        mean_h = h1_prime + h2_prime
    elif abs(h1_prime - h2_prime) <= 180:
        mean_h = (h1_prime + h2_prime) / 2
    elif h1_prime + h2_prime < 360:
        mean_h = (h1_prime + h2_prime + 360) / 2
    else:
        mean_h = (h1_prime + h2_prime - 360) / 2

    t = (
        1
        - 0.17 * math.cos(math.radians(mean_h - 30))
        + 0.24 * math.cos(math.radians(2 * mean_h))
        + 0.32 * math.cos(math.radians(3 * mean_h + 6))
        - 0.20 * math.cos(math.radians(4 * mean_h - 63))
    )
    delta_theta = 30 * math.exp(-(((mean_h - 275) / 25) ** 2))
    r_c = 2 * math.sqrt((mean_c_prime ** 7) / (mean_c_prime ** 7 + 25 ** 7))
    s_l = 1 + (0.015 * (mean_l - 50) ** 2) / math.sqrt(20 + (mean_l - 50) ** 2)
    s_c = 1 + 0.045 * mean_c_prime
    s_h = 1 + 0.015 * mean_c_prime * t
    r_t = -math.sin(math.radians(2 * delta_theta)) * r_c
    l_term = delta_l / s_l
    c_term = delta_c / s_c
    h_term = delta_h / s_h
    return math.sqrt(l_term ** 2 + c_term ** 2 + h_term ** 2 + r_t * c_term * h_term)


def percentile(values: Sequence[float], fraction: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    position = max(0, min(len(ordered) - 1, math.ceil(fraction * len(ordered)) - 1))
    return ordered[position]


def resolve_path(value: str, spec_path: Path | None) -> Path:
    path = Path(value)
    if path.is_absolute():
        return path
    if spec_path is not None:
        candidate = spec_path.parent / path
        if candidate.exists():
            return candidate.resolve()
    return (ROOT / path).resolve()


def palette_distances(pixels: Sequence[RGB], palette: Sequence[RGB], max_samples: int) -> list[float]:
    if not pixels:
        return []
    step = max(1, math.ceil(len(pixels) / max(1, max_samples)))
    palette_lab = [rgb_to_lab(color) for color in palette]
    lab_cache: dict[RGB, LAB] = {}
    distances: list[float] = []
    for color in pixels[::step]:
        lab = lab_cache.setdefault(color, rgb_to_lab(color))
        distances.append(min(delta_e_ciede2000(lab, target) for target in palette_lab))
    return distances


def is_linear_mix(current: RGB, first: RGB, second: RGB) -> bool:
    if current in (first, second) or first == second:
        return False
    vector = tuple(float(second[index] - first[index]) for index in range(3))
    denominator = sum(component * component for component in vector)
    if denominator < 12 ** 2:
        return False
    offset = tuple(float(current[index] - first[index]) for index in range(3))
    proportion = sum(offset[index] * vector[index] for index in range(3)) / denominator
    if not 0.05 < proportion < 0.95:
        return False
    projection = tuple(first[index] + proportion * vector[index] for index in range(3))
    residual = math.sqrt(sum((current[index] - projection[index]) ** 2 for index in range(3)))
    return residual <= 2.5


def anti_alias_candidates(image: Image.Image, palette: Sequence[RGB]) -> tuple[int, int]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = pixel_data(rgba)
    palette_lab = [rgb_to_lab(color) for color in palette]
    lab_cache: dict[RGB, LAB] = {}
    candidates: set[int] = set()
    opaque = 0
    for index, (_, _, _, alpha) in enumerate(pixels):
        if alpha > 0:
            opaque += 1
        if 0 < alpha < 255:
            candidates.add(index)
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            index = y * width + x
            red, green, blue, alpha = pixels[index]
            if alpha != 255 or index in candidates:
                continue
            color = red, green, blue
            lab = lab_cache.setdefault(color, rgb_to_lab(color))
            if min(delta_e_ciede2000(lab, target) for target in palette_lab) <= 1.0:
                continue
            horizontal = pixels[index - 1][:3], pixels[index + 1][:3]
            vertical = pixels[index - width][:3], pixels[index + width][:3]
            if is_linear_mix(color, horizontal[0], horizontal[1]) or is_linear_mix(color, vertical[0], vertical[1]):
                candidates.add(index)
    return len(candidates), opaque


def in_regions(x: int, y: int, regions: Sequence[Sequence[int]]) -> bool:
    for region in regions:
        if len(region) != 4:
            raise VisualQAError("dithering region must be [x, y, width, height]")
        left, top, width, height = (int(value) for value in region)
        if left <= x < left + width and top <= y < top + height:
            return True
    return False


def unapproved_dither_blocks(image: Image.Image, allowed_regions: Sequence[Sequence[int]]) -> int:
    rgb = image.convert("RGBA")
    width, height = rgb.size
    pixels = pixel_data(rgb)
    count = 0
    for y in range(height - 1):
        for x in range(width - 1):
            indexes = (y * width + x, y * width + x + 1, (y + 1) * width + x, (y + 1) * width + x + 1)
            values = [pixels[index] for index in indexes]
            if any(value[3] == 0 for value in values):
                continue
            colors = [value[:3] for value in values]
            if colors[0] == colors[3] and colors[1] == colors[2] and colors[0] != colors[1]:
                if not in_regions(x, y, allowed_regions):
                    count += 1
    return count


def measure_outline(
    image: Image.Image,
    outline: dict[str, Any],
    defaults: dict[str, Any],
    spec_path: Path | None,
) -> tuple[dict[str, Any], list[str]]:
    required = bool(outline.get("required", False))
    mask_value = outline.get("mask_path")
    if not required and not mask_value:
        return {"status": "not_requested"}, []
    if not mask_value:
        return {"status": "not_measured"}, ["outline_mask_required_for_measurement"]
    mask_path = resolve_path(str(mask_value), spec_path)
    if not mask_path.is_file():
        return {"status": "mask_missing", "mask_path": str(mask_path)}, ["outline_mask_missing"]
    mask = Image.open(mask_path).convert("L")
    if mask.size != image.size:
        return {"status": "mask_size_mismatch", "mask_size": list(mask.size)}, ["outline_mask_size_mismatch"]

    width, height = image.size
    mask_pixels = pixel_data(mask)
    image_pixels = pixel_data(image.convert("RGB"))
    boundary: set[int] = set()
    inside = {index for index, value in enumerate(mask_pixels) if value >= 128}
    for index in inside:
        x, y = index % width, index // width
        neighbors = []
        if x > 0:
            neighbors.append(index - 1)
        if x + 1 < width:
            neighbors.append(index + 1)
        if y > 0:
            neighbors.append(index - width)
        if y + 1 < height:
            neighbors.append(index + width)
        if len(neighbors) < 4 or any(neighbor not in inside for neighbor in neighbors):
            boundary.add(index)
    if not boundary:
        return {"status": "empty_boundary"}, ["outline_mask_has_no_boundary"]

    second_ring: set[int] = set()
    for index in inside - boundary:
        x, y = index % width, index // width
        neighbors = []
        if x > 0:
            neighbors.append(index - 1)
        if x + 1 < width:
            neighbors.append(index + 1)
        if y > 0:
            neighbors.append(index - width)
        if y + 1 < height:
            neighbors.append(index + width)
        if any(neighbor in boundary for neighbor in neighbors):
            second_ring.add(index)

    target = parse_hex_color(str(outline.get("color", defaults.get("color", "#000000"))))
    target_lab = rgb_to_lab(target)
    delta_max = float(outline.get("delta_e_max", defaults.get("delta_e_max", 4.0)))
    coverage_min = float(outline.get("coverage_min", defaults.get("coverage_min", 0.9)))
    spill_max = float(outline.get("inner_spill_max", defaults.get("inner_spill_max", 0.15)))
    cache: dict[RGB, float] = {}

    def is_outline_color(color: RGB) -> bool:
        return cache.setdefault(color, delta_e_ciede2000(rgb_to_lab(color), target_lab)) <= delta_max

    coverage = sum(is_outline_color(image_pixels[index]) for index in boundary) / len(boundary)
    spill = (
        sum(is_outline_color(image_pixels[index]) for index in second_ring) / len(second_ring)
        if second_ring else 0.0
    )
    errors = []
    if coverage < coverage_min:
        errors.append("outline_boundary_coverage_below_minimum")
    if spill > spill_max:
        errors.append("outline_thicker_than_one_pixel")
    return {
        "status": "measured",
        "mask_path": str(mask_path),
        "boundary_pixels": len(boundary),
        "coverage": round(coverage, 6),
        "coverage_min": coverage_min,
        "inner_ring_pixels": len(second_ring),
        "inner_spill": round(spill, 6),
        "inner_spill_max": spill_max,
        "target_thickness_px": 1,
    }, errors


def audit_image(
    image_path: Path,
    spec: dict[str, Any],
    constitution: dict[str, Any],
    spec_path: Path | None = None,
) -> dict[str, Any]:
    image = Image.open(image_path)
    rgba = image.convert("RGBA")
    defaults = constitution.get("qa_defaults", {})
    errors: list[str] = []
    warnings: list[str] = []
    expected_size_raw = spec.get("expected_size", constitution.get("internal_resolution"))
    if not isinstance(expected_size_raw, list) or len(expected_size_raw) != 2:
        raise VisualQAError("expected_size must be [width, height]")
    expected_size = int(expected_size_raw[0]), int(expected_size_raw[1])
    if rgba.size != expected_size:
        errors.append("resolution_mismatch")

    biome = str(spec.get("biome", ""))
    palette_values = spec.get("palette") or constitution.get("palettes", {}).get(biome)
    if not isinstance(palette_values, list) or not palette_values:
        raise VisualQAError(f"missing palette for biome: {biome}")
    palette = [parse_hex_color(str(value)) for value in palette_values]
    rgba_pixels = pixel_data(rgba)
    opaque_rgb = [value[:3] for value in rgba_pixels if value[3] > 0]
    if not opaque_rgb:
        errors.append("image_has_no_visible_pixels")

    unique_colors = len(set(opaque_rgb))
    max_unique = int(spec.get("max_unique_colors", defaults.get("max_unique_colors", 900)))
    if unique_colors > max_unique:
        errors.append("unique_color_budget_exceeded")

    distances = palette_distances(
        opaque_rgb,
        palette,
        int(spec.get("max_palette_samples", defaults.get("max_palette_samples", 20000))),
    )
    delta_mean = statistics.fmean(distances) if distances else 0.0
    delta_p95 = percentile(distances, 0.95)
    mean_max = float(spec.get("palette_delta_e_mean_max", defaults.get("palette_delta_e_mean_max", 8.0)))
    p95_max = float(spec.get("palette_delta_e_p95_max", defaults.get("palette_delta_e_p95_max", 12.0)))
    if delta_mean > mean_max:
        errors.append("palette_delta_e_mean_exceeded")
    if delta_p95 > p95_max:
        errors.append("palette_delta_e_p95_exceeded")

    aa_count, visible_count = anti_alias_candidates(rgba, palette)
    aa_ratio = aa_count / visible_count if visible_count else 0.0
    aa_max = float(spec.get("aa_candidate_ratio_max", defaults.get("aa_candidate_ratio_max", 0.0025)))
    if aa_ratio > aa_max:
        errors.append("anti_alias_candidate_ratio_exceeded")

    allowed_dither_regions = spec.get("dithering_regions", [])
    if not isinstance(allowed_dither_regions, list):
        raise VisualQAError("dithering_regions must be a list of boxes")
    dither_blocks = unapproved_dither_blocks(rgba, allowed_dither_regions)
    dither_max = int(spec.get("unapproved_dither_blocks_max", defaults.get("unapproved_dither_blocks_max", 0)))
    if dither_blocks > dither_max:
        errors.append("dithering_detected_outside_approved_regions")

    outline_config = spec.get("outline", {})
    if not isinstance(outline_config, dict):
        raise VisualQAError("outline must be an object")
    outline_metrics, outline_errors = measure_outline(
        rgba,
        outline_config,
        defaults.get("outline", {}),
        spec_path,
    )
    errors.extend(outline_errors)
    if outline_metrics.get("status") == "not_requested":
        warnings.append("outline_not_measured_without_mask")

    return {
        "schema_version": "2.0.0",
        "tool": "visual_qa_v2",
        "tool_version": VERSION,
        "pass": not errors,
        "corrections": errors,
        "warnings": warnings,
        "asset": {
            "path": str(image_path),
            "sha256": sha256_file(image_path),
            "mode": image.mode,
            "size": list(image.size),
            "expected_size": list(expected_size),
            "biome": biome,
        },
        "metrics": {
            "visible_pixels": visible_count,
            "unique_colors": unique_colors,
            "unique_colors_max": max_unique,
            "palette_metric": "CIEDE2000",
            "palette_samples": len(distances),
            "palette_delta_e_mean": round(delta_mean, 6),
            "palette_delta_e_mean_max": mean_max,
            "palette_delta_e_p95": round(delta_p95, 6),
            "palette_delta_e_p95_max": p95_max,
            "aa_candidate_pixels": aa_count,
            "aa_candidate_ratio": round(aa_ratio, 8),
            "aa_candidate_ratio_max": aa_max,
            "unapproved_dither_blocks": dither_blocks,
            "unapproved_dither_blocks_max": dither_max,
            "outline": outline_metrics,
        },
    }


def audit_file(image_path: Path, spec_path: Path, constitution_path: Path = DEFAULT_CONSTITUTION) -> dict[str, Any]:
    return audit_image(
        image_path.resolve(),
        read_object(spec_path.resolve()),
        read_object(constitution_path.resolve()),
        spec_path.resolve(),
    )


def load_labels(path: Path) -> list[dict[str, Any]]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(value, dict):
        value = value.get("labels")
    if not isinstance(value, list) or any(not isinstance(item, dict) for item in value):
        raise VisualQAError("labels JSON must be a list or an object with a labels list")
    return value


def inject_labels(
    image_path: Path,
    labels: Iterable[dict[str, Any]],
    output_path: Path,
    font_path: Path,
    font_license_path: Path,
    font_size: int,
    font_sha256: str | None = None,
) -> dict[str, Any]:
    if not font_path.is_file():
        raise VisualQAError(f"font file is missing: {font_path}")
    if not font_license_path.is_file():
        raise VisualQAError(f"font license is missing: {font_license_path}")
    actual_font_hash = sha256_file(font_path)
    if font_sha256 and actual_font_hash.lower() != font_sha256.lower():
        raise VisualQAError("font SHA-256 mismatch")

    image = Image.open(image_path).convert("RGBA")
    font = ImageFont.truetype(str(font_path), font_size)
    width, height = image.size
    rendered = 0
    for label in labels:
        text = unicodedata.normalize("NFC", str(label.get("text", ""))).upper()
        if not text:
            raise VisualQAError("label text may not be empty")
        x, y = int(label.get("x", -1)), int(label.get("y", -1))
        fill = parse_hex_color(str(label.get("fill", "#F5C542"))) + (255,)
        shadow = parse_hex_color(str(label.get("shadow", "#000000"))) + (255,)
        mask = Image.new("L", image.size, 0)
        draw = ImageDraw.Draw(mask)
        bounds = draw.textbbox((x, y), text, font=font)
        if bounds[0] < 0 or bounds[1] < 0 or bounds[2] > width or bounds[3] > height:
            raise VisualQAError(f"label is outside canvas: {text}")
        draw.text((x, y), text, font=font, fill=255)
        binary = mask.point(lambda value: 255 if value >= 128 else 0)
        shadow_mask = Image.new("L", image.size, 0)
        if width > 1 and height > 1:
            shadow_mask.paste(binary.crop((0, 0, width - 1, height - 1)), (1, 1))
        image.paste(shadow, (0, 0, width, height), shadow_mask)
        image.paste(fill, (0, 0, width, height), binary)
        rendered += 1
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path, format="PNG", optimize=False)
    return {
        "ok": True,
        "labels": rendered,
        "output": str(output_path),
        "output_sha256": sha256_file(output_path),
        "font_sha256": actual_font_hash,
        "font_license": str(font_license_path),
        "anti_aliased_glyph_mask": False,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    audit = subparsers.add_parser("audit", help="Audit one image against a JSON asset spec")
    audit.add_argument("image", type=Path)
    audit.add_argument("spec", type=Path)
    audit.add_argument("--constitution", type=Path, default=DEFAULT_CONSTITUTION)
    audit.add_argument("--report", type=Path)

    inject = subparsers.add_parser("inject", help="Inject uppercase labels with a licensed font")
    inject.add_argument("image", type=Path)
    inject.add_argument("labels", type=Path)
    inject.add_argument("output", type=Path)
    inject.add_argument("--font", type=Path, required=True)
    inject.add_argument("--font-license", type=Path, required=True)
    inject.add_argument("--font-size", type=int, default=12)
    inject.add_argument("--font-sha256")
    return parser


def run(argv: Sequence[str] | None = None) -> int:
    arguments = list(argv if argv is not None else sys.argv[1:])
    if arguments and arguments[0] not in {"audit", "inject", "-h", "--help"}:
        arguments.insert(0, "audit")
    args = build_parser().parse_args(arguments)
    try:
        if args.command == "audit":
            result = audit_file(args.image, args.spec, args.constitution)
            text = json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True)
            if args.report:
                args.report.parent.mkdir(parents=True, exist_ok=True)
                args.report.write_text(text + "\n", encoding="utf-8")
            print(text)
            return 0 if result["pass"] else 1
        result = inject_labels(
            args.image,
            load_labels(args.labels),
            args.output,
            args.font,
            args.font_license,
            args.font_size,
            args.font_sha256,
        )
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        return 0
    except (OSError, VisualQAError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(run())
