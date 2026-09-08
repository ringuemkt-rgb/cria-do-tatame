#!/usr/bin/env python3
"""Build resolved BJJ reference records and paired-motion authoring specs.

This tool never converts source footage into assets. It only resolves the
research source table into deterministic, non-shipping specifications.
"""
from __future__ import annotations
import argparse
import json
import math
from pathlib import Path

PHASES = ["anticipation", "entry", "contact", "stabilization", "response", "recovery"]
CONTACT_TEMPLATES = {
    "TAKEDOWNS": [("upper_body", "lower_body", "control")],
    "SWEEPS": [("legs", "base", "control"), ("upper_body", "upper_body", "control")],
    "GUARD_PASSES": [("upper_body", "guard_frame", "pressure"), ("pelvis", "pelvis", "control")],
    "ARM_LOCKS": [("control_grip", "target_limb", "control")],
    "CHOKES": [("upper_body", "upper_torso", "control")],
    "LEG_ENTANGLEMENTS": [("legs", "target_leg", "control")],
    "ESCAPES": [("frames", "control_surface", "post")],
}

def phase_allocation(total: int) -> list[int]:
    patterns = {
        8: [2,1,1,1,2,1], 9: [2,2,1,1,2,1], 10: [2,2,1,2,2,1],
        11: [2,2,2,2,2,1], 12: [2,2,2,2,2,2],
        13: [3,2,2,2,2,2], 14: [3,3,2,2,2,2],
    }
    if total in patterns:
        return patterns[total]
    if total < 6:
        raise ValueError("frame budget must allow all six phases")
    weights = [0.20,0.18,0.14,0.18,0.18,0.12]
    raw = [w * total for w in weights]
    out = [max(1, int(math.floor(v))) for v in raw]
    while sum(out) > total:
        candidates = [i for i,v in enumerate(out) if v > 1]
        out[max(candidates, key=lambda i: out[i] - raw[i])] -= 1
    while sum(out) < total:
        out[max(range(6), key=lambda i: raw[i] - out[i])] += 1
    return out

def phase_notes(t: dict) -> dict[str, list[str]]:
    anticipation = t["anticipation"][:1] or ["preparação observável"]
    entry = t["anticipation"][1:] or [f"entrada para {t['name']}"]
    contact = t["control"][:1] or ["primeiro contato"]
    stabilization = t["control"][1:] or ["controle estabilizado"]
    high_risk = t["safety_class"].startswith("HIGH_RISK")
    if high_risk:
        response = ["prevenção precoce, interrupção segura ou tap"]
        recovery = ["finalização permanece visualmente abstraída; tap/intervenção e retorno seguro"]
    else:
        response = t["defense"] or ["resposta defensiva observável"]
        recovery = ["retorno posicional seguro"]
    if t["id"] == "e07":
        response = ["desengaje precoce, prevenção posicional ou tap; sem instrução direcional"]
        recovery = ["retorno seguro sem representar rotação de escape"]
    return dict(zip(PHASES, [anticipation,entry,contact,stabilization,response,recovery]))

def resolve(source: dict) -> tuple[dict, dict]:
    records, specs = [], []
    for t in source["techniques"]:
        notes = phase_notes(t)
        lo, hi = t["animation_frames"]
        target = round((lo + hi) / 2)
        allocation = phase_allocation(target)
        contacts = [
            {"id":f"c{i}","attacker_region":a,"defender_region":b,"kind":kind,
             "active_phases":["contact","stabilization","response"]}
            for i,(a,b,kind) in enumerate(CONTACT_TEMPLATES[t["family"]],1)
        ]
        high_risk = t["safety_class"].startswith("HIGH_RISK")
        records.append({
            "schema":"ctt_reference_investigation_v1","technique_id":t["id"],"name":t["name"],
            "verification_status":"DRAFT_AWAITING_SOURCE_CITATION",
            "classification":{"family":t["family"],"position_start":t["position_start"],"position_end":t["position_end"],"gi":t["gi"],"nogi":t["nogi"],"safety_class":t["safety_class"]},
            "reference_layer":{"sources":[],"citation_only":True,"asset_ingestion":False},
            "observed_dynamics":notes,
            "observed_timing":{"measured":False,"samples":[]},
            "animation_timing":{"fps":12,"target_frames":[lo,hi],"authored_for_readability":True},
            "biomechanics":{"key_joints":["pelvis_attacker","pelvis_defender","shoulders_both","knees_both"],
                "contact_pairs":[f"attacker.{c['attacker_region']}:defender.{c['defender_region']}" for c in contacts],
                "center_of_mass_notes":["confirmar continuidade de base, peso e contato por captura própria"],
                "prohibited_pose_errors":["body_interpenetration","teleport_contact","joint_discontinuity"]},
            "defensive_response":{"representation":"high_level_only","dangerous_directional_instruction":False,
                **({"escape_instruction":None,"escape_instruction_policy":"DO_NOT_PRESCRIBE_DIRECTIONAL_ESCAPE"} if high_risk else {})},
            "production":{"reference_video_shipping":False,"owned_capture_required":True,"paired_motion_required":True,
                "visual_qa_required":True,"biomechanics_qa_required":True,"human_review_required":True,"shipping":False}
        })
        phases = [{"name":name,"frames":frames,"source_notes":notes[name],
                   "contact_intent_ids":[c["id"] for c in contacts] if name in {"contact","stabilization","response"} else [],
                   "sync_events":[name]} for name,frames in zip(PHASES,allocation)]
        spec = {
            "schema":"ctt_paired_motion_spec_v1","technique_id":t["id"],"family":t["family"],"safety_class":t["safety_class"],"fps":12,
            "frame_budget":{"range":[lo,hi],"target":target,"allocation_sum":sum(allocation)},
            "fighters":{"attacker":"rig_role_attacker","defender":"rig_role_defender"},
            "phases":phases,"contact_intents":contacts,
            "sync_map_spec":{"pivot_region":"shared_center_of_contact","frame_align":True},
            "provenance":{"atlas_ref":t["id"],"citation_only":True,"owned_capture_required":True},
            "shipping":{"eligible":False,"gates":["L1","L2","L3","L4"]},
            "qa":{"contact_max_frame_error":1,"pivot_drift_px":1,"teleport_threshold":0.18,"angular_deg_target":10,"thresholds_are_engineering_targets":True},
            "safety_policy":{"dangerous_directional_escape_instruction":False,"high_risk_finish_detail":"ABSTRACTED" if high_risk else "STANDARD"}
        }
        if spec["frame_budget"]["target"] != spec["frame_budget"]["allocation_sum"]:
            raise AssertionError(f"frame allocation mismatch: {t['id']}")
        specs.append(spec)
    return ({"schema":"ctt_reference_investigation_atlas_v1","version":"1.2","status":"RESEARCH_ONLY","policy":source["policy"],"count":len(records),"techniques":records},
            {"schema":"ctt_paired_motion_specs_collection_v1","version":"1.0","count":len(specs),"specs":specs})

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--source", default="data/research/atlas_dinamica_source_v1.json")
    p.add_argument("--atlas-out", default="data/research/reference_investigation_v1.json")
    p.add_argument("--specs-out", default="data/motions/paired_motion_specs_v1.json")
    args = p.parse_args()
    source = json.loads(Path(args.source).read_text(encoding="utf-8"))
    atlas, specs = resolve(source)
    Path(args.atlas_out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.specs_out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.atlas_out).write_text(json.dumps(atlas,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    Path(args.specs_out).write_text(json.dumps(specs,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"generated {atlas['count']} reference records and {specs['count']} paired-motion specs")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
