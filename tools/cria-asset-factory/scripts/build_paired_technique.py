#!/usr/bin/env python3
"""Build two independent actor strips and a shared sync map. No combat logic."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
try:
    from .build_spritesheet import build
    from .common import FACTIONS, candidate, json_write, output_dir, pngs
    from .fighter_roster import validate_pair
    from .generate_sync_map import make_sync, parse_counts
except ImportError:
    from build_spritesheet import build
    from common import FACTIONS, candidate, json_write, output_dir, pngs
    from fighter_roster import validate_pair
    from generate_sync_map import make_sync, parse_counts

ROOT = Path(__file__).resolve().parents[3]


def run(tech_id: str, attacker_id: str, defender_id: str,
        attacker: Path, defender: Path, out: Path, counts: list[int],
        commit: int, outfit: str, faction: str | None,
        origin: str = "UNKNOWN", license_id: str = "UNKNOWN") -> dict:
    ids = {row["id"] for row in json.loads((ROOT / "data/techniques.json").read_text(
        encoding="utf-8"))["techniques"]}
    if tech_id not in ids:
        raise ValueError("technique ID absent from canonical gameplay catalogue")
    attacker_profile, defender_profile = validate_pair(attacker_id, defender_id, ROOT)
    # Only a transition already registered for candidate authoring may be drawn.
    transition_path = ROOT / "data/transitions" / f"{tech_id}.json"
    if not transition_path.is_file():
        raise ValueError("technique is not in candidate authoring transitions")
    transition = json.loads(transition_path.read_text(encoding="utf-8"))
    if transition.get("shipping") is not False or transition.get("qa_status") != "pending":
        raise ValueError("technique transition must remain a pending candidate")
    if outfit not in ("gi_white", "gi_blue", "nogi"):
        raise ValueError("unsupported outfit")
    if outfit == "nogi" and transition.get("nogi") is not True:
        raise ValueError("technique is not flagged for NO-GI candidate authoring")
    if outfit != "nogi" and transition.get("gi") is not True:
        raise ValueError("technique is not flagged for GI candidate authoring")
    if faction is not None and faction not in FACTIONS:
        raise ValueError("unknown palette faction")
    # Fighter-specific skill, event eligibility and legality remain UNVERIFIED.
    # Never use this output as proof that a matchup is currently playable.
    count_a, count_b = len(pngs(attacker)), len(pngs(defender))
    if count_a != count_b or count_a != sum(counts):
        raise ValueError(f"mismatched actor phase counts: {count_a}/{count_b}/{sum(counts)}")
    output_dir(out)
    build(attacker, out / "attacker", kind="technique_attacker", faction=faction,
          origin=origin, license_id=license_id)
    build(defender, out / "defender", kind="technique_defender", faction=faction,
          origin=origin, license_id=license_id)
    sync = make_sync(tech_id, counts, commit)
    json_write(out / "sync_map.json", sync)
    json_write(out / "hitbox.json", candidate(
        "paired_hitbox", attacker=[], defender=[], frame_count=count_a,
        status="PENDING_HUMAN_ANNOTATION", gameplay_authority=False))
    meta = candidate("paired_technique", id=tech_id, attacker_id=attacker_id,
                     defender_id=defender_id, outfit=outfit, faction=faction,
                     origin=origin, license_id=license_id, frame_count=count_a, fps=12,
                     attacker_name=attacker_profile["display_name"],
                     defender_name=defender_profile["display_name"],
                     fighter_technique_eligibility="UNVERIFIED",
                     fight_runtime_ready=False)
    json_write(out / "metadata.json", meta)
    (out / "contact_notes.md").write_text(
        "# Human review pending\n\nContact/occlusion: UNKNOWN.\n"
        "No score, success or legality inferred from frames.\n", encoding="utf-8")
    (out / "import_notes.md").write_text(
        "# Godot handoff pending\n\n12 fps / 128x128 / pivot (64,96), paired clock.\n"
        "Existing combat logic decides outcome; validate in scene before shipping.\n", encoding="utf-8")
    return meta


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--id", required=True)
    ap.add_argument("--attacker-id", required=True, help="Any canonical roster fighter ID")
    ap.add_argument("--defender-id", required=True, help="Any OTHER canonical roster fighter ID")
    ap.add_argument("--attacker", type=Path, required=True)
    ap.add_argument("--defender", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--counts", default="2,2,2,3,2,2")
    ap.add_argument("--commit-frame", type=int, default=8)
    ap.add_argument("--outfit", choices=["gi_white", "gi_blue", "nogi"], default="gi_white")
    ap.add_argument("--faction", choices=sorted(FACTIONS))
    ap.add_argument("--origin", default="UNKNOWN")
    ap.add_argument("--license", default="UNKNOWN")
    args = ap.parse_args()
    print(run(args.id, args.attacker_id, args.defender_id, args.attacker, args.defender,
              args.out, parse_counts(args.counts), args.commit_frame, args.outfit,
              args.faction, args.origin, args.license))


if __name__ == "__main__":
    main()
