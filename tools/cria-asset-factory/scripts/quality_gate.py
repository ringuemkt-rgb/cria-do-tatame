#!/usr/bin/env python3
"""Fail-closed QA for candidate transitions and optional visual packages.

Usage:
    python tools/cria-asset-factory/scripts/quality_gate.py
    python tools/cria-asset-factory/scripts/quality_gate.py --candidate /path/to/baiana
Never sets shipping=true and never modifies runtime/official catalog.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FACTORY = Path(__file__).resolve().parents[1]
PHASES = ["anticipation", "entry", "establish", "stabilize", "response", "recovery"]
BASE = {"#0B0B0D", "#C9971C", "#EDE6D6", "#1E3A5F", "#2D5016",
        "#B85C38", "#D4A574", "#8B0000", "#4B0082"}
FACTIONS = {"ALE": "#FF9408", "LEM": "#4A6741", "NTM": "#3FE3F5"}
FIELDS = {
    "id", "family", "entry_state", "exit_state", "gi", "nogi",
    "base_chance", "cost", "advantage_gain", "advantage_required",
    "advantage_modifier", "is_fake", "fake_punish", "is_ground_strike",
    "stamina_drain_opponent", "denial_reward", "defense_response",
    "defense_window", "commit_frame", "stabilization_seconds",
    "score_event", "legal_ibjjf", "legal_adcc", "phases", "anatomy",
    "shipping", "qa_status",
}


def read(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object: {path}")
    return data


def require_false(value: dict, path: Path, errors: list[str]) -> None:
    if value.get("shipping") is not False:
        errors.append(f"{path}: shipping must be literal false")
    if value.get("qa_status") not in ("pending", None):
        errors.append(f"{path}: only candidate QA status allowed")


def check_catalog(root: Path, errors: list[str]) -> None:
    catalog = read(root / "data/techniques.json")
    by_id = {t["id"]: t for t in catalog["techniques"]}
    index_file = root / "data/transitions/index.json"
    index = read(index_file)
    require_false(index, index_file, errors)
    refs = index.get("techniques", [])
    if not isinstance(refs, list) or not 1 <= len(refs) <= 12:
        errors.append("transition index requires 1..12 entries")
        return
    ids = [item.get("id") for item in refs if isinstance(item, dict)]
    if len(ids) != len(refs) or len(ids) != len(set(ids)):
        errors.append("duplicate or missing index IDs")
    actual_files = {x.name for x in (root / "data/transitions").glob("*.json") if x.name != "index.json"}
    expected_files = {f"{item}.json" for item in ids}
    if actual_files != expected_files:
        errors.append(f"transition index/file mismatch: extra={actual_files-expected_files}, missing={expected_files-actual_files}")

    for name in ids:
        path = root / "data/transitions" / f"{name}.json"
        if not path.is_file() or name not in by_id:
            errors.append(f"missing/noncanonical transition: {name}")
            continue
        row, canon = read(path), by_id[name]
        require_false(row, path, errors)
        missing = FIELDS - row.keys()
        if missing:
            errors.append(f"{name}: missing fields {sorted(missing)}")
        for key in ("id", "family", "entry_state", "exit_state", "base_chance"):
            if row.get(key) != (name if key == "id" else canon.get(key)):
                errors.append(f"{name}: {key} differs from data/techniques.json")
        if row.get("cost") != canon.get("cost"):
            errors.append(f"{name}: cost differs from canonical cost (gas/focus)")
        if row.get("phases") != PHASES:
            errors.append(f"{name}: phase ordering mismatch")
        if row.get("defense_response") is not None and row["defense_response"] not in by_id:
            errors.append(f"{name}: unknown defense_response")
        if row.get("qa_status") != "pending":
            errors.append(f"{name}: qa_status must be pending")
        for flag in ("gi", "nogi", "is_fake", "is_ground_strike",
                     "legal_ibjjf", "legal_adcc"):
            if type(row.get(flag)) is not bool:
                errors.append(f"{name}: {flag} must be boolean")
        for key in ("base_chance", "defense_window"):
            val = row.get(key)
            if type(val) not in (int, float) or not 0 <= val <= 1:
                errors.append(f"{name}: {key} outside 0..1")
        for key in ("commit_frame", "fake_punish", "stabilization_seconds",
                    "advantage_gain", "advantage_required", "advantage_modifier"):
            val = row.get(key)
            if type(val) not in (int, float) or val < 0:
                errors.append(f"{name}: invalid nonnegative {key}")
        if not isinstance(row.get("cost"), dict) or set(row["cost"]) != {"gas", "focus"}:
            errors.append(f"{name}: cost must use only gas/focus")
        for k, fields in (
            ("denial_reward", {"advantage_gain", "stamina_regen"}),
            ("stamina_drain_opponent", {"gas", "focus"}),
            ("anatomy", {"attacker_contact", "defender_contact", "primary_joint", "control_points"}),
        ):
            obj = row.get(k)
            if not isinstance(obj, dict) or set(obj) != fields:
                errors.append(f"{name}: malformed {k}")
        anatomy = row.get("anatomy", {})
        for k in ("attacker_contact", "defender_contact", "control_points"):
            if isinstance(anatomy, dict) and not isinstance(anatomy.get(k), list):
                errors.append(f"{name}: anatomy.{k} must be list")
        if row.get("is_ground_strike") is not False:
            errors.append(f"{name}: position-only slice cannot enable striking")


def check_style(root: Path, errors: list[str]) -> set[str]:
    path = root / "config/art_direction.json"
    art = read(path)
    require_false(art, path, errors)
    if art.get("canvas") != [128, 128] or art.get("pivot") != [64, 96]:
        errors.append("visual canvas/pivot broken")
    if set(art.get("base_palette", [])) != BASE or art.get("factions") != FACTIONS:
        errors.append("visual palette/factions differ from art-direction lock")
    if art.get("resample") != "nearest" or art.get("combat_view") != "side":
        errors.append("noncanonical interpolation or combat view")
    if not all(art.get(x) is True for x in ("no_blur", "no_smooth_gradients", "no_photorealism", "no_3d_render", "no_baked_hud")):
        errors.append("visual safety lock incomplete")
    return BASE | set(FACTIONS.values())


def check_no_runtime_duplication(errors: list[str]) -> None:
    for path in FACTORY.rglob("*"):
        if not path.is_file() or "__pycache__" in path.parts:
            continue
        if path.name in ("CombatManager.gd", "DeckManager.gd", "AudioManager.gd", "project.godot"):
            errors.append(f"forbidden runtime artifact inside factory: {path}")
        if path.suffix == ".gd" and re.search(
            r"^\s*class_name\s+(CombatManager|DeckManager|AudioManager)\s*$",
            path.read_text(encoding="utf-8"), re.MULTILINE,
        ):
            errors.append(f"forbidden singleton declaration: {path}")


def check_candidate(candidate: Path, colors: set[str], errors: list[str]) -> None:
    if not candidate.is_dir():
        errors.append(f"candidate does not exist: {candidate}")
        return
    path = candidate / "metadata.json"
    if not path.is_file():
        errors.append(f"{candidate}: missing metadata.json")
        return
    meta = read(path)
    require_false(meta, path, errors)
    for path in candidate.rglob("*.json"):
        try:
            obj = read(path)
            if obj.get("shipping") is True:
                errors.append(f"{path}: candidate may not assert shipping=true")
        except (ValueError, json.JSONDecodeError):
            errors.append(f"invalid candidate JSON: {path}")
    is_paired = meta.get("kind") == "paired_technique"
    if is_paired:
        sync_file = candidate / "sync_map.json"
        if not sync_file.is_file():
            errors.append("paired technique missing sync_map.json")
        else:
            sync = read(sync_file)
            require_false(sync, sync_file, errors)
            ordered = [p.get("name") for p in sync.get("phases", []) if isinstance(p, dict)]
            if ordered != PHASES:
                errors.append("sync_map six ordered phases required")
            if sync.get("attacker_anchor") != [64, 96] or sync.get("defender_anchor") != [64, 96]:
                errors.append("sync_map paired pivots not [64,96]")
        for actor in ("attacker", "defender"):
            if not (candidate / actor / "metadata.json").is_file():
                errors.append(f"paired technique missing {actor}/metadata.json")
    if meta.get("kind") in ("paired_technique", "combat_animation", "animation", "technique_attacker", "technique_defender"):
        if meta.get("pivot") not in (None, [64, 96]):
            errors.append("sprite metadata pivot mismatch")
    png_files = list(candidate.rglob("*.png"))
    if png_files:
        try:
            from PIL import Image
        except ImportError:
            errors.append("Pillow needed for PNG palette QA: pip install Pillow")
            return
        allowed = {tuple(bytes.fromhex(value[1:])) for value in colors}
        for png in png_files:
            with Image.open(png) as im:
                if "final" in png.parts and im.size != (128, 128):
                    errors.append(f"{png}: gameplay frame must be 128x128")
                rgba = im.convert("RGBA")
                for r, g, b, alpha in rgba.getdata():
                    if alpha not in (0, 255) or (alpha and (r, g, b) not in allowed):
                        errors.append(f"{png}: noncanonical pixel/alpha")
                        break
            if "final" in png.parts:
                for suffix in (".license.json", ".provenance.json", ".qa.json"):
                    side = png.with_suffix(suffix)
                    if not side.is_file():
                        errors.append(f"{png}: missing {suffix} sidecar")
                qa_file = png.with_suffix(".qa.json")
                if qa_file.is_file() and read(qa_file).get("pivot") != [64, 96]:
                    errors.append(f"{png}: qa sidecar pivot mismatch")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT, help="Official repository root")
    parser.add_argument("--candidate", type=Path, help="Optional candidate package for paired/palette inspection")
    args = parser.parse_args()
    errors: list[str] = []
    try:
        check_catalog(args.root, errors)
        colors = check_style(args.root, errors)
        check_no_runtime_duplication(errors)
        if args.candidate:
            check_candidate(args.candidate, colors, errors)
    except (OSError, KeyError, ValueError, TypeError, json.JSONDecodeError) as exc:
        errors.append(str(exc))
    for error in errors:
        print("FAIL:", error)
    print(f"{'FAIL' if errors else 'PASS candidate-only'}: {len(errors)} issue(s); shipping remains false")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
