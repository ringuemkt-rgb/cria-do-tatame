#!/usr/bin/env python3
"""Fail-closed structural validator for CRIA Grappling Motion Lab V1."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
MOTION_LAB = ROOT / "data/research/grappling_motion_lab_contract_v1.json"
CORPUS = ROOT / "data/research/grappling_video_corpus_contract_v1.json"
SOURCE_LEDGER = ROOT / "data/research/grappling_video_source_ledger_v1.json"
TOOL_REGISTRY = ROOT / "data/research/motion_tool_registry_v1.json"
CAPTURE_TEMPLATE = ROOT / "data/research/grappling_capture_session_template_v1.json"
CLIP_SCHEMA = ROOT / "assets/schemas/grappling_motion_clip_v1.schema.json"
COMPLETION = ROOT / "data/combat/bjj_completion_gate_v1.json"
PHYSICAL_BINDINGS = ROOT / "data/combat/grappling_physical_bindings_slice_v1.json"
SKILL = ROOT / ".agents/skills/cria-grappling-motion-lab/SKILL.md"
DOC = ROOT / "docs/gameplay/GRAPPLING_MOTION_LAB_V1.md"
EXTERNAL_REGISTRY = ROOT / "data/production/external_tool_registry_v1.json"

RAW_MEDIA_EXTENSIONS = {".mp4", ".mov", ".mkv", ".avi", ".mxf", ".webm", ".mts", ".m2ts"}
CANONICAL_PHASES = ["anticipation", "entry", "establish", "stabilize", "response", "recovery"]


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.relative_to(ROOT)} root must be object")
    return value


def _ids(rows: Any) -> set[str]:
    if not isinstance(rows, list):
        return set()
    return {str(row.get("id", "")) for row in rows if isinstance(row, dict) and row.get("id")}


def validate() -> dict[str, Any]:
    errors: list[str] = []
    required_paths = [
        MOTION_LAB, CORPUS, SOURCE_LEDGER, TOOL_REGISTRY, CAPTURE_TEMPLATE,
        CLIP_SCHEMA, COMPLETION, PHYSICAL_BINDINGS, SKILL, DOC, EXTERNAL_REGISTRY,
    ]
    for path in required_paths:
        if not path.exists():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")
    if errors:
        return {"ok": False, "errors": errors}

    lab = load(MOTION_LAB)
    corpus = load(CORPUS)
    ledger = load(SOURCE_LEDGER)
    tools = load(TOOL_REGISTRY)
    template = load(CAPTURE_TEMPLATE)
    schema = load(CLIP_SCHEMA)
    completion = load(COMPLETION)
    bindings = load(PHYSICAL_BINDINGS)
    skill_text = SKILL.read_text(encoding="utf-8")
    doc_text = DOC.read_text(encoding="utf-8")

    if lab.get("version") != "1.0.0" or lab.get("status") != "ACTIVE_AUTHORING_AND_RESEARCH_CONTRACT":
        errors.append("Motion Lab contract must be active v1.0.0")
    if lab.get("shipping") is not False or lab.get("runtime_authority") is not False:
        errors.append("Motion Lab research metadata must remain non-shipping and non-runtime-authoritative")

    authority = lab.get("authorities", {})
    expected_authorities = {
        "combat_state": "src/combat/BJJGraphReducerV2.gd",
        "grappling_runtime": "src/combat/CriaGrapplingRuntimeV1.gd",
        "physical_state": "src/combat/GrapplingPhysicalStateV1.gd",
        "physical_bindings": "data/combat/grappling_physical_bindings_slice_v1.json",
        "rules": "data/combat/bjj_rulesets_verified_v1.json",
        "sprite_pipeline": "data/visual/sprite_forge_contract_v2.json",
        "source_rights": "data/research/grappling_video_corpus_contract_v1.json",
        "source_ledger": "data/research/grappling_video_source_ledger_v1.json",
    }
    for key, value in expected_authorities.items():
        if authority.get(key) != value:
            errors.append(f"Motion Lab authority mismatch: {key}")

    non_authority = lab.get("non_authority_rules", {})
    for flag in (
        "pose_model_may_define_position",
        "action_model_may_define_technique",
        "video_embedding_may_define_rule",
        "motion_generator_may_define_contact",
        "renderer_may_define_score",
        "generated_motion_may_set_shipping_true",
        "public_video_url_is_permission",
    ):
        if non_authority.get(flag) is not False:
            errors.append(f"non-authority flag must remain false: {flag}")

    canonical_from_completion = completion.get("paired_animation_contract", {}).get("required_phases", [])
    if canonical_from_completion != CANONICAL_PHASES:
        errors.append("BJJ completion gate canonical phases changed unexpectedly")
    if lab.get("six_phase_motion_contract") != CANONICAL_PHASES:
        errors.append("Motion Lab phases must match canonical BJJ six-phase contract")

    phase_evidence = lab.get("phase_evidence", {})
    if phase_evidence.get("edge_presence_implies_continuity") is not False:
        errors.append("edge presence must never imply contact continuity")
    if phase_evidence.get("hidden_grip_may_be_inferred_as_fact") is not False:
        errors.append("hidden grip must never be inferred as fact")
    if phase_evidence.get("low_confidence_contact_state") != "UNKNOWN":
        errors.append("low-confidence contact must remain UNKNOWN")

    rights = corpus.get("rights_policy", {})
    if rights.get("default_status") != "BLOCKED_UNTIL_RIGHTS_CLASSIFIED":
        errors.append("corpus must remain rights-blocked by default")
    if rights.get("public_url_is_not_permission") is not True:
        errors.append("public URL must not be treated as permission")
    if rights.get("broadcast_or_instructional_video_may_be_used_automatically_for_commercial_training") is not False:
        errors.append("broadcast/instructional video cannot default to commercial training")
    if rights.get("preferred_corpus") != "CRIA_OWN_CAPTURE_WITH_RELEASES":
        errors.append("CRIA-owned capture with releases must remain preferred commercial corpus")

    source_tier_a = lab.get("source_tiers", {}).get("A_CRIA_OWN_MULTIVIEW", {})
    tier_a_requirements = set(source_tier_a.get("requirements", []))
    for field in ("athlete_release_refs", "recording_rights_ref", "raw_file_sha256", "camera_calibration_bundle"):
        if field not in tier_a_requirements:
            errors.append(f"own-capture rights/provenance requirement missing: {field}")

    capture = lab.get("capture_protocol", {})
    recommended = capture.get("recommended_view_range", [])
    if capture.get("minimum_for_gold_multiview") != 4:
        errors.append("gold multiview minimum must remain four cameras")
    if not isinstance(recommended, list) or recommended != [4, 8]:
        errors.append("recommended multiview range must remain 4..8")
    if int(capture.get("preferred_views", 0)) < int(capture.get("minimum_for_gold_multiview", 999)):
        errors.append("preferred camera count cannot be below gold minimum")

    if schema.get("$id") != "cria.grappling_motion_clip.v1.schema":
        errors.append("unexpected Grappling Motion Clip schema id")
    schema_required = set(schema.get("required", []))
    for field in (
        "clip_id", "source_id", "source_tier", "rights_status", "allowed_uses", "capture",
        "time", "modality", "ruleset_context", "technique", "athletes", "phase_spans",
        "derived_artifacts", "occlusion", "expert_review", "provenance", "shipping",
    ):
        if field not in schema_required:
            errors.append(f"motion clip schema missing required field: {field}")
    rights_enum = schema.get("properties", {}).get("rights_status", {}).get("enum", [])
    for value in ("BLOCKED", "RESEARCH_ONLY", "COMMERCIAL_DERIVATION_ALLOWED"):
        if value not in rights_enum:
            errors.append(f"motion clip rights enum missing: {value}")
    phase_enum = (
        schema.get("properties", {}).get("phase_spans", {}).get("items", {})
        .get("properties", {}).get("phase", {}).get("enum", [])
    )
    if phase_enum != CANONICAL_PHASES:
        errors.append("motion clip schema phases diverge from canonical six phases")
    if schema.get("properties", {}).get("shipping", {}).get("const") is not False:
        errors.append("motion clip metadata cannot be shipping evidence by itself")

    if template.get("status") != "TEMPLATE_NOT_EVIDENCE" or template.get("capture_complete") is not False:
        errors.append("capture template must remain explicitly non-evidence")
    if template.get("shipping") is not False:
        errors.append("capture template cannot claim shipping")
    template_capture = template.get("capture", {})
    if int(template_capture.get("camera_count", 0)) < 4 or len(template_capture.get("cameras", [])) < 4:
        errors.append("capture template must preserve at least four planned cameras")
    if template.get("recording_rights", {}).get("commercial_derivation_allowed") is not False:
        errors.append("blank capture template cannot pre-authorize commercial derivation")
    if template.get("promotion", {}).get("may_create_shipping_animation_reference") is not False:
        errors.append("blank capture template cannot promote shipping animation references")
    for participant in template.get("participants", []):
        if participant.get("athlete_release_ref") is not None:
            errors.append("template must not contain fabricated athlete release refs")
    for camera in template_capture.get("cameras", []):
        if camera.get("raw_file_sha256") is not None:
            errors.append("template must not contain fabricated raw-file hashes")

    if tools.get("reuse_authority") != "data/production/external_tool_registry_v1.json":
        errors.append("Motion tool registry must defer reuse authority to external tool registry")
    if tools.get("shipping") is not False:
        errors.append("motion research registry cannot be shipping evidence")
    tool_policy = tools.get("policy", {})
    for flag in (
        "this_registry_may_authorize_runtime_dependency",
        "this_registry_may_authorize_asset_shipping",
    ):
        if tool_policy.get(flag) is not False:
            errors.append(f"motion tool policy must remain false: {flag}")

    high = {row.get("id"): row for row in tools.get("high_value_candidates", []) if isinstance(row, dict)}
    if high.get("pose2sim", {}).get("source") != "perfanalytics/pose2sim":
        errors.append("Pose2Sim canonical source must be perfanalytics/pose2sim")
    if high.get("pose2sim", {}).get("observed_license") != "BSD-3-Clause":
        errors.append("Pose2Sim license classification must remain BSD-3-Clause until re-audited")
    if high.get("opensim", {}).get("observed_license") != "Apache-2.0":
        errors.append("OpenSim core must remain classified Apache-2.0 until re-audited")
    if high.get("dvc", {}).get("observed_license") != "Apache-2.0":
        errors.append("DVC must remain classified Apache-2.0 until re-audited")

    restricted = {row.get("id"): row for row in tools.get("restricted_or_reference_only", []) if isinstance(row, dict)}
    for tool_id in ("freemocap", "blendanything", "intermask", "coshmdm", "interact2ar", "intergen_interhuman", "vicos_bjj", "smplx"):
        if tool_id not in restricted:
            errors.append(f"restricted/reference-only tool missing: {tool_id}")
    if restricted.get("blendanything", {}).get("commercial_use_default") is not False:
        errors.append("BlendAnything current noncommercial license must block default commercial use")
    if restricted.get("vicos_bjj", {}).get("commercial_use_default") is not False:
        errors.append("ViCoS noncommercial data must block default commercial use")
    if restricted.get("intermask", {}).get("commercial_pretrained_use_default") is not False:
        errors.append("InterMask pretrained/data path cannot default to commercial use")

    source_rows = ledger.get("sources", [])
    claims = ledger.get("ingestion_claim", {})
    if not isinstance(source_rows, list):
        errors.append("source ledger sources must be an array")
        source_rows = []
    if not source_rows:
        if ledger.get("status") != "ACTIVE_EMPTY_LEDGER":
            errors.append("empty source ledger must say ACTIVE_EMPTY_LEDGER")
        for field in ("videos_ingested", "expert_reviewed_observations", "commercial_training_eligible_videos"):
            if int(claims.get(field, -1)) != 0:
                errors.append(f"empty source ledger must claim zero: {field}")
    else:
        if ledger.get("status") == "ACTIVE_EMPTY_LEDGER":
            errors.append("non-empty source ledger cannot claim ACTIVE_EMPTY_LEDGER")
        if int(claims.get("videos_ingested", 0)) > len(source_rows):
            errors.append("videos_ingested cannot exceed source-ledger records")

    binding_policy = bindings.get("policy", {})
    if binding_policy.get("runtime_may_infer_hidden_contact") is not False:
        errors.append("physical bindings may not infer hidden contact")
    if binding_policy.get("runtime_may_infer_contact_continuity_from_edge_presence") is not False:
        errors.append("physical bindings may not infer continuity from edge presence")

    research_root = ROOT / "data/research"
    raw_media_in_git = [str(path.relative_to(ROOT)) for path in research_root.rglob("*") if path.is_file() and path.suffix.lower() in RAW_MEDIA_EXTENSIONS]
    if raw_media_in_git:
        errors.append("raw media committed under data/research: " + ", ".join(raw_media_in_git))

    for token in (
        "A public URL is not permission",
        "Six-phase evidence",
        "3D-to-pixel handoff",
        "Automation may prelabel. Automation may never final-approve.",
    ):
        if token not in skill_text:
            errors.append(f"Motion Lab skill missing required policy token: {token}")
    for token in ("rights intake", "active learning", "contact_continuity", "Sprite Forge V2"):
        if token not in doc_text:
            errors.append(f"Motion Lab documentation missing required concept: {token}")

    return {
        "ok": not errors,
        "errors": errors,
        "canonical_phases": CANONICAL_PHASES,
        "preferred_views": capture.get("preferred_views"),
        "high_value_tools": len(high),
        "restricted_tools": len(restricted),
        "source_records": len(source_rows),
        "videos_ingested_claim": int(claims.get("videos_ingested", 0)),
        "raw_media_in_research_tree": raw_media_in_git,
        "shipping": False,
    }


def main() -> int:
    report = validate()
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
