#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data/visual/visual_canon_contract_v2.json"
AUDIT_PATH = ROOT / "data/visual/reference_audit_v2.json"
SKILL_PATH = ROOT / ".agents/skills/cria-visual-canon-director/SKILL.md"
EXPECTED_ALE_DISPLAY = "Os Aleluiados"

REQUIRED_FILES = [
    ".agents/skills/cria-visual-canon-director/SKILL.md",
    ".agents/skills/cria-visual-canon-director/references/VISUAL_RECONCILIATION.md",
    ".agents/skills/cria-visual-canon-director/references/QUALITY_GATES.md",
    ".agents/skills/cria-visual-canon-director/references/PRODUCTION_RECIPES.md",
    ".agents/skills/cria-visual-canon-director/scripts/validate_skill.py",
    "data/visual/visual_canon_contract_v2.json",
    "data/visual/reference_audit_v2.json",
    "docs/art_bible/VISUAL_CANON_SYSTEM_V2.md",
]


def read_text(relative: str | Path) -> str:
    path = relative if isinstance(relative, Path) else ROOT / relative
    if not path.is_file():
        display = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
        raise AssertionError(f"arquivo obrigatório ausente: {display}")
    return path.read_text(encoding="utf-8")


def load_json(relative: str | Path) -> dict[str, Any]:
    text = read_text(relative)
    value = json.loads(text)
    assert isinstance(value, dict), f"raiz JSON deve ser objeto: {relative}"
    return value


def validate_required_files() -> None:
    for relative in REQUIRED_FILES:
        read_text(relative)


def validate_contract() -> None:
    contract = load_json(CONTRACT_PATH)
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
    assert factions["display_names"] == {
        "ALE": EXPECTED_ALE_DISPLAY,
        "LEM": "Lá Ele Mil Vezes",
        "NTM": "Nós Tem Um Molho",
    }
    assert factions["legacy_aliases"]["os_aleluia"] == "ALE"
    assert factions["visual_rules"]["fourth_faction_forbidden"] is True

    states = contract["asset_states"]
    assert states == [
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
    assert source["techniques"] == "data/techniques.json"
    assert source["characters"] == "data/characters.json"
    assert source["arenas"] == "data/arenas.json"
    assert source["factions"] == "data/factions.json"

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

    hud = contract["hud"]
    assert "combat_runtime" in hud["surfaces"]
    assert "art_bible" in hud["surfaces"]
    assert hud["editorial_panels_in_combat_forbidden"] is True
    assert hud["long_text_in_combat_forbidden"] is True

    world = contract["world_map"]
    assert world["model"] == "regional_node_and_route_map"
    assert world["continuous_3d_open_world_promised"] is False
    assert world["runtime_nodes_must_exist"] is True

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

    quality = contract["quality"]
    assert quality["minimum_score_for_qa"] == 90
    assert quality["minimum_score_for_human_approval"] == 95
    assert quality["blockers_override_score"] is True


def validate_reference_audit() -> None:
    audit = load_json(AUDIT_PATH)
    assert audit["status"] == "canonical_reference_audit"
    assert audit["policy"]["images_are_reference_not_runtime"] is True
    assert audit["policy"]["canon_overrides_image_text"] is True
    groups = audit["groups"]
    assert len(groups) >= 10
    assert all(group["runtime_direct"] is False for group in groups)
    assert {group["id"] for group in groups} >= {
        "brand_logo",
        "character_bible_sheets",
        "faction_banners",
        "arena_bible_sheets",
        "combat_mockups",
        "world_maps",
        "technique_breakdowns",
        "gi_no_gi_variants",
    }
    corrections = audit["character_corrections"]
    assert "replace_Ruan_Cria_header" in corrections["ruan_macacao"]
    assert "hair_is_not_weapon" in corrections["leoa_quilombola"]
    assert "replace_real_police_branding" in corrections["delegado_montenegro"]
    arena = audit["arena_corrections"]
    assert "Itubera_context_not_Chapada_Diamantina" in arena["pancada_grande"]
    assert "local_cultural_review" in arena["zambiapunga"]


def validate_skill_package() -> None:
    skill = read_text(SKILL_PATH)
    assert "name: cria-visual-canon-director" in skill
    assert 'version: "2.0.0"' in skill
    assert EXPECTED_ALE_DISPLAY in skill
    assert "Ruan “Macacão” Silva" in skill
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

    quality = read_text(".agents/skills/cria-visual-canon-director/references/QUALITY_GATES.md")
    recipes = read_text(".agents/skills/cria-visual-canon-director/references/PRODUCTION_RECIPES.md")
    reconciliation = read_text(".agents/skills/cria-visual-canon-director/references/VISUAL_RECONCILIATION.md")
    assert "Bloqueadores absolutos" in quality
    assert "Gate Android físico" in quality
    assert "Receita de técnica pareada" in recipes
    assert "OS ALELUIADOS" in recipes
    assert "Delegado Montenegro" in reconciliation
    assert "Pancada Grande" in reconciliation


def validate_existing_visual_manifest() -> None:
    manifest = load_json("data/visual/production_manifest_v02.json")
    assert manifest["canon_protagonist"] == "ruan_macacao"
    style = manifest["visual_style"]
    assert style["combat_sprite_height_px"] == 72
    assert style["hub_sprite_cell_px"] == 64
    assert style["grid_px"] == 16
    assert style["texture_filter"] == "nearest"
    assert "attacker" in manifest["quality_gate"]["paired_technique_extra_files"]
    assert "defender" in manifest["quality_gate"]["paired_technique_extra_files"]
    assert "sync_map.json" in manifest["quality_gate"]["paired_technique_extra_files"]
    character_ids = {item["id"] for item in manifest["characters"]}
    assert {"ruan_macacao", "davi_relampago", "mestre_dende"}.issubset(character_ids)
    arena_ids = {item["id"] for item in manifest["arenas"]}
    assert {"arena_do_dique", "terreiro_da_luta", "zambiapunga", "budokan_das_aguas"}.issubset(arena_ids)


def validate_canon_name_reconciliation() -> None:
    canon = load_json("data/production/canon_contract_v4_1.json")
    migration = load_json("data/production/faction_migration_v4_2.json")
    catalog = load_json("data/factions.json")
    director = load_json("data/factions/faction_director_v02.json")
    mapper = read_text("src/factions/FactionIdentityV4.gd")
    decisions = read_text("docs/DECISIONS.md")
    agents = read_text("AGENTS.md")
    migration_doc = read_text("docs/migrations/V4_2_FACTIONS_SAVE.md")

    ale_v41 = next(item for item in canon["active_factions_future_domain"] if item["id"] == "ALE")
    assert ale_v41["display_name"] == EXPECTED_ALE_DISPLAY
    assert canon["d10"]["canonical_display_name"] == EXPECTED_ALE_DISPLAY
    assert migration["active_factions"]["ALE"]["display_name"] == EXPECTED_ALE_DISPLAY
    active_ale = next(item for item in catalog["factions"] if item.get("canonical_id") == "ALE")
    assert active_ale["id"] == "os_aleluia"
    assert active_ale["name"] == EXPECTED_ALE_DISPLAY
    assert director["factions"]["ALE"]["name"] == EXPECTED_ALE_DISPLAY
    assert f'"ALE": "{EXPECTED_ALE_DISPLAY}"' in mapper
    assert f"**{EXPECTED_ALE_DISPLAY}**" in decisions
    assert f"**{EXPECTED_ALE_DISPLAY}**" in agents
    assert f"| `ALE` | {EXPECTED_ALE_DISPLAY} | `os_aleluia` |" in migration_doc

    canonical_targets = [
        "AGENTS.md",
        "docs/DECISIONS.md",
        "docs/migrations/V4_2_FACTIONS_SAVE.md",
        "data/production/canon_contract_v4_1.json",
        "data/production/faction_migration_v4_2.json",
        "data/factions.json",
        "data/factions/faction_director_v02.json",
        "src/factions/FactionIdentityV4.gd",
    ]
    exact_old = re.compile(r'(?<!s)Os Aleluiado(?!s)')
    for relative in canonical_targets:
        assert not exact_old.search(read_text(relative)), f"display singular legado permaneceu em {relative}"


def validate_documentation_and_governance() -> None:
    decisions = read_text("docs/DECISIONS.md")
    index = read_text("docs/INDEX.md")
    agents = read_text("AGENTS.md")
    governance = load_json("data/production/repository_governance_v01.json")
    package = load_json("package.json")

    for decision in range(1, 14):
        assert f"## D{decision} —" in decisions, f"D{decision} ausente"
    assert "## D13 — Sistema visual canônico" in decisions
    assert "visual_canon_contract_v2.json" in index
    assert "VISUAL_CANON_SYSTEM_V2.md" in index
    assert "cria-visual-canon-director" in index
    assert "cria-visual-canon-director" in agents
    assert "visual_canon_contract_v2.json" in agents

    required = set(governance["required_governance_files"])
    assert set(REQUIRED_FILES).issubset(required)
    protected = governance["protected_invariants"]
    assert protected["protagonist_id"] == "ruan_macacao"
    assert protected["active_faction_display_names"]["ALE"] == EXPECTED_ALE_DISPLAY
    assert protected["visual_contract"] == "res://data/visual/visual_canon_contract_v2.json"
    assert protected["visual_skill"] == ".agents/skills/cria-visual-canon-director/SKILL.md"
    assert protected["final_art_dimension"] == "2D"
    assert protected["visual_presentation"] == "2.5D"

    scripts = package["scripts"]
    assert scripts["validate:visual-canon"] == "python tools/audit/validate_visual_canon_v2.py"
    assert "validate:visual-canon" in scripts["quality"]


def validate_forbidden_drift() -> None:
    combined = "\n".join(
        read_text(path)
        for path in [
            ".agents/skills/cria-visual-canon-director/SKILL.md",
            ".agents/skills/cria-visual-canon-director/references/VISUAL_RECONCILIATION.md",
            "docs/art_bible/VISUAL_CANON_SYSTEM_V2.md",
            "data/visual/visual_canon_contract_v2.json",
        ]
    )
    assert "Ruan “Cria” Silva" not in combined
    assert "Caio Ravel" not in combined
    assert "Chapada Diamantina" not in combined or "not_Chapada_Diamantina" in combined or "não deve" in combined
    lower = combined.lower()
    assert "instant_finish\": true" not in lower
    assert "quatro facções ativas" not in lower


def main() -> int:
    checks = [
        validate_required_files,
        validate_contract,
        validate_reference_audit,
        validate_skill_package,
        validate_existing_visual_manifest,
        validate_canon_name_reconciliation,
        validate_documentation_and_governance,
        validate_forbidden_drift,
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
    print("- skill, contratos, QA, governança e dados coerentes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
