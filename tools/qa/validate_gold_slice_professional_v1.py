#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(rel: str):
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    contract = load("data/production/gold_slice_professional_v1.json")
    feedback = load("data/combat/combat_feedback_v1.json")
    timing = load("data/combat/bjj_timing_windows_v1.json")
    living = load("data/world/terreiro_living_hub_v1.json")
    checklist = load("data/qa/android_gold_slice_manual_checklist_v1.json")
    golden = load("data/combat/golden_chain_ruan_davi_v1.json")
    settings = load("data/settings.json")

    if contract.get("shipping") is True:
        errors.append("gold_slice_contract_must_default_shipping_false")
    if contract.get("authorities", {}).get("combat") != "CombatManager":
        errors.append("combat_authority_must_remain_CombatManager")
    if contract.get("authorities", {}).get("audio") != "AudioManager":
        errors.append("audio_authority_must_remain_AudioManager")

    required = set(contract.get("fight_acceptance", {}).get("required_techniques", []))
    golden_ids = {
        str(x.get("technique_id"))
        for x in golden.get("success_chain", []) + golden.get("alternate_branches", [])
    }
    for branch in golden.get("defense_branches", []):
        golden_ids.add(str(branch.get("attack_id")))
        golden_ids.add(str(branch.get("counter_id")))
    if required != golden_ids:
        errors.append(f"gold_technique_set_mismatch:{sorted(required ^ golden_ids)}")

    feedback_ids = set(feedback.get("profiles", {}))
    if feedback_ids != required:
        errors.append(f"feedback_profiles_mismatch:{sorted(feedback_ids ^ required)}")

    touch_floor = int(timing.get("input_profiles", {}).get("touch", {}).get("minimum_counter_window_ms", 0))
    contract_floor = int(contract.get("fight_acceptance", {}).get("touch_counter_floor_ms", 0))
    if contract_floor != touch_floor or contract_floor < 250:
        errors.append("touch_counter_floor_must_match_authority_and_be_at_least_250ms")

    if not bool(settings.get("accessibility", {}).get("large_touch_targets", False)):
        errors.append("large_touch_targets_must_remain_enabled")
    if "reduced_motion" not in settings.get("accessibility", {}):
        errors.append("reduced_motion_setting_missing")
    if "screen_shake" not in settings.get("video", {}):
        errors.append("screen_shake_setting_missing")

    if set(living.get("time_blocks", {})) != {"manha", "tarde", "noite", "madrugada"}:
        errors.append("terreiro_time_blocks_must_cover_full_day")
    if int(living.get("max_ambience_layers", 0)) < 3:
        errors.append("terreiro_requires_at_least_three_ambience_layers")

    expected_manual = {
        "landscape_ok", "safe_area_ok", "touch_ok", "text_readable",
        "menu_to_terreiro_ok", "pre_fight_ok", "combat_ok", "result_ok",
        "cria_live_ok", "week_advance_ok", "save_restart_ok",
        "sustained_fps_45_or_better", "no_severe_thermal", "audio_balance_ok",
    }
    checks = set(checklist.get("checks", {}))
    if checks != expected_manual:
        errors.append(f"android_manual_checklist_mismatch:{sorted(checks ^ expected_manual)}")
    if any(checklist.get("checks", {}).values()):
        errors.append("manual_checklist_template_must_fail_closed")

    android = contract.get("android_acceptance", {})
    if not bool(android.get("physical_device_required", False)):
        errors.append("physical_android_device_gate_required")
    if int(android.get("sustained_floor_fps", 0)) < 45:
        errors.append("android_sustained_floor_below_45")
    if android.get("release_ready_default") is not False:
        errors.append("release_ready_default_must_be_false")

    for section in ("pixel_authoring", "godot_test", "profiling", "audio", "offline_ai"):
        if not contract.get("toolchain", {}).get(section):
            errors.append(f"toolchain_section_missing:{section}")

    if errors:
        print("FAIL gold_slice_professional_v1")
        for err in errors:
            print(err)
        return 1
    print("OK gold_slice_professional_v1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
