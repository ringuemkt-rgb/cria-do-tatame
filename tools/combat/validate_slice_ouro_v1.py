#!/usr/bin/env python3
"""Fail-closed validator for the gold-slice transition contract."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
OVERLAY_PATH = ROOT / "data/techniques/technique_slice_ouro_v1.json"
MAPPER_PATH = ROOT / "data/combat/state_mapper_v1.json"
POLICY_PATH = ROOT / "data/ai/davi_policy_slice_v1.json"
TECHNIQUES_PATH = ROOT / "data/techniques.json"
RESOLVER_PATH = ROOT / "src/combat/TechniqueResolver.gd"
MAPPER_SRC_PATH = ROOT / "src/combat/SliceStateMapper.gd"
REGISTRY_PATH = ROOT / "src/autoloads/DataRegistry.gd"
DAVI_PATH = ROOT / "src/combat/DaviAIController.gd"

REQUIRED_IDS = (
    "grip_de_ferro",
    "baiana",
    "sprawl",
    "corte_joelho",
    "chave_braco",
    "triangulo",
    "mata_leao",
)
REQUIRED_FIELDS = (
    "entry_state",
    "exit_state",
    "state_to_defended",
    "defense_response",
    "defense_window",
    "commit_frame",
    "chain_id",
)
REQUIRED_RUNTIME = (
    "PLAYER_STANDING_NEUTRAL",
    "PLAYER_TOP_CLINCH",
    "PLAYER_TOP_GUARD",
    "PLAYER_TOP_SIDE",
    "PLAYER_TOP_MOUNT",
    "PLAYER_BACK_ATTACK",
    "PLAYER_SUBMISSION_ATTACK",
)
ALIASES = {
    "knee_cut": "corte_joelho",
    "clinch_entry": "grip_de_ferro",
    "kimura": "chave_braco",
}


def fail(message: str) -> None:
    print(f"SLICE_OURO_FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"{path.relative_to(ROOT)} invalid: {exc}")
    if not isinstance(value, dict):
        fail(f"{path.relative_to(ROOT)} must be an object")
    return value


def text(path: Path) -> str:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def resolve_python(technique: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
    current = str(context.get("state", "PLAYER_STANDING_NEUTRAL"))
    entry = str(technique.get("entry_state", ""))
    exit_state = str(technique.get("exit_state", current))
    defended = str(technique.get("state_to_defended", current))
    commit = int(technique.get("commit_frame", 0) or 0)
    window = float(technique.get("defense_window", 0.0) or 0.0)
    response = ALIASES.get(str(technique.get("defense_response", "")), str(technique.get("defense_response", "")))
    frame = float(context.get("frame", 999.0))
    defender_input = ALIASES.get(str(context.get("defense_input", "")), str(context.get("defense_input", "")))
    if bool(context.get("released_before_commit", False)) and commit > 0 and frame < commit:
        return {"success": False, "denied": False, "faked": True, "state_to": current}
    in_window = window > 0.0 and commit > 0 and frame <= commit * window
    if entry in ("", current) and response and defender_input == response and in_window:
        return {"success": False, "denied": True, "faked": False, "state_to": defended}
    return {"success": True, "denied": False, "faked": False, "state_to": exit_state}


def validate() -> dict[str, Any]:
    overlay = load_json(OVERLAY_PATH)
    mapper = load_json(MAPPER_PATH)
    policy = load_json(POLICY_PATH)
    catalog = load_json(TECHNIQUES_PATH)
    resolver = text(RESOLVER_PATH)
    mapper_src = text(MAPPER_SRC_PATH)
    registry = text(REGISTRY_PATH)
    davi = text(DAVI_PATH)

    if overlay.get("shipping") is True:
        fail("overlay cannot claim shipping")
    if bool(overlay.get("runtime_authority", False)) is not True:
        fail("overlay must keep runtime_authority true for deny fields")

    by_id: dict[str, dict[str, Any]] = {}
    for raw in overlay.get("techniques", []):
        if isinstance(raw, dict) and raw.get("id"):
            by_id[str(raw["id"])] = raw
    missing = [tid for tid in REQUIRED_IDS if tid not in by_id]
    if missing:
        fail(f"overlay missing techniques: {missing}")
    for tid, row in by_id.items():
        for field in REQUIRED_FIELDS:
            if field not in row:
                fail(f"{tid} missing {field}")
        if not str(row.get("entry_state", "")).startswith("PLAYER_"):
            fail(f"{tid} entry_state must be PLAYER_*")

    catalog_ids = {str(item.get("id")) for item in catalog.get("techniques", []) if isinstance(item, dict)}
    for tid in REQUIRED_IDS:
        if tid not in catalog_ids:
            fail(f"techniques.json missing {tid}")

    runtime_map = mapper.get("catalog_to_runtime", {})
    mirror = mapper.get("mirror", {})
    for key in ("disputa_pegada", "guarda_aberta", "montada", "costas"):
        if key not in runtime_map:
            fail(f"mapper missing catalog key {key}")
    for state in REQUIRED_RUNTIME:
        if state == "PLAYER_STANDING_NEUTRAL":
            continue
        if state not in mirror:
            fail(f"mapper missing mirror for {state}")

    nodes = policy.get("nodes", [])
    if len(nodes) < 7:
        fail("davi policy needs 7 state nodes")
    deny_map = policy.get("deny_map", {})
    if deny_map.get("baiana") != "sprawl":
        fail("davi deny_map must map baiana -> sprawl")

    tokens = (
        ("TechniqueResolver.gd", resolver, ("denied", "chain_id", "released_before_commit", "state_to_defended")),
        ("SliceStateMapper.gd", mapper_src, ("catalog_to_runtime", "PLAYER_TOP_GUARD")),
        ("DataRegistry.gd", registry, ("_apply_slice_ouro_overlay", "technique_slice_ouro")),
        ("DaviAIController.gd", davi, ("davi_policy_slice_v1", "_preferred_ids_for_state")),
    )
    for label, source, required in tokens:
        for token in required:
            if token not in source:
                fail(f"{label} missing token {token}")

    baiana = by_id["baiana"]
    denied = resolve_python(baiana, {"state": "PLAYER_STANDING_NEUTRAL", "frame": 1, "defense_input": "sprawl"})
    if denied.get("denied") is not True or denied.get("state_to") != "PLAYER_TOP_CLINCH":
        fail(f"baiana vs sprawl smoke failed: {denied}")

    faked = resolve_python(baiana, {"state": "PLAYER_STANDING_NEUTRAL", "frame": 3, "released_before_commit": True})
    if faked.get("faked") is not True or faked.get("state_to") != "PLAYER_STANDING_NEUTRAL":
        fail(f"baiana fake smoke failed: {faked}")

    report = {
        "ok": True,
        "shipping": False,
        "overlay_techniques": len(by_id),
        "davi_nodes": len(nodes),
        "deny_smoke": "baiana_vs_sprawl",
        "state_to": denied["state_to"],
    }
    print(json.dumps(report, ensure_ascii=False))
    return report


if __name__ == "__main__":
    validate()
