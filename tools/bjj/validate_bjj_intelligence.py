#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def fail(errors, msg):
    errors.append(msg)


def validate():
    errors = []
    required_skills = {
        ".agents/skills/cria-bjj-fight-intelligence/SKILL.md": ["version: 1.0.0", "fail_closed: true", "shipping_default: false", "generative: auxiliary_only"],
        ".agents/skills/cria-video-intelligence/SKILL.md": ["version: 0.1.0", "stop_condition: CORPUS_GAP | LICENSE_UNKNOWN | SOURCE_BYTES_MISSING"],
        ".agents/skills/cria-pixel-motion-pipeline/SKILL.md": ["version: 0.1.0", "generative: auxiliary_only"],
        ".agents/skills/cria-combat-runtime/SKILL.md": ["version: 0.1.0", "runtime_authority: CombatManager", "runtime_implementation_status: SPEC_ONLY"],
    }
    for path, needles in required_skills.items():
        p = ROOT / path
        if not p.exists():
            fail(errors, f"missing skill {path}")
            continue
        text = p.read_text(encoding="utf-8")
        for needle in needles:
            if needle not in text:
                fail(errors, f"{path}: missing contract marker {needle}")

    manifest = load("data/visual/production_manifest_v02.json")
    tech = {x["id"]: x for x in manifest.get("paired_techniques", [])}
    canonical = tech.get("raspagem_tesoura")
    if not canonical:
        fail(errors, "production manifest missing raspagem_tesoura")
    dossier = load("data/bjj/dossiers/003_raspagem_tesoura.json")
    if dossier.get("shipping") is not False:
        fail(errors, "dossier 003 must be shipping=false")
    proposal = dossier.get("proposal", {})
    has_conflict = canonical and (
        proposal.get("frame_spec", {}).get("frames_total") != canonical.get("frames_target")
        or proposal.get("entry") != canonical.get("entry")
        or proposal.get("success_states") != [canonical.get("exit")]
    )
    if has_conflict and dossier.get("status") != "DRAFT_CONFLICT_PENDING_RESOLUTION":
        fail(errors, "dossier 003 conflicts with authority but is not blocked")
    if has_conflict and len(dossier.get("conflicts", [])) < 1:
        fail(errors, "dossier 003 must enumerate authority conflicts")

    gate = load("data/bjj/dossiers/001_baiana_single_leg_human_gate.json")
    if gate.get("assistant_may_recommend_but_not_sign") is not True:
        fail(errors, "AI must not sign human_bjj_gate")
    if gate.get("human_decision") != "PENDING":
        fail(errors, "human gate must remain pending until explicit human review")
    if gate.get("shipping") is not False:
        fail(errors, "baiana human-gate dossier must remain shipping=false")

    corpus = load("data/bjj/corpus/baiana_single_leg_v1.json")
    custody = corpus.get("custody", {})
    if custody.get("license_status") == "UNKNOWN":
        if custody.get("status") != "CUSTODY_BLOCKED":
            fail(errors, "unknown license must block custody")
        for stage in ("V2_event_annotation", "V3_pose_keypoints"):
            if not str(corpus.get("stages", {}).get(stage, {}).get("status", "")).endswith("BLOCKED_BY_V1"):
                fail(errors, f"{stage} must be blocked by V1")
    if corpus.get("evidence_claim") != "NO_VIDEO_ANALYSIS_PERFORMED":
        fail(errors, "cannot claim video analysis without source bytes")

    return errors


if __name__ == "__main__":
    problems = validate()
    if problems:
        for problem in problems:
            print("FAIL:", problem)
        raise SystemExit(1)
    print("BJJ INTELLIGENCE CONTRACT OK; FAIL-CLOSED BLOCKS PRESERVED")
