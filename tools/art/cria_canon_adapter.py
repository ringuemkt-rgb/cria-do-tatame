#!/usr/bin/env python3
"""Compile a character visual-canon record into a CRIA Sprite Forge job spec.

The adapter is intentionally offline and deterministic. It does not generate art,
invoke external models, modify gameplay authority, or promote assets.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Any

PROFILE_REL = pathlib.Path("data/visual/sprite_qa_profiles_v1.json")
CANON_DIR_REL = pathlib.Path("data/chars/canon")
CHARACTERS_REL = pathlib.Path("data/characters.json")
FORGE_REL = pathlib.Path("data/visual/sprite_forge_contract_v1.json")


def _read_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def _character_by_id(data: dict[str, Any], character_id: str) -> dict[str, Any] | None:
    chars = data.get("characters", [])
    if not isinstance(chars, list):
        return None
    for item in chars:
        if isinstance(item, dict) and item.get("id") == character_id:
            return item
    return None


def _all_actions(canon: dict[str, Any]) -> list[str]:
    sets = canon.get("action_sets", {})
    ordered: list[str] = []
    for key in ("common", "bjj_positional", "signature", "striking_candidates"):
        values = sets.get(key, []) if isinstance(sets, dict) else []
        if isinstance(values, list):
            for action in values:
                if isinstance(action, str) and action not in ordered:
                    ordered.append(action)
    return ordered


def validate_sources(repo_root: pathlib.Path, character_id: str) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any], dict[str, Any]]:
    canon_path = repo_root / CANON_DIR_REL / f"{character_id}.json"
    canon = _read_json(canon_path)
    characters = _read_json(repo_root / CHARACTERS_REL)
    profiles = _read_json(repo_root / PROFILE_REL)
    forge = _read_json(repo_root / FORGE_REL)

    if canon.get("character_id") != character_id:
        raise ValueError("visual canon character_id mismatch")
    runtime_char = _character_by_id(characters, character_id)
    if runtime_char is None:
        raise ValueError(f"{character_id} absent from data/characters.json")
    if runtime_char.get("canon") is not True:
        raise ValueError(f"{character_id} is not canon in data/characters.json")
    if canon.get("display_name") != runtime_char.get("name"):
        raise ValueError("visual canon display_name differs from canonical character data")

    frame = canon.get("frame_contract", {})
    forge_frame = forge.get("frame_contract", {})
    if frame.get("size_px") != forge_frame.get("size_px"):
        raise ValueError("visual canon frame size differs from Sprite Forge contract")
    if frame.get("pivot_px") != forge_frame.get("pivot_px"):
        raise ValueError("visual canon pivot differs from Sprite Forge contract")

    if canon.get("shipping") is not False:
        raise ValueError("visual canon cannot authorize shipping")
    return canon, runtime_char, profiles, forge


def compile_spec(repo_root: pathlib.Path, character_id: str, actions: list[str] | None = None) -> dict[str, Any]:
    canon, runtime_char, profiles, forge = validate_sources(repo_root, character_id)
    available = _all_actions(canon)
    selected = actions or available
    unknown = [action for action in selected if action not in available]
    if unknown:
        raise ValueError(f"unknown/non-canonical visual actions: {', '.join(unknown)}")

    profile_registry = profiles.get("action_profile_registry", {})
    profile_defs = profiles.get("profiles", {})
    striking = set(canon.get("action_sets", {}).get("striking_candidates", []))
    signatures = set(canon.get("action_sets", {}).get("signature", []))

    jobs: list[dict[str, Any]] = []
    for action in selected:
        profile_id = profile_registry.get(action)
        if not isinstance(profile_id, str):
            raise ValueError(f"no QA profile registered for action '{action}'")
        profile = profile_defs.get(profile_id)
        if not isinstance(profile, dict):
            raise ValueError(f"missing QA profile definition '{profile_id}'")
        authority = "tooling_capability"
        if action not in striking:
            authority = "canonical_visual_action"
        if action in signatures:
            authority = "canonical_signature_visual_action"
        jobs.append(
            {
                "action": action,
                "qa_profile": profile_id,
                "qa_thresholds": profile,
                "gameplay_authority": False if action in striking else None,
                "authority_status": authority,
                "requires_custom_threshold_override": bool(profile.get("requires_explicit_threshold_override", False)),
            }
        )

    return {
        "$schema": "cria.sprite_forge_job_spec.v1",
        "version": "1.0.0",
        "character_id": character_id,
        "display_name": runtime_char.get("name"),
        "visual_canon": (CANON_DIR_REL / f"{character_id}.json").as_posix(),
        "reference": canon["reference_contract"]["master_reference"],
        "reference_status": canon["reference_contract"]["master_reference_status"],
        "identity_lock_required": True,
        "frame_contract": canon["frame_contract"],
        "visual_language": canon["visual_language"],
        "fx_policy": canon["fx_policy"],
        "jobs": jobs,
        "upstream_pin": forge["upstream_research"]["pinned_commit"],
        "runtime_dependency": False,
        "shipping": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--character", required=True)
    parser.add_argument("--actions", default="", help="comma-separated action subset; default is all declared actions")
    parser.add_argument("--root", default=".")
    parser.add_argument("--output", default="")
    args = parser.parse_args()

    repo_root = pathlib.Path(args.root).resolve()
    actions = [item.strip() for item in args.actions.split(",") if item.strip()] or None
    try:
        spec = compile_spec(repo_root, args.character, actions)
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"FAIL canon adapter: {exc}")
        return 1

    text = json.dumps(spec, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        out = repo_root / args.output
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
        print(f"wrote {out}")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
