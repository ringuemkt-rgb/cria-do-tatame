#!/usr/bin/env python3
"""Build a deterministic Visual Foundry queue from the canonical visual manifest.

This planner does not call external AI services. It converts the repository's
canonical visual scope into explicit production jobs that can later be consumed
by Blender/cloud adapters.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = ROOT / "data/visual/production_manifest_v02.json"
DEFAULT_PROFILE = ROOT / "data/visual/visual_foundry_profile_v1.json"
DEFAULT_OUTPUT = ROOT / "production/visual_foundry/queue_v1.jsonl"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def build_character_jobs(manifest: dict[str, Any], profile: dict[str, Any]) -> list[dict[str, Any]]:
    animation_profiles = manifest.get("animation_profiles", {})
    jobs: list[dict[str, Any]] = []

    for character in manifest.get("characters", []):
        action_names: list[str] = []
        for profile_name in character.get("profiles", []):
            action_names.extend(animation_profiles.get(profile_name, []))

        # deterministic de-duplication while preserving manifest order
        actions = list(dict.fromkeys(action_names + character.get("signature", [])))
        jobs.append(
            {
                "job_version": 1,
                "kind": "character_master_to_sprite",
                "character_id": character["id"],
                "role": character.get("role"),
                "actions": actions,
                "source_manifest": profile["source_manifest"],
                "profile": profile["id"],
                "stages": [
                    "reference_lock",
                    "master_3d",
                    "retopology",
                    "materials",
                    "rig",
                    "animation",
                    "orthographic_render",
                    "pixel_pass",
                    "sprite_forge_qa",
                    "godot_integration"
                ],
                "output_dir": f"production/visual_foundry/{character['id']}",
                "shipping_target": "2d_sprite",
                "requires_provenance": True,
            }
        )
    return jobs


def build_paired_technique_jobs(manifest: dict[str, Any], profile: dict[str, Any]) -> list[dict[str, Any]]:
    jobs: list[dict[str, Any]] = []
    for technique in manifest.get("paired_techniques", []):
        jobs.append(
            {
                "job_version": 1,
                "kind": "paired_technique",
                "technique_id": technique["id"],
                "entry": technique.get("entry"),
                "exit": technique.get("exit"),
                "frames_target": technique.get("frames_target"),
                "phases": technique.get("phases", []),
                "profile": profile["id"],
                "required_outputs": profile.get("paired_technique_outputs", []),
                "stages": [
                    "pose_blocking",
                    "shared_contact_points",
                    "attacker_animation",
                    "defender_animation",
                    "sync_map",
                    "orthographic_render",
                    "paired_sprite_qa"
                ],
                "output_dir": f"production/visual_foundry/techniques/{technique['id']}",
            }
        )
    return jobs


def build_queue(manifest: dict[str, Any], profile: dict[str, Any]) -> list[dict[str, Any]]:
    return build_character_jobs(manifest, profile) + build_paired_technique_jobs(manifest, profile)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--profile", type=Path, default=DEFAULT_PROFILE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--stdout", action="store_true")
    args = parser.parse_args()

    manifest = load_json(args.manifest)
    profile = load_json(args.profile)
    queue = build_queue(manifest, profile)

    if args.stdout:
        for job in queue:
            print(json.dumps(job, ensure_ascii=False, sort_keys=True))
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for job in queue:
            handle.write(json.dumps(job, ensure_ascii=False, sort_keys=True) + "\n")

    print(f"Visual Foundry: {len(queue)} jobs -> {args.output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
