#!/usr/bin/env python3
"""Validate Phase-1 data, narrative linkage and release evidence. Fail closed.

Structure/canon/linkage validation is intentionally separated from release readiness.
A structurally valid repository is not automatically release-ready.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Any

ROOT = pathlib.Path(".")
DATA = ROOT / "data"

ERRORS: list[str] = []
LINKAGE_ERRORS: list[str] = []

BACKBONES = [
    "world/world_map_v4.json",
    "world/arena_info_v1.json",
    "world/clandestine_v1.json",
    "factions/factions_v2.json",
    "combat/roster_v3.json",
    "combat/ai_weights_v1.json",
    "progression/training_exercises_v2.json",
    "brand/canon_lock.json",
    "visual/ui_theme_v2.json",
    "visual/icons_manifest_v1.json",
    "narrative/acts_v3.json",
    "narrative/missions_v1.json",
]


def load(rel: str) -> dict[str, Any]:
    path = DATA / rel
    if not path.exists():
        ERRORS.append(f"missing:{rel}")
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        ERRORS.append(f"invalid_json:{rel}:{exc}")
        return {}
    if not isinstance(value, dict):
        ERRORS.append(f"root_not_object:{rel}")
        return {}
    return value


def load_root(rel: str) -> dict[str, Any]:
    path = ROOT / rel
    if not path.exists():
        ERRORS.append(f"missing:{rel}")
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        ERRORS.append(f"invalid_json:{rel}:{exc}")
        return {}
    if not isinstance(value, dict):
        ERRORS.append(f"root_not_object:{rel}")
        return {}
    return value


def expect(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def gate_bool(row: dict[str, Any], key: str) -> bool:
    value = row.get(key)
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.lower() in {
            "pass", "passed", "approved", "clear", "cleared", "integrated", "true"
        }
    return False


def narrative_linkage(acts: dict[str, Any], missions: dict[str, Any]) -> tuple[int, int, int]:
    beat_ids: list[str] = []
    for row in acts.get("atos", []):
        if not isinstance(row, dict) or "beats" not in row:
            continue
        act_id = row.get("id")
        beats = row.get("beats")
        if not isinstance(beats, list):
            LINKAGE_ERRORS.append(f"acts:beats_not_list:{act_id}")
            continue
        for beat in beats:
            if not isinstance(beat, dict) or not isinstance(beat.get("id"), str):
                LINKAGE_ERRORS.append(f"acts:invalid_beat:{act_id}")
                continue
            beat_ids.append(beat["id"])

    beat_set = set(beat_ids)
    if len(beat_set) != len(beat_ids):
        LINKAGE_ERRORS.append("acts:duplicate_beat_ids")

    mission_rows = missions.get("missions", [])
    if not isinstance(mission_rows, list):
        LINKAGE_ERRORS.append("missions:missions_not_list")
        mission_rows = []

    mission_ids: list[str] = []
    mission_map: dict[str, str] = {}
    campaign_count = 0
    prologue_count = 0
    for row in mission_rows:
        if not isinstance(row, dict):
            LINKAGE_ERRORS.append("missions:row_not_object")
            continue
        mission_id = row.get("id")
        beat = row.get("beat")
        if not isinstance(mission_id, str) or not isinstance(beat, str):
            LINKAGE_ERRORS.append("missions:id_or_beat_invalid")
            continue
        mission_ids.append(mission_id)
        mission_map[mission_id] = beat
        if beat not in beat_set:
            LINKAGE_ERRORS.append(f"missions:unknown_beat:{mission_id}:{beat}")
        if mission_id.startswith("z"):
            prologue_count += 1
        elif mission_id.startswith("m"):
            campaign_count += 1

    if len(set(mission_ids)) != len(mission_ids):
        LINKAGE_ERRORS.append("missions:duplicate_ids")

    linkage_rows = missions.get("linkage", [])
    if not isinstance(linkage_rows, list):
        LINKAGE_ERRORS.append("missions:linkage_not_list")
        linkage_rows = []
    linked_ids: set[str] = set()
    for row in linkage_rows:
        if not isinstance(row, dict):
            LINKAGE_ERRORS.append("missions:linkage_row_not_object")
            continue
        mission_id = row.get("mission")
        beat = row.get("beat")
        if not isinstance(mission_id, str) or not isinstance(beat, str):
            LINKAGE_ERRORS.append("missions:linkage_id_or_beat_invalid")
            continue
        linked_ids.add(mission_id)
        if beat not in beat_set:
            LINKAGE_ERRORS.append(f"linkage:unknown_beat:{mission_id}:{beat}")
        if mission_map.get(mission_id) != beat:
            LINKAGE_ERRORS.append(f"linkage:mismatch:{mission_id}:{beat}")

    for mission_id in sorted(set(mission_map) - linked_ids):
        LINKAGE_ERRORS.append(f"linkage:missing_row:{mission_id}")

    # Repo Update v1 contract: Z1-Z5 are prologue; campaign target remains 40.
    if prologue_count != 5:
        LINKAGE_ERRORS.append(f"missions:prologue_count!={prologue_count}:expected=5")
    if campaign_count != 40:
        LINKAGE_ERRORS.append(f"missions:campaign_count!={campaign_count}:expected=40")

    return len(beat_set), prologue_count, campaign_count


def release_readiness() -> dict[str, Any]:
    ledger = load_root("production/coverage/asset_links_v1.json")
    visual = load_root("production/evidence/visual_runtime_qa_v1.json")
    android = load_root("production/evidence/android_physical_device_v1.json")
    release_status = load("production/release_gate_status_v01.json")
    registry = load_root("assets/manifest_v2.json")

    links = [row for row in ledger.get("links", []) if isinstance(row, dict)]
    approved_links = [
        row for row in links
        if gate_bool(row, "human_approved")
        and gate_bool(row, "qa_passed")
        and gate_bool(row, "rights_cleared")
    ]
    rights_clear = [row for row in links if gate_bool(row, "rights_cleared")]
    qa_passed = [row for row in links if gate_bool(row, "qa_passed")]
    rights_pct = round(100.0 * len(rights_clear) / len(links), 2) if links else 0.0
    qa_pct = round(100.0 * len(qa_passed) / len(links), 2) if links else 0.0

    frames = int(visual.get("frames_checked", 0) or 0)
    visual_pass = visual.get("status") == "PASS"
    android_pass = android.get("status") == "PASS"

    audio_assets = 0
    for asset in registry.get("assets", []):
        if not isinstance(asset, dict):
            continue
        path = str(asset.get("path", "")).lower()
        if path.endswith((".wav", ".ogg", ".mp3", ".flac")):
            audio_assets += 1

    gates = release_status.get("gates", {})
    all_release_gates_pass = bool(gates) and all(
        isinstance(value, dict) and value.get("status") == "passed"
        for value in gates.values()
    )

    release_ready = all([
        len(approved_links) >= 1,
        rights_pct == 100.0,
        qa_pct == 100.0,
        frames > 0,
        visual_pass,
        audio_assets > 0,
        android_pass,
        all_release_gates_pass,
    ])
    blockers: list[str] = []
    if len(approved_links) < 1:
        blockers.append("approved_assets<1")
    if rights_pct != 100.0:
        blockers.append(f"rights_coverage={rights_pct}%")
    if qa_pct != 100.0:
        blockers.append(f"qa_coverage={qa_pct}%")
    if frames <= 0 or not visual_pass:
        blockers.append(f"visual_runtime={visual.get('status')} frames={frames}")
    if audio_assets <= 0:
        blockers.append("audio_assets=0")
    if not android_pass:
        blockers.append(f"android_physical={android.get('status')}")
    if not all_release_gates_pass:
        blockers.append("release_gate_status_has_pending_or_blocked_gates")

    return {
        "approved_assets": len(approved_links),
        "rights_coverage_percent": rights_pct,
        "qa_coverage_percent": qa_pct,
        "frames_checked": frames,
        "audio_assets": audio_assets,
        "android_physical_status": android.get("status"),
        "all_release_gates_pass": all_release_gates_pass,
        "release_ready": release_ready,
        "blockers": blockers,
    }


def main(require_release: bool = False) -> int:
    wm = load("world/world_map_v4.json")
    arena_info = load("world/arena_info_v1.json")
    clandestine = load("world/clandestine_v1.json")
    factions = load("factions/factions_v2.json")
    roster = load("combat/roster_v3.json")
    ai = load("combat/ai_weights_v1.json")
    training = load("progression/training_exercises_v2.json")
    lock = load("brand/canon_lock.json")
    theme = load("visual/ui_theme_v2.json")
    icons = load("visual/icons_manifest_v1.json")
    acts = load("narrative/acts_v3.json")
    missions = load("narrative/missions_v1.json")

    expect(len(BACKBONES) == 12, "internal:backbone_count!=12")

    expect(lock.get("tese") == "Ser forte é ser gentil.", "canon:tese")
    setting = lock.get("setting", {})
    expect(setting.get("regiao") == "Baixo Sul da Bahia", "canon:setting.regiao")
    expect(setting.get("hub") == "Ituberá", "canon:setting.hub")
    expect(lock.get("protagonista", {}).get("p1_faixa") == "branca", "canon:ruan_p1_faixa")
    expect(lock.get("produto", {}).get("nft") is False, "canon:nft_must_be_false")
    expect(lock.get("produto", {}).get("blockchain_required") is False, "canon:blockchain_required_must_be_false")

    # Current runtime world authority remains 10 pages / 40 nodes until C6 has concrete payload.
    nodes_list = wm.get("nodes", [])
    nodes = {
        node.get("id"): node
        for node in nodes_list
        if isinstance(node, dict) and isinstance(node.get("id"), str)
    }
    counts = wm.get("canonical_counts", {})
    pages = wm.get("pages", [])
    expect(len(pages) == 10, "world:pages!=10")
    expect(len(wm.get("municipalities", [])) == 14, "world:municipalities!=14")
    expect(len(nodes_list) == 40, "world:nodes!=40")
    expect(counts.get("pages") == 10, "world:canonical_counts.pages")
    expect(counts.get("municipalities") == 14, "world:canonical_counts.municipalities")
    expect(counts.get("nodes") == 40, "world:canonical_counts.nodes")

    runtime = wm.get("runtime", {})
    expect(runtime.get("shipping_bases") is False, "world:shipping_bases_must_be_false")
    expect(runtime.get("base_path_scheme") == "candidate_until_ingested", "world:base_path_scheme")
    for page in pages:
        if not isinstance(page, dict):
            ERRORS.append("world:page_not_object")
            continue
        base = page.get("base")
        expect(
            isinstance(base, str) and base.startswith("candidate://assets/arenas/base/"),
            f"world:page_base_not_candidate:{page.get('id')}",
        )
        expect(
            not (isinstance(base, str) and base.startswith("res://")),
            f"world:page_base_false_runtime_ref:{page.get('id')}",
        )

    expected_geo = {
        "arena_do_dique": "itubera",
        "quartel_pf": "valenca",
        "quartel_cacaueira": "itubera",
        "ferro_velho_lapa": "salvador",
        "pancada_grande": "itubera",
    }
    for node_id, municipality in expected_geo.items():
        expect(nodes.get(node_id, {}).get("mun") == municipality, f"geo:{node_id}!={municipality}")
    expect("ponte_do_saici" in nodes, "geo:ponte_do_saici_missing")
    expect(wm.get("aliases", {}).get("ponte_do_saci") == "ponte_do_saici", "geo:ponte_alias")

    prohibited = ["Rio de Janeiro", "Chapada Diamantina"]
    world_text = json.dumps(wm, ensure_ascii=False) + json.dumps(arena_info, ensure_ascii=False)
    for term in prohibited:
        expect(term not in world_text, f"canon_diff:prohibited_world_term:{term}")

    arena_rows = arena_info.get("arenas", [])
    arena_ids = {
        row.get("id")
        for row in arena_rows
        if isinstance(row, dict) and isinstance(row.get("id"), str)
    }
    expect(arena_info.get("count") == 40, "arena_info:declared_count!=40")
    expect(len(arena_rows) == 40, "arena_info:rows!=40")
    expect(arena_ids == set(nodes), "arena_info:ids_do_not_match_world_map")

    phase_factions = factions.get("factions", [])
    faction_map = {
        row.get("id", row.get("sigla")): row.get("display_name", row.get("nome"))
        for row in phase_factions if isinstance(row, dict)
    }
    faction_colors = {
        row.get("id", row.get("sigla")): row.get("color", row.get("cor"))
        for row in phase_factions if isinstance(row, dict)
    }
    lock_factions = {
        row.get("sigla"): row
        for row in lock.get("faccoes", []) if isinstance(row, dict)
    }
    expected_factions = {
        "ALE": ("Os Aleluiado", "#FF9408"),
        "LEM": ("Lá Ele Mil Vezes", "#4A6741"),
        "NTM": ("Nós Tem Um Molho", "#3FE3F5"),
    }
    expect(set(faction_map) == set(expected_factions), "factions:ids")
    for faction_id, (name, color) in expected_factions.items():
        expect(faction_map.get(faction_id) == name, f"faction:{faction_id}:name")
        expect(faction_colors.get(faction_id) == color, f"faction:{faction_id}:color")
        expect(lock_factions.get(faction_id, {}).get("nome") == name, f"canon_diff:{faction_id}:name")
        expect(lock_factions.get(faction_id, {}).get("cor") == color, f"canon_diff:{faction_id}:color")

    galpao = next(
        (row for row in clandestine.get("arenas", [])
         if isinstance(row, dict) and row.get("id") == "galpao_piacava"),
        {},
    )
    expect(galpao.get("faction") == "ALE", "canon_diff:galpao_piacava!=ALE")

    fighters = roster.get("fighters", roster.get("roster", roster.get("lutadores", [])))
    expect(roster.get("count") == 17, "roster:declared_count!=17")
    expect(len(fighters) == 17, "roster:count!=17")
    fighter_ids = [row.get("id") for row in fighters if isinstance(row, dict)]
    expect(len(set(fighter_ids)) == 17, "roster:duplicate_ids")

    clandestine_rows = clandestine.get("arenas", [])
    expected_clandestine_ids = {
        node.get("id")
        for node in nodes_list
        if isinstance(node, dict) and node.get("tipo") == "clandestina"
    }
    actual_clandestine_ids = {
        row.get("id")
        for row in clandestine_rows
        if isinstance(row, dict) and isinstance(row.get("id"), str)
    }
    expect(len(expected_clandestine_ids) == 7, "world:clandestine_count!=7")
    expect(len(clandestine_rows) == 7, "clandestine:rows!=7")
    expect(actual_clandestine_ids == expected_clandestine_ids, "clandestine:ids_do_not_match_world_map")

    expect(training.get("conditioning_decay_per_day") == -1, "training:conditioning_decay_per_day!=-1")
    expect(training.get("numeric_calibration_status") == "pending_epic56", "training:calibration_status")
    expect(ai.get("numeric_calibration_status") == "pending_epic55", "ai:calibration_status")
    profiles = ai.get("profiles", [])
    expect(len(profiles) == 17, "ai:profiles!=17")
    expect(all(row.get("weights") is None for row in profiles if isinstance(row, dict)), "ai:numeric_weights_present")

    expect(theme.get("brand", {}).get("bg") == "#0B0B0D", "ui_theme:brand_bg")
    expect(theme.get("brand", {}).get("border") == "#C9971C", "ui_theme:brand_border")
    expect(theme.get("brand", {}).get("text") == "#EDE6D6", "ui_theme:brand_text")
    expect(icons.get("status") == "reference_candidate", "icons:status")
    expect(icons.get("shipping") is False, "icons:shipping_must_be_false")

    beat_count, prologue_count, campaign_count = narrative_linkage(acts, missions)

    structure_ok = not ERRORS
    linkage_ok = not LINKAGE_ERRORS
    release = release_readiness()

    print(f"STRUCTURE_OK={'PASS' if structure_ok else 'FAIL'}")
    print(f"LINKAGE_OK={'PASS' if linkage_ok else 'FAIL'}")
    print(f"CANON_DIFF={'CLEAN' if structure_ok else 'DIRTY'}")
    print(f"NARRATIVE={beat_count}_beats/{prologue_count}_prologue/{campaign_count}_campaign_missions")
    print(
        "RELEASE_EVIDENCE="
        f"approved={release['approved_assets']} "
        f"rights={release['rights_coverage_percent']}% "
        f"qa={release['qa_coverage_percent']}% "
        f"frames={release['frames_checked']} "
        f"audio={release['audio_assets']} "
        f"android={release['android_physical_status']}"
    )
    print(f"RELEASE_READY={'PASS' if release['release_ready'] else 'BLOCKED'}")

    if ERRORS:
        for error in ERRORS:
            print(f"- {error}")
    if LINKAGE_ERRORS:
        for error in LINKAGE_ERRORS:
            print(f"- {error}")
    if not release["release_ready"]:
        for blocker in release["blockers"]:
            print(f"- release_blocker:{blocker}")

    if not (structure_ok and linkage_ok):
        return 1
    if require_release and not release["release_ready"]:
        return 2
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--release", action="store_true", help="Fail unless release evidence is complete")
    args = parser.parse_args()
    sys.exit(main(require_release=args.release))
