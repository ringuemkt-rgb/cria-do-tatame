#!/usr/bin/env python3
"""Copy one existing canonical transition into a candidate authoring scaffold.

This does not add a new gameplay ID, alter catalogue, or create a scene.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
try:
    from .common import candidate, json_write, output_dir
except ImportError:
    from common import candidate, json_write, output_dir

ROOT = Path(__file__).resolve().parents[3]


def run(tech_id: str, out: Path | None = None, scaffold_dir: Path | None = None) -> Path:
    catalogue = json.loads((ROOT / "data/techniques.json").read_text(encoding="utf-8"))
    if tech_id not in {x["id"] for x in catalogue["techniques"]}:
        raise ValueError("Only existing canonical IDs are authorized in this slice")
    source = ROOT / "data/transitions" / f"{tech_id}.json"
    if not source.is_file():
        raise FileNotFoundError(f"Transition not approved for this slice: {tech_id}")
    row = json.loads(source.read_text(encoding="utf-8"))
    if row.get("shipping") is not False or row.get("qa_status") != "pending":
        raise ValueError("invalid source candidate transition")
    if scaffold_dir is not None:
        output_dir(scaffold_dir)
        for role in ("attacker", "defender"):
            for stage in ("raw", "clean", "final"):
                (scaffold_dir / role / stage).mkdir(parents=True)
        json_write(scaffold_dir / "metadata.json", candidate(
            "technique_scaffold", id=tech_id, pending_frames=True, pending_sync=True))
        json_write(scaffold_dir / "sync_map.draft.json", candidate(
            "paired_sync_draft", technique_id=tech_id, fps=12,
            frame_count=0, phases=[], contacts={"status": "UNKNOWN", "events": []}))
        (scaffold_dir / "import_notes.md").write_text(
            "# Not importable yet\n\nTwo frame strips and sync_map.json are pending.\n",
            encoding="utf-8")
        (scaffold_dir / "qa_report.md").write_text(
            "# Candidate only\n\n- [ ] Frames\n- [ ] Pair sync\n- [ ] Rights/scene/quality\n\nshipping=false\n",
            encoding="utf-8")
    dest = out or (scaffold_dir / "technique.json" if scaffold_dir else None)
    if dest is None:
        raise ValueError("--out or --scaffold-dir required")
    if dest.exists():
        raise FileExistsError(dest)
    json_write(dest, row)
    return dest


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--id", required=True)
    ap.add_argument("--out", type=Path)
    ap.add_argument("--scaffold-dir", type=Path)
    args = ap.parse_args()
    print(run(args.id, args.out, args.scaffold_dir))


if __name__ == "__main__":
    main()
