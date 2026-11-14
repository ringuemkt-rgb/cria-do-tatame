#!/usr/bin/env python3
"""Process an existing animation cycle; side view for combat and 3/4 for world_idle."""
from __future__ import annotations
import argparse
from pathlib import Path
try:
    from .build_spritesheet import build
    from .common import ANIMATIONS, FACTIONS, candidate, json_write
    from .fighter_roster import fighter_or_fail
except ImportError:
    from build_spritesheet import build
    from common import ANIMATIONS, FACTIONS, candidate, json_write
    from fighter_roster import fighter_or_fail


def run(character: str, animation: str, source: Path, out: Path,
        outfit: str, faction: str | None, origin: str = "UNKNOWN",
        license_id: str = "UNKNOWN", mocap: Path | None = None) -> dict:
    profile = fighter_or_fail(character)
    if animation not in ANIMATIONS:
        raise ValueError("unsupported animation type")
    if outfit not in ("gi_white", "gi_blue", "nogi"):
        raise ValueError("outfit must be gi_white/gi_blue/nogi")
    if faction is not None and faction not in FACTIONS:
        raise ValueError("unknown palette faction")
    # Faction membership and GI/NO-GI technical eligibility require separate review.
    if mocap is not None and not mocap.is_file():
        raise FileNotFoundError(mocap)
    meta = build(source, out, kind="combat_animation", faction=faction,
                 origin=origin, license_id=license_id)
    meta.update(character_id=character, character_name=profile["display_name"],
                combat_eligibility="UNVERIFIED", animation=animation, outfit=outfit,
                view="three_quarter" if animation == "world_idle" else "side",
                mocap_reference=str(mocap) if mocap else None)
    json_write(out / "metadata.json", meta)
    json_write(out / "animation_profile.json", candidate(
        "animation_profile", character_id=character, action=animation,
        frame_count=meta["frame_count"], view=meta["view"], fps=meta["fps"],
        outfit=outfit, source_mocap=str(mocap) if mocap else None))
    return meta


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--character", required=True, help="Any canonical roster fighter ID")
    ap.add_argument("--animation", choices=sorted(ANIMATIONS), required=True)
    ap.add_argument("--input", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--outfit", choices=("gi_white", "gi_blue", "nogi"), default="gi_white")
    ap.add_argument("--faction", choices=sorted(FACTIONS))
    ap.add_argument("--origin", default="UNKNOWN")
    ap.add_argument("--license", default="UNKNOWN")
    ap.add_argument("--mocap", type=Path, help="BVH/FreeMoCap reference, not an auto-rig")
    args = ap.parse_args()
    print(run(args.character, args.animation, args.input, args.out,
              args.outfit, args.faction, args.origin, args.license, args.mocap))


if __name__ == "__main__":
    main()
