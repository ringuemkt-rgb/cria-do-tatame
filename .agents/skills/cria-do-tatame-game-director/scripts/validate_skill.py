#!/usr/bin/env python3
"""Valida a skill Cria do Tatame Game Director e seus vínculos canônicos.

Usa somente a biblioteca padrão para rodar localmente e em CI.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SKILL_ROOT = ROOT / ".agents" / "skills" / "cria-do-tatame-game-director"
SKILL_FILE = SKILL_ROOT / "SKILL.md"
REQUIRED_REFERENCES = {
    "references/OPERATING_MODEL.md",
    "references/QUALITY_GATES.md",
    "references/TOOL_ROUTING.md",
}
EXPECTED_NAME = "cria-do-tatame-game-director"
EXPECTED_FACTIONS = {"LEM", "NTM", "ALE"}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def load_json(path: Path) -> dict:
    return json.loads(read(path))


def validate_frontmatter(errors: list[str]) -> None:
    if not SKILL_FILE.exists():
        errors.append("SKILL.md ausente")
        return
    text = read(SKILL_FILE)
    match = re.match(r"^---\n(?P<header>.*?)\n---\n", text, flags=re.DOTALL)
    if not match:
        errors.append("SKILL.md sem frontmatter YAML válido")
        return
    header = match.group("header")
    name_match = re.search(r"^name:\s*(.+)$", header, flags=re.MULTILINE)
    description_match = re.search(r"^description:\s*(.+)$", header, flags=re.MULTILINE)
    if not name_match:
        errors.append("frontmatter sem name")
    elif name_match.group(1).strip() != EXPECTED_NAME:
        errors.append("name não corresponde ao diretório da skill")
    if not description_match or not description_match.group(1).strip():
        errors.append("frontmatter sem description")
    elif len(description_match.group(1).strip()) > 1024:
        errors.append("description excede 1024 caracteres")


def validate_package(errors: list[str]) -> None:
    for relative in sorted(REQUIRED_REFERENCES):
        if not (SKILL_ROOT / relative).exists():
            errors.append(f"recurso obrigatório ausente: {relative}")


def validate_activation(errors: list[str]) -> None:
    agents = ROOT / "AGENTS.md"
    if not agents.exists():
        errors.append("AGENTS.md ausente")
        return
    text = read(agents)
    expected_path = ".agents/skills/cria-do-tatame-game-director/SKILL.md"
    if expected_path not in text:
        errors.append("AGENTS.md não ativa a skill do diretor")


def validate_repository_truth(errors: list[str]) -> None:
    project = ROOT / "project.godot"
    if not project.exists():
        errors.append("project.godot ausente")
    else:
        text = read(project)
        if 'run/main_scene="res://scenes/main_menu/MainMenu.tscn"' not in text:
            errors.append("main scene canônica foi alterada")

    factions_path = ROOT / "data" / "factions" / "factions_v3.json"
    if not factions_path.exists():
        errors.append("factions_v3.json ausente")
    else:
        data = load_json(factions_path)
        factions = set(data.get("faccoes", {}).keys())
        if factions != EXPECTED_FACTIONS:
            errors.append(f"facções inválidas: {sorted(factions)}")
        for nucleus_id, nucleus in data.get("nucleos", {}).items():
            if nucleus.get("faccao_pai") not in EXPECTED_FACTIONS:
                errors.append(f"núcleo {nucleus_id} sem facção-pai válida")


def main() -> int:
    errors: list[str] = []
    validate_frontmatter(errors)
    validate_package(errors)
    validate_activation(errors)
    validate_repository_truth(errors)

    report = {
        "ok": not errors,
        "skill": EXPECTED_NAME,
        "repository": "ringuemkt-rgb/cria-do-tatame",
        "errors": errors,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
