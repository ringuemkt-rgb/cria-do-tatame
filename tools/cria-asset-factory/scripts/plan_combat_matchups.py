#!/usr/bin/env python3
"""Generate a lightweight roster-derived coverage matrix (NO gameplay fights).

Enumerate all canonical pairs without creating NxN sprites/techniques/AI systems.
The output is an authoring plan, never an eligibility or release claim.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import sys
from pathlib import Path

try:
    from .fighter_roster import ROOT, load_fighters, fighter_or_fail, validate_pair
except ImportError:
    from fighter_roster import ROOT, load_fighters, fighter_or_fail, validate_pair

OUTFITS = ("gi_white", "gi_blue", "nogi")


def load_candidate_techniques(root: Path = ROOT) -> list[dict]:
    data = json.loads((root / "data/transitions/index.json").read_text(encoding="utf-8"))
    if data.get("shipping") is not False:
        raise ValueError("candidate-only technique index expected")
    master = json.loads((root / "data/techniques.json").read_text(encoding="utf-8"))
    canonical = {item["id"]: item for item in master["techniques"]}
    refs = data.get("techniques")
    if not isinstance(refs, list) or not refs:
        raise ValueError("missing candidate technique list")
    techniques: list[dict] = []
    seen: set[str] = set()
    for ref in refs:
        technique_id = ref.get("id") if isinstance(ref, dict) else None
        if not isinstance(technique_id, str) or technique_id not in canonical or technique_id in seen:
            raise ValueError(f"missing, duplicate, or noncanonical technique ID: {technique_id!r}")
        seen.add(technique_id)
        row = json.loads((root / "data/transitions" / (technique_id + ".json")).read_text(encoding="utf-8"))
        if row.get("shipping") is not False or row.get("qa_status") != "pending":
            raise ValueError(f"{technique_id}: invalid authoring/shipping state")
        for field in ("entry_state", "exit_state", "family"):
            if row.get(field) != canonical[technique_id].get(field):
                raise ValueError(f"{technique_id}: differs from canonical {field}")
        techniques.append({
            "technique_id": technique_id,
            "gi_authoring_supported": row.get("gi") is True,
            "nogi_authoring_supported": row.get("nogi") is True,
            "gameplay_eligibility": "UNVERIFIED_PER_FIGHTER_AND_RULESET",
            "biomechanics": "REVIEW_PENDING",
            "shipping": False,
        })
    return techniques


def plan(root: Path = ROOT, first: str | None = None, second: str | None = None,
         selected_technique: str | None = None) -> dict:
    fighters = load_fighters(root)
    order = sorted(fighters)
    if second and not first:
        raise ValueError("--opponent requires --fighter")
    if first:
        fighter_or_fail(first, root)
    if second:
        validate_pair(first, second, root)
    pairs = ([tuple(sorted((first, second)))] if second else
             [(first, name) if first < name else (name, first)
              for name in order if name != first] if first else
             list(itertools.combinations(order, 2)))
    pairs = sorted(set(pairs))
    techniques = load_candidate_techniques(root)
    if selected_technique:
        techniques = [item for item in techniques if item["technique_id"] == selected_technique]
        if not techniques:
            raise ValueError("technique not in candidate index; full graph cannot be inferred")
    if not pairs:
        raise ValueError("no matchups planned")
    rows = [{
        "fighter_a": a, "fighter_b": b, "directed_roles": [
            {"attacker_id": a, "defender_id": b},
            {"attacker_id": b, "defender_id": a},
        ],
        "technique_eligibility": "UNVERIFIED",
        "paired_animation_status": "NOT_GENERATED",
        "match_playable": False,
        "shipping": False,
        "qa_status": "pending",
    } for a, b in pairs]
    roster_bytes = (root / "data/combat/roster_v3.json").read_bytes()
    return {
        "schema": "cria.universal_combat_authoring.plan.v1",
        "scope": "CANONICAL_ROSTER_CANDIDATE_COVERAGE_ONLY",
        "source_of_truth": "data/combat/roster_v3.json",
        "roster_sha256": hashlib.sha256(roster_bytes).hexdigest(),
        "techniques_source": "data/techniques.json",
        "candidate_transition_source": "data/transitions/index.json",
        "full_bjj_graph_available": (root / "data/bjj/bjj_knowledge_graph_v1.json").is_file(),
        "not_a_runtime_matchmaking_system": True,
        "gameplay_authority": False,
        "all_fighters_can_execute_all_techniques": "NOT_ESTABLISHED",
        "character_count": len(fighters),
        "character_identities": [{
            "id": k, "display_name": v["display_name"], "role": v["role"],
            "playability": "NOT_CERTIFIED_BY_THIS_PLAN",
        } for k, v in sorted(fighters.items())],
        "matchup_count": len(rows),
        "directed_role_count": len(rows) * 2,
        "technique_candidate_count": len(techniques),
        "candidate_techniques": techniques,
        "matchups": rows,
        "no_pairwise_asset_duplication": True,
        "shared_motion_policy": "REUSE_REVIEWED_ROLE_AND_TECHNIQUE_ANIMATIONS_WHERE_BIOMECHANICALLY_VALID",
        "required_next_steps": [
            "review_fighter_gi_nogi_profiles",
            "review_fighter_technique_eligibility_per_ruleset",
            "resolve_master_versus_slice_kg_state_mappings",
            "create_and_approve_actor_identity_and_motion",
            "validate_contact_and_body_scale_for_each_pair",
            "integrate_with_existing_Godot_combat_consumers",
            "test_on_device",
        ],
        "qa_status": "pending",
        "shipping": False,
    }


def save_plan(result: dict, out: Path, root: Path = ROOT) -> None:
    dest = out.resolve()
    forbidden = ("src", "scenes", "assets", "data", ".github", ".git")
    if any(dest.is_relative_to((root / p).resolve()) for p in forbidden):
        raise ValueError("authoring plan may not overwrite gameplay or runtime asset paths")
    if result.get("shipping") is not False or result.get("gameplay_authority") is not False:
        raise ValueError("authoring plan cannot be promoted")
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("x", encoding="utf-8") as handle:
        json.dump(result, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    scope = ap.add_mutually_exclusive_group(required=True)
    scope.add_argument("--all", action="store_true", help="All canonical unordered matchups")
    scope.add_argument("--fighter", help="One roster fighter versus the remaining roster")
    ap.add_argument("--opponent", help="Requires --fighter, selects exactly one opponent")
    ap.add_argument("--technique", help="Optional candidate technique ID from index")
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    try:
        if args.all and args.opponent:
            raise ValueError("--opponent only valid with --fighter")
        result = plan(first=args.fighter, second=args.opponent, selected_technique=args.technique)
        save_plan(result, args.out)
        print(json.dumps({
            "status": "CANDIDATE_ROSTER_PLAN_CREATED",
            "characters": result["character_count"],
            "matchups": result["matchup_count"],
            "directed_roles": result["directed_role_count"],
            "technique_candidates": result["technique_candidate_count"],
            "full_graph_available": result["full_bjj_graph_available"],
            "shipping": False, "output": str(args.out),
        }, ensure_ascii=False))
        return 0
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
