#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

PATHS = {
    "contract": ROOT / "data/social/crialive_v1.json",
    "sponsors": ROOT / "data/sponsors.json",
    "service": ROOT / "src/social/CriaLiveService.gd",
    "virality": ROOT / "src/social/CriaLiveViralityEngine.gd",
    "feed": ROOT / "src/social/CriaLiveFeedGenerator.gd",
    "composer": ROOT / "src/social/CriaLivePostComposer.gd",
    "manager": ROOT / "src/autoloads/CriaLiveInteractionManager.gd",
    "save": ROOT / "src/autoloads/SaveManager.gd",
    "project": ROOT / "project.godot",
}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def validate_contract(data: dict) -> None:
    require(data.get("version") == "1.0.0", "CriaLive contract must be v1.0.0")
    authority = data.get("authority", {})
    require(authority.get("combat") == "CombatManager", "CombatManager must remain combat authority")
    require(authority.get("progression_ledger") == "ProgressionOS", "ProgressionOS must remain ledger authority")
    require(authority.get("money") == "WorldState", "WorldState must remain money authority")
    require(authority.get("save") == "SaveManager v6", "SaveManager v6 must remain save authority")
    require(set(data.get("post_types", [])) >= {"clip_luta", "treino", "provocacao", "patrocinado"}, "post types incomplete")
    require(set(data.get("tone_rules", {})) == {"humilde", "confiante", "provocador"}, "tone contract drift")
    require(int(data.get("nemesis", {}).get("technique_exposure_threshold", 0)) == 2, "nemesis threshold must be 2")
    require(data.get("slice_proposals"), "slice must ship at least one proposal")
    tiers = data.get("follower_tiers", [])
    require(len(tiers) >= 5, "follower tier ladder incomplete")
    previous_max = -1
    for tier in tiers:
        require(int(tier["min"]) == previous_max + 1, f"tier gap/overlap at {tier.get('id')}")
        require(int(tier["max"]) >= int(tier["min"]), f"invalid tier range {tier.get('id')}")
        previous_max = int(tier["max"])


def validate_sponsor(data: dict) -> None:
    sponsors = {row.get("id"): row for row in data.get("sponsors", [])}
    require("academia_suplementos" in sponsors, "slice sponsor academia_suplementos missing")
    spec = sponsors["academia_suplementos"]
    require(int(spec.get("weekly_reward", 0)) == 40, "slice sponsor payout must be 40")
    require(int(spec.get("obligations", {}).get("posts_per_week", 0)) == 1, "slice sponsor needs one weekly post")


def validate_code() -> None:
    service = PATHS["service"].read_text(encoding="utf-8")
    require("class_name CriaLiveService" in service, "CriaLiveService class missing")
    for forbidden in ("WorldState.", "ProgressionOS.", "CombatManager."):
        require(forbidden not in service, f"service crossed authority firewall: {forbidden}")
    require("func publish_post" in service, "publish loop missing")
    require("func accept_proposal" in service, "proposal loop missing")
    require("func weekly_tick" in service, "weekly payout loop missing")
    require("func sign_sponsor" in service, "sponsor loop missing")

    virality = PATHS["virality"].read_text(encoding="utf-8")
    require("_stable_seed" in virality and "RandomNumberGenerator" in virality, "seeded virality contract missing")

    manager = PATHS["manager"].read_text(encoding="utf-8")
    require("CriaLiveServiceScript" in manager, "persistent manager does not bridge CriaLiveService")
    require("_on_week_completed" in manager, "weekly bridge missing")
    require("ProgressionOS.record_event" in manager, "ledger bridge missing")
    require("WorldState.money" in manager, "money authority bridge missing")

    save = PATHS["save"].read_text(encoding="utf-8")
    require('data["cria_live_interaction_state"]' in save, "save v6 does not persist CriaLive interaction state")

    project = PATHS["project"].read_text(encoding="utf-8")
    require("CriaLiveService=" not in project, "CriaLiveService must not become an autoload")


def main() -> int:
    for path in PATHS.values():
        require(path.exists(), f"missing required file: {path.relative_to(ROOT)}")
    validate_contract(load_json(PATHS["contract"]))
    validate_sponsor(load_json(PATHS["sponsors"]))
    validate_code()
    print("CriaLive V1 contract OK — deterministic post/proposal/sponsor slice wired without authority duplication")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
