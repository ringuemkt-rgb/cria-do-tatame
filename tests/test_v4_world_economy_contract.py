from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_dual_economy_has_no_molho_pay_to_win() -> None:
    data = load("data/economy.json")
    assert set(data["moedas"]) == {"CRIACOIN", "MOLHO"}
    assert data["moedas"]["CRIACOIN"]["tipo"] == "limpa_rastreavel"
    assert data["moedas"]["MOLHO"]["tipo"] == "cinza_nao_rastreavel"
    molho_purchases = set(data["moedas"]["MOLHO"]["compra"])
    assert not molho_purchases.intersection({"carta", "skill_tree", "atributo", "treino", "tecnica"})
    assert data["regras"][-1]["then"]["molho_permitido"] is False
    source = (ROOT / "src/autoloads/EconomyV4.gd").read_text(encoding="utf-8").lower()
    assert "molho_cannot_buy_combat_power" in source
    assert "worldstate.money" in source


def test_world_map_has_exactly_eleven_municipal_nodes() -> None:
    data = load("data/world/world_map_nodes_v4.json")
    nodes = data["nodes"]
    assert len(nodes) == 11
    assert set(nodes) == {
        "itubera", "valenca", "taperoa", "nilo_pecanha", "camamu",
        "cairu", "marau", "itacare", "ibirapitanga", "pirai_do_norte",
        "presidente_tancredo_neves",
    }
    pratigi = data["special_locations"]["pratigi"]
    assert pratigi["municipio"] == "Ituberá"
    assert "pratigi" not in nodes
    for node_id, node in nodes.items():
        assert node["faccao"] in {"LEM", "NTM", "ALE", "neutral"}, node_id
        assert node["travel_cost"], node_id


def test_seasonal_events_use_only_fictional_operations() -> None:
    data = load("data/world/seasonal_events_v4.json")
    event_ids = {event["id"] for event in data["eventos"]}
    assert {"zambiapunga", "paralelo_pratigi", "sao_joao", "chuvas_itubera"}.issubset(event_ids)
    operation_ids = {operation["id"] for operation in data["operacoes_ficticias"]}
    assert operation_ids == {"op_carimbo", "op_tres_mangues"}
    serialized = json.dumps(data, ensure_ascii=False).lower()
    assert "operação chancelas" not in serialized
    assert "operação três coqueiros" not in serialized
    assert "somente nomes e operações fictícios" in serialized


def test_informant_runtime_is_choice_and_evidence_only() -> None:
    source = (ROOT / "src/autoloads/InformantSystem.gd").read_text(encoding="utf-8").lower()
    assert 'const statuses := ["nenhum", "abordado", "recrutado", "ativo", "queimado", "recusado"]' in source
    assert "func add_evidence" in source
    assert "func burn_identity" in source
    assert "func can_reach_martyr_ending" in source
    for forbidden in ("weapon", "firearm", "gunfight", "shoot_target", "kill_target"):
        assert forbidden not in source


def test_runtime_wiring_and_save_contracts() -> None:
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    save = (ROOT / "src/autoloads/SaveManager.gd").read_text(encoding="utf-8")
    assert 'Economy="*res://src/autoloads/EconomyV4.gd"' in project
    assert 'InformantSystem="*res://src/autoloads/InformantSystem.gd"' in project
    assert 'WorldMapManager="*res://src/autoloads/WorldMapManagerV4.gd"' in project
    assert 'data["economy_v4_state"]' in save
    assert 'data["informant_state"]' in save
    assert "Economy.load_from_dict" in save
    assert "InformantSystem.load_from_dict" in save
