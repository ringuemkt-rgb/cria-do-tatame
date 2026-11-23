#!/usr/bin/env python3
"""Canonical fighter lookup for reusable combat *authoring*.

All IDs are read from data/combat/roster_v3.json. This module never unlocks
playability, authorizes BJJ rules, changes saves, or enables shipping.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ID = re.compile(r"^[a-z][a-z0-9_]*$")


def load_fighters(root: Path = ROOT) -> dict[str, dict]:
    roster = json.loads((root / "data/combat/roster_v3.json").read_text(encoding="utf-8"))
    fighters = roster.get("fighters")
    if not isinstance(fighters, list) or not fighters:
        raise ValueError("canonical roster must provide a nonempty fighters list")
    if roster.get("count") != len(fighters):
        raise ValueError("roster.count disagrees with fighters array; do not invent missing fighters")
    if roster.get("guardrails", {}).get("fictional_archetypes_only") is not True:
        raise ValueError("roster fictional-archetypes guard not enabled")
    result: dict[str, dict] = {}
    for fighter in fighters:
        if not isinstance(fighter, dict):
            raise ValueError("roster fighter must be a JSON object")
        fighter_id = fighter.get("id")
        if not isinstance(fighter_id, str) or not ID.fullmatch(fighter_id):
            raise ValueError(f"invalid roster fighter ID: {fighter_id!r}")
        if fighter_id in result:
            raise ValueError(f"duplicate canonical roster ID: {fighter_id}")
        if not isinstance(fighter.get("display_name"), str) or not fighter["display_name"].strip():
            raise ValueError(f"{fighter_id}: missing display_name")
        if not isinstance(fighter.get("role"), str) or not fighter["role"].strip():
            raise ValueError(f"{fighter_id}: missing role")
        result[fighter_id] = fighter
    return result


def fighter_or_fail(fighter_id: str, root: Path = ROOT) -> dict:
    fighters = load_fighters(root)
    if fighter_id not in fighters:
        raise ValueError(f"fighter {fighter_id!r} is absent from canonical roster")
    return fighters[fighter_id]


def validate_pair(attacker_id: str, defender_id: str, root: Path = ROOT) -> tuple[dict, dict]:
    if attacker_id == defender_id:
        raise ValueError("combat authoring requires two distinct fighter IDs")
    return fighter_or_fail(attacker_id, root), fighter_or_fail(defender_id, root)
