#!/usr/bin/env python3
"""Validate the eight fighter styles and the integrated skill-tree vertical slice."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
STYLES_PATH = ROOT / "data" / "player" / "fighter_styles_v01.json"
TREE_PATH = ROOT / "data" / "player" / "skill_tree_v02.json"
TECHNIQUES_PATH = ROOT / "data" / "techniques.json"
REGISTRY_PATH = ROOT / "src" / "autoloads" / "DataRegistry.gd"
WORLD_STATE_PATH = ROOT / "src" / "autoloads" / "WorldState.gd"
COMBAT_PATH = ROOT / "src" / "autoloads" / "CombatManager.gd"
LIVE_PATH = ROOT / "src" / "autoloads" / "CriaLiveManager.gd"
RUNTIME_PATH = ROOT / "src" / "career" / "FighterStyleSystem.gd"
SCREEN_PATH = ROOT / "scenes" / "ui" / "StyleProgressionScreen.tscn"
SCREEN_SCRIPT_PATH = ROOT / "scenes" / "ui" / "StyleProgressionScreen.gd"
HUB_PATH = ROOT / "scenes" / "hubs" / "TerreiroDaLuta.gd"
CAREER_PATH = ROOT / "src" / "autoloads" / "CareerLoop.gd"
PROJECT_PATH = ROOT / "project.godot"


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_numeric_map(value: Any, label: str) -> None:
    require(isinstance(value, dict), f"{label} must be an object")
    for key, number in value.items():
        require(isinstance(key, str) and key, f"{label} contains an invalid key")
        require(isinstance(number, (int, float)) and not isinstance(number, bool), f"{label}.{key} must be numeric")


def main() -> int:
    styles = load_json(STYLES_PATH)
    tree = load_json(TREE_PATH)
    techniques = load_json(TECHNIQUES_PATH).get("techniques", [])
    technique_ids = {str(item.get("id", "")) for item in techniques if isinstance(item, dict)}
    technique_families = {
        str(item.get("family", item.get("familia", "")))
        for item in techniques
        if isinstance(item, dict)
    }

    require(styles.get("$schema") == "fighter_styles_v1", "invalid fighter style schema")
    require(styles.get("default_style_id") == "pressao", "Ruan must start from the canonical pressure identity")
    require(styles.get("progression_currency") == "skill_points", "styles must use the existing save currency")
    affinity_policy = styles.get("faction_affinity_policy", {})
    require(affinity_policy.get("narrative_reaction_only") is True, "faction affinity must remain narrative")
    require(affinity_policy.get("does_not_change_membership") is True, "styles cannot change faction membership")

    expected_style_ids = {"fluxo", "anaconda", "magnata", "comunidade", "professor", "idolo", "pressao", "alfa"}
    style_list = styles.get("styles", [])
    style_ids = {str(item.get("id", "")) for item in style_list if isinstance(item, dict)}
    require(len(style_list) == 8 and style_ids == expected_style_ids, "the style wheel must contain exactly eight canonical candidates")
    require(len({str(item.get("color", "")) for item in style_list}) == 8, "style colors must be unique")

    valid_branches = {"tecnica", "controle", "mental", "fisico"}
    for style in style_list:
        style_id = str(style.get("id", ""))
        require(re.fullmatch(r"#[0-9A-Fa-f]{6}", str(style.get("color", ""))) is not None, f"invalid color for {style_id}")
        require(style.get("faction_affinity") in {"LEM", "NTM", "ALE"}, f"invalid affinity for {style_id}")
        require(style.get("primary_branch") in valid_branches, f"invalid primary branch for {style_id}")
        requirements = style.get("requirements", {})
        require(isinstance(requirements, dict) and requirements, f"missing requirements for {style_id}")
        for branch_id, points in requirements.items():
            require(branch_id in valid_branches and 0 <= int(points) <= 10, f"invalid requirement for {style_id}:{branch_id}")
        signatures = style.get("signature_techniques", [])
        require(2 <= len(signatures) <= 3, f"{style_id} must expose two or three signatures")
        require(set(signatures) <= technique_ids, f"{style_id} references a technique outside the active catalog")
        require_numeric_map(style.get("starting_resources", {}), f"{style_id}.starting_resources")
        require_numeric_map(style.get("family_chance_bonus", {}), f"{style_id}.family_chance_bonus")
        require(set(style.get("family_chance_bonus", {})) <= technique_families, f"{style_id} references an unknown technique family")
        require_numeric_map(style.get("post_combat", {}), f"{style_id}.post_combat")
        live = style.get("cria_live", {})
        require(isinstance(live, dict) and str(live.get("recommended_tone", "")), f"{style_id} lacks a Cria Live profile")

    limits = styles.get("runtime_limits", {})
    require(float(limits.get("family_chance_bonus_cap", 1.0)) <= 0.12, "style chance cap exceeds deterministic budget")
    require(float(limits.get("win_money_multiplier_cap", 9.0)) <= 1.2, "style economy multiplier exceeds 1.2")
    require(float(limits.get("reputation_bonus_cap", 9.0)) <= 3.0, "style reputation bonus exceeds 3")

    require(tree.get("$schema") == "skill_tree_v2", "invalid skill-tree schema")
    require(tree.get("currency") == "skill_points", "skill tree must spend WorldState.skill_points")
    require(tree.get("state_key") == "skill_tree_v2_levels", "skill tree state key changed without migration")
    branches = tree.get("branches", [])
    require(len(branches) == 4, "skill tree must expose four branches")
    require({str(item.get("id", "")) for item in branches} == valid_branches, "skill-tree branches do not match the style contract")
    node_ids: set[str] = set()
    for branch in branches:
        nodes = branch.get("nodes", [])
        require(len(nodes) == 4, f"branch {branch.get('id')} must expose four nodes")
        for node in nodes:
            node_id = str(node.get("id", ""))
            require(node_id and node_id not in node_ids, f"duplicate skill node: {node_id}")
            node_ids.add(node_id)
            require(int(node.get("max_level", 0)) == 10, f"{node_id} must have ten levels")
            require(int(node.get("cost_per_level", 0)) == 1, f"{node_id} must spend one existing skill point")
            effects = node.get("effects_per_level", {})
            require(set(effects) <= {"starting_resources", "family_chance_bonus"}, f"unsupported runtime effect in {node_id}")
            for group, values in effects.items():
                require_numeric_map(values, f"{node_id}.{group}")
            require(set(effects.get("family_chance_bonus", {})) <= technique_families, f"{node_id} references an unknown family")
    require(len(node_ids) == 16, "skill tree must contain exactly sixteen nodes")

    texts = {
        "registry": REGISTRY_PATH.read_text(encoding="utf-8"),
        "world": WORLD_STATE_PATH.read_text(encoding="utf-8"),
        "combat": COMBAT_PATH.read_text(encoding="utf-8"),
        "live": LIVE_PATH.read_text(encoding="utf-8"),
        "runtime": RUNTIME_PATH.read_text(encoding="utf-8"),
        "screen": SCREEN_PATH.read_text(encoding="utf-8"),
        "screen_script": SCREEN_SCRIPT_PATH.read_text(encoding="utf-8"),
        "hub": HUB_PATH.read_text(encoding="utf-8"),
        "career": CAREER_PATH.read_text(encoding="utf-8"),
        "project": PROJECT_PATH.read_text(encoding="utf-8"),
    }
    require('"fighter_styles"' in texts["registry"] and '"skill_tree_v2"' in texts["registry"], "DataRegistry does not load style progression")
    require('"story_flags": story_flags' in texts["world"] and 'story_flags = data.get("story_flags"' in texts["world"], "style state is not covered by save roundtrip")
    require("WorldState.skill_points" in texts["runtime"] and "skill_tree_v2_levels" in texts["runtime"], "runtime bypasses existing progression state")
    require("apply_starting_resources" in texts["combat"] and "get_family_chance_bonus" in texts["combat"], "CombatManager does not consume styles")
    require("get_post_combat_modifiers" in texts["combat"], "style rewards are not integrated")
    require("get_cria_live_profile" in texts["live"] and '"style_id"' in texts["live"], "Cria Live does not react to style")
    require("StyleProgressionScreen.tscn" in texts["hub"], "Terreiro does not expose progression")
    require("WorldState.skill_points += 1" in texts["career"], "the mandatory Terreiro training loop cannot earn skill points")
    require("purchase_node" in texts["screen_script"] and "set_active_style" in texts["screen_script"], "progression screen is not interactive")
    require("custom_minimum_size = Vector2(150, 52)" in texts["screen"], "progression screen lacks a 48px+ touch target")
    require('FighterStyleSystem="' not in texts["project"], "fighter styles must not create a new autoload")

    serialized = json.dumps({"styles": styles, "tree": tree}, ensure_ascii=False)
    require("cria_points" not in serialized, "mockup-only cria_points leaked into runtime data")
    print(
        "[fighter-styles] ok: eight styles, four branches, sixteen nodes, "
        "existing technique/save/economy IDs and combat/Cria Live/UI consumers validated"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
