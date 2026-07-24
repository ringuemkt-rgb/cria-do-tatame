from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def test_playability_reason_codes_are_canonical() -> None:
    payload = load("data/combat/playability_reason_codes.json")
    assert set(payload["reason_codes"]) == {
        "OK",
        "DECISION_LOCKED",
        "FIGHTER_MISSING",
        "CARD_MISSING",
        "CARD_NOT_IN_LOADOUT",
        "CARD_FORBIDDEN_BY_PROFILE",
        "CARD_NOT_IN_HAND",
        "POSITION_INVALID",
        "STORY_REQUIREMENT",
        "RULESET_FORBIDS_CARD",
        "RESOURCE_INSUFFICIENT",
    }


def test_rulesets_are_authoritative_about_victory() -> None:
    rulesets = load("data/combat/rulesets.json")["rulesets"]
    assert rulesets["OFICIAL"]["caminhos_vitoria"] == ["finalizacao", "pontos", "desistencia"]
    assert rulesets["CLANDESTINA"]["caminhos_vitoria"] == ["finalizacao", "desistencia"]
    assert rulesets["RITO"]["caminhos_vitoria"] == ["ceder"]
    assert rulesets["FESTIVAL"]["caminhos_vitoria"] == ["finalizacao", "pontos"]
    assert rulesets["DOJO"]["caminhos_vitoria"] == []
    assert rulesets["MORAL"]["caminhos_vitoria"] == ["resistir_discurso"]


def test_ruan_kimura_binding_matches_card_catalog() -> None:
    cards = {card["id"]: card for card in load("data/combat/cards.json")["cartas"]}
    manifest = load("data/characters/ruan/animation_manifest.json")
    binding = manifest["bindings"]["kimura"]
    assert binding["card_id"] == "kimura"
    assert binding["move_number"] == 23
    assert binding["technique_id"] == cards["kimura"]["tecnica"]
    assert binding["animation_state"] == cards["kimura"]["frames_anim"]


def test_runtime_contains_single_playability_authority() -> None:
    runtime = (ROOT / "src/combat/PositionalCardCombatV41.gd").read_text(encoding="utf-8")
    assert "func pode_jogar(" in runtime
    assert "func can_play_card(" in runtime
    assert "return pode_jogar(fighter_id, card_id)" in runtime
    assert "func try_resolve_victory(" in runtime
    assert 'get("caminhos_vitoria"' in runtime


def test_owner_policy_guards_unlock_loadout_and_migration() -> None:
    hub = (ROOT / "src/hub/SkillHubLoadoutV41.gd").read_text(encoding="utf-8")
    for method in (
        "func unlock_for_owner(",
        "func can_include(",
        "func forbid_moral_for_owner(",
        "func _sanitize_deck(",
        "func import_state(",
    ):
        assert method in hub
    assert '"owner_policies"' in hub
    assert '"card_forbidden_by_profile"' in hub


def test_moral_gate_is_persistent_and_read_by_ending() -> None:
    world = (ROOT / "src/autoloads/WorldStateV4.gd").read_text(encoding="utf-8")
    endings = (ROOT / "src/autoloads/EndingResolverV4.gd").read_text(encoding="utf-8")
    progression = (ROOT / "src/progression/ProgressionEffects.gd").read_text(encoding="utf-8")
    assert '"moral_nao_humilhar": false' in world
    assert 'flags.get("moral_nao_humilhar", false)' in endings
    assert "and moral_nao_humilhar" in endings
    assert '"respeito_nao_humilhar"' in progression


def test_contract_documents_the_full_chain() -> None:
    contract = (ROOT / "docs/COMBAT_INTEGRATION_CONTRACT.md").read_text(encoding="utf-8")
    for phrase in (
        "progressão → acesso → loadout",
        "Regra canônica de carta jogável",
        "Autoridade dos rulesets sobre vitória",
        "Binding de animação",
        "Definition of Done",
    ):
        assert phrase in contract
