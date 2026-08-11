#!/usr/bin/env python3
"""Validate the inactive canon-v5 world/narrative proposal without activating it."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter, deque
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/production/canon_v5_migration_proposal.json"
MISSIONS = ROOT / "data/missions/campaign_missions_v1.json"
WORLD = ROOT / "data/world/mapa_v3.json"
ARENAS = ROOT / "data/arenas/arenas_12_v3.json"
ROSTER = ROOT / "data/characters/elenco_23_v3.json"
TREE = ROOT / "data/skill_tree/skill_tree_v3.json"
YARN_ROOT = ROOT / "data/dialogues/yarn_drafts"
EXPECTED_YARN = {
    "M06": "M06_a_faixa_e_a_duvida.yarn",
    "M08": "M08_helena_recruta.yarn",
    "M23": "M23_racha.yarn",
    "M31": "M31_vespera.yarn",
    "M36": "M36_ultima_ordem.yarn",
    "M39": "M39_o_ledger.yarn",
}
FORBIDDEN_BRANDS = ("IBJJF", "John Wick", "Hitman", "UFC")


def load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {path}")
    return value


def duplicate_ids(items: list[dict[str, Any]]) -> list[str]:
    counts = Counter(str(item.get("id", "")) for item in items)
    return sorted(key for key, count in counts.items() if not key or count > 1)


def flatten_keys(value: Any) -> list[str]:
    keys: list[str] = []
    if isinstance(value, dict):
        for key, child in value.items():
            keys.append(str(key))
            keys.extend(flatten_keys(child))
    elif isinstance(value, list):
        for child in value:
            keys.extend(flatten_keys(child))
    return keys


def main() -> int:
    errors: list[str] = []
    try:
        contract = load_object(CONTRACT)
        mission_data = load_object(MISSIONS)
        world = load_object(WORLD)
        arena_data = load_object(ARENAS)
        roster = load_object(ROSTER)
        tree = load_object(TREE)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"ok": False, "errors": [str(exc)]}, ensure_ascii=False, indent=2))
        return 1

    if contract.get("status") != "draft_pending_human_canon_migration" or contract.get("effective") is not False:
        errors.append("canon-v5 proposal must stay draft and ineffective")
    runtime_policy = contract.get("runtime_policy", {})
    if runtime_policy.get("runtime_activation") is not False or runtime_policy.get("save_migration") is not False:
        errors.append("proposal may not activate runtime or save migration")

    missions = mission_data.get("missions", [])
    expected_mission_ids = [f"M{number:02d}" for number in range(1, 41)]
    mission_ids = [str(item.get("id", "")) for item in missions]
    if mission_data.get("runtime_active") is not False or mission_data.get("runtime_consumer") is not None:
        errors.append("campaign proposal must have no runtime consumer before canon migration")
    if mission_ids != expected_mission_ids:
        errors.append("campaign missions must be ordered M01..M40")
    if duplicate_ids(missions):
        errors.append(f"duplicate or empty mission IDs: {duplicate_ids(missions)}")
    act_counts = Counter(item.get("act") for item in missions)
    if act_counts != Counter({1: 8, 2: 8, 3: 8, 4: 8, 5: 8}):
        errors.append(f"each act must contain eight missions: {dict(act_counts)}")
    mission_index = {mission_id: index for index, mission_id in enumerate(mission_ids)}
    map_node_ids = {str(node.get("id", "")) for node in world.get("nodes", [])}
    for index, mission in enumerate(missions):
        mission_id = str(mission.get("id", ""))
        for field in ("name", "type", "location_node", "public_objective", "rewards", "gates"):
            if field not in mission:
                errors.append(f"{mission_id} missing {field}")
        if mission.get("location_node") not in map_node_ids:
            errors.append(f"{mission_id} references missing map node {mission.get('location_node')}")
        gates = mission.get("gates", {})
        if not isinstance(gates, dict):
            errors.append(f"{mission_id} gates must be an object")
            continue
        for required in gates.get("requires_missions", []):
            if required not in mission_index or mission_index[required] >= index:
                errors.append(f"{mission_id} has missing or forward requirement {required}")
        for choice in mission.get("choices", []):
            choice_id = str(choice.get("id", ""))
            effects = choice.get("effects", {})
            if not choice_id or not isinstance(effects, dict):
                errors.append(f"{mission_id} has invalid choice")
                continue
            if "tap" in choice_id and float(effects.get("honor", 0)) < 0:
                errors.append(f"{mission_id} penalizes a tap choice")
        source = mission.get("dialogue_source")
        if source and not (ROOT / str(source)).is_file():
            errors.append(f"{mission_id} dialogue source is missing: {source}")

    if mission_data.get("systems", {}).get("submission_safety", {}).get("automatic_submission") is not False:
        errors.append("automatic submission must remain false")
    if mission_data.get("systems", {}).get("betting", {}).get("real_money") is not False:
        errors.append("betting must not use real money")
    ending_ids = {str(item.get("id", "")) for item in mission_data.get("endings", [])}
    if ending_ids != {"root", "idol", "shadow", "double_face", "cria"}:
        errors.append(f"invalid ending catalog: {sorted(ending_ids)}")
    for thread in mission_data.get("threads", []):
        plants = thread.get("plants", [])
        harvests = thread.get("harvests", [])
        if not plants or not harvests:
            errors.append(f"thread {thread.get('id')} needs plants and harvests")
            continue
        if any(item not in mission_index for item in [*plants, *harvests]):
            errors.append(f"thread {thread.get('id')} references missing mission")
        elif min(mission_index[item] for item in harvests) <= min(mission_index[item] for item in plants):
            errors.append(f"thread {thread.get('id')} harvests before it is planted")
    m36 = next((item for item in missions if item.get("id") == "M36"), {})
    if not m36.get("hidden_objective", {}).get("fallback"):
        errors.append("M36 must have a fallback so cover cannot deadlock M39")

    nodes = world.get("nodes", [])
    edges = world.get("edges", [])
    node_ids = [str(item.get("id", "")) for item in nodes]
    if duplicate_ids(nodes):
        errors.append(f"duplicate or empty map node IDs: {duplicate_ids(nodes)}")
    adjacency = {node_id: set() for node_id in node_ids}
    for edge in edges:
        start, end = str(edge.get("from", "")), str(edge.get("to", ""))
        if start not in adjacency or end not in adjacency:
            errors.append(f"map edge references missing node: {start}->{end}")
            continue
        if float(edge.get("cost_criacoin", -1)) < 0 or float(edge.get("time_hours", -1)) < 0:
            errors.append(f"map edge has negative cost/time: {start}->{end}")
        adjacency[start].add(end)
        adjacency[end].add(start)
    if node_ids:
        visited = {node_ids[0]}
        queue = deque([node_ids[0]])
        while queue:
            current = queue.popleft()
            for neighbor in adjacency[current] - visited:
                visited.add(neighbor)
                queue.append(neighbor)
        if visited != set(node_ids):
            errors.append(f"world graph is disconnected: {sorted(set(node_ids) - visited)}")

    arenas = arena_data.get("arenas", [])
    arena_ids = {str(item.get("id", "")) for item in arenas}
    if len(arenas) != 12 or duplicate_ids(arenas):
        errors.append("arena proposal must contain 12 unique arenas")
    allowed_rules = set(arena_data.get("ruleset_ids", []))
    for arena in arenas:
        arena_id = str(arena.get("id", ""))
        if arena.get("municipality_node") not in map_node_ids:
            errors.append(f"{arena_id} references missing municipality node")
        if arena.get("ruleset_id") not in allowed_rules:
            errors.append(f"{arena_id} has invalid ruleset")
        safety = arena.get("safety", {})
        for required_safety in ("level_padded_mat", "protected_boundary", "telegraphs_preserved"):
            if safety.get(required_safety) is not True:
                errors.append(f"{arena_id} missing safety flag {required_safety}")
    for node in nodes:
        for arena_id in node.get("arenas", []):
            if arena_id not in arena_ids:
                errors.append(f"map node {node.get('id')} references missing arena {arena_id}")

    combatants = roster.get("combatants", [])
    if len(combatants) != 23 or duplicate_ids(combatants):
        errors.append("roster proposal must contain 23 unique combatants")
    playable_count = sum(item.get("playable_proposed") is True for item in combatants)
    if playable_count != 18 or roster.get("playable_proposed_count") != 18:
        errors.append(f"roster must expose exactly 18 playable proposals, got {playable_count}")
    allowed_factions = {"ALE", "LEM", "NTM", "NEUTRAL"}
    allowed_styles = set(roster.get("style_ids", []))
    for combatant in combatants:
        if combatant.get("faction_id") not in allowed_factions:
            errors.append(f"{combatant.get('id')} has invalid faction")
        if combatant.get("style_id") not in allowed_styles:
            errors.append(f"{combatant.get('id')} has invalid style")
    if not any(item.get("id") == "oni_da_lapa" and "oni_do_sul" in item.get("aliases", []) for item in combatants):
        errors.append("stable oni_da_lapa ID and proposed oni_do_sul alias must be explicit")

    branches = tree.get("branches", [])
    if tree.get("runtime_active") is not False or tree.get("respec_cost") != 500:
        errors.append("skill tree must stay inactive and use a 500 Criacoin respec proposal")
    if len(branches) != 5 or duplicate_ids(branches):
        errors.append("skill tree proposal must contain five unique branches")
    for branch in branches:
        nodes_in_branch = branch.get("nodes", [])
        if not nodes_in_branch or any(node.get("max_rank") != 3 for node in nodes_in_branch):
            errors.append(f"branch {branch.get('id')} nodes must have three ranks")
        if branch.get("ultimate", {}).get("automatic_submission") is not False:
            errors.append(f"branch {branch.get('id')} ultimate violates tap/escape sovereignty")
    if any("damage" in key.lower() or "dano" in key.lower() for key in flatten_keys(tree)):
        errors.append("skill tree may not model submission damage")

    for title, filename in EXPECTED_YARN.items():
        path = YARN_ROOT / filename
        if not path.is_file():
            errors.append(f"missing Yarn draft {filename}")
            continue
        text = path.read_text(encoding="utf-8")
        if f"title: {title}" not in text or "---" not in text or not text.rstrip().endswith("==="):
            errors.append(f"invalid basic Yarn node structure: {filename}")
        if re.search(r"<<\s*(HONRA|CAPA|FOCO|SOMBRA)\b", text, flags=re.IGNORECASE):
            errors.append(f"Yarn state update must use <<set $variable ...>>: {filename}")
        if ";" in "".join(re.findall(r"<<.*?>>", text)):
            errors.append(f"Yarn commands may not combine statements with semicolons: {filename}")

    proposal_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (CONTRACT, MISSIONS, WORLD, ARENAS, ROSTER, TREE, *sorted(YARN_ROOT.glob("*.yarn")))
    )
    for brand in FORBIDDEN_BRANDS:
        if brand.lower() in proposal_text.lower():
            errors.append(f"real/commercial benchmark name must not enter proposal data: {brand}")

    result = {
        "ok": not errors,
        "errors": errors,
        "counts": {
            "missions": len(missions),
            "acts": len(act_counts),
            "endings": len(ending_ids),
            "map_nodes": len(nodes),
            "map_edges": len(edges),
            "arenas": len(arenas),
            "combatants": len(combatants),
            "playable_proposed": playable_count,
            "skill_branches": len(branches),
            "yarn_drafts": len(EXPECTED_YARN),
        },
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
