#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
DEFAULT_DECK = DATA / "ruan_deck_inicial.json"
TECHNIQUES = DATA / "techniques.json"

BELT_LEVEL_LIMIT = {
    "branca": 2,
    "azul": 3,
    "roxa": 4,
    "marrom": 5,
    "preta": 5,
}
FORBIDDEN_LEGACY = ("caio ravel", "ruan cria", "ruan_cria", "caio_ravel")
VALID_KINDS = {"active", "passive"}
VALID_CATEGORIES = {
    "pegada", "queda", "passagem", "raspagem", "controle",
    "finalizacao", "defesa", "transicao",
}


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_deck(path: Path) -> dict[str, Any]:
    errors: list[str] = []
    warnings: list[str] = []
    deck = read_json(path)
    technique_rows = read_json(TECHNIQUES).get("techniques", [])
    technique_ids = {str(row.get("id", "")) for row in technique_rows}
    technique_names = {
        str(row.get("id", "")): str(row.get("nome", row.get("name", "")))
        for row in technique_rows
    }

    if deck.get("owner_id") != "ruan_macacao":
        errors.append("deck inicial deve pertencer a ruan_macacao")
    belt = str(deck.get("belt", ""))
    if belt not in BELT_LEVEL_LIMIT:
        errors.append(f"faixa inválida: {belt}")
    max_level = BELT_LEVEL_LIMIT.get(belt, 0)

    limits = deck.get("limits", {})
    if limits != {"active": 5, "passive": 3, "hand": 3}:
        errors.append("limites devem ser 5 ativas, 3 passivas e mão de 3")

    cards = deck.get("cards", [])
    card_ids = [str(card.get("id", "")) for card in cards]
    for card_id, count in Counter(card_ids).items():
        if not card_id or count > 1:
            errors.append(f"ID de carta vazio ou duplicado: {card_id or '<vazio>'}")

    cards_by_id = {str(card.get("id", "")): card for card in cards}
    for card in cards:
        card_id = str(card.get("id", "<sem_id>"))
        technique_id = str(card.get("technique_id", ""))
        level = card.get("level")
        if technique_id not in technique_ids:
            errors.append(f"{card_id}: técnica inexistente no cânone: {technique_id}")
        if card.get("kind") not in VALID_KINDS:
            errors.append(f"{card_id}: kind inválido")
        if card.get("category") not in VALID_CATEGORIES:
            errors.append(f"{card_id}: categoria inválida")
        if not isinstance(level, int) or level < 1 or level > 5:
            errors.append(f"{card_id}: nível deve estar entre 1 e 5")
        elif bool(card.get("unlocked", False)) and level > max_level:
            errors.append(f"{card_id}: nível {level} excede limite {max_level} da faixa {belt}")
        if float(card.get("base_power", -1)) < 0 or float(card.get("base_power", 31)) > 30:
            errors.append(f"{card_id}: base_power fora de 0..30")
        if technique_id in technique_names and str(card.get("name", "")) != technique_names[technique_id]:
            warnings.append(f"{card_id}: nome difere do catálogo ({technique_names[technique_id]})")

    equipped = deck.get("equipped", {})
    active = equipped.get("active", [])
    passive = equipped.get("passive", [])
    if len(active) > 5 or len(passive) > 3:
        errors.append("deck equipado excede 5 cartas ativas ou 3 passivas")
    if len(set(active + passive)) != len(active + passive):
        errors.append("a mesma carta não pode ocupar mais de um slot")
    for card_id in active:
        card = cards_by_id.get(card_id)
        if not card:
            errors.append(f"carta ativa equipada não existe: {card_id}")
        elif card.get("kind") != "active" or not card.get("unlocked", False):
            errors.append(f"carta ativa inválida/bloqueada: {card_id}")
    for card_id in passive:
        card = cards_by_id.get(card_id)
        if not card:
            errors.append(f"carta passiva equipada não existe: {card_id}")
        elif card.get("kind") != "passive" or not card.get("unlocked", False):
            errors.append(f"carta passiva inválida/bloqueada: {card_id}")

    normalized_text = json.dumps(deck, ensure_ascii=False).lower().replace("“", "").replace("”", "")
    for forbidden in FORBIDDEN_LEGACY:
        if forbidden in normalized_text:
            errors.append(f"conteúdo legado proibido encontrado: {forbidden}")

    return {
        "ok": not errors,
        "file": str(path.relative_to(ROOT)),
        "errors": errors,
        "warnings": warnings,
        "counts": {"cards": len(cards), "active": len(active), "passive": len(passive)},
        "belt": belt,
        "belt_level_limit": max_level,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Valida conteúdo do Lore Guardian e decks contra o cânone.")
    parser.add_argument("path", nargs="?", default=str(DEFAULT_DECK))
    args = parser.parse_args()
    path = Path(args.path).resolve()
    if not path.exists():
        print(json.dumps({"ok": False, "errors": [f"arquivo ausente: {path}"]}, ensure_ascii=False, indent=2))
        return 1
    try:
        result = validate_deck(path)
    except (OSError, json.JSONDecodeError, TypeError, ValueError) as exc:
        result = {"ok": False, "errors": [str(exc)], "file": str(path)}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
