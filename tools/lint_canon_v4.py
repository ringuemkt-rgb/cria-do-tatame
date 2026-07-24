from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {"LEM", "NTM", "ALE"}
FORBIDDEN_AS_FACTION = {
    "terreiro",
    "raiz",
    "cria_live",
    "circuito_oficial",
    "dragao_vermelho",
    "fantasma",
}


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def assert_exact_three(values: set[str], label: str) -> None:
    assert values == ALLOWED, f"{label}: esperado {sorted(ALLOWED)}, recebido {sorted(values)}"


def validate_factions_v3() -> None:
    data = load("data/factions/factions_v3.json")
    factions = set(data.get("faccoes", {}))
    assert_exact_three(factions, "factions_v3.faccoes")
    nuclei = data.get("nucleos", {})
    for nucleus_id, nucleus in nuclei.items():
        assert nucleus_id not in factions, f"núcleo promovido a facção: {nucleus_id}"
        assert nucleus.get("faccao_pai") in ALLOWED, nucleus_id


def validate_core_catalog() -> None:
    data = load("data/factions.json")
    ids = {str(item.get("id", "")) for item in data.get("factions", [])}
    assert_exact_three(ids, "factions.json.factions")
    institutions = {str(item.get("id", "")) for item in data.get("institutions", [])}
    axes = {str(item.get("id", "")) for item in data.get("community_axes", [])}
    retired = {str(item.get("id", "")) for item in data.get("retired_lore", [])}
    assert {"circuito_oficial", "cria_live"}.issubset(institutions)
    assert {"terreiro", "raiz"}.issubset(axes)
    assert {"dragao_vermelho", "fantasma"}.issubset(retired)
    assert ids.isdisjoint(institutions | axes | retired)


def validate_director() -> None:
    data = load("data/factions/faction_director_v3.json")
    assert_exact_three(set(data.get("factions", {})), "faction_director_v3.factions")
    assert data.get("faction_ids") == ["LEM", "NTM", "ALE"]
    source = (ROOT / "src/autoloads/FactionDirectorV3.gd").read_text(encoding="utf-8")
    assert 'const CANONICAL_IDS := ["LEM", "NTM", "ALE"]' in source
    assert "faction_director_v3.json" in source
    assert "faction_territories_v3.json" in source


def validate_territories() -> None:
    data = load("data/world/faction_territories_v3.json")
    for territory_id, territory in data.get("territories", {}).items():
        assert territory.get("owner") in ALLOWED | {"neutral"}, territory_id
        assert set(territory.get("challengers", [])).issubset(ALLOWED), territory_id
    for rivalry in data.get("initial_rivalries", []):
        assert rivalry.get("a") in ALLOWED
        assert rivalry.get("b") in ALLOWED
        assert rivalry.get("a") != rivalry.get("b")


def validate_runtime_wiring() -> None:
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    manager = (ROOT / "src/autoloads/FactionManager.gd").read_text(encoding="utf-8")
    save = (ROOT / "src/autoloads/SaveManager.gd").read_text(encoding="utf-8")
    assert 'FactionDirectorManager="*res://src/autoloads/FactionDirectorV3.gd"' in project
    assert 'FactionDirectorManager="*res://src/autoloads/FactionDirectorManager.gd"' not in project
    assert 'const ALL_FACTIONS := ["LEM", "NTM", "ALE"]' in manager
    assert "const SAVE_VERSION := 5" in save
    assert "FactionSaveMigrationV3Script.needs_migration" in save
    assert "FactionSaveMigrationV3Script.migrate" in save

    # O array ativo não pode conter alias, eixo ou grupo aposentado.
    match = re.search(r"const ALL_FACTIONS := \[(.*?)\]", manager)
    assert match, "ALL_FACTIONS ausente"
    active_literal = match.group(1).lower()
    for forbidden in FORBIDDEN_AS_FACTION:
        assert forbidden not in active_literal, f"{forbidden} voltou ao array ativo"


def validate_no_fourth_faction_in_active_data() -> None:
    active_files = [
        "data/factions/factions_v3.json",
        "data/factions/faction_director_v3.json",
        "data/factions.json",
        "data/world/faction_territories_v3.json",
    ]
    for relative in active_files:
        data = load(relative)
        serialized = json.dumps(data, ensure_ascii=False)
        # Todas as referências em campos semanticamente ativos são verificadas
        # pelos validadores estruturais acima; aqui bloqueamos IDs canônicos
        # semelhantes que tentem criar uma quarta sigla.
        for candidate in re.findall(r'"(?:id|owner|faccao_pai|a|b)"\s*:\s*"([A-Z]{3,5})"', serialized):
            if candidate in {"CRIACOIN", "MOLHO"}:
                continue
            assert candidate in ALLOWED or candidate == "", f"quarta facção em {relative}: {candidate}"


def main() -> int:
    validate_factions_v3()
    validate_core_catalog()
    validate_director()
    validate_territories()
    validate_runtime_wiring()
    validate_no_fourth_faction_in_active_data()
    print("canon-v4: OK — runtime, catálogo, territórios e save usam exatamente LEM, NTM e ALE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
