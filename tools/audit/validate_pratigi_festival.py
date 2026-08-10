#!/usr/bin/env python3
"""Validate the Pratigi parallel festival vertical slice and its safety contracts."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ARENAS_PATH = ROOT / "data" / "arenas.json"
CONFIG_PATH = ROOT / "data" / "arenas" / "pratigi_festival_v01.json"
HUBS_PATH = ROOT / "data" / "world" / "hubs_dense_v01.json"
SCENE_PATH = ROOT / "scenes" / "combat" / "arenas" / "PratigiFestivalArena.tscn"
SCENE_SCRIPT_PATH = ROOT / "scenes" / "combat" / "arenas" / "PratigiFestivalArena.gd"
DIRECTOR_PATH = ROOT / "src" / "combat" / "arena" / "ClandestineEventDirector.gd"
PROJECT_PATH = ROOT / "project.godot"


def load_json(path: Path) -> dict:
    """Load one JSON object or fail with a useful path."""
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return data


def require(condition: bool, message: str) -> None:
    """Raise an assertion with a concise validation error."""
    if not condition:
        raise AssertionError(message)


def main() -> int:
    """Run the Pratigi arena contract validation."""
    arenas = load_json(ARENAS_PATH).get("arenas", [])
    by_id = {str(item.get("id", "")): item for item in arenas}
    config = load_json(CONFIG_PATH)
    event_destinations = load_json(HUBS_PATH).get("event_destinations", {})

    require("praia_de_pratigi" in by_id, "canonical Pratigi base arena is missing")
    require("praia_de_pratigi_festival" in by_id, "festival arena variant is missing")
    festival = by_id["praia_de_pratigi_festival"]
    require(
        festival.get("parallel_variant_of") == "praia_de_pratigi",
        "festival must remain a parallel variant of canonical Pratigi",
    )
    require(festival.get("fictional_event") is True, "festival must be explicitly fictional")
    require(
        festival.get("officially_sanctioned") is False,
        "parallel festival cannot masquerade as an official circuit",
    )
    require(
        festival.get("referee_role") == "community_mediator",
        "clandestine event needs a tap-enforcing community mediator",
    )

    policy = config.get("content_policy", {})
    betting = config.get("betting", {})
    heat = config.get("heat", {})
    require(policy.get("real_money_gambling") is False, "real-money gambling must stay disabled")
    require(policy.get("authority_evasion_gameplay") is False, "authority evasion gameplay is forbidden")
    require(policy.get("technical_stoppage_required") is True, "technical stoppage is mandatory")
    require(betting.get("real_money_allowed") is False, "betting may use only internal currency")
    require(betting.get("purchase_with_real_money") is False, "stakes cannot be bought with real money")
    require(0 <= int(betting.get("maximum_stake", -1)) <= 150, "stake cap must remain bounded")
    require(
        0.0 < float(heat.get("warning_threshold", 0.0))
        < float(heat.get("interdiction_threshold", 0.0))
        <= 100.0,
        "heat thresholds must be ordered inside 0..100",
    )

    destination = event_destinations.get("pratigi_festival", {})
    require(
        destination.get("entry_scene") == "res://scenes/combat/arenas/PratigiFestivalArena.tscn",
        "Pratigi event destination must consume the scene",
    )
    require(int(destination.get("unlock_act", 0)) == 2, "Pratigi parallel route must remain an Act 2 unlock")
    require("activities" not in destination, "event destination cannot advertise unimplemented hub activities")

    for path in [SCENE_PATH, SCENE_SCRIPT_PATH, DIRECTOR_PATH]:
        require(path.is_file(), f"missing runtime file: {path.relative_to(ROOT)}")
    scene_text = SCENE_PATH.read_text(encoding="utf-8")
    for node_name in [
        "ArenaBackdrop",
        "AnimatedWaterLine",
        "BlueCorner",
        "GoldCorner",
        "CommunityReferee",
        "DJStage",
        "RaveCrowd",
        "CrowdChant",
        "EventDirector",
        "EventHUD",
        "InterdictionOverlay",
    ]:
        require(f'name="{node_name}"' in scene_text, f"scene is missing {node_name}")

    project_text = PROJECT_PATH.read_text(encoding="utf-8")
    require("ClandestineEventDirector=" not in project_text, "event director must stay scene-local")
    require("PratigiFestivalArena=" not in project_text, "arena must not become an autoload")

    print("[pratigi-festival] ok: data, scene, safety, map consumer and scope validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
