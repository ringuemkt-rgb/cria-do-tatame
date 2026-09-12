#!/usr/bin/env python3
"""Validate the CRIA DO TATAME skill-tree visual bible contracts.

Fail-closed rules:
- exactly 10 visual reference pages;
- reference images are non-runtime and shipping=false;
- five canonical skill paths exist exactly once;
- generated visual text/numbers are not gameplay authority;
- canonical faction names and five-belt order remain untouched;
- numeric balance stays pending until the declared gameplay EPICs.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def fail(msg: str) -> None:
    raise AssertionError(msg)


def main() -> int:
    visual = load("data/visual/skill_tree_visual_manifest_v1.json")
    graph = load("data/progression/skill_graph_v1.json")
    ui = load("data/visual/skill_tree_ui_contract_v1.json")
    canon = load("data/brand/canon_lock.json")
    factions = load("data/factions/factions_v2.json")

    pages = visual.get("pages", [])
    if len(pages) != 10:
        fail(f"visual pages != 10: {len(pages)}")
    if [p.get("order") for p in pages] != list(range(1, 11)):
        fail("visual page order must be exactly 1..10")
    if len({p.get("id") for p in pages}) != 10:
        fail("visual page ids must be unique")
    if visual.get("shipping") is not False:
        fail("visual bible must remain shipping=false")
    if visual.get("text_authority") is not False:
        fail("generated text must not be authority")
    if visual.get("numeric_balance_authority") is not False:
        fail("generated numeric balance must not be authority")
    if visual.get("repo_binary_status") != "pending_phase2_ingestion":
        fail("reference binaries must remain pending Phase 2 ingestion")
    for page in pages:
        if page.get("dimensions") != [1672, 941]:
            fail(f"unexpected dimensions for {page.get('id')}")
        sha = page.get("source_sha256", "")
        if len(sha) != 64:
            fail(f"invalid sha256 for {page.get('id')}")
        if not page.get("library_file_id", "").startswith("libfile_"):
            fail(f"missing persistent Library id for {page.get('id')}")

    paths = graph.get("paths", [])
    ids = [p.get("id") for p in paths]
    expected_paths = ["pressure", "technique", "mobility", "finalization", "resilience"]
    if ids != expected_paths:
        fail(f"canonical paths mismatch: {ids}")
    if graph.get("belt_order") != ["white", "blue", "purple", "brown", "black"]:
        fail("canonical belt order drift")
    if graph.get("numeric_balance_status") != "pending_epic55_epic56":
        fail("numeric balance must remain pending")
    if graph.get("guardrails", {}).get("ui_decides_rules") is not False:
        fail("UI must not decide progression rules")

    if ui.get("runtime_rules", {}).get("no_baked_text_for_interactive_ui") is not True:
        fail("runtime UI must forbid baked interactive text")
    if ui.get("runtime_rules", {}).get("no_reference_image_as_runtime_screen") is not True:
        fail("reference boards must not be runtime screens")
    if ui.get("accessibility", {}).get("color_only_signaling") is not False:
        fail("color-only node signaling is forbidden")

    official = {f["id"]: f["display_name"] for f in factions.get("factions", [])}
    expected_factions = {
        "ALE": "Os Aleluiado",
        "LEM": "Lá Ele Mil Vezes",
        "NTM": "Nós Tem Um Molho",
    }
    if official != expected_factions:
        fail(f"faction canon drift: {official}")

    canon_belts = graph.get("belt_order")
    if len(canon_belts) != 5:
        fail("five-belt progression required")

    print("SKILL_TREE_VISUAL_BIBLE_OK")
    print(f"pages={len(pages)} paths={len(paths)} shipping={visual.get('shipping')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
