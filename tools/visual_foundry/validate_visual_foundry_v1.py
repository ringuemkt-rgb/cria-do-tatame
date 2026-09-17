#!/usr/bin/env python3
"""Validate Visual Foundry v1 contracts against the canonical production manifest."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "data/visual/production_manifest_v02.json"
PROFILE = ROOT / "data/visual/visual_foundry_profile_v1.json"
TOOL_REGISTRY = ROOT / "tools/visual_foundry/tool_registry_v1.json"
QUEUE_BUILDER = ROOT / "tools/visual_foundry/build_foundry_queue.py"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def fail(message: str) -> None:
    raise AssertionError(message)


def main() -> int:
    for path in (MANIFEST, PROFILE, TOOL_REGISTRY, QUEUE_BUILDER):
        if not path.exists():
            fail(f"missing required file: {path.relative_to(ROOT)}")

    manifest = load(MANIFEST)
    profile = load(PROFILE)
    registry = load(TOOL_REGISTRY)

    if profile.get("source_manifest") != "data/visual/production_manifest_v02.json":
        fail("visual foundry must point to canonical production manifest v02")

    style = manifest.get("visual_style", {})
    sprite = profile.get("sprite", {})

    expected_pairs = {
        "combat_height_px": style.get("combat_sprite_height_px"),
        "hub_cell_px": style.get("hub_sprite_cell_px"),
        "hub_directions": style.get("hub_directions"),
        "grid_px": style.get("grid_px"),
        "texture_filter": style.get("texture_filter"),
        "outline_px": style.get("outline_px"),
        "rim_light_px": style.get("rim_light_px"),
    }
    for key, expected in expected_pairs.items():
        if sprite.get(key) != expected:
            fail(f"profile mismatch for {key}: {sprite.get(key)!r} != {expected!r}")

    tool_policy = profile.get("tool_policy", {})
    if tool_policy.get("blender", {}).get("status") != "preferred":
        fail("Blender must remain the preferred neutral DCC for this pipeline")

    expected_tools = {"blender", "triposg", "triposr", "trellis2", "unirig", "instant_meshes", "quadriflow"}
    registry_tools = {item.get("id"): item for item in registry.get("tools", [])}
    if set(registry_tools) != expected_tools:
        fail(f"tool registry ids mismatch: {sorted(registry_tools)}")

    for tool in expected_tools:
        profile_status = tool_policy.get(tool, {}).get("status")
        registry_status = registry_tools[tool].get("status")
        if profile_status != registry_status:
            fail(f"status drift for {tool}: profile={profile_status!r}, registry={registry_status!r}")
        if registry_tools[tool].get("runtime_dependency") is not False:
            fail(f"{tool} must not be a runtime dependency")

    for tool in expected_tools - {"blender"}:
        if tool_policy.get(tool, {}).get("status") not in {"candidate", "approved"}:
            fail(f"external tool {tool} must be explicitly candidate or approved")

    required_gates = {
        "license_provenance",
        "identity_lock",
        "stable_scale",
        "stable_pivot",
        "paired_animation_sync",
        "sprite_forge_validation",
        "godot_scene_integration",
        "mobile_performance",
    }
    gates = profile.get("gates", {})
    missing_gates = sorted(name for name in required_gates if gates.get(name) is not True)
    if missing_gates:
        fail(f"missing mandatory gates: {', '.join(missing_gates)}")

    characters = manifest.get("characters", [])
    character_ids = [item.get("id") for item in characters]
    if len(character_ids) != len(set(character_ids)):
        fail("duplicate character ids in canonical manifest")

    techniques = manifest.get("paired_techniques", [])
    technique_ids = [item.get("id") for item in techniques]
    if len(technique_ids) != len(set(technique_ids)):
        fail("duplicate paired technique ids in canonical manifest")

    arenas = manifest.get("arenas", [])
    arena_ids = [item.get("id") for item in arenas]
    if len(arena_ids) != len(set(arena_ids)):
        fail("duplicate arena ids in canonical manifest")

    ui_screens = manifest.get("ui_screens", [])
    if len(ui_screens) != len(set(ui_screens)):
        fail("duplicate UI screen ids in canonical manifest")

    if not characters or not techniques or not arenas or not ui_screens:
        fail("canonical graphic scope must include characters, paired techniques, arenas and UI")

    print(
        "Visual Foundry v1 contract OK — "
        f"{len(characters)} characters, {len(techniques)} paired techniques, "
        f"{len(arenas)} arenas, {len(ui_screens)} UI screens"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
