#!/usr/bin/env python3
"""Validate the canonical Cria do Tatame visual and logo contract."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "data/visual/official_visual_contract_v1.json"
STANDARD = ROOT / "docs/art_bible/OFFICIAL_VISUAL_STANDARD_V1.md"
MATRIX = ROOT / "docs/art_bible/VISUAL_RECONCILIATION_MATRIX_V1.md"
LOGO_REF = ROOT / "docs/art_bible/references/official_logo_reference_v1.png"
CONTACT_SHEET = ROOT / "docs/art_bible/references/visual_reference_contact_sheet_v1.jpg"
AGENTS = ROOT / "AGENTS.md"
SKILL = ROOT / ".agents/skills/cria-do-tatame-game-director/SKILL.md"

EXPECTED_ART_PALETTE = {
    "#0A0A0A", "#1A1A1A", "#B8860B", "#F2C230", "#F2F2F2",
    "#D92323", "#1E3A5F", "#2D5016", "#4B0082",
}
EXPECTED_FACTIONS = {"LEM", "NTM", "ALE"}
REQUIRED_LOGO_COMPONENTS = {
    "silverback_gorilla",
    "gold_aviator_glasses",
    "circular_discipline_focus_respect_evolution_halo",
    "wordmark_CRIA_DO_TATAME",
    "descriptor_JIU_JITSU_E_TUDO",
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def main() -> int:
    errors: list[str] = []

    for path in (CONTRACT, STANDARD, MATRIX, LOGO_REF, CONTACT_SHEET, AGENTS, SKILL):
        if not path.exists():
            errors.append(f"missing required visual artifact: {path.relative_to(ROOT)}")

    if CONTRACT.exists():
        try:
            data = json.loads(read_text(CONTRACT))
        except json.JSONDecodeError as exc:
            errors.append(f"invalid visual contract JSON: {exc}")
            data = {}

        product = data.get("product", {})
        logo = data.get("official_logo", {})
        palettes = data.get("palettes", {})
        corrections = data.get("canon_corrections", {})

        if product.get("official_title") != "Cria do Tatame – Pressão":
            errors.append("official product title drifted")
        if product.get("master_brand_name") != "CRIA DO TATAME":
            errors.append("master brand name drifted")
        if product.get("descriptor") != "JIU-JITSU É TUDO":
            errors.append("official descriptor drifted")
        if logo.get("id") != "cdt_primary_silverback_lockup_v1":
            errors.append("official logo id drifted")
        if logo.get("declaration") != "Esta é a logo oficial completa do jogo.":
            errors.append("official logo declaration missing")
        if set(logo.get("components_required", [])) != REQUIRED_LOGO_COMPONENTS:
            errors.append("official logo component set is incomplete")
        if set(palettes.get("pixel_art", [])) != EXPECTED_ART_PALETTE:
            errors.append("pixel-art palette does not match the canonical nine colors")
        if set(corrections.get("factions_exact", [])) != EXPECTED_FACTIONS:
            errors.append("visual contract must preserve exactly LEM, NTM and ALE")
        if corrections.get("protagonist_display") != "Ruan ‘Macacão’ Silva":
            errors.append("canonical protagonist display name drifted")
        if corrections.get("forbidden_protagonist_alias") != "Ruan ‘Cria’ Silva":
            errors.append("forbidden protagonist alias guard is missing")
        if corrections.get("arena_do_dique_region") != "Salvador - Bahia":
            errors.append("Arena do Dique region drifted")
        if corrections.get("praia_de_pratigi_region") != "Ituberá - Bahia":
            errors.append("Praia de Pratigi region drifted")

    if STANDARD.exists():
        standard = read_text(STANDARD)
        for required in (
            "logo oficial completa do jogo",
            "cdt_primary_silverback_lockup_v1",
            "Ruan “Macacão” Silva",
            "Praia de Pratigi",
            "45 FPS",
        ):
            if required not in standard:
                errors.append(f"visual standard missing required statement: {required}")

    if AGENTS.exists():
        agents = read_text(AGENTS)
        if "OFFICIAL_VISUAL_STANDARD_V1.md" not in agents:
            errors.append("AGENTS.md does not bind the official visual standard")
        if "official_visual_contract_v1.json" not in agents:
            errors.append("AGENTS.md does not bind the executable visual contract")

    if SKILL.exists():
        skill = read_text(SKILL)
        if "OFFICIAL_VISUAL_STANDARD_V1.md" not in skill:
            errors.append("game director skill does not load the official visual standard")

    report = {
        "ok": not errors,
        "contract": str(CONTRACT.relative_to(ROOT)),
        "official_logo": "cdt_primary_silverback_lockup_v1",
        "errors": errors,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
