from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def test_contract_freezes_2d_pixel_art_with_2_5d_presentation() -> None:
    contract = load("data/visual/visual_canon_contract_v2.json")
    style = contract["visual_style"]
    assert contract["contract_id"] == "cria_visual_canon_v2"
    assert contract["status"] == "canonical_contract"
    assert style["final_art_dimension"] == "2D"
    assert style["three_dimensional_reference_allowed"] is True
    assert style["three_dimensional_final_art_forbidden"] is True
    assert style["texture_filter"] == "nearest"
    assert style["combat_sprite_height_px"] == 72
    assert style["hub_sprite_cell_px"] == 64
    assert style["grid_px"] == 16
    assert style["safe_area_percent"] == 7
    assert style["minimum_touch_target_dp"] == 48
    assert style["minimum_device_fps"] == 45


def test_contract_protects_canon_and_bjj_animation_rules() -> None:
    contract = load("data/visual/visual_canon_contract_v2.json")
    assert contract["product"]["protagonist_id"] == "ruan_macacao"
    assert contract["product"]["protagonist_display"] == "Ruan Macacão Silva"
    assert contract["factions"]["active_ids"] == ["ALE", "LEM", "NTM"]
    assert contract["factions"]["display_names"]["ALE"] == "Os Aleluiados"
    assert contract["factions"]["legacy_aliases"]["os_aleluia"] == "ALE"
    assert contract["source_of_truth_by_category"]["techniques"] == "data/techniques.json"
    paired = contract["paired_animation"]
    assert paired["attacker_and_defender_required"] is True
    assert paired["equal_frame_count_required"] is True
    assert paired["shared_pivot_required"] is True
    assert paired["grip_before_force_required"] is True
    assert paired["finish_resolutions"] == ["tap", "escape", "technical_intervention"]
    assert paired["instant_finish"] is False


def test_reference_audit_classifies_images_without_promoting_them() -> None:
    audit = load("data/visual/reference_audit_v2.json")
    assert audit["policy"]["images_are_reference_not_runtime"] is True
    assert audit["policy"]["canon_overrides_image_text"] is True
    assert len(audit["groups"]) >= 10
    assert all(group["runtime_direct"] is False for group in audit["groups"])
    assert "replace_Ruan_Cria_header" in audit["character_corrections"]["ruan_macacao"]
    assert "hair_is_not_weapon" in audit["character_corrections"]["leoa_quilombola"]
    assert "replace_real_police_branding" in audit["character_corrections"]["delegado_montenegro"]
    assert "Itubera_context_not_Chapada_Diamantina" in audit["arena_corrections"]["pancada_grande"]


def test_skill_has_modes_gates_and_production_recipes() -> None:
    skill = read(".agents/skills/cria-visual-canon-director/SKILL.md")
    quality = read(".agents/skills/cria-visual-canon-director/references/QUALITY_GATES.md")
    recipes = read(".agents/skills/cria-visual-canon-director/references/PRODUCTION_RECIPES.md")
    assert "name: cria-visual-canon-director" in skill
    assert 'version: "2.0.0"' in skill
    assert "Ruan “Macacão” Silva" in skill
    assert "Os Aleluiados" in skill
    assert "/tecnica-pareada" in skill
    assert "/integrar-godot" in skill
    assert "/release-visual" in skill
    assert "Bloqueadores absolutos" in quality
    assert "Gate Android físico" in quality
    assert "Receita de técnica pareada" in recipes
    assert "OS ALELUIADOS" in recipes


def test_asset_states_and_batch_policy_prevent_false_completion() -> None:
    contract = load("data/visual/visual_canon_contract_v2.json")
    assert contract["asset_states"] == [
        "reference_only",
        "canon_reconciled",
        "production_candidate",
        "qa_passed",
        "human_approved",
        "godot_integrated",
        "device_tested",
        "release_ready",
    ]
    assert contract["state_transitions_must_be_sequential"] is True
    assert contract["batch_policy"] == {
        "maximum_items": 10,
        "same_asset_type_required": True,
        "single_visual_anchor_required": True,
        "one_batch_one_commit": True,
        "qa_before_next_batch": True,
        "automatic_promotion_forbidden": True,
    }


def test_canonical_faction_display_is_plural_without_changing_alias() -> None:
    canon = load("data/production/canon_contract_v4_1.json")
    migration = load("data/production/faction_migration_v4_2.json")
    catalog = load("data/factions.json")
    director = load("data/factions/faction_director_v02.json")
    mapper = read("src/factions/FactionIdentityV4.gd")
    ale_v41 = next(item for item in canon["active_factions_future_domain"] if item["id"] == "ALE")
    assert ale_v41["display_name"] == "Os Aleluiados"
    assert migration["active_factions"]["ALE"]["display_name"] == "Os Aleluiados"
    ale_catalog = next(item for item in catalog["factions"] if item.get("canonical_id") == "ALE")
    assert ale_catalog["id"] == "os_aleluia"
    assert ale_catalog["name"] == "Os Aleluiados"
    assert director["factions"]["ALE"]["name"] == "Os Aleluiados"
    assert '"os_aleluia": "ALE"' in mapper
    assert '"ALE": "Os Aleluiados"' in mapper


def test_visual_validators_pass() -> None:
    commands = [
        [sys.executable, ".agents/skills/cria-visual-canon-director/scripts/validate_skill.py"],
        [sys.executable, "tools/audit/validate_visual_canon_v2.py"],
    ]
    for command in commands:
        result = subprocess.run(
            command,
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stdout + result.stderr
