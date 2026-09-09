#!/usr/bin/env python3
"""Derive Sprite Forge v2 authoring requirements from CRIA authoritative data.

This script never generates art and never promotes shipping. It materializes what
must eventually exist so character/world/technique coverage cannot be hand-waved.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
POLICY_REL = Path("data/visual/sprite_forge_requirements_v2.json")
CONTRACT_REL = Path("data/visual/sprite_forge_contract_v2.json")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def add_req(rows: list[dict[str, Any]], *, category: str, source_id: str, kind: str,
            priority: int, source_refs: list[str], scope: str = "FULL_GAME",
            blockers: list[str] | None = None, metadata: dict[str, Any] | None = None) -> None:
    row: dict[str, Any] = {
        "requirement_id": f"sprite_v2:{category}:{source_id}:{kind}",
        "category": category,
        "source_id": source_id,
        "kind": kind,
        "priority": priority,
        "scope": scope,
        "status": "pending",
        "shipping": False,
        "source_refs": sorted(set(source_refs)),
        "blockers": sorted(set(blockers or [])),
    }
    if metadata:
        row["metadata"] = metadata
    rows.append(row)


def choose_bjj_graph(policy: dict[str, Any]) -> tuple[dict[str, Any], str, list[str], str]:
    src = policy["sources"]
    full_path = ROOT / src["bjj_full_graph"]
    minimum = policy["technique"]["full_graph_minimum"]
    if full_path.exists():
        full = load_json(full_path)
        positions = full.get("positions", full.get("posicoes", []))
        techniques = full.get("techniques", full.get("tecnicas", []))
        chains = full.get("chains", [])
        if len(positions) >= minimum["positions"] and len(techniques) >= minimum["techniques"] and len(chains) >= minimum["chains"]:
            return full, src["bjj_full_graph"], [], "FULL_GAME"
    slice_path = ROOT / src["bjj_slice_fallback"]
    if not slice_path.exists():
        return {"positions": [], "techniques": [], "chains": []}, src["bjj_slice_fallback"], ["authoritative_bjj_graph_unavailable"], "BLOCKED"
    return load_json(slice_path), src["bjj_slice_fallback"], ["full_bjj_graph_not_complete"], policy["technique"]["slice_graph_scope"]


def derive(root: Path = ROOT) -> dict[str, Any]:
    policy = load_json(root / POLICY_REL)
    contract = load_json(root / CONTRACT_REL)
    rows: list[dict[str, Any]] = []
    blockers: list[dict[str, str]] = []

    roster_path = root / policy["sources"]["roster"]
    arena_path = root / policy["sources"]["arena_info"]
    if not roster_path.exists():
        blockers.append({"code": "roster_missing", "path": policy["sources"]["roster"]})
        roster = {"fighters": []}
    else:
        roster = load_json(roster_path)
    if not arena_path.exists():
        blockers.append({"code": "arena_info_missing", "path": policy["sources"]["arena_info"]})
        arena_info = {"arenas": []}
    else:
        arena_info = load_json(arena_path)

    p1_fighters = set(policy["priority"]["p1_fighters"])
    p1_locations = set(policy["priority"]["p1_locations"])
    char = policy["character"]
    for fighter in roster.get("fighters", []):
        fid = fighter["id"]
        priority = policy["priority"]["p1_priority"] if fid in p1_fighters else policy["priority"]["full_roster_priority"]
        canon_path = root / f"data/chars/canon/{fid}.json"
        local_blockers = [] if canon_path.exists() else ["identity_master_source_missing"]
        refs = [policy["sources"]["roster"]]
        if canon_path.exists():
            refs.append(str(canon_path.relative_to(root)))
        for variant in char["variants"]:
            for kind in (
                char["identity_artifacts"]
                + char["world_locomotion_actions"]
                + char["combat_upright_actions"]
                + char["combat_ground_actions"]
                + char["presentation_artifacts"]
            ):
                add_req(
                    rows,
                    category="character",
                    source_id=fid,
                    kind=f"{variant}:{kind}",
                    priority=priority,
                    source_refs=refs,
                    blockers=local_blockers,
                    metadata={"display_name": fighter.get("display_name"), "role": fighter.get("role"), "variant": variant},
                )

    world_kinds = policy["world_location"]["requirements"]
    for arena in arena_info.get("arenas", []):
        aid = arena["id"]
        priority = policy["priority"]["p1_priority"] if aid in p1_locations else policy["priority"]["world_priority"]
        for kind in world_kinds:
            add_req(
                rows,
                category="world",
                source_id=aid,
                kind=kind,
                priority=priority,
                source_refs=[policy["sources"]["arena_info"]],
                metadata={"municipality": arena.get("mun"), "location_type": arena.get("tipo"), "ecosystem": arena.get("ecossistema")},
            )

    graph, graph_ref, technique_blockers, technique_scope = choose_bjj_graph(policy)
    techniques = graph.get("techniques", graph.get("tecnicas", []))
    if technique_blockers:
        blockers.append({"code": technique_blockers[0], "path": graph_ref})
    for tech in techniques:
        tid = tech.get("id")
        if not tid:
            continue
        for kind in policy["technique"]["requirements"]:
            add_req(
                rows,
                category="technique",
                source_id=tid,
                kind=kind,
                priority=policy["priority"]["technique_priority"],
                source_refs=[graph_ref, policy["sources"]["bjj_completion_gate"]],
                scope=technique_scope,
                blockers=technique_blockers,
                metadata={"from": tech.get("from", tech.get("de")), "to": tech.get("to", tech.get("para")), "type": tech.get("type", tech.get("tipo"))},
            )

    rows.sort(key=lambda r: (r["priority"], r["category"], r["source_id"], r["kind"]))
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["category"]] = counts.get(row["category"], 0) + 1

    return {
        "$schema": "cria.sprite_forge.requirements.materialized.v2",
        "version": "2.0.0",
        "status": "MATERIALIZED_REQUIREMENTS",
        "contract": str(CONTRACT_REL),
        "policy": str(POLICY_REL),
        "shipping": False,
        "source_blockers": blockers,
        "summary": {
            "fighters": len(roster.get("fighters", [])),
            "world_locations": len(arena_info.get("arenas", [])),
            "bjj_techniques_available_for_derivation": len(techniques),
            "requirements_total": len(rows),
            "requirements_by_category": counts,
        },
        "requirements": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", default=None)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    result = derive(ROOT)
    output_rel = args.output or load_json(ROOT / POLICY_REL)["output"]
    output = ROOT / output_rel
    text = json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n"

    if args.check:
        if not output.exists():
            print(f"FAIL missing materialized output: {output_rel}")
            return 1
        existing = output.read_text(encoding="utf-8")
        if existing != text:
            print(f"FAIL stale materialized output: {output_rel}")
            return 1
        print(f"Sprite Forge v2 derivation PASS: requirements={result['summary']['requirements_total']} blockers={len(result['source_blockers'])}")
        return 0

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(text, encoding="utf-8")
    print(f"WROTE {output_rel}: requirements={result['summary']['requirements_total']} blockers={len(result['source_blockers'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
