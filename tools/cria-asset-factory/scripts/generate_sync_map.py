#!/usr/bin/env python3
"""Build six-phase attacker/defender frame-locked sync_map.json."""
from __future__ import annotations
import argparse
from pathlib import Path
try:
    from .common import PHASES, PIVOT, candidate, json_write, safe_id
except ImportError:
    from common import PHASES, PIVOT, candidate, json_write, safe_id


def parse_counts(value: str) -> list[int]:
    try:
        counts = [int(v.strip()) for v in value.split(",")]
    except ValueError as exc:
        raise ValueError("six comma-separated positive frame counts required") from exc
    if len(counts) != 6 or min(counts) < 1:
        raise ValueError("six positive phase counts required")
    return counts


def make_sync(tech_id: str, counts: list[int], commit: int, fps: int = 12) -> dict:
    safe_id(tech_id)
    if len(counts) != 6 or min(counts) < 1:
        raise ValueError("six positive phase counts required")
    total = sum(counts)
    if not 0 <= commit < total:
        raise ValueError(f"commit_frame must be between 0 and {total - 1}")
    spans, cursor = [], 0
    for phase, length in zip(PHASES, counts):
        spans.append({
            "name": phase, "start_frame": cursor, "end_frame_inclusive": cursor + length - 1,
            "frame_count": length, "attacker_range": [cursor, cursor + length - 1],
            "defender_range": [cursor, cursor + length - 1],
        })
        cursor += length
    return candidate("paired_sync", technique_id=tech_id, fps=fps, frame_count=total,
                     commit_frame=commit, phases=spans, attacker_anchor=PIVOT[:],
                     defender_anchor=PIVOT[:], contacts={"status": "UNKNOWN", "events": []},
                     alignment="shared_clock", rules_authority=False)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--id", required=True)
    ap.add_argument("--counts", required=True, help="e.g. 2,2,2,3,2,2")
    ap.add_argument("--commit-frame", type=int, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    json_write(args.out, make_sync(args.id, parse_counts(args.counts), args.commit_frame))
    print(args.out)


if __name__ == "__main__":
    main()
