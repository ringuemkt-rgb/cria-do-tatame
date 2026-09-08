#!/usr/bin/env python3
"""Fail-closed validator for .agents/skills/cria-art-direction.

This gate validates the repository-installed authoring skill against current
executable canon/visual tokens. It does not approve any binary asset.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SKILL = ROOT / ".agents/skills/cria-art-direction/SKILL.md"
PALETTE = ROOT / ".agents/skills/cria-art-direction/references/palette.md"
ANCHORS = ROOT / ".agents/skills/cria-art-direction/references/anchors.md"
QA = ROOT / ".agents/skills/cria-art-direction/references/qa.md"
CANON = ROOT / "data/production/canon_contract_v4_1.json"
UI = ROOT / "data/visual/ui_theme_v2.json"
P1 = ROOT / "production/p1/cria_art_p1_commands_v1.json"

REQUIRED_FILES = [SKILL, PALETTE, ANCHORS, QA, CANON, UI, P1]


def fail(msg: str) -> None:
    raise SystemExit(f"ART_DIRECTION_FAIL: {msg}")


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - surfaced by gate
        fail(f"invalid json {path.relative_to(ROOT)}: {exc}")


def main() -> int:
    missing = [str(p.relative_to(ROOT)) for p in REQUIRED_FILES if not p.exists()]
    if missing:
        fail(f"missing required files: {missing}")

    skill = SKILL.read_text(encoding="utf-8")
    palette = PALETTE.read_text(encoding="utf-8")
    anchors = ANCHORS.read_text(encoding="utf-8")
    qa = QA.read_text(encoding="utf-8")
    canon = load_json(CANON)
    ui = load_json(UI)
    p1 = load_json(P1)

    required_skill_tokens = [
        "name: cria-art-direction",
        "version: 1.0.0",
        "shipping=false",
        "data/production/canon_contract_v4_1.json",
        "data/visual/ui_theme_v2.json",
        "128x128",
        "[64,96]",
        "Os Aleluiado",
        "Costa das Marés",
        "PAIRED_TECHNIQUE",
        "human visual approval",
    ]
    for token in required_skill_tokens:
        if token not in skill:
            fail(f"SKILL.md missing required token: {token}")

    # D10 is intentionally strict: the superseded plural must never be reintroduced
    # into the installed art-direction skill/reference package.
    for path, text in [(SKILL, skill), (PALETTE, palette), (ANCHORS, anchors), (QA, qa)]:
        if "Os Aleluiados" in text:
            fail(f"superseded ALE display name present in {path.relative_to(ROOT)}")

    d10 = canon.get("d10", {})
    if d10.get("canonical_display_name") != "Os Aleluiado":
        fail("canon contract D10 no longer matches expected ALE display name")

    expected_brand = {
        "bg": "#0B0B0D",
        "border": "#C9971C",
        "text": "#EDE6D6",
        "accent": "#C9971C",
    }
    brand = ui.get("brand", {})
    for key, value in expected_brand.items():
        if brand.get(key) != value:
            fail(f"ui_theme_v2 brand.{key}={brand.get(key)!r}, expected {value}")
        if value not in skill or value not in palette:
            fail(f"visual token {value} missing from skill/palette")

    expected_factions = {"ALE": "#FF9408", "LEM": "#4A6741", "NTM": "#3FE3F5"}
    factions = ui.get("factions", {})
    for faction_id, color in expected_factions.items():
        if factions.get(faction_id) != color:
            fail(f"ui_theme_v2 faction {faction_id} mismatch")
        if color not in palette:
            fail(f"palette reference missing faction token {faction_id} {color}")

    if "body_scale_cv <= 0.08" not in qa or "anchor_y_std <= 0.05" not in qa:
        fail("QA reference lost Sprite Forge thresholds")

    if p1.get("status") != "AUTHORING_QUEUE":
        fail("P1 command manifest must remain AUTHORING_QUEUE")
    if p1.get("shipping") is not False:
        fail("P1 command manifest must default shipping=false")
    if p1.get("source_fixture") != "data/bjj/bjj_kg_slice_ruan_davi_v1.json":
        fail("P1 commands must be bound to the current Ruan x Davi fixture")

    batches = p1.get("batches", [])
    ids = [b.get("id") for b in batches]
    required_batches = {"P1-CHAR-01", "P1-TECH-01", "P1-ARENA-01", "P1-UI-01"}
    if not required_batches.issubset(ids):
        fail(f"missing P1 batches: {sorted(required_batches - set(ids))}")

    # The heel-hook entry exists only to test legality in the current GI slice fixture.
    generated_ids = {
        c.get("source_id")
        for batch in batches
        for c in batch.get("commands", [])
        if isinstance(c, dict)
    }
    if "slice_heel_hook" in generated_ids:
        fail("slice_heel_hook is validation-only and must not enter the GI P1 visual queue")

    print("ART_DIRECTION_OK")
    print(f"skill={SKILL.relative_to(ROOT)}")
    print(f"p1_batches={len(batches)}")
    print(f"p1_commands={sum(len(b.get('commands', [])) for b in batches)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
