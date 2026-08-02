#!/usr/bin/env python3
"""Validate the P0 canon for faction ALE, Baixo Sul map and gold vertical slice."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]

CANON_PATH = ROOT / "data/production/canon_contract_v4_1.json"
FACTION_MIGRATION_PATH = ROOT / "data/production/faction_migration_v4_2.json"
GOVERNANCE_PATH = ROOT / "data/production/repository_governance_v01.json"
FACTIONS_PATH = ROOT / "data/factions.json"
FACTION_DIRECTOR_PATH = ROOT / "data/factions/faction_director_v02.json"
WORLD_MAP_PATH = ROOT / "data/world/baixo_sul_map_v2.json"
VERTICAL_SLICE_PATH = ROOT / "data/production/vertical_slice_gold_v1.json"
TECHNIQUES_PATH = ROOT / "data/techniques.json"
DECISIONS_PATH = ROOT / "docs/DECISIONS.md"
AGENTS_PATH = ROOT / "AGENTS.md"

EXPECTED_ALE_DISPLAY = "Os Aleluiados"
EXPECTED_ACTIVE_FACTIONS = {"ALE", "LEM", "NTM"}
EXPECTED_MUNICIPALITIES = {
    "itubera",
    "igrapiuna",
    "camamu",
    "nilo_pecanha",
    "valenca",
    "cairu",
    "wenceslau_guimaraes",
}
EXPECTED_ARENAS = {
    "terreiro_luta",
    "dique_itubera",
    "praia_pratigi",
    "cachoeira_pancada",
    "ponte_saici",
    "manguezal_profundo",
    "zambiapunga",
    "beira_rio_nilo",
    "ferro_velho_cais",
    "casario_camamu",
    "ginasio_valenca",
    "porto_valenca",
    "praia_gamboa",
    "dojo_igrapiuna",
    "clareira_mata",
}
EXPECTED_VERTICAL_SLICE_TECHNIQUES = {
    "grip_de_ferro",
    "baiana",
    "sprawl",
    "puxada_guarda",
    "corte_joelho",
    "montada_pesada",
    "saida_montada",
    "mata_leao",
}
FORBIDDEN_PLAYABLE_NODES = {"salvador", "sao_paulo", "itacare"}


class ValidationError(RuntimeError):
    """Raised when a canonical invariant is violated."""


def load_json(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise ValidationError(f"Arquivo obrigatório ausente: {path.relative_to(ROOT)}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValidationError(f"JSON inválido em {path.relative_to(ROOT)}: {exc}") from exc
    if not isinstance(data, dict):
        raise ValidationError(f"Objeto JSON esperado em {path.relative_to(ROOT)}")
    return data


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate_ale_display() -> None:
    canon = load_json(CANON_PATH)
    migration = load_json(FACTION_MIGRATION_PATH)
    governance = load_json(GOVERNANCE_PATH)
    factions = load_json(FACTIONS_PATH)
    director = load_json(FACTION_DIRECTOR_PATH)

    future = {item["id"]: item for item in canon.get("active_factions_future_domain", [])}
    require(set(future) == EXPECTED_ACTIVE_FACTIONS, "Domínio futuro deve conter exatamente ALE, LEM e NTM")
    require(future["ALE"]["display_name"] == EXPECTED_ALE_DISPLAY, "Contrato v4.1 usa display incorreto de ALE")
    require(canon.get("d10", {}).get("canonical_display_name") == EXPECTED_ALE_DISPLAY, "D10 executável não usa Os Aleluiados")

    active = migration.get("active_factions", {})
    require(set(active) == EXPECTED_ACTIVE_FACTIONS, "Migração v4.2 deve conter exatamente três facções")
    require(active["ALE"]["display_name"] == EXPECTED_ALE_DISPLAY, "Migração v4.2 usa display incorreto de ALE")

    protected = governance.get("protected_invariants", {}).get("active_faction_display_names", {})
    require(protected.get("ALE") == EXPECTED_ALE_DISPLAY, "Governança usa display incorreto de ALE")

    ale_catalog = next(
        (item for item in factions.get("factions", []) if item.get("canonical_id") == "ALE"),
        None,
    )
    require(ale_catalog is not None, "Catálogo não contém a facção ALE")
    require(ale_catalog.get("id") == "os_aleluia", "Alias legado os_aleluia deve ser preservado")
    require(ale_catalog.get("name") == EXPECTED_ALE_DISPLAY, "Catálogo usa display incorreto de ALE")

    ale_director = director.get("factions", {}).get("ALE", {})
    require(ale_director.get("name") == EXPECTED_ALE_DISPLAY, "Faction Director usa display incorreto de ALE")

    decisions = DECISIONS_PATH.read_text(encoding="utf-8")
    agents = AGENTS_PATH.read_text(encoding="utf-8")
    require("## D10 — Nome canônico da facção ALE" in decisions, "D10 ausente em DECISIONS.md")
    require(EXPECTED_ALE_DISPLAY in decisions, "DECISIONS.md não registra Os Aleluiados")
    require(f"nome de exibição de ALE: **{EXPECTED_ALE_DISPLAY}**" in agents, "AGENTS.md não protege Os Aleluiados")


def validate_world_map() -> None:
    world = load_json(WORLD_MAP_PATH)
    scope = world.get("world_scope", {})
    require(scope.get("playable_region") == "Baixo Sul da Bahia", "Região jogável deve ser Baixo Sul da Bahia")
    require(scope.get("playable_outside_region_forbidden") is True, "Jogo fora do Baixo Sul deve ser bloqueado")
    require(scope.get("hub_municipality_id") == "itubera", "Ituberá deve ser o hub municipal")

    municipalities = {item["id"]: item for item in world.get("municipalities", [])}
    require(set(municipalities) == EXPECTED_MUNICIPALITIES, "Municípios jogáveis não correspondem ao cânone")
    require(all(item.get("playable") is True for item in municipalities.values()), "Todo município listado deve ser jogável")

    arenas = {item["id"]: item for item in world.get("arenas", [])}
    require(set(arenas) == EXPECTED_ARENAS, "O contrato deve conter exatamente as 15 arenas canônicas")
    require(len(arenas) == 15, "Quantidade de arenas canônicas deve ser 15")
    require(arenas["ponte_saici"].get("municipality_id") == "itubera", "Ponte do Saicí deve pertencer a Ituberá")
    require(arenas["praia_pratigi"].get("municipality_id") == "itubera", "Pratigi deve pertencer a Ituberá")
    require(arenas["zambiapunga"].get("municipality_id") == "nilo_pecanha", "Zambiapunga deve pertencer a Nilo Peçanha")

    for arena in arenas.values():
        require(arena.get("municipality_id") in municipalities, f"Arena sem município canônico: {arena.get('id')}")

    boundaries = {item["id"] for item in world.get("non_playable_boundaries", [])}
    require(FORBIDDEN_PLAYABLE_NODES <= boundaries, "Salvador, São Paulo e Itacaré devem estar nas bordas não jogáveis")
    require(not (FORBIDDEN_PLAYABLE_NODES & set(municipalities)), "Nó externo foi promovido a município jogável")

    invariants = world.get("technical_invariants", {})
    require(invariants.get("instant_finish") is False, "instant_finish deve permanecer false")
    require(invariants.get("clash_modifier_min") == -0.30, "Clamp mínimo incorreto")
    require(invariants.get("clash_modifier_max") == 0.35, "Clamp máximo incorreto")

    decisions = DECISIONS_PATH.read_text(encoding="utf-8")
    require("## D14 — Mundo jogável: Baixo Sul da Bahia" in decisions, "D14 ausente em DECISIONS.md")


def validate_vertical_slice() -> None:
    contract = load_json(VERTICAL_SLICE_PATH)
    techniques = load_json(TECHNIQUES_PATH)
    technique_ids = {item.get("id") for item in techniques.get("techniques", [])}

    require(contract.get("player", {}).get("character_id") == "ruan_macacao", "Ruan deve ser o jogador do vertical slice")
    require(contract.get("opponent", {}).get("character_id") == "davi_relampago", "Davi deve ser o rival do vertical slice")
    require(contract.get("world", {}).get("hub_arena_id") == "terreiro_luta", "Terreiro deve ser o hub do vertical slice")
    require(contract.get("world", {}).get("combat_arena_id") == "dique_itubera", "Dique de Ituberá deve ser a arena")

    combat = contract.get("combat", {})
    selected = set(combat.get("paired_technique_ids", []))
    require(selected == EXPECTED_VERTICAL_SLICE_TECHNIQUES, "Oito técnicas pareadas do vertical slice divergentes")
    require(selected <= technique_ids, f"Técnicas inexistentes no catálogo: {sorted(selected - technique_ids)}")
    require(combat.get("instant_finish") is False, "Vertical slice não pode permitir finalização instantânea")
    require(combat.get("clash_modifier") == {"min": -0.30, "max": 0.35}, "Clamp do vertical slice incorreto")
    require(combat.get("fixed_hud_resources") == ["gas", "control", "grip", "flow"], "HUD fixo deve ter Gás, Controle, Pegada e Fluxo")

    deck = contract.get("deck", {})
    require(deck.get("active_cards_equipped") == 5, "Deck deve equipar cinco cartas ativas")
    require(deck.get("passive_fundamentals") == 3, "Deck deve conter três fundamentos passivos")
    require(deck.get("contextual_hand_size") == 3, "Mão contextual deve conter três cartas")

    device = contract.get("device_gate", {})
    require(device.get("android_arm64_physical_test_required") is True, "Teste físico Android deve ser obrigatório")
    require(device.get("minimum_sustained_fps") == 45, "Meta mínima do vertical slice deve ser 45 FPS")


def validate() -> list[str]:
    checks = [
        ("ale_display", validate_ale_display),
        ("baixo_sul_world", validate_world_map),
        ("vertical_slice_gold", validate_vertical_slice),
    ]
    passed: list[str] = []
    for name, check in checks:
        check()
        passed.append(name)
    return passed


def main() -> int:
    try:
        passed = validate()
    except (ValidationError, OSError, KeyError, TypeError) as exc:
        print(f"[P0Canon] FAIL: {exc}", file=sys.stderr)
        return 1

    print(f"[P0Canon] PASS: {', '.join(passed)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
