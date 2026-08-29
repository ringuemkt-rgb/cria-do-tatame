#!/usr/bin/env python3
"""Fail-closed V4 OIIA lore gate for the Cria do Tatame repository."""
from __future__ import annotations

import argparse
import json
import sys
import tempfile
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SELF = Path(__file__).resolve()

WHITELIST = {
    "OIIA-A01": "Serinhaém/Santarém, 1758–1759",
    "OIIA-A02": "Paiaiá como primeiros povoadores",
    "OIIA-A03": "divergência Paiaiá 10×40 preservada",
    "OIIA-A04": "João Francisco de Souza, 1828",
    "OIIA-A05": "Maximiana, 1875, APEB 69/2468/12",
    "OIIA-A06": "Felicidade, 1880",
    "OIIA-A07": "Central para Porto Grande",
    "OIIA-A08": "Lei 759/1909 sobre foros, não fundação",
    "OIIA-A09": "topônimo de 1943/1944",
    "OIIA-A10": "Decreto 34.293/1953",
    "OIIA-A11": "nipo-baianos por volta de 1954",
    "OIIA-A12": "Igrapiúna: 1801, 1890, 1931, 1933, 1938 e 1989–1990",
    "OIIA-A13": "Carta Régia de 1811 e seus motivos formais",
    "OIIA-A14": "Boitaraca, Jatimane e Lagoa Santa, 653 ha",
    "OIIA-A15": "Zambiapunga como patrimônio em 2018",
    "OIIA-A16": "APA Pratigi, 85.686 ha, 1998/2001",
    "OIIA-A17": "Revolta de Camamu, 1691–1692",
    "OIIA-A18": "Carta Régia de 1668",
    "OIIA-A19": "Firestone/Michelin e Fazenda Três Pancadas, referência histórica somente",
}

BLACKLIST = {
    "OIIA-B01": "Ituberá nasceu 1909",
    "OIIA-B02": "Ituberá é nome indígena original",
    "OIIA-B03": "todos Tupinambá",
    "OIIA-B04": "guerra 300 anos",
    "OIIA-B05": "guerra de 300 anos",
    "OIIA-B06": "Pancada Grande campo de batalha",
    "OIIA-B07": "Nilo Peçanha por ataques indígenas",
    "OIIA-B08": "Igrapiúna só 1989",
    "OIIA-B09": "comunidade certificada = titulada",
    "OIIA-B10": "restauração IA = evidência",
}

FUTURE_FILES = (
    "docs/future/world_map_v3.md",
    "docs/future/arenas_v2.md",
    "docs/future/roster_v2.md",
    "docs/future/factions_v2.md",
    "docs/future/marcos_v2.md",
    "docs/future/systems_v2.md",
    "docs/future/ux_v2.md",
    "docs/future/graphics_v3.md",
    "docs/future/crime_v2.md",
    "docs/future/homenagens_v4.md",
)

TEXT_SUFFIXES = {
    ".md", ".txt", ".json", ".jsonl", ".gd", ".tscn", ".tres", ".cfg",
    ".yml", ".yaml", ".html", ".css", ".js", ".mjs", ".py",
}
SKIP_DIRS = {".git", ".godot", "node_modules", "builds", "tmp", "reports"}
VISUAL_TRIGGERS = (
    "recriacao visual",
    "reconstrucao visual",
    "restauracao generativa",
    "imagem gerada por ia",
    "derivado visual",
)
VISUAL_LABEL = "derivado visual nunca evidencia"
MAP_TRIGGER = "mapa sei"
MAP_LABEL = "reconstrucao moderna"
FUTURE_REAL_MARKS = ("firestone", "michelin", "adcc", "ibjjf", "ufc")


def normalize(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value)
    plain = "".join(char for char in decomposed if not unicodedata.combining(char))
    tokens = "".join(char.casefold() if char.isalnum() else " " for char in plain)
    return " ".join(tokens.split())


def iter_text_files(root: Path):
    for path in sorted(root.rglob("*")):
        relative_parts = path.relative_to(root).parts
        if not path.is_file() or any(part in SKIP_DIRS for part in relative_parts):
            continue
        if path.resolve() == SELF:
            continue
        if path.suffix.casefold() not in TEXT_SUFFIXES and path.name not in {"README", "LICENSE"}:
            continue
        yield path


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError) as exc:
        raise AssertionError(f"não foi possível ler {path}: {exc}") from exc


def validate_tree(root: Path, require_contract: bool = True) -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    for path in iter_text_files(root):
        text = read_text(path)
        normalized = normalize(text)
        relative = str(path.relative_to(root))
        for claim_id, blocked in BLACKLIST.items():
            if normalize(blocked) in normalized:
                findings.append({"code": "BLACKLIST", "claim_id": claim_id, "path": relative})
        if any(trigger in normalized for trigger in VISUAL_TRIGGERS) and VISUAL_LABEL not in normalized:
            findings.append({"code": "VISUAL_LABEL_MISSING", "path": relative})
        if MAP_TRIGGER in normalized and MAP_LABEL not in normalized:
            findings.append({"code": "MAP_LABEL_MISSING", "path": relative})
        if relative.startswith("docs/future/"):
            for mark in FUTURE_REAL_MARKS:
                if mark in normalized:
                    findings.append({"code": "REAL_MARK_IN_PRODUCT_REFERENCE", "term": mark, "path": relative})

    if not require_contract:
        return findings

    for relative in FUTURE_FILES:
        path = root / relative
        if not path.is_file():
            findings.append({"code": "FUTURE_FILE_MISSING", "path": relative})
            continue
        first_line = read_text(path).splitlines()[0] if read_text(path).splitlines() else ""
        if "PÓS-SLICE — ref D232/D233" not in first_line:
            findings.append({"code": "FUTURE_HEADER_INVALID", "path": relative})

    homenagens = root / "docs/future/homenagens_v4.md"
    if homenagens.is_file():
        content = read_text(homenagens)
        for claim_id in WHITELIST:
            if claim_id not in content:
                findings.append({"code": "WHITELIST_ID_MISSING", "claim_id": claim_id, "path": str(homenagens.relative_to(root))})
    return findings


def self_test() -> None:
    with tempfile.TemporaryDirectory(prefix="lore-v4-") as temp:
        root = Path(temp)
        clean = root / "clean.md"
        clean.write_text("Recriação visual — derivado visual, nunca evidência.\n", encoding="utf-8")
        assert validate_tree(root, require_contract=False) == []

        clean.write_text(BLACKLIST["OIIA-B01"], encoding="utf-8")
        assert any(item["code"] == "BLACKLIST" for item in validate_tree(root, require_contract=False))

        clean.write_text("Recriação visual sem rótulo.", encoding="utf-8")
        assert any(item["code"] == "VISUAL_LABEL_MISSING" for item in validate_tree(root, require_contract=False))

        clean.write_text("Mapa SEI — reconstrução moderna.", encoding="utf-8")
        assert validate_tree(root, require_contract=False) == []
    print(json.dumps({"tool": "validate_lore_v4", "self_test": "PASS"}, ensure_ascii=False))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0

    root = args.root.resolve()
    findings = validate_tree(root)
    report = {
        "gate": "V4_OIIA_LORE",
        "status": "PASS" if not findings else "BLOCKED",
        "whitelist_claims": len(WHITELIST),
        "blacklist_patterns": len(BLACKLIST),
        "findings": findings,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not findings else 1


if __name__ == "__main__":
    sys.exit(main())
