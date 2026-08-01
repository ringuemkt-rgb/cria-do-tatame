#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
ALE_DISPLAY = "Os Aleluiados"
SKILL_ROOT = ROOT / ".agents/skills/cria-visual-canon-director"

REQUIRED_FILES = [
    ".github/workflows/visual-canon.yml",
    ".agents/skills/cria-visual-canon-director/SKILL.md",
    ".agents/skills/cria-visual-canon-director/references/VISUAL_RECONCILIATION.md",
    ".agents/skills/cria-visual-canon-director/references/QUALITY_GATES.md",
    ".agents/skills/cria-visual-canon-director/references/PRODUCTION_RECIPES.md",
    ".agents/skills/cria-visual-canon-director/scripts/validate_skill.py",
    "data/visual/visual_canon_contract_v2.json",
    "data/visual/reference_audit_v2.json",
    "docs/art_bible/VISUAL_CANON_SYSTEM_V2.md",
]


def read(relative: str | Path) -> str:
    path = relative if isinstance(relative, Path) else ROOT / relative
    if not path.is_file():
        raise AssertionError(f"arquivo ausente: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def load(relative: str | Path) -> dict[str, Any]:
    value = json.loads(read(relative))
    assert isinstance(value, dict), f"raiz JSON inválida: {relative}"
    return value


def validate_files() -> None:
    for relative in REQUIRED_FILES:
        read(relative)


def validate_contract() -> None:
    contract = load("data/visual/visual_canon_contract_v2.json")
    assert contract["schema_version"] == "2.0.0"
    assert contract["contract_id"] == "cria_visual_canon_v2"
    assert contract["status"] == "canonical_contract"

    product = contract["product"]
    assert product["protagonist_id"] == "ruan_macacao"
    assert product["protagonist_display"] == "Ruan Macacão Silva"
    assert product["origin"] == "Ituberá, Baixo Sul da Bahia"
    assert product["core"] == "Jiu-Jitsu Brasileiro posicional"
    assert product["platform_floor"] == "android_arm64"
    assert product["runtime"] == "deterministic_offline"

    style = contract["visual_style"]
    assert style["final_art_dimension"] == "2D"
    assert style["three_dimensional_reference_allowed"] is True
    assert style["three_dimensional_final_art_forbidden"] is True
    assert style["texture_filter"] == "nearest"
    assert style["grid_px"] == 16
    assert style["combat_sprite_height_px"] == 72
    assert style["hub_sprite_cell_px"] == 64
    assert style["outline_px"] == 1
    assert style["rim_light_px"] == 1
    assert style["safe_area_percent"] == 7
    assert style["minimum_touch_target_dp"] == 48
    assert style["minimum_device_fps"] == 45
    assert style["readability_scales_percent"] == [100, 50, 25]

    factions = contract["factions"]
    assert factions["active_ids"] == ["ALE", "LEM", "NTM"]
    assert factions["display_names"]["ALE"] == ALE_DISPLAY
    assert factions["legacy_aliases"]["os_aleluia"] == "ALE"
    assert factions["visual_rules"]["fourth_faction_forbidden"] is True

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

    source = contract["source_of_truth_by_category"]
    assert source == {
        "characters": "data/characters.json",
        "arenas": "data/arenas.json",
        "factions": "data/factions.json",
        "techniques": "data/techniques.json",
        "visual_inventory": "data/visual/production_manifest_v02.json",
        "brand": "data/visual/brand_identity_v01.json",
    }

    batch = contract["batch_policy"]
    assert batch["maximum_items"] == 10
    assert batch["same_asset_type_required"] is True
    assert batch["one_batch_one_commit"] is True
    assert batch["qa_before_next_batch"] is True
    assert batch["automatic_promotion_forbidden"] is True

    paired = contract["paired_animation"]
    assert paired["attacker_and_defender_required"] is True
    assert paired["equal_frame_count_required"] is True
    assert paired["shared_pivot_required"] is True
    assert paired["grip_before_force_required"] is True
    assert paired["finish_resolutions"] == ["tap", "escape", "technical_intervention"]
    assert paired["instant_finish"] is False
    assert paired["human_biomechanics_review_required"] is True

    assert contract["world_map"]["model"] == "regional_node_and_route_map"
    assert contract["world_map"]["continuous_3d_open_world_promised"] is False
    assert contract["hud"]["editorial_panels_in_combat_forbidden"] is True
    assert contract["quality"]["minimum_score_for_qa"] == 90
    assert contract["quality"]["minimum_score_for_human_approval"] == 95
    assert contract["quality"]["blockers_override_score"] is True

    forbidden = set(contract["forbidden_final_styles"])
    assert {
        "photography",
        "photorealistic_3d",
        "blurred_pixel_art",
        "generic_tropical_favela",
        "mma_striking_core",
        "gore",
        "injury_reward_animation",
    }.issubset(forbidden)


def validate_audit_and_skill() -> None:
    audit = load("data/visual/reference_audit_v2.json")
    assert audit["status"] == "canonical_reference_audit"
    assert audit["policy"]["images_are_reference_not_runtime"] is True
    assert audit["policy"]["canon_overrides_image_text"] is True
    assert len(audit["groups"]) >= 10
    assert all(group["runtime_direct"] is False for group in audit["groups"])
    assert "replace_Ruan_Cria_header" in audit["character_corrections"]["ruan_macacao"]
    assert "hair_is_not_weapon" in audit["character_corrections"]["leoa_quilombola"]
    assert "replace_real_police_branding" in audit["character_corrections"]["delegado_montenegro"]
    assert "Itubera_context_not_Chapada_Diamantina" in audit["arena_corrections"]["pancada_grande"]

    skill = read(SKILL_ROOT / "SKILL.md")
    assert "name: cria-visual-canon-director" in skill
    assert 'version: "2.0.0"' in skill
    assert "Ruan “Macacão” Silva" in skill
    assert ALE_DISPLAY in skill
    assert "2D pixel art com apresentação 2.5D" in skill
    assert "máximo de dez imagens por lote" in skill
    assert "data/techniques.json" in skill
    assert "tap, escape ou intervenção técnica" in skill
    for mode in [
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
    ]:
        assert mode in skill

    assert "Bloqueadores absolutos" in read(SKILL_ROOT / "references/QUALITY_GATES.md")
    recipes = read(SKILL_ROOT / "references/PRODUCTION_RECIPES.md")
    assert "Receita de técnica pareada" in recipes
    assert "OS ALELUIADOS" in recipes


def validate_manifest() -> None:
    manifest = load("data/visual/production_manifest_v02.json")
    assert manifest["canon_protagonist"] == "ruan_macacao"
    style = manifest["visual_style"]
    assert style["combat_sprite_height_px"] == 72
    assert style["hub_sprite_cell_px"] == 64
    assert style["grid_px"] == 16
    assert style["texture_filter"] == "nearest"
    extra = manifest["quality_gate"]["paired_technique_extra_files"]
    assert {"attacker", "defender", "sync_map.json"}.issubset(set(extra))
    characters = {item["id"] for item in manifest["characters"]}
    assert {"ruan_macacao", "davi_relampago", "mestre_dende"}.issubset(characters)
    arenas = {item["id"] for item in manifest["arenas"]}
    assert {"arena_do_dique", "terreiro_da_luta", "zambiapunga", "budokan_das_aguas"}.issubset(arenas)


def validate_active_canon() -> None:
    canon = load("data/production/canon_contract_v4_1.json")
    migration = load("data/production/faction_migration_v4_2.json")
    catalog = load("data/factions.json")
    director = load("data/factions/faction_director_v02.json")
    mapper = read("src/factions/FactionIdentityV4.gd")

    ale = next(item for item in canon["active_factions_future_domain"] if item["id"] == "ALE")
    assert ale["display_name"] == ALE_DISPLAY
    assert canon["d10"]["canonical_display_name"] == ALE_DISPLAY
    assert canon["d10"]["preserved_legacy_id"] == "os_aleluia"
    assert migration["active_factions"]["ALE"]["display_name"] == ALE_DISPLAY
    assert migration["active_factions"]["ALE"]["legacy_ids"] == ["os_aleluia"]

    catalog_ale = next(item for item in catalog["factions"] if item.get("canonical_id") == "ALE")
    assert catalog_ale["id"] == "os_aleluia"
    assert catalog_ale["name"] == ALE_DISPLAY
    assert director["factions"]["ALE"]["name"] == ALE_DISPLAY
    assert director["factions"]["ALE"]["short_name"] == "Aleluiados"
    assert '"os_aleluia": "ALE"' in mapper
    assert f'"ALE": "{ALE_DISPLAY}"' in mapper

    # O nome antigo pode aparecer em histórico de decisão, mas nunca como valor ativo.
    active_serialized = json.dumps(
        {
            "canon_display": canon["d10"]["canonical_display_name"],
            "migration_display": migration["active_factions"]["ALE"]["display_name"],
            "catalog_display": catalog_ale["name"],
            "director_display": director["factions"]["ALE"]["name"],
        },
        ensure_ascii=False,
    )
    assert "Os Aleluiado\"" not in active_serialized


def validate_governance() -> None:
    decisions = read("docs/DECISIONS.md")
    index = read("docs/INDEX.md")
    agents = read("AGENTS.md")
    governance = load("data/production/repository_governance_v01.json")
    package = load("package.json")

    for decision in range(1, 14):
        assert f"## D{decision} —" in decisions
    assert "## D13 — Sistema visual canônico" in decisions
    assert f"**{ALE_DISPLAY}**" in decisions
    assert f"**{ALE_DISPLAY}**" in agents
    assert "visual_canon_contract_v2.json" in index
    assert "VISUAL_CANON_SYSTEM_V2.md" in index
    assert "cria-visual-canon-director" in index
    assert "cria-visual-canon-director" in agents

    required = set(governance["required_governance_files"])
    assert set(REQUIRED_FILES).issubset(required)
    protected = governance["protected_invariants"]
    assert protected["protagonist_id"] == "ruan_macacao"
    assert protected["active_faction_display_names"]["ALE"] == ALE_DISPLAY
    assert protected["visual_contract"] == "res://data/visual/visual_canon_contract_v2.json"
    assert protected["visual_skill"] == ".agents/skills/cria-visual-canon-director/SKILL.md"
    assert protected["final_art_dimension"] == "2D"
    assert protected["visual_presentation"] == "2.5D"
    assert protected["visual_batch_maximum"] == 10

    scripts = package["scripts"]
    assert scripts["validate:visual-canon"] == "python tools/audit/validate_visual_canon_v2.py"
    assert "validate:visual-canon" in scripts["quality"]


def validate_no_active_drift() -> None:
    contract = load("data/visual/visual_canon_contract_v2.json")
    assert contract["product"]["protagonist_display"] != "Ruan Cria Silva"
    assert contract["paired_animation"]["instant_finish"] is False
    assert contract["factions"]["active_ids"] == ["ALE", "LEM", "NTM"]
    assert "Caio Ravel" not in json.dumps(contract, ensure_ascii=False)


def main() -> int:
    checks = [
        validate_files,
        validate_contract,
        validate_audit_and_skill,
        validate_manifest,
        validate_active_canon,
        validate_governance,
        validate_no_active_drift,
    ]
    failures: list[str] = []
    for check in checks:
        try:
            check()
        except Exception as exc:  # noqa: BLE001 - CLI agrega todas as falhas
            failures.append(f"{check.__name__}: {exc}")
    if failures:
        print("[VisualCanonV2] FALHOU")
        for failure in failures:
            print(f" - {failure}")
        return 1
    print("[VisualCanonV2] OK")
    print("- arte final: 2D pixel art")
    print("- apresentação: 2.5D por camadas/parallax")
    print("- facções: ALE/LEM/NTM; ALE = Os Aleluiados")
    print("- referências classificadas; promoção automática bloqueada")
    print("- skill, contratos, QA, workflow, governança e dados coerentes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
