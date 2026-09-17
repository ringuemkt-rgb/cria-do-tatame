#!/usr/bin/env python3
"""Validate Visual Foundry v1 contracts against the canonical production manifest."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "data/visual/production_manifest_v02.json"
PROFILE = ROOT / "data/visual/visual_foundry_profile_v1.json"
QUEUE_BUILDER = ROOT / "tools/visual_foundry/build_foundry_queue.py"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def fail(message: str) -> None:
    raise AssertionError(message)


def main() -> int:
    for path in (MANIFEST, PROFILE, QUEUE_BUILDER):
        if not path.exists():
            fail(f"missing required file: {path.relative_to(ROOT)}")

    manifest = load(MANIFEST)
    profile = load(PROFILE)

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

    candidate_tools = ["triposg", "triposr", "trellis2", "unirig", "instant_meshes", "quadriflow"]
    for tool in candidate_tools:
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
    ids = [item.get("id") for item in characters]
    if len(ids) != len(set(ids)):
        fail("duplicate character ids in canonical manifest")

    techniques = manifest.get("paired_techniques", [])
    technique_ids = [item.get("id") for item in techniques]
    if len(technique_ids) != len(set(technique_ids)):
        fail("duplicate paired technique ids in canonical manifest")

    if not characters:
        fail("canonical manifest has no characters")
    if not techniques:
        fail("canonical manifest has no paired techniques")

    print(
        "Visual Foundry v1 contract OK — "
        f"{len(characters)} characters, {len(techniques)} paired techniques"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
