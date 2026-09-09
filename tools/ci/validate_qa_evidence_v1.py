#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data/production/qa_evidence_contract_v1.json"


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def nonempty(value):
    return value is not None and value != "" and value != [] and value != {}


def validate_visual(payload, contract):
    errors = []
    status = payload.get("status")
    frames = int(payload.get("frames_checked", 0) or 0)
    scenes = int(payload.get("scenes_checked", 0) or 0)
    if status == "PASS":
        if frames <= 0:
            errors.append("visual_pass_with_zero_frames")
        if scenes <= 0:
            errors.append("visual_pass_with_zero_scenes")
        for field in ["commit_sha", "godot_version", "human_reviewer", "checked_at"]:
            if not nonempty(payload.get(field)):
                errors.append(f"visual_pass_missing_{field}")
        required_viewports = set(contract["visual_runtime"]["required_viewports"])
        if not required_viewports.issubset(set(payload.get("viewport_matrix", []))):
            errors.append("visual_pass_missing_required_viewports")
        required_classes = set(contract["visual_runtime"]["required_scene_classes"])
        if not required_classes.issubset(set(payload.get("scene_classes_checked", []))):
            errors.append("visual_pass_missing_scene_classes")
        if not payload.get("frame_evidence"):
            errors.append("visual_pass_without_frame_evidence")
    return errors


def validate_android(payload):
    errors = []
    if payload.get("status") == "PASS":
        required = [
            "commit_sha", "apk_sha256", "device_manufacturer", "device_model",
            "android_version", "abi", "installation_proof", "launch_proof",
            "touch_proof", "combat_proof", "save_resume_proof",
            "frame_pacing_observation", "human_reviewer", "checked_at"
        ]
        for field in required:
            if not nonempty(payload.get(field)):
                errors.append(f"android_pass_missing_{field}")
        model = str(payload.get("device_model", "")).lower()
        manufacturer = str(payload.get("device_manufacturer", "")).lower()
        if "emulator" in model or "emulator" in manufacturer:
            errors.append("android_physical_pass_uses_emulator")
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--release", action="store_true")
    args = parser.parse_args()
    contract = load(CONTRACT_PATH)
    visual = load(ROOT / contract["visual_runtime"]["evidence_path"])
    android = load(ROOT / contract["android_physical"]["evidence_path"])
    errors = validate_visual(visual, contract) + validate_android(android)
    report = {
        "visual_status": visual.get("status"),
        "visual_frames_checked": int(visual.get("frames_checked", 0) or 0),
        "android_physical_status": android.get("status"),
        "errors": errors,
        "release_ready": not errors and visual.get("status") == "PASS" and android.get("status") == "PASS"
    }
    print(json.dumps(report, indent=2, ensure_ascii=False))
    if errors:
        return 1
    if args.release and not report["release_ready"]:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
