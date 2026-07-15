#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = ROOT / "data" / "visual" / "production_manifest_v02.json"
DEFAULT_OUTPUT = ROOT / "tools" / "ai_asset_pipeline" / "generated_queue" / "production_queue_v02.jsonl"

STYLE = (
    "HD Pixel Art 2.5D Regional Premium, Baixo Sul da Bahia, mobile-readable, "
    "stable anatomy and proportions, nearest-neighbor pixel edges, no embedded text, "
    "no real brands, transparent background when applicable"
)


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_jsonl(path: Path, rows: Iterable[dict[str, Any]]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
            count += 1
    return count


def character_rows(manifest: dict[str, Any]) -> Iterable[dict[str, Any]]:
    profiles: dict[str, list[str]] = manifest["animation_profiles"]
    for character in manifest["characters"]:
        character_id = character["id"]
        actions: list[str] = []
        for profile_id in character["profiles"]:
            actions.extend(profiles[profile_id])
        actions.extend(character.get("signature", []))
        for action in sorted(set(actions)):
            yield {
                "task_id": f"character::{character_id}::{action}",
                "kind": "character_animation",
                "target": character_id,
                "action": action,
                "prompt": (
                    f"{STYLE}. Character {character_id}; action {action}; one action only; "
                    "clean sprite sheet grid; consistent pivots; readable silhouette; production reference."
                ),
                "output_dir": f"assets/graphics/characters/{character_id}/{action}",
                "required_outputs": manifest["quality_gate"]["required_files"],
                "status": "todo",
            }


def technique_rows(manifest: dict[str, Any]) -> Iterable[dict[str, Any]]:
    base_outputs = list(manifest["quality_gate"]["required_files"])
    paired_outputs = list(manifest["quality_gate"]["paired_technique_extra_files"])
    for technique in manifest["paired_techniques"]:
        technique_id = technique["id"]
        yield {
            "task_id": f"technique::{technique_id}",
            "kind": "paired_technique_animation",
            "target": technique_id,
            "entry_state": technique["entry"],
            "exit_state": technique["exit"],
            "frames_target": technique["frames_target"],
            "phases": technique.get("phases", []),
            "prompt": (
                f"{STYLE}. Synchronized Brazilian jiu-jitsu technique {technique_id}; "
                f"entry {technique['entry']}; exit {technique['exit']}; attacker and defender on separate sheets; "
                "safe technical depiction; shared origin; contact points and phase transitions explicit."
            ),
            "output_dir": f"assets/graphics/techniques/{technique_id}",
            "required_outputs": base_outputs + paired_outputs,
            "status": "todo",
        }


def arena_rows(manifest: dict[str, Any]) -> Iterable[dict[str, Any]]:
    extras = manifest["quality_gate"]["arena_extra_files"]
    for arena in manifest["arenas"]:
        for variant in arena["variants"]:
            yield {
                "task_id": f"arena::{arena['id']}::{variant}",
                "kind": "arena_package",
                "target": arena["id"],
                "variant": variant,
                "layers": arena["layers"],
                "prompt": (
                    f"{STYLE}. Arena {arena['id']}; type {arena['type']}; variant {variant}; "
                    "five-layer 2.5D parallax environment; clean playable lane; separate crowd, props, particles and foreground."
                ),
                "output_dir": f"assets/graphics/arenas/{arena['id']}/{variant}",
                "required_outputs": extras,
                "status": "todo",
            }


def ui_rows(manifest: dict[str, Any]) -> Iterable[dict[str, Any]]:
    for screen in manifest["ui_screens"]:
        yield {
            "task_id": f"ui::{screen}",
            "kind": "ui_screen",
            "target": screen,
            "prompt": (
                f"{STYLE}. Mobile-first Godot UI mockup for {screen}; 1280x720 landscape; "
                "large touch targets, safe-area aware, black graphite and burned gold, no baked text."
            ),
            "output_dir": f"assets/graphics/ui/{screen}",
            "required_outputs": ["mockup.png", "nine_patch", "icons", "ui_metadata.json", "qa_report.md"],
            "status": "todo",
        }


def audio_rows(manifest: dict[str, Any]) -> Iterable[dict[str, Any]]:
    outputs = manifest["quality_gate"]["audio_extra_files"]
    for package in manifest["audio_packages"]:
        yield {
            "task_id": f"audio::{package}",
            "kind": "audio_package",
            "target": package,
            "prompt": (
                f"Original game audio package {package} for Cria do Tatame; Brazilian regional atmosphere; "
                "clean loop or one-shot as appropriate; no copyrighted melody or sampled commercial recording."
            ),
            "output_dir": f"assets/audio/{package}",
            "required_outputs": outputs,
            "status": "todo",
        }


def main() -> int:
    parser = argparse.ArgumentParser(description="Build the complete audiovisual production queue.")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--kind",
        choices=["all", "characters", "techniques", "arenas", "ui", "audio"],
        default="all",
    )
    args = parser.parse_args()

    manifest = load_json(args.manifest)
    builders = {
        "characters": character_rows,
        "techniques": technique_rows,
        "arenas": arena_rows,
        "ui": ui_rows,
        "audio": audio_rows,
    }

    selected = builders.keys() if args.kind == "all" else [args.kind]
    rows: list[dict[str, Any]] = []
    for key in selected:
        rows.extend(builders[key](manifest))

    rows.sort(key=lambda item: item["task_id"])
    count = write_jsonl(args.output, rows)
    summary: dict[str, int] = {}
    for row in rows:
        summary[row["kind"]] = summary.get(row["kind"], 0) + 1

    print(json.dumps({"ok": True, "count": count, "by_kind": summary, "output": str(args.output)}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
