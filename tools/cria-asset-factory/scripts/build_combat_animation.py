#!/usr/bin/env python3
"""Process an existing animation cycle; side view for combat and 3/4 for world_idle."""
from __future__ import annotations
import argparse
from pathlib import Path
try:
    from .build_spritesheet import build
    from .common import ANIMATIONS, CHARACTERS, FACTIONS, candidate, json_write
except ImportError:
    from build_spritesheet import build
    from common import ANIMATIONS, CHARACTERS, FACTIONS, candidate, json_write


def run(character: str, animation: str, source: Path, out: Path,
        outfit: str, faction: str | None, origin: str = "UNKNOWN",
        license_id: str = "UNKNOWN", mocap: Path | None = None) -> dict:
    if character not in CHARACTERS or animation not in ANIMATIONS:
        raise ValueError("canonical character/animation required")
    if outfit not in ("gi_white", "gi_blue", "nogi"):
        raise ValueError("outfit must be gi_white/gi_blue/nogi")
    if outfit == "nogi" and faction not in FACTIONS:
        raise ValueError("NO-GI requires canonical faction")
    if mocap is not None and not mocap.is_file():
        raise FileNotFoundError(mocap)
    meta = build(source, out, kind="combat_animation", faction=faction,
                 origin=origin, license_id=license_id)
    meta.update(character_id=character, animation=animation, outfit=outfit,
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
    ap.add_argument("--character", choices=sorted(CHARACTERS), required=True)
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
