#!/usr/bin/env python3
"""Fail-closed validator for the optional God Mode AI Sprite Forge adapter."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
ADAPTER = ROOT / "data/visual/godmode_sprite_adapter_v1.json"
REGISTRY = ROOT / "data/production/external_tool_registry_v1.json"

REQUIRED_TOOLS = {
    "list_actions",
    "list_models",
    "upload_image",
    "generate_sprite",
    "get_sprite_result",
    "remove_background",
    "get_bg_removal_result",
    "upscale_animation",
    "get_upscale_result",
}

REQUIRED_PROVENANCE = {
    "asset_id",
    "source_requirement_id",
    "provider_id",
    "provider_interface",
    "provider_action",
    "provider_model_or_tool",
    "provider_revision_or_observation_date",
    "identity_master_id",
    "source_references",
    "input_rights_status",
    "terms_snapshot",
    "raw_output_hash",
    "normalization_evidence",
    "qa_evidence",
    "human_editor",
    "human_approval",
    "rights_status",
    "shipping",
}


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.name} root must be object")
    return value


def main() -> int:
    errors: list[str] = []
    try:
        adapter = load(ADAPTER)
        registry = load(REGISTRY)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(json.dumps({"ok": False, "errors": [str(exc)]}, indent=2))
        return 1

    if adapter.get("status") != "CANDIDATE_AUTHORING_ADAPTER":
        errors.append("adapter status must remain CANDIDATE_AUTHORING_ADAPTER")
    for field in ("shipping", "runtime_dependency", "canon_authority", "combat_authority"):
        if adapter.get(field) is not False:
            errors.append(f"{field} must remain false")

    provider = adapter.get("provider", {})
    if provider.get("id") != "godmodeai_sprite_service":
        errors.append("provider.id must be godmodeai_sprite_service")
    auth = provider.get("authentication", {})
    if auth.get("environment_variable") != "GODMODEAI_API_TOKEN":
        errors.append("auth must use GODMODEAI_API_TOKEN")
    if auth.get("must_not_be_committed") is not True or auth.get("must_not_be_written_to_sidecars") is not True:
        errors.append("token secrecy gates must remain true")
    interfaces = provider.get("interfaces", {})
    if interfaces.get("mcp_endpoint") != "https://www.godmodeai.co/api/mcp":
        errors.append("unexpected God Mode MCP endpoint")

    tools = set(adapter.get("supported_authoring_tools", []))
    missing_tools = sorted(REQUIRED_TOOLS - tools)
    if missing_tools:
        errors.append(f"missing provider tools: {missing_tools}")

    input_gate = adapter.get("input_gate", {})
    if input_gate.get("approved_identity_master_required_for_character_animation") is not True:
        errors.append("identity master must be required")
    if input_gate.get("input_rights_must_be_known") is not True:
        errors.append("input rights must be known")
    if input_gate.get("generic_attack_prompt_may_define_bjj_motion") is not False:
        errors.append("generic attack prompts must never define BJJ motion")
    if input_gate.get("bjj_transition_id_required_for_bjj_animation") is not True:
        errors.append("BJJ animation must require transition id")

    generation = adapter.get("generation_policy", {})
    for key in (
        "raw_provider_output_may_enter_runtime_paths",
        "provider_may_choose_shipping",
        "provider_may_define_canon",
        "provider_may_define_bjj_legality_or_scoring",
        "remote_service_required_for_gameplay",
    ):
        if generation.get(key) is not False:
            errors.append(f"generation_policy.{key} must remain false")
    if generation.get("raw_provider_output_status") != "CANDIDATE":
        errors.append("raw provider output must remain CANDIDATE")
    if generation.get("whole_action_strip_preferred_over_independent_frame_generation") is not True:
        errors.append("whole-strip generation preference must remain enabled")

    normalization = adapter.get("normalization_handoff", {})
    if normalization.get("frame_px") != [128, 128]:
        errors.append("normalized frame must remain 128x128")
    if normalization.get("upright_pivot_px") != [64, 96]:
        errors.append("upright pivot must remain [64, 96]")
    if normalization.get("resampling") != "nearest":
        errors.append("resampling must remain nearest")
    for key in (
        "integer_scale_only",
        "binary_alpha_after_normalization",
        "shared_scale_per_strip",
        "shared_anchor_per_strip",
        "identity_comparison_required",
        "preview_harness_required",
        "godot_runtime_evidence_required_before_promotion",
    ):
        if normalization.get(key) is not True:
            errors.append(f"normalization_handoff.{key} must remain true")

    rights = adapter.get("rights_policy", {})
    if rights.get("provider_terms_guarantee_output_uniqueness") is not False:
        errors.append("provider uniqueness must not be assumed")
    if rights.get("provider_terms_guarantee_non_infringement") is not False:
        errors.append("provider non-infringement must not be assumed")
    if rights.get("cria_rights_review_still_required") is not True:
        errors.append("CRIA rights review must remain required")
    if rights.get("public_share_opt_in_must_remain_false_for_private_cria_assets") is not True:
        errors.append("private CRIA assets must not be public-shared by default")

    provenance = set(adapter.get("required_provenance_fields", []))
    missing_provenance = sorted(REQUIRED_PROVENANCE - provenance)
    if missing_provenance:
        errors.append(f"missing provenance fields: {missing_provenance}")

    promotion = adapter.get("promotion_gate", {})
    if promotion.get("default_shipping") is not False:
        errors.append("default shipping must remain false")
    for key in (
        "requires_sprite_forge_v2_pass",
        "requires_human_visual_review",
        "requires_human_rights_review",
        "requires_biomechanical_review_for_bjj",
        "requires_godot_import_and_runtime_visual_evidence",
        "secret_presence_is_hard_fail",
    ):
        if promotion.get(key) is not True:
            errors.append(f"promotion_gate.{key} must remain true")

    sources = {row.get("id"): row for row in registry.get("sources", []) if isinstance(row, dict)}
    service = sources.get("godmodeai_sprite_service")
    skill = sources.get("godmodeai_sprites_skill")
    if not service:
        errors.append("external tool registry missing godmodeai_sprite_service")
    elif service.get("direct_code_reuse") is not False or service.get("direct_asset_reuse") is not False:
        errors.append("God Mode service must not grant direct code/asset reuse")
    if not skill:
        errors.append("external tool registry missing godmodeai_sprites_skill")
    elif skill.get("revision") != provider.get("official_skill_revision"):
        errors.append("official skill revision drift between adapter and registry")

    result = {"ok": not errors, "errors": errors}
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
