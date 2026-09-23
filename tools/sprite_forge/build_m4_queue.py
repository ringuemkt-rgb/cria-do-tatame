"""Build a conservative M4 intake queue from canonical repository manifests.

The queue intentionally describes candidate work; it never promotes files and
never adds a new runtime consumer. Arena props remain pack-level requests until
an item-level spec exists.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "data" / "visual" / "production_manifest_v02.json"
CATALOG = ROOT / "data" / "visual" / "graphic_asset_catalog_v01.json"
DEFAULT_OUTPUT = ROOT / "tools" / "sprite_forge" / "generated_queue" / "m4_queue_v01.jsonl"

TECHNIQUE_ICON_TARGETS = {
    "grip_de_ferro",
    "baiana",
    "knee_cut",
    "cem_quilos",
    "montada",
    "mata_leao",
}
UI_ICON_TARGETS = {
    "combat_hud_mobile",
    "submission_hud",
    "result_screen",
    "cria_live_feed",
}
ARENA_TARGETS = {
    ("terreiro_da_luta", "afternoon"),
    ("arena_do_dique", "event_day"),
}


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def queue_row(
    task_id: str,
    kind: str,
    target: str,
    output_dir: str,
    *,
    status: str = "needs_specification",
    **extra: Any,
) -> dict[str, Any]:
    return {
        "task_id": task_id,
        "kind": kind,
        "target": target,
        "output_dir": output_dir,
        "status": status,
        "promotion": "forbidden_without_human_review",
        **extra,
    }


def build(manifest: dict[str, Any], catalog: dict[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    catalog_techniques = {item["id"]: item for item in catalog.get("techniques", [])}
    for target in sorted(TECHNIQUE_ICON_TARGETS):
        if target not in catalog_techniques:
            continue
        rows.append(
            queue_row(
                f"m4::technique_icon::{target}",
                "technique_icon_pack",
                target,
                f"assets/graphics/techniques/{target}",
                status="queued",
                outputs=["icon", "card_art", "thumbnail", "ui_metadata.json", "qa_report.md"],
                canonical_assets=catalog_techniques[target].get("assets", []),
                consumer="technique_catalog_and_code_native_ui",
            )
        )

    for screen in sorted(UI_ICON_TARGETS):
        if screen not in manifest.get("ui_screens", []):
            continue
        rows.append(
            queue_row(
                f"m4::ui_icons::{screen}",
                "ui_icon_pack",
                screen,
                f"assets/graphics/ui/{screen}/icons",
                status="queued",
                outputs=["icons", "ui_metadata.json", "qa_report.md"],
                consumer=screen,
                text_policy="text_rendered_in_godot",
            )
        )

    manifest_arenas = {item["id"]: item for item in manifest.get("arenas", [])}
    for arena_id, variant in sorted(ARENA_TARGETS):
        arena = manifest_arenas.get(arena_id)
        if not arena or variant not in arena.get("variants", []):
            continue
        base = f"assets/graphics/arenas/{arena_id}/{variant}"
        for kind, subdir, layer in [
            ("arena_props_pack", "props", "props"),
            ("arena_particles_pack", "particles", "particles"),
        ]:
            rows.append(
                queue_row(
                    f"m4::{kind}::{arena_id}::{variant}",
                    kind,
                    f"{arena_id}/{variant}",
                    f"{base}/{subdir}",
                    status="needs_item_specification",
                    layers=[layer],
                    arena_type=arena["type"],
                    consumer=f"arena::{arena_id}::{variant}",
                    required_before_generation=[
                        "item_id",
                        "dimensions",
                        "palette",
                        "collision_or_none",
                        "mobile_fallback",
                        "license_chain",
                    ],
                )
            )
    return sorted(rows, key=lambda row: row["task_id"])


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a governed M4 candidate intake queue")
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument("--catalog", type=Path, default=CATALOG)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    rows = build(read_json(args.manifest), read_json(args.catalog))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
    summary = {
        "ok": True,
        "count": len(rows),
        "by_kind": {kind: sum(row["kind"] == kind for row in rows) for kind in sorted({row["kind"] for row in rows})},
        "output": str(args.output),
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
