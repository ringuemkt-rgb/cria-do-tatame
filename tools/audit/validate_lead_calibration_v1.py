#!/usr/bin/env python3
"""Validate the Lead calibration canon, hygiene and Clause 23–30 gates."""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]


def read_text(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"arquivo obrigatório ausente: {relative}")
    return path.read_text(encoding="utf-8")


def load_json(relative: str) -> dict[str, Any]:
    value = json.loads(read_text(relative))
    assert isinstance(value, dict), f"raiz JSON deve ser objeto: {relative}"
    return value


def validate_governance() -> None:
    contract = load_json("data/production/lead_calibration_contract_v1.json")
    assert contract["branch"] == "lead/calibracao-v1"
    assert contract["decision_range"] == {"first": 12, "last": 47}
    assert contract["merge_authorized"] is False
    assert contract["one_lot"] is True
    assert contract["human_gates"]["authorized_signer"] == "Mestre Satoshi"
    assert contract["human_gates"]["agent_signature_forbidden"] is True
    decisions = read_text("docs/DECISIONS.md")
    prompt = read_text("docs/production/CRIA_VISUAL_GRAPPLING_MASTER_PROMPT_V1.md")
    for decision in range(12, 48):
        assert f"## D{decision} —" in decisions, f"D{decision} ausente"
    for clause in range(23, 31):
        assert f"### {clause}." in prompt, f"Cláusula {clause} ausente"


def validate_canon_data() -> None:
    characters = load_json("data/characters.json")["characters"]
    by_id = {item["id"]: item for item in characters}
    assert by_id["ruan_macacao"]["campaign_belt"] == "white"
    assert by_id["ruan_macacao"]["gold_slice_belt"] == {"color": "blue", "stripes": 2}
    assert by_id["ruan_macacao"]["visual_constraints"] == {
        "tattoos": False,
        "back_patch": False,
        "wear_max_percent": 30,
    }
    assert by_id["davi_relampago"]["belt"] == "blue"
    defined = {"lucas_caveira", "montenegro_die", "nado", "helena_vaz", "patrono"}
    assert defined.issubset(by_id)
    for character_id in defined:
        assert by_id[character_id]["production_status"] == "defined_not_produced"

    story = load_json("data/story/infiltration_canon_v1.json")
    assert story["safeguards"]["real_people_organizations_and_institutions"] is False
    assert story["safeguards"]["criminal_method_instruction"] is False
    assert story["safeguards"]["minors_in_risk_scenes"] is False
    assert story["circuits"]["clandestine_nogi"]["points"] is False


def validate_factions_and_ui() -> None:
    expected = {
        "ALE": ("#2E8FE2", ["arena_do_dique", "budokan_das_aguas"]),
        "LEM": ("#3FBF3F", ["colonia_nishimura", "beco_do_engenho"]),
        "NTM": ("#D93A2B", ["camamu_manguezal", "ferro_velho_da_lapa"]),
    }
    contract = load_json("data/production/faction_migration_v4_2.json")["active_factions"]
    for faction_id, (color, territories) in expected.items():
        assert contract[faction_id]["primary_color"] == color
        assert contract[faction_id]["starting_territories"] == territories

    tokens = load_json("data/visual/tokens.json")
    assert tokens["hud"]["visible_contextual_actions"] == 5
    assert len(tokens["hud"]["action_vocabulary"]) == 7
    assert tokens["hud"]["striking_actions_forbidden"] is True
    assert tokens["skill_tree"] == {"branches": 4, "tiers_per_branch": 5}
    assert tokens["crowd"]["maximum_simultaneous_animated"] == 4
    assert tokens["stage_budget"]["atlas_max_count"] == 2
    assert tokens["stage_budget"]["atlas_max_size_px"] == [2048, 2048]
    assert tokens["stage_budget"]["draw_calls_max"] == 24
    assert tokens["stage_budget"]["particles_simultaneous_max"] == 64


def validate_endings_are_data_driven() -> None:
    endings = load_json("data/finais_adultos.json")
    assert endings["runtime_ids"] == {
        "CRIA": "heroi_duas_aguas",
        "IDOLO": "estrela_vazia",
        "SOMBRA": "rei_dos_atalhos",
        "DUPLA_FACE": "traidor_silencioso",
        "RAIZ": "raiz_eterna",
    }
    assert len(endings["evaluation_order"]) == 5
    calculator = read_text("src/narrative/EndingsCalculator.gd")
    assert "static func calculate" in calculator
    assert "evaluation_order" in calculator
    assert "condicoes" in calculator
    for consumer in ("src/autoloads/WorldState.gd", "src/autoloads/StorySceneDirector.gd"):
        text = read_text(consumer)
        assert 'preload("res://src/narrative/EndingsCalculator.gd")' in text
        assert "EndingsCalculatorScript.calculate" in text
        for final_id in endings["runtime_ids"].values():
            assert final_id not in text, f"final hardcoded em {consumer}: {final_id}"


def validate_hygiene_and_tools() -> None:
    assert not (ROOT / "apk").exists()
    assert not (ROOT / "CRIA_DO_TATAME_COMPLETE_100_MOBILE_GITHUB_APK_READY_v1_2.zip").exists()
    assert not (ROOT / "index-1.html").exists()
    assert (ROOT / "index.html").is_file()
    assert (ROOT / "tools/audit/visual_lab.html").is_file()
    assert (ROOT / "docs/archived/data/nft/nft_catalog_v01.json").is_file()
    assert not (ROOT / "data/nft/nft_catalog_v01.json").exists()
    assert (ROOT / "docs/archived/systems/FACTION_DIRECTOR_V2.md").is_file()
    assert (ROOT / "docs/archived/systems/WORLD_DIRECTOR_ARCHITECTURE.md").is_file()
    tool = load_json("tools/sprite_forge/tool_manifest.json")
    assert tool["license"] == "MIT"
    assert tool["commit"] == "64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2"
    assert tool["magenta_fringe_is_qa_failure"] is True
    workflow = read_text(".github/workflows/godot-gd-delivery-gate.yml")
    assert "runtime_smoke.gd" in workflow
    assert "godot_import.log" in workflow


def main() -> int:
    checks = [
        validate_governance,
        validate_canon_data,
        validate_factions_and_ui,
        validate_endings_are_data_driven,
        validate_hygiene_and_tools,
    ]
    errors: list[str] = []
    for check in checks:
        try:
            check()
        except (AssertionError, OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
            errors.append(f"{check.__name__}: {exc}")
    if errors:
        print("Lead calibration validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Lead calibration validation passed.")
    print(f"- decisions: D12-D47 ({36} records)")
    print("- clauses: 23-30")
    print("- human signer: Mestre Satoshi")
    print("- automatic promotion: forbidden")
    return 0


if __name__ == "__main__":
    sys.exit(main())
