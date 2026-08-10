#!/usr/bin/env python3
"""Validate the visual, paired-animation and combat-flow production protocol."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PROTOCOL_PATH = ROOT / "data" / "visual" / "visual_gameplay_protocol_v01.json"
CANON_PATH = ROOT / "data" / "production" / "canon_contract_v4_1.json"
SUPREME_PATH = ROOT / "data" / "production" / "supreme_build_contract_v01.json"
MANIFEST_PATH = ROOT / "data" / "visual" / "production_manifest_v02.json"
ARENA_ANIMATION_PATH = ROOT / "data" / "visual" / "arena_animation_flow_v01.json"
BOM_PATH = ROOT / "data" / "production" / "visual_asset_bom_v01.json"
BRIEFS_PATH = ROOT / "data" / "visual" / "vertical_slice_asset_briefs_v01.json"
PROMPT_BUILDER_PATH = ROOT / "tools" / "visual" / "build_asset_prompt.py"
THEME_PATH = ROOT / "src" / "ui" / "CriaVisualTheme.gd"
TACTICAL_HUD_PATH = ROOT / "scenes" / "ui" / "CombatTacticalHUD.gd"
COMBAT_SCENE_PATH = ROOT / "scenes" / "combat" / "CombatArenaBase.tscn"
PROJECT_PATH = ROOT / "project.godot"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def project_viewport() -> list[int]:
    text = PROJECT_PATH.read_text(encoding="utf-8")
    width = re.search(r"window/size/viewport_width=(\d+)", text)
    height = re.search(r"window/size/viewport_height=(\d+)", text)
    require(width is not None and height is not None, "project viewport is not explicit")
    return [int(width.group(1)), int(height.group(1))]


def main() -> int:
    protocol = load_json(PROTOCOL_PATH)
    canon = load_json(CANON_PATH)
    supreme = load_json(SUPREME_PATH)
    manifest = load_json(MANIFEST_PATH)
    arena_animation = load_json(ARENA_ANIMATION_PATH)
    bom = load_json(BOM_PATH)
    briefs = load_json(BRIEFS_PATH)

    require(protocol.get("$schema") == "visual_gameplay_protocol_v1", "invalid visual protocol schema")
    require(protocol.get("status") == "active_production_contract", "visual protocol is not active")

    authorities = protocol.get("authorities", {})
    for relative in authorities.values():
        require((ROOT / str(relative)).is_file(), f"missing visual authority: {relative}")

    policy = protocol.get("reference_policy", {})
    require(policy.get("references_are_shipping_assets") is False, "reference board cannot be shipping art")
    require(policy.get("copy_pixels_into_shipping") is False, "reference pixels cannot be copied into shipping")
    require(policy.get("human_art_direction_required") is True, "human art direction gate is required")

    references = protocol.get("reference_board", [])
    require(len(references) == 10, "the approved direction board must inventory exactly 10 references")
    reference_ids = {str(item.get("id", "")) for item in references}
    require(len(reference_ids) == 10, "reference ids must be unique")
    for item in references:
        require(re.fullmatch(r"[0-9a-f]{64}", str(item.get("sha256", ""))) is not None, "invalid reference sha256")
        require(item.get("detected_container") == "JPEG", "current reference board must retain detected JPEG provenance")
        require(item.get("shipping_ready") is False, "reference image promoted without provenance/QA")
        dimensions = item.get("dimensions", [])
        require(len(dimensions) == 2 and min(int(value) for value in dimensions) >= 720, "reference resolution is too small")

    style = protocol.get("house_style", {})
    require(style.get("runtime_viewport") == project_viewport(), "visual viewport differs from project.godot")
    require(style.get("pixel_filter") == "nearest", "pixel art must use nearest filtering")
    palette = style.get("palette", {})
    required_colors = {"ink", "frame_gold", "honor_gold", "tatame_blue", "conflict_red", "focus_violet", "respect_green"}
    require(required_colors <= set(palette), "semantic palette is incomplete")
    for value in palette.values():
        require(re.fullmatch(r"[0-9A-F]{6}", str(value)) is not None, f"invalid palette color: {value}")
    metrics = style.get("metrics", {})
    require(int(metrics.get("touch_target_min_px", 0)) >= 48, "touch targets must be at least 48 px")
    require(float(metrics.get("body_clear_zone_width_ratio", 0.0)) >= 0.50, "fighter clear zone must retain half the screen")
    typography = style.get("typography", {})
    require(typography.get("generated_image_text_forbidden") is True, "generated art cannot bake UI text")
    require(typography.get("runtime_text_nodes_required") is True, "UI text must remain a runtime node")

    filters = protocol.get("canonical_filters", {})
    require(filters.get("protagonist_id") == supreme.get("canon", {}).get("protagonist_id"), "visual protagonist breaks canon")
    expected_factions = [item.get("id") for item in canon.get("active_factions_future_domain", [])]
    require(filters.get("active_factions") == expected_factions, "visual protocol introduces a non-canonical faction")
    require(filters.get("offline_critical_gameplay") is True, "critical gameplay must remain offline")
    require(filters.get("real_money_betting") is False, "real-money betting is forbidden")
    require(filters.get("mandatory_online_progression") is False, "online progression cannot be mandatory")
    require(filters.get("fourth_active_faction") is False, "fourth active faction is forbidden")
    require(filters.get("graphic_injury") is False, "graphic injury conflicts with the safe combat contract")

    screens = protocol.get("screen_contracts", {})
    required_screens = {"main_menu", "terreiro_hub", "world_map", "combat", "cria_live", "deck_builder", "arena_briefing"}
    require(required_screens <= set(screens), "screen contract is incomplete")
    for screen_id, screen in screens.items():
        require(set(screen.get("reference_ids", [])) <= reference_ids, f"{screen_id} uses an unknown reference")
        require(screen.get("primary_task"), f"{screen_id} has no primary task")
        if str(screen.get("status", "")).startswith("integrated"):
            relative = str(screen.get("runtime_scene", ""))
            require(relative and (ROOT / relative).is_file(), f"integrated screen is missing: {screen_id}")

    visual_flow = protocol.get("combat_visual_flow", {})
    steps = visual_flow.get("tactical_steps", [])
    require([item.get("id") for item in steps] == ["grip", "base", "takedown", "control", "finish"], "tactical flow order changed")
    require(visual_flow.get("submission_phases") == supreme.get("combat_contract", {}).get("submission_phases"), "submission phases differ from supreme contract")
    require(visual_flow.get("simulation_may_read_presentation") is False, "presentation cannot change simulation")

    image_steps = protocol.get("image_creation_protocol", {}).get("steps", [])
    require(len(image_steps) == 9 and image_steps[-1] == "reference_side_by_side_and_human_approval", "image workflow must end in visual comparison and approval")
    evidence = protocol.get("image_creation_protocol", {}).get("quality_evidence", {})
    require(evidence.get("retry_limit_is_not_quality_guarantee") is True, "visual retry limit was misrepresented as a guarantee")
    require("visual_fidelity" in evidence.get("automation_cannot_certify", []), "automation must not certify visual fidelity")
    require("reference_and_runtime_capture_same_viewport_side_by_side" in evidence.get("human_checks", []), "side-by-side visual review is missing")

    require(bom.get("$schema") == "visual_asset_bom_v1", "invalid visual BOM")
    require(bom.get("counting_unit") == "approved_asset_pack", "visual BOM must count packs, not arbitrary files")
    require(bom.get("file_count_claimed") is False, "visual BOM makes an unsupported file-count claim")
    target_map = {str(item.get("id", "")): int(item.get("target", 0)) for item in bom.get("targets", [])}
    content_targets = supreme.get("content_targets", {})
    require(target_map.get("character_pack") == content_targets.get("characters"), "character BOM differs from supreme target")
    require(target_map.get("paired_technique_pack") == content_targets.get("paired_bjj_techniques"), "technique BOM differs from supreme target")
    require(target_map.get("arena_pack") == content_targets.get("arenas"), "arena BOM differs from supreme target")
    require(target_map.get("ui_screen") == content_targets.get("ui_screens"), "UI BOM differs from supreme target")
    require(target_map.get("sfx_pack") == content_targets.get("sfx"), "SFX BOM differs from supreme target")

    require(briefs.get("$schema") == "visual_asset_briefs_v1" and briefs.get("shipping_ready") is False, "visual briefs were promoted prematurely")
    brief_ids = set()
    for brief in briefs.get("briefs", []):
        brief_id = str(brief.get("id", ""))
        require(brief_id and brief_id not in brief_ids, "visual brief IDs must be unique")
        brief_ids.add(brief_id)
        require(set(brief.get("reference_ids", [])) <= reference_ids, f"{brief_id} uses an unknown reference")
        require(set(brief.get("palette_tokens", [])) <= set(palette), f"{brief_id} uses an unknown palette token")
        require("visible_words" in brief.get("forbidden", []), f"{brief_id} allows generated text")
        require(brief.get("required_review"), f"{brief_id} lacks human review gates")
    require(PROMPT_BUILDER_PATH.is_file(), "visual prompt builder is missing")

    paired = protocol.get("paired_animation_protocol", {})
    require(paired.get("phases") == supreme.get("combat_contract", {}).get("paired_animation_phases"), "paired animation phases differ from supreme contract")
    require(paired.get("sprite_clip_fps") == arena_animation.get("runtime_policy", {}).get("sprite_clip_fps"), "animation FPS profiles conflict")
    required_pair_outputs = set(supreme.get("asset_pack_contracts", {}).get("paired_technique", []))
    require(required_pair_outputs <= set(paired.get("required_outputs", [])), "paired animation package is incomplete")
    require("bjj_human_review" in paired.get("qa_gates", []), "BJJ human review gate missing")
    require("android_visual_test" in paired.get("qa_gates", []), "Android visual gate missing")

    audio = protocol.get("audio_protocol", {})
    require(audio.get("runtime_authority") == canon.get("runtime_authorities", {}).get("audio"), "visual protocol duplicates AudioManager")
    require(audio.get("streaming_dependency") is False, "audio cannot depend on streaming")
    require(audio.get("critical_information_requires_visual_pair") is True, "critical sound needs a visual equivalent")

    require(protocol.get("production_states") == [
        "specified", "implemented", "integrated", "validated_automatically", "human_or_device_tested", "release_ready"
    ], "artifact states changed")
    require(manifest.get("visual_style", {}).get("name") == style.get("name"), "visual style name conflicts with production manifest")

    for path in [THEME_PATH, TACTICAL_HUD_PATH, COMBAT_SCENE_PATH]:
        require(path.is_file(), f"missing runtime consumer: {path.relative_to(ROOT)}")
    require("visual_gameplay_protocol_v01.json" in THEME_PATH.read_text(encoding="utf-8"), "theme does not consume visual protocol")
    require("CombatTacticalHUD" in COMBAT_SCENE_PATH.read_text(encoding="utf-8"), "combat scene does not integrate tactical HUD")

    print("[visual-gameplay] ok: 10 references, 7 screen contracts, canonical UI tokens, paired animation/audio gates and combat HUD consumer")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
