#!/usr/bin/env python3
"""Dependency-free structural gate for visual QA v2."""

from __future__ import annotations

import ast
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONSTITUTION = ROOT / "data/visual/visual_constitution_v2.json"
TOOL = ROOT / "tools/audit/visual_qa_v2.py"


def main() -> int:
    errors: list[str] = []
    try:
        constitution = json.loads(CONSTITUTION.read_text(encoding="utf-8"))
        source = TOOL.read_text(encoding="utf-8")
        tree = ast.parse(source, filename=str(TOOL))
    except (OSError, json.JSONDecodeError, SyntaxError) as exc:
        print(json.dumps({"ok": False, "errors": [str(exc)]}, indent=2))
        return 1

    if constitution.get("internal_resolution") != [480, 270]:
        errors.append("visual constitution must keep 480x270 internal resolution")
    expected_palettes = {"pratigi", "dique", "lapa", "terreiro", "mapa", "crialive"}
    if set(constitution.get("palettes", {})) != expected_palettes:
        errors.append("visual constitution has an incomplete biome palette catalog")
    defaults = constitution.get("qa_defaults", {})
    if defaults.get("palette_delta_e_mean_max") != 8.0 or defaults.get("palette_delta_e_p95_max") != 12.0:
        errors.append("CIEDE2000 targets must remain mean<=8 and p95<=12")
    if constitution.get("label_policy", {}).get("font_file_and_license_required") is not True:
        errors.append("deterministic labels must require a font file and license")

    functions = {node.name for node in tree.body if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))}
    required = {"delta_e_ciede2000", "anti_alias_candidates", "measure_outline", "audit_image", "inject_labels"}
    if not required.issubset(functions):
        errors.append(f"visual QA is missing functions: {sorted(required - functions)}")
    resize_calls = [
        node for node in ast.walk(tree)
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) and node.func.attr == "resize"
    ]
    if resize_calls:
        errors.append("visual QA must never resize an input as part of validation")
    for fragment in ("CIEDE2000", "outline_mask_required_for_measurement", "font license", "aa_candidate_ratio"):
        if fragment not in source:
            errors.append(f"visual QA source is missing contract fragment: {fragment}")

    result = {"ok": not errors, "errors": errors, "palettes": len(constitution.get("palettes", {}))}
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
