#!/usr/bin/env python3
"""Fail-closed checks for canonical full-roster exhibition scaffolding."""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(relative: str) -> dict:
    data = json.loads((ROOT / relative).read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Invalid JSON object: {relative}")
    return data


def audit() -> list[str]:
    errors = []
    roster = load("data/combat/roster_v3.json")
    game_chars = load("data/characters.json")
    techniques = load("data/techniques.json")
    profiles = load("data/combat/fighter_profiles_universal_v1.json")
    bridge = load("data/combat/technique_identity_bridge_universal_v1.json")
    shadow = load("data/combat/combat_manager_bjj_shadow_map_v1.json")
    roster_by_id = {c["id"]: c for c in roster["fighters"]}
    legacy_by_id = {x["id"]: x for x in techniques["techniques"]}
    canon_char = {x["id"]: x for x in game_chars["characters"]}
    if len(roster_by_id) != len(roster["fighters"]) or roster["count"] != len(roster["fighters"]):
        errors.append("roster duplicates or wrong count")
    if len(profiles.get("profiles", {})) != roster["count"] or set(profiles["profiles"]) != set(roster_by_id):
        errors.append("fighter profiles do not cover canonical roster")
    if profiles.get("shipping") is not False or profiles.get("status") != "EXHIBITION_PREVIEW_UNCALIBRATED":
        errors.append("profiles shipping/status invalid")
    for ident, item in profiles.get("profiles", {}).items():
        canon = roster_by_id.get(ident, {})
        if canon.get("display_name") != item.get("display_name") or item.get("signature_trigger") != canon.get("signature_trigger"):
            errors.append(f"{ident}: identity/signature drift")
        if item.get("shipping") is not False or item.get("human_approved") is not False:
            errors.append(f"{ident}: unapproved profile cannot ship")
        repertoire = item.get("technique_repertoire", [])
        if not repertoire or len(repertoire) != len(set(repertoire)) or not set(repertoire).issubset(legacy_by_id):
            errors.append(f"{ident}: invalid repertoire")
        if not set(item.get("preferred_actions", [])).issubset(repertoire):
            errors.append(f"{ident}: AI tries unknown repertoire")
        for action_id in repertoire:
            action = legacy_by_id[action_id]
            owner = action.get("dono", action.get("owner", "qualquer"))
            if owner not in ("", "qualquer", ident):
                errors.append(f"{ident}: owner lock violated {action_id}")
        fields = item.get("attributes", {})
        if len(fields) < 10 or any(type(v) not in (int, float) or not 0 <= v <= 120 for v in fields.values()):
            errors.append(f"{ident}: invalid attributes")
        source = canon_char.get(ident, {}).get("stats")
        if source:
            for name, original in source.items():
                if name in fields and original != fields[name]:
                    errors.append(f"{ident}: legacy stats overridden {name}")
        for key in ("aggression", "patience", "risk", "counter_bias"):
            v = item.get("tactical_ai", {}).get(key)
            if type(v) not in (float, int) or not 0.0 <= v <= 1.0:
                errors.append(f"{ident}: {key} invalid")
    if bridge.get("shipping") is not False or len(bridge.get("techniques", {})) != len(legacy_by_id) or set(bridge["techniques"]) != set(legacy_by_id):
        errors.append("bridge coverage/shipping broken")
    for ident, source in bridge.get("techniques", {}).items():
        live = legacy_by_id[ident]
        if source.get("legacy_id") != ident or source.get("legacy_from") != live.get("entry_state") or source.get("legacy_to") != live.get("exit_state"):
            errors.append(f"bridge {ident}: legacy state drift")
        official = shadow["legacy_action_map"].get(ident)
        if official and (source.get("bjj_kg_id") != official.get("canonical") or source.get("known_semantic_delta") != official.get("known_delta")):
            errors.append(f"bridge {ident}: shadow mapping contradicted")
    return errors


if __name__ == "__main__":
    failures = audit()
    for error in failures:
        print("FAIL:", error)
    print(f"{'FAIL' if failures else 'PASS universal combat candidate'}: {len(failures)} error(s)")
    raise SystemExit(bool(failures))
