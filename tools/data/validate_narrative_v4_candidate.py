#!/usr/bin/env python3
"""Validate the narrative v4 candidate without promoting it to runtime authority."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
N = ROOT / "data" / "narrative"

EXPECTED_ACT_IDS = [
    "ato_1_o_chao",
    "ato_2_o_molde",
    "ato_3_o_nome",
    "ato_4_a_queda",
    "ato_5_o_legado",
]


def load(name: str) -> dict:
    path = N / name
    if not path.exists():
        raise AssertionError(f"missing {path.relative_to(ROOT)}")
    return json.loads(path.read_text(encoding="utf-8"))


def _find_beat(acts: dict, beat_id: str) -> tuple[int, dict] | None:
    for index, act in enumerate(acts.get("acts", []), start=1):
        for beat in act.get("required_beats", []):
            if beat.get("id") == beat_id:
                return index, beat
    return None


def validate() -> list[str]:
    errors: list[str] = []
    canon = load("canon_v4.json")
    prologue = load("prologue_v1.json")
    acts = load("acts_v4.json")
    dialogues = load("dialogues_v4.json")
    chorus = load("chorus_v1.json")
    endings = load("endings_v3.json")

    if canon.get("status") != "CANON_CANDIDATE_NOT_RUNTIME_AUTHORITY":
        errors.append("canon_v4 must remain candidate, not runtime authority")
    if canon.get("current_runtime_authority") != "data/narrative/canon_v3.json":
        errors.append("canon_v3 must remain current runtime authority")

    stable = canon.get("act_identity_policy", {}).get("stable_ids", [])
    if stable != EXPECTED_ACT_IDS:
        errors.append("stable act IDs changed")
    actual = [a.get("id") for a in acts.get("acts", [])]
    if actual != EXPECTED_ACT_IDS:
        errors.append("acts_v4 IDs/order must preserve v3")

    if prologue.get("id") != "parte_zero_o_carro_de_mao":
        errors.append("Parte Zero ID missing")
    if len(prologue.get("scenes", [])) != 5:
        errors.append("Parte Zero must contain C0.1-C0.5")

    vera = _find_beat(acts, "vera_recruta")
    if not vera or vera[0] != 2 or not vera[1].get("mandatory"):
        errors.append("Vera recruitment must be mandatory in Act 2")
    elif "vera_salles" not in vera[1].get("characters", []):
        errors.append("Vera ID must remain vera_salles")

    biel = _find_beat(acts, "morte_biel")
    if not biel or biel[0] != 4 or not biel[1].get("irreversible"):
        errors.append("Biel irreversible death must remain in Act 4")

    pipoca = _find_beat(acts, "pipoca_isca")
    if not pipoca or not pipoca[1].get("pipoca_survives"):
        errors.append("Pipoca must survive the bait beat")

    chupeta = _find_beat(acts, "ruan_vs_chupeta")
    if not chupeta or chupeta[1].get("finish_rule") != "release_submission_then_stabilize_control":
        errors.append("Chupeta climax must resolve by released submission then stable control")

    for required in ["restituicao", "davi_revanche", "byaku_rematch", "dandara_abraco", "instituto_cria"]:
        found = _find_beat(acts, required)
        if not found or found[0] != 5:
            errors.append(f"Act 5 payoff missing: {required}")

    truth_policy = canon.get("truth_policy", {})
    threshold = truth_policy.get("threshold")
    if threshold != 8:
        errors.append("truth threshold must remain 8")

    forbidden_name = truth_policy.get("name", "Teruko Nishiuchi")
    for group_name in ["prologue_dialogues", "act_dialogues"]:
        for entry in dialogues.get(group_name, []):
            text = json.dumps(entry, ensure_ascii=False)
            if forbidden_name in text:
                errors.append(f"hidden truth name leaked before gate in {group_name}")
    for entry in dialogues.get("truth_dialogues", []):
        if forbidden_name in json.dumps(entry, ensure_ascii=False) and entry.get("requires_truth_fragments", 0) < threshold:
            errors.append("truth dialogue names Teruko without threshold gate")

    truth_chorus = chorus.get("ending_variants", {}).get("truth_overlay", {})
    if truth_chorus.get("requires_truth_fragments") != 8 or not truth_chorus.get("name_reveal"):
        errors.append("Coro truth reveal must be gated at 8 fragments")

    mains = endings.get("main_endings", [])
    if [e.get("id") for e in mains] != ["heroi_duas_aguas", "rei_dos_atalhos"]:
        errors.append("endings_v3 must keep exactly the two established main endings")
    overlay = endings.get("truth_overlay", {})
    if overlay.get("main_ending") is not False or overlay.get("required_fragments") != 8:
        errors.append("A Verdade must remain an 8-fragment overlay, not a main ending")
    if set(overlay.get("can_overlay", [])) != {"heroi_duas_aguas", "rei_dos_atalhos"}:
        errors.append("truth overlay must remain compatible with both main endings")

    hero = next((e for e in mains if e.get("id") == "heroi_duas_aguas"), {})
    if "carro_de_mao_retorna" not in hero.get("core_sequence", []):
        errors.append("wheelbarrow motif must return in hero ending")

    decisions = canon.get("migration_decisions", {})
    if decisions.get("tinker_knows_operation_from") != "act_2":
        errors.append("Tinker must know the operation from Act 2")
    if decisions.get("dende_truth") != "perpetuated_silence_but_not_sole_author_of_erasure":
        errors.append("Dende silence semantics drifted")

    return errors


def main() -> int:
    errors = validate()
    if errors:
        for err in errors:
            print(f"ERROR: {err}")
        print(f"narrative-v4: FAIL ({len(errors)} errors)")
        return 1
    print("narrative-v4: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
