#!/usr/bin/env python3
"""Validate the data-driven combat audio/visual presentation contract."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
PRESENTATION_PATH = ROOT / "data" / "combat" / "combat_presentation_v01.json"
AUDIO_PATH = ROOT / "data" / "audio" / "audio_cues_v01.json"
TECHNIQUES_PATH = ROOT / "data" / "techniques.json"
DIRECTOR_PATH = ROOT / "src" / "combat" / "presentation" / "CombatPresentationDirector.gd"
GAMEFEEL_PATH = ROOT / "src" / "gamefeel" / "GameFeelManager.gd"
OVERLAY_PATH = ROOT / "src" / "gamefeel" / "CombatImpactOverlay.gd"
ARENA_PATH = ROOT / "scenes" / "combat" / "CombatArenaBase.gd"


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def resolve_audio(cues: dict[str, Any], cue_id: str) -> dict[str, Any]:
    seen: set[str] = set()
    cue = cues.get(cue_id, {})
    while isinstance(cue, dict) and "alias" in cue:
        alias = str(cue.get("alias", ""))
        require(alias and alias not in seen, f"audio alias cycle or empty alias at {cue_id}")
        seen.add(alias)
        cue = cues.get(alias, {})
    return cue if isinstance(cue, dict) else {}


def main() -> int:
    presentation = load_json(PRESENTATION_PATH)
    audio = load_json(AUDIO_PATH)
    techniques = load_json(TECHNIQUES_PATH).get("techniques", [])
    technique_ids = {str(item.get("id", "")) for item in techniques if isinstance(item, dict)}
    technique_families = {
        str(item.get("family", item.get("familia", "geral")))
        for item in techniques
        if isinstance(item, dict)
    }

    require(presentation.get("$schema") == "combat_presentation_v1", "invalid combat presentation schema")
    require(audio.get("$schema") == "audio_cues_v1", "invalid audio catalog schema")
    policy = presentation.get("runtime_policy", {})
    require(policy.get("simulation_independent") is True, "presentation must stay outside simulation")
    require(policy.get("presentation_may_not_change_outcome") is True, "presentation cannot alter outcomes")
    require(policy.get("offline_required") is True, "combat presentation must work offline")

    budgets = presentation.get("android_budgets", {})
    require(1 <= int(budgets.get("max_concurrent_impacts", 0)) <= 8, "impact budget must be 1..8")
    require(1 <= int(budgets.get("max_concurrent_sfx", 0)) <= 12, "SFX budget must be 1..12")
    require(0 <= int(budgets.get("max_hit_stop_ms", -1)) <= 100, "hit-stop budget exceeds 100 ms")
    require(0.0 <= float(budgets.get("max_shake_px", -1)) <= 8.0, "shake budget exceeds 8 px")
    require(0.0 <= float(budgets.get("max_flash_alpha", -1)) <= 0.16, "flash alpha exceeds safety cap")
    require(float(budgets.get("max_strobe_hz", 99.0)) <= 2.0, "strobe budget exceeds 2 Hz")

    configured_techniques = set(presentation.get("techniques", {}))
    require(configured_techniques <= technique_ids, "presentation overrides unknown techniques")
    configured_families = set(presentation.get("families", {}))
    require(configured_families <= technique_families, "presentation config contains unknown technique families")

    sfx = audio.get("sfx", {})
    require(isinstance(sfx, dict) and sfx, "audio catalog has no SFX")
    referenced_cues: set[str] = set()
    for group in [presentation.get("defaults", {}), presentation.get("families", {}), presentation.get("techniques", {}), presentation.get("deck_clash", {})]:
        for entry in group.values():
            if isinstance(entry, dict) and entry.get("audio_cue") not in (None, "", "none"):
                referenced_cues.add(str(entry["audio_cue"]))
    referenced_cues.update(str(value) for value in presentation.get("state_audio", {}).values())
    for cue_id in sorted(referenced_cues):
        cue = resolve_audio(sfx, cue_id)
        require(cue, f"presentation references missing audio cue: {cue_id}")
        asset = str(cue.get("asset", ""))
        fallback = cue.get("fallback", {})
        require(asset.startswith("res://assets/audio/") or isinstance(fallback, dict), f"invalid audio source for {cue_id}")
        if not (ROOT / asset.removeprefix("res://")).exists():
            require(isinstance(fallback, dict) and fallback, f"missing asset for {cue_id} requires a fallback")

    for path in [DIRECTOR_PATH, GAMEFEEL_PATH, OVERLAY_PATH, ARENA_PATH]:
        require(path.is_file(), f"missing runtime file: {path.relative_to(ROOT)}")
    arena_text = ARENA_PATH.read_text(encoding="utf-8")
    require("CombatPresentationDirectorScript" in arena_text, "combat arena does not consume presentation director")
    require('AudioManager.play_sfx(action_id)' not in arena_text, "arena still duplicates technique SFX")
    require('apply_for_technique", action_id' not in arena_text, "arena still duplicates hardcoded game feel")

    print(
        "[combat-presentation] ok: "
        f"{len(referenced_cues)} cues, {len(configured_families)} families, "
        "Android/accessibility budgets and single consumer validated"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
