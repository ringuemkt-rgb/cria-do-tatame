#!/usr/bin/env python3
"""Prepare a Qwen/ComfyUI authoring job for an EXISTING Gold Slice technique.

Writes only JSON; never runs inference or promotes an asset. The canonical
registry and model profile are read directly from the official repository.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

try:
    from .fighter_roster import load_fighters, validate_pair
except ImportError:
    from fighter_roster import load_fighters, validate_pair

ROOT = Path(__file__).resolve().parents[3]
KINDS = {
    "character_combat_pose_concept",
    "character_turnaround_concept",
    "arena_environment_concept",
    "prop_concept",
    "icon_concept",
}
PHASES = ("anticipation", "entry", "establish", "stabilize", "response", "recovery")
OUTFITS = ("gi_white", "gi_blue", "nogi")


def load_json(path: Path) -> dict:
    obj = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(obj, dict):
        raise ValueError(f"non-object JSON: {path}")
    return obj


def make_job(tech_id: str, character_id: str, outfit: str, phase: str, kind: str,
             reference: Path | None = None, repo_root: Path = ROOT,
             opponent_id: str | None = None) -> dict:
    catalog = load_json(repo_root / "data/techniques.json")["techniques"]
    transitions = load_json(repo_root / "data/transitions/index.json")
    if transitions.get("shipping") is not False:
        raise ValueError("transition index is not a candidate")
    available = {x["id"] for x in transitions["techniques"]}
    tech = next((x for x in catalog if x["id"] == tech_id), None)
    if tech_id not in available or tech is None:
        raise ValueError("only IDs in the existing 10-technique Gold Slice are allowed")
    transition = load_json(repo_root / "data/transitions" / (tech_id + ".json"))
    if transition.get("shipping") is not False or transition.get("qa_status") != "pending":
        raise ValueError("transition cannot be used for candidate authoring")
    if (transition.get("entry_state") != tech["entry_state"]
            or transition.get("exit_state") != tech["exit_state"]):
        raise ValueError("canonical transition state conflict")
    fighters = load_fighters(repo_root)
    if character_id not in fighters:
        raise ValueError("character ID not found in canonical roster")
    if opponent_id is not None:
        validate_pair(character_id, opponent_id, repo_root)
    if outfit not in OUTFITS or phase not in PHASES or kind not in KINDS:
        raise ValueError("unsupported outfit/phase/kind")
    if outfit == "nogi" and transition.get("nogi") is not True:
        raise ValueError("NO-GI authoring not flagged for this technique")
    if outfit != "nogi" and transition.get("gi") is not True:
        raise ValueError("GI authoring not flagged for this technique")
    profile = load_json(repo_root / "data/ai/qwen_pixel_art_profile_v1.json")
    art = load_json(repo_root / "config/art_direction.json")
    if profile.get("shipping") is not False or art.get("shipping") is not False:
        raise ValueError("art/model profile is not candidate-only")
    if reference is not None and not reference.is_file():
        raise FileNotFoundError(f"licensed reference missing: {reference}")
    variant = "off-white GI" if outfit == "gi_white" else "blue GI" if outfit == "gi_blue" else "NO-GI rashguard and shorts, NO GI grips"
    # These are design references only. Character anatomy and source rights still require QA.
    text = (
        profile["prompt_contract"]["prefix"]
        + f" Fighter {character_id} ({fighters[character_id]['display_name']}); technique {tech_id}; side-view grappling; "
        + (f"visual opponent {opponent_id} ({fighters[opponent_id]['display_name']}); " if opponent_id else "")
        + f"phase {phase}; {variant}; source states {tech['entry_state']} -> {tech['exit_state']}; "
        + "pixel grid, precise 5-finger hands, grounded contact, original fictional insignia, "
        + "no logos, no baked text, no hallucinated hidden grips; "
        + f"style family {art['style']}; pivot (64,96) on 128x128 target. "
        + "This is an authoring concept, NOT an authoritative BJJ outcome."
    )
    return {
        "schema": "cria.asset_factory.generation_job.v1",
        "kind": kind, "technique_id": tech_id,
        "character_id": character_id, "opponent_id": opponent_id,
        "character_name": fighters[character_id]["display_name"],
        "outfit": outfit, "phase": phase,
        "fighter_technique_eligibility": "UNVERIFIED",
        "match_playable": False,
        "entry_state": tech["entry_state"], "exit_state": tech["exit_state"],
        "model_id": profile["base_model"]["id"],
        "model_revision": profile["base_model"]["revision"],
        "adapter_id": profile["lora"]["id"],
        "adapter_revision": profile["lora"]["revision"],
        "width": 1024, "height": 1024,
        "target_frame": art["canvas"], "pivot": art["pivot"], "fps": art["fps"],
        "prompt": text,
        "reference_path": str(reference.resolve()) if reference else None,
        "reference_rights": "REVIEW_PENDING",
        "identity_approved": False,
        "biomechanics_approved": False,
        "godot_scene_tested": False,
        "output_status": "NOT_GENERATED",
        "shipping": False, "qa_status": "pending",
    }


def save_job(output: Path, job: dict, repo_root: Path = ROOT) -> None:
    output = output.resolve()
    # Never place generated candidate jobs in authoritative runtime/content paths.
    forbidden = [repo_root / item for item in ("src", "scenes", "data", "assets", ".github")]
    if any(output.is_relative_to(path.resolve()) for path in forbidden):
        raise ValueError("candidate job cannot write into runtime or shipping paths")
    if job.get("shipping") is not False or job.get("qa_status") != "pending":
        raise ValueError("unsafe candidate JSON")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("x", encoding="utf-8") as fh:
        json.dump(job, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--id", required=True)
    ap.add_argument("--character", required=True, help="Canonical roster fighter ID")
    ap.add_argument("--opponent", help="Optional distinct canonical opponent; concept only")
    ap.add_argument("--outfit", choices=OUTFITS, default="gi_white")
    ap.add_argument("--phase", choices=PHASES, default="anticipation")
    ap.add_argument("--kind", choices=sorted(KINDS), default="character_combat_pose_concept")
    ap.add_argument("--reference", type=Path, help="Already licensed/consented image path")
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    try:
        job = make_job(args.id, args.character, args.outfit, args.phase,
                       args.kind, args.reference, opponent_id=args.opponent)
        save_job(args.out, job)
        print(f"Candidate job written (no inference, shipping=false): {args.out}")
        return 0
    except (OSError, KeyError, ValueError, json.JSONDecodeError) as exc:
        ap.error(str(exc))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
