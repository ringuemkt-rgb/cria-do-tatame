#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = Path(__file__).resolve().parents[4]
SKILL_PATH = SKILL_ROOT / "SKILL.md"
CONTRACT_PATH = REPO_ROOT / "data/visual/visual_canon_contract_v2.json"
REQUIRED_REFERENCES = [
    SKILL_ROOT / "references/VISUAL_RECONCILIATION.md",
    SKILL_ROOT / "references/QUALITY_GATES.md",
    SKILL_ROOT / "references/PRODUCTION_RECIPES.md",
]


def read_text(path: Path) -> str:
    if not path.is_file():
        raise AssertionError(f"arquivo ausente: {path.relative_to(REPO_ROOT)}")
    return path.read_text(encoding="utf-8")


def validate_frontmatter() -> None:
    skill = read_text(SKILL_PATH)
    assert skill.startswith("---\n"), "SKILL.md sem frontmatter YAML"
    assert "name: cria-visual-canon-director" in skill
    assert 'version: "2.0.0"' in skill
    assert "contract: data/visual/visual_canon_contract_v2.json" in skill
    assert "license: Proprietary" in skill


def validate_operating_contract() -> None:
    skill = read_text(SKILL_PATH)
    required_phrases = [
        "Ruan “Macacão” Silva",
        "Os Aleluiados",
        "HD painted pixel art 2D com apresentação 2.5D",
        "data/techniques.json",
        "tap, escape ou intervenção técnica",
        "máximo de dez imagens por lote",
        "Nunca compensar uma lacuna com invenção convincente",
    ]
    for phrase in required_phrases:
        assert phrase in skill, f"regra obrigatória ausente: {phrase}"

    required_modes = [
        "/auditar-referencia",
        "/normalizar-canon",
        "/personagem",
        "/tecnica-pareada",
        "/arena",
        "/mapa",
        "/hud",
        "/faccao",
        "/lote",
        "/qa-visual",
        "/integrar-godot",
        "/release-visual",
    ]
    for mode in required_modes:
        assert mode in skill, f"modo operacional ausente: {mode}"


def validate_references() -> None:
    for path in REQUIRED_REFERENCES:
        text = read_text(path)
        assert len(text) >= 1500, f"referência visual incompleta: {path.name}"
    quality = read_text(SKILL_ROOT / "references/QUALITY_GATES.md")
    recipes = read_text(SKILL_ROOT / "references/PRODUCTION_RECIPES.md")
    reconciliation = read_text(SKILL_ROOT / "references/VISUAL_RECONCILIATION.md")
    assert "Bloqueadores absolutos" in quality
    assert "Gate Android físico" in quality
    assert "Receita de técnica pareada" in recipes
    assert "Prompt ALE" in recipes
    assert "Pancada Grande" in reconciliation
    assert "Delegado Montenegro" in reconciliation


def validate_machine_contract_link() -> None:
    contract = json.loads(read_text(CONTRACT_PATH))
    assert contract["contract_id"] == "cria_visual_canon_v2"
    assert contract["status"] == "canonical_contract"
    assert contract["skill_path"] == ".agents/skills/cria-visual-canon-director/SKILL.md"
    assert contract["factions"]["display_names"]["ALE"] == "Os Aleluiados"
    assert contract["visual_style"]["final_art_dimension"] == "2D"
    assert contract["visual_style"]["three_dimensional_final_art_forbidden"] is True
    assert contract["paired_animation"]["instant_finish"] is False
    assert contract["batch_policy"]["maximum_items"] == 10


def main() -> int:
    checks = [
        validate_frontmatter,
        validate_operating_contract,
        validate_references,
        validate_machine_contract_link,
    ]
    failures: list[str] = []
    for check in checks:
        try:
            check()
        except Exception as exc:  # noqa: BLE001 - CLI agrega todas as falhas
            failures.append(f"{check.__name__}: {exc}")
    if failures:
        print("[CriaVisualCanonSkill] FALHOU")
        for failure in failures:
            print(f" - {failure}")
        return 1
    print("[CriaVisualCanonSkill] OK - skill, referências e contrato vinculados")
    return 0


if __name__ == "__main__":
    sys.exit(main())
