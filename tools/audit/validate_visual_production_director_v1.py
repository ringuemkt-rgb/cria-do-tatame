#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = "data/visual/visual_production_director_v1.json"
SKILL = ".agents/skills/cria-visual-production-director/SKILL.md"
STANDARD = "docs/art_bible/VISUAL_RECONCILIATION_AND_PRODUCTION_STANDARD_V2.md"
TEMPLATE = "data/visual/templates/visual_asset_brief_v1.json"
DISPLAY_ALE = "Os Aleluiados"
LEGACY_ID = "os_aleluia"


def read_text(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"arquivo obrigatório ausente: {relative}")
    return path.read_text(encoding="utf-8")


def load_json(relative: str) -> dict[str, Any]:
    try:
        data = json.loads(read_text(relative))
    except json.JSONDecodeError as exc:
        raise AssertionError(f"JSON inválido em {relative}: {exc}") from exc
    assert isinstance(data, dict), f"objeto raiz inválido em {relative}"
    return data


def validate_contract() -> None:
    contract = load_json(CONTRACT)
    assert contract["contract_id"] == "cria_visual_production_director_v1"
    assert contract["status"] == "active_contract"
    assert contract["skill_path"] == SKILL
    assert contract["human_standard"] == STANDARD
    assert contract["target"]["viewport"] == [1280, 720]
    assert contract["target"]["platform_floor"] == "android_arm64"

    protagonist = contract["canon"]["protagonist"]
    assert protagonist["id"] == "ruan_macacao"
    assert protagonist["display_name"] == "Ruan Macacão Silva"
    assert protagonist["nickname"] == "Macacão"
    assert protagonist["origin"] == "Ituberá, Baixo Sul da Bahia"

    factions = {item["id"]: item for item in contract["canon"]["active_factions"]}
    assert set(factions) == {"ALE", "LEM", "NTM"}
    assert factions["ALE"]["display_name"] == DISPLAY_ALE
    assert factions["ALE"]["legacy_ids"] == [LEGACY_ID]

    combat = contract["canon"]["combat_identity"]
    assert combat["position_before_submission"] is True
    assert combat["beat_em_up"] is False
    assert combat["mma_core"] is False
    assert combat["instant_finish"] is False
    assert combat["technique_authority"] == "data/techniques.json"

    style = contract["visual_style"]
    assert style["dimension"] == "2D_with_2_5D_depth"
    assert style["grid_px"] == 16
    assert style["combat_sprite_height_px"] == 72
    assert style["hub_sprite_cell_px"] == 64
    assert style["texture_filter"] == "nearest"
    assert "photorealism" in style["final_render_forbidden"]
    assert "generic_3d" in style["final_render_forbidden"]

    paired = contract["surfaces"]["paired_technique"]
    assert paired["attacker_and_defender_required"] is True
    assert paired["equal_frame_count_required"] is True
    assert paired["shared_pivot_required"] is True
    assert paired["sync_map_required"] is True

    ui = contract["ui"]
    assert ui["language"] == "pt-BR"
    assert contract["surfaces"]["combat_hud"]["touch_target_dp_min"] == 48
    assert contract["surfaces"]["combat_hud"]["safe_area_percent_min"] == 7

    score = contract["quality_score"]
    assert score["minimum_total"] == 90
    assert sum(score["dimensions"].values()) == 100
    assert set(score["full_score_required"]) == {
        "canon",
        "bjj_technical_coherence",
        "license_origin",
    }
    assert score["shipping_requires_human_approval"] is True
    assert score["shipping_requires_physical_device_test"] is True

    legal = contract["legal"]
    assert legal["real_brands_forbidden_without_license"] is True
    assert legal["real_government_or_police_symbols_forbidden"] is True
    assert legal["ai_output_auto_promotion_forbidden"] is True


def validate_skill() -> None:
    skill = read_text(SKILL)
    required = [
        "# CRIA VISUAL PRODUCTION DIRECTOR — SKILL MESTRE",
        "## 4. Cânone visual congelado",
        "Ruan “Macacão” Silva",
        "Os Aleluiados",
        "## 8. GI e No-Gi",
        "## 10. Técnicas e animação pareada",
        "## 13. UI/HUD mobile-first",
        "## 16. Modos operacionais",
        "## 18. Quality score",
        "/auditar",
        "/personagem",
        "/animacao",
        "/arena",
        "/mapa",
        "/hud",
        "/faccao",
        "/integrar",
        "/qa",
    ]
    for marker in required:
        assert marker in skill, f"skill sem marcador obrigatório: {marker}"
    assert "Não gere cada frame isoladamente" in skill
    assert "posição antes de submissão" in skill.lower()
    assert "Nunca invente aprovação" in skill


def validate_human_standard() -> None:
    standard = read_text(STANDARD)
    assert "**Status:** ACTIVE" in standard
    assert "Ruan “Macacão” Silva" in standard
    assert "ALE — Os Aleluiados" in standard
    assert "Separação entre art bible e runtime" in standard
    assert "Pipeline de técnica pareada" in standard
    assert "Definition of Done visual" in standard
    assert "A cachoeira é visualmente forte" in standard
    assert "A imagem de Ruan × Davi" in standard


def validate_template() -> None:
    template = load_json(TEMPLATE)
    assert template["status"] == "canon_pending"
    assert template["visual"]["logical_grid_px"] == 16
    assert template["visual"]["safe_area_percent"] == 7
    assert template["animation"]["whole_strip_required"] is False
    assert template["legal_review"]["real_brand"] is False
    assert set(template["qa"]) >= {
        "canon",
        "bjj_technical_coherence",
        "silhouette_readability",
        "frame_consistency",
        "license_origin",
        "total",
        "blockers",
        "human_approved",
        "device_tested",
    }


def validate_project_alignment() -> None:
    project = read_text("project.godot")
    manifest = load_json("data/visual/production_manifest_v02.json")
    assert 'window/size/viewport_width=1280' in project
    assert 'window/size/viewport_height=720' in project
    assert 'textures/canvas_textures/default_texture_filter=0' in project
    visual = manifest["visual_style"]
    assert visual["grid_px"] == 16
    assert visual["combat_sprite_height_px"] == 72
    assert visual["hub_sprite_cell_px"] == 64
    assert visual["texture_filter"] == "nearest"
    assert manifest["canon_protagonist"] == "ruan_macacao"


def validate_active_faction_display() -> None:
    canon = load_json("data/production/canon_contract_v4_1.json")
    migration = load_json("data/production/faction_migration_v4_2.json")
    catalog = load_json("data/factions.json")
    director = load_json("data/factions/faction_director_v02.json")
    governance = load_json("data/production/repository_governance_v01.json")
    mapper = read_text("src/factions/FactionIdentityV4.gd")
    decisions = read_text("docs/DECISIONS.md")
    agents = read_text("AGENTS.md")

    ale_contract = next(
        item for item in canon["active_factions_future_domain"] if item["id"] == "ALE"
    )
    assert ale_contract["display_name"] == DISPLAY_ALE
    assert canon["d10"]["canonical_display_name"] == DISPLAY_ALE
    assert migration["active_factions"]["ALE"]["display_name"] == DISPLAY_ALE
    assert governance["protected_invariants"]["active_faction_display_names"]["ALE"] == DISPLAY_ALE

    ale_catalog = next(item for item in catalog["factions"] if item.get("canonical_id") == "ALE")
    assert ale_catalog["id"] == LEGACY_ID
    assert ale_catalog["name"] == DISPLAY_ALE
    assert director["factions"]["ALE"]["name"] == DISPLAY_ALE
    assert f'"ALE": "{DISPLAY_ALE}"' in mapper
    assert DISPLAY_ALE in decisions
    assert DISPLAY_ALE in agents

    active_authority_files = {
        "data/production/canon_contract_v4_1.json": json.dumps(canon, ensure_ascii=False),
        "data/production/faction_migration_v4_2.json": json.dumps(migration, ensure_ascii=False),
        "data/factions.json": json.dumps(catalog, ensure_ascii=False),
        "data/factions/faction_director_v02.json": json.dumps(director, ensure_ascii=False),
        "src/factions/FactionIdentityV4.gd": mapper,
        "docs/DECISIONS.md": decisions,
        "AGENTS.md": agents,
    }
    for path, content in active_authority_files.items():
        assert "Os Aleluiado" not in content, f"forma antiga ativa em {path}"


def validate_governance_and_package() -> None:
    package = load_json("package.json")
    governance = load_json("data/production/repository_governance_v01.json")
    index = read_text("docs/INDEX.md")
    agents = read_text("AGENTS.md")

    assert package["scripts"]["validate:visual-director"] == (
        "python tools/audit/validate_visual_production_director_v1.py"
    )
    assert "validate:visual-director" in package["scripts"]["quality"]

    required = set(governance["required_governance_files"])
    for path in [
        SKILL,
        CONTRACT,
        STANDARD,
        TEMPLATE,
        "tools/audit/validate_visual_production_director_v1.py",
        "tests/test_visual_production_director_v1.py",
    ]:
        assert path in required, f"governança não exige {path}"

    assert "cria-visual-production-director" in index
    assert "visual_production_director_v1.json" in index
    assert "VISUAL_RECONCILIATION_AND_PRODUCTION_STANDARD_V2.md" in index
    assert SKILL in agents
    assert CONTRACT in agents


def main() -> int:
    checks = [
        validate_contract,
        validate_skill,
        validate_human_standard,
        validate_template,
        validate_project_alignment,
        validate_active_faction_display,
        validate_governance_and_package,
    ]
    failures: list[str] = []
    for check in checks:
        try:
            check()
        except Exception as exc:  # noqa: BLE001 - CLI agrega todas as falhas
            failures.append(f"{check.__name__}: {exc}")

    if failures:
        print("[VisualProductionDirectorV1] FALHOU")
        for failure in failures:
            print(f" - {failure}")
        return 1

    print("[VisualProductionDirectorV1] OK")
    print("- skill, contrato, padrão humano e template validados")
    print("- Ruan Macacão e Os Aleluiados coerentes nas fontes ativas")
    print("- pixel art 2D/2.5D, BJJ posicional e mobile-first protegidos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
