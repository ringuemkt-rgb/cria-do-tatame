#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(rel: str) -> dict:
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    atlas = load("data/maps/map_atlas_runtime_v1.json")
    world = load("data/world/world_map_v4.json")
    moon = load("data/world/moon_tide_v01.json")
    if atlas.get("shipping") is True:
        errors.append("atlas_shipping_must_be_false")
    pages = [str(p.get("id")) for p in atlas.get("pages", [])]
    if pages != [f"{i:02d}" for i in range(1, 11)]:
        errors.append("atlas_pages_must_be_01_to_10")
    world_pages = [str(p.get("id")) for p in world.get("pages", [])]
    if world_pages != pages:
        errors.append("world_map_pages_mismatch")
    if int(moon.get("cycle_days", 0)) != 8:
        errors.append("moon_cycle_must_be_8")
    if len(moon.get("phases", [])) != 8:
        errors.append("moon_phases_must_be_8")
    forbidden = set(atlas.get("forbidden", []))
    for token in ("second CombatManager", "new autoload", "LLM controlling combat or map frames"):
        if token not in forbidden:
            errors.append(f"missing_forbidden:{token}")
    authorities = atlas.get("authorities", {})
    if authorities.get("travel") != "WorldMapManager":
        errors.append("travel_authority")
    if authorities.get("combat") != "CombatManager":
        errors.append("combat_authority")
    itubera = load("data/maps/pages/map_02_itubera.json")
    if len(itubera.get("life", [])) > 4:
        errors.append("itubera_life_cap")
    profiles = load("data/world/npc_map_profiles_v01.json")
    node_ids = {str(n.get("id")) for n in world.get("nodes", [])}
    for profile in profiles.get("profiles", []):
        home = str(profile.get("home_node", ""))
        if home not in node_ids:
            errors.append(f"unknown_home_node:{profile.get('id')}:{home}")
    if errors:
        print("FAIL")
        for err in errors:
            print(err)
        return 1
    print("OK map_atlas_runtime_v1")
    return 0


if __name__ == "__main__":
    sys.exit(main())
