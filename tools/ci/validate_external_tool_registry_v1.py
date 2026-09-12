#!/usr/bin/env python3
"""Validate external tool/source intake for CRIA DO TATAME.

The registry is research metadata, not permission to copy. This gate blocks direct
code/asset reuse when licensing is missing, non-commercial, conflicting, unknown,
or when the source is explicitly deactivated.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "data/production/external_tool_registry_v1.json"
HEX40 = re.compile(r"^[0-9a-f]{40}$")

CLEAR_CODE_LICENSES = {
    "CLEAR_MIT",
    "CLEAR_APACHE_2_0",
    "CLEAR_APACHE_2_0_METADATA",
    "CLEAR_BSD_2_CLAUSE",
    "CLEAR_BSD_3_CLAUSE",
}

NO_DIRECT_REUSE_PREFIXES = (
    "NO_LICENSE",
    "UNVERIFIED",
    "CONFLICT_",
    "CC_BY_NC",
    "REPO_STRUCTURE_MIT_ASSET_RIGHTS_UNKNOWN",
    "INTERNAL_DEACTIVATED",
)

ADOPTIONS_FORBID_DIRECT_REUSE = {
    "STUDY_AND_REIMPLEMENT_CONCEPTS_ONLY",
    "LOW_PRIORITY_REFERENCE_ONLY",
    "REIMPLEMENT_CONCEPTS_ONLY",
    "REIMPLEMENT_CONCEPTS_PENDING_LICENSE_REVIEW",
    "TAXONOMY_AND_TOOL_REFERENCE_ONLY",
    "DESIGN_PATTERN_REFERENCE_ONLY",
    "COMPARATIVE_DESIGN_REFERENCE_ONLY",
    "BLOCKED_DEACTIVATED",
}


def load() -> dict[str, Any]:
    value = json.loads(REGISTRY.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("external tool registry root must be object")
    return value


def main() -> int:
    errors: list[str] = []
    try:
        registry = load()
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(json.dumps({"ok": False, "errors": [str(exc)]}, indent=2))
        return 1

    if registry.get("status") != "ACTIVE_RESEARCH_REGISTRY":
        errors.append("registry must remain ACTIVE_RESEARCH_REGISTRY")
    policy = registry.get("default_policy", {})
    expected_false = ("runtime_dependency", "shipping_default", "canon_authority")
    for key in expected_false:
        if policy.get(key) is not False:
            errors.append(f"default_policy.{key} must remain false")
    for key in ("pin_revision", "copy_code_only_when_license_clear", "copy_assets_only_when_asset_level_rights_clear", "concept_reimplementation_allowed"):
        if policy.get(key) is not True:
            errors.append(f"default_policy.{key} must remain true")

    sources = registry.get("sources")
    if not isinstance(sources, list) or not sources:
        errors.append("registry has no sources")
        sources = []

    seen: set[str] = set()
    for entry in sources:
        if not isinstance(entry, dict):
            errors.append("source entry is not an object")
            continue
        sid = entry.get("id")
        if not isinstance(sid, str) or not sid:
            errors.append("source has invalid id")
            continue
        if sid in seen:
            errors.append(f"duplicate source id: {sid}")
        seen.add(sid)

        for field in ("kind", "source", "revision", "license_status", "adoption", "direct_code_reuse", "direct_asset_reuse", "cria_roles", "notes"):
            if field not in entry:
                errors.append(f"{sid}: missing {field}")

        license_status = str(entry.get("license_status", ""))
        adoption = str(entry.get("adoption", ""))
        direct_code = entry.get("direct_code_reuse") is True
        direct_asset = entry.get("direct_asset_reuse") is True

        if direct_code and license_status not in CLEAR_CODE_LICENSES:
            errors.append(f"{sid}: direct_code_reuse=true without clear permissive license ({license_status})")
        if license_status.startswith(NO_DIRECT_REUSE_PREFIXES) and (direct_code or direct_asset):
            errors.append(f"{sid}: ambiguous/noncommercial/deactivated source cannot allow direct reuse")
        if adoption in ADOPTIONS_FORBID_DIRECT_REUSE and (direct_code or direct_asset):
            errors.append(f"{sid}: adoption={adoption} forbids direct reuse")

        if adoption == "BLOCKED_DEACTIVATED" and entry.get("cria_roles"):
            errors.append(f"{sid}: deactivated source must have no CRIA roles")

        if entry.get("kind") == "github_repo" and adoption in {
            "PORT_SELECTED_PATTERNS",
            "REIMPLEMENT_CONCEPTS_PENDING_LICENSE_REVIEW",
            "STUDY_AND_REIMPLEMENT_CONCEPTS_ONLY",
            "LOW_PRIORITY_REFERENCE_ONLY",
            "REIMPLEMENT_CONCEPTS_ONLY",
            "TAXONOMY_AND_TOOL_REFERENCE_ONLY",
        }:
            revision = str(entry.get("revision", ""))
            if not HEX40.fullmatch(revision):
                errors.append(f"{sid}: GitHub source must be pinned to immutable 40-char commit SHA")

        if sid == "claude_code_game_studios":
            if license_status != "CLEAR_MIT" or adoption != "PORT_SELECTED_PATTERNS":
                errors.append("Claude Code Game Studios must remain selected-pattern port only under MIT")
        elif sid == "pixellab_mcp":
            if entry.get("kind") != "remote_mcp_service":
                errors.append("PixelLab must remain a remote MCP authoring service")
            if entry.get("source") != "https://api.pixellab.ai/mcp":
                errors.append("PixelLab MCP endpoint must remain the audited official endpoint")
            if adoption != "ADOPTED_EXTERNAL_AUTHORING_PROVIDER":
                errors.append("PixelLab must remain an external authoring provider")
            if direct_code or direct_asset:
                errors.append("PixelLab registry entry must not imply direct upstream code/asset reuse")
            if entry.get("runtime_dependency") is not False or entry.get("shipping_default") is not False or entry.get("canon_authority") is not False:
                errors.append("PixelLab must remain non-runtime, shipping=false and non-canonical")
            auth = entry.get("authentication", {})
            if auth.get("scheme") != "bearer" or auth.get("forbid_repository_token") is not True:
                errors.append("PixelLab bearer token must be secret-store/environment only")
            output_policy = entry.get("output_policy", {})
            if output_policy.get("automatic_shipping") is not False or output_policy.get("human_visual_review_required") is not True:
                errors.append("PixelLab outputs must remain candidate-only and human-reviewed")
            if output_policy.get("model_training_reuse_without_written_permission") is not False:
                errors.append("PixelLab outputs must not be authorized for model training without written permission")
        elif sid == "wolfcha":
            if direct_code or license_status != "CONFLICT_README_MIT_LICENSE_FILE_APACHE_2_0":
                errors.append("Wolfcha must remain no-copy while README/LICENSE discrepancy is unresolved")
        elif sid == "sprite_animator":
            if direct_code or adoption != "REIMPLEMENT_CONCEPTS_ONLY":
                errors.append("Sprite Animator must remain concept-only without separate commercial license")
        elif sid == "blendi_sprite_sheet_creator":
            if direct_code or direct_asset or license_status != "NO_LICENSE_FOUND" or adoption != "STUDY_AND_REIMPLEMENT_CONCEPTS_ONLY":
                errors.append("blendi sprite-sheet-creator must remain pinned no-copy reference until upstream publishes a clear license")
        elif sid == "pixelsrpg_forge":
            if direct_asset or adoption != "TAXONOMY_AND_TOOL_REFERENCE_ONLY":
                errors.append("PixelSRPG Forge assets must remain blocked from direct CRIA use")
        elif sid == "old_cria_android_repo":
            if adoption != "BLOCKED_DEACTIVATED" or direct_code or direct_asset:
                errors.append("old CRIA Android repository must remain deactivated")

    required = {
        "qwen_2512_pixel_art_lora",
        "pixellab_mcp",
        "claude_code_game_studios",
        "wolfcha",
        "cline_qwen_snes_engine",
        "pixel_life_simulator",
        "sprite_animator",
        "blendi_sprite_sheet_creator",
        "pixelsrpg_forge",
        "mia_deepseek_v4_1_html_100",
        "mia_gpt6_astra_html_100",
        "old_cria_android_repo",
    }
    missing = sorted(required - seen)
    if missing:
        errors.append(f"required audited sources missing: {missing}")

    result = {"ok": not errors, "sources": len(sources), "errors": errors}
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
