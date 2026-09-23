#!/usr/bin/env python3
"""Structural validator for ctt_paired_motion_v1.

Standard-library only so it can run inside the repository quality gate.
This validator never promotes assets and does not claim biomechanical validity.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

REQUIRED_TOP = {
    "schema", "technique_id", "fps", "actors", "joint_set",
    "frames", "contacts", "events", "provenance",
}
ROLES = {"attacker", "defender"}
EVENT_ORDER = ["anticipation", "entry", "establish", "stabilize", "response"]
TERMINAL_EVENTS = {"tap", "escape", "intervention"}
RESEARCH_OR_RESTRICTED = {
    "mamma", "easymocap", "wham", "4dhumans", "smpl", "smplx",
    "chi3d", "interact", "sbu", "amass",
}


def _finite_vec3(value: object) -> bool:
    return (
        isinstance(value, list)
        and len(value) == 3
        and all(isinstance(v, (int, float)) and math.isfinite(float(v)) for v in value)
    )


def validate(data: dict) -> list[str]:
    errors: list[str] = []
    missing = sorted(REQUIRED_TOP - set(data))
    if missing:
        errors.append(f"missing top-level fields: {', '.join(missing)}")
        return errors

    if data.get("schema") != "ctt_paired_motion_v1":
        errors.append("schema must be ctt_paired_motion_v1")

    fps = data.get("fps")
    if not isinstance(fps, int) or not 12 <= fps <= 240:
        errors.append("fps must be an integer in [12, 240]")

    actors = data.get("actors")
    if not isinstance(actors, list) or len(actors) != 2:
        errors.append("actors must contain exactly two entries")
    else:
        roles = {a.get("role") for a in actors if isinstance(a, dict)}
        if roles != ROLES:
            errors.append("actors must contain exactly attacker and defender")
        for actor in actors:
            if not isinstance(actor, dict) or not str(actor.get("character_id", "")).strip():
                errors.append("each actor requires a non-empty character_id")

    joint_set = data.get("joint_set")
    if not isinstance(joint_set, list) or len(joint_set) < 12:
        errors.append("joint_set must contain at least 12 unique joints")
        joint_set = []
    elif len(set(joint_set)) != len(joint_set):
        errors.append("joint_set contains duplicate joints")

    frames = data.get("frames")
    frame_numbers: list[int] = []
    if not isinstance(frames, list) or len(frames) < 2:
        errors.append("frames must contain at least two frames")
        frames = []
    else:
        for index, frame in enumerate(frames):
            if not isinstance(frame, dict):
                errors.append(f"frame[{index}] must be an object")
                continue
            number = frame.get("frame")
            if not isinstance(number, int) or number < 0:
                errors.append(f"frame[{index}].frame must be a non-negative integer")
                continue
            frame_numbers.append(number)
            for role in ROLES:
                pose = frame.get(role)
                joints = pose.get("joints") if isinstance(pose, dict) else None
                if not isinstance(joints, dict):
                    errors.append(f"frame {number}: {role}.joints missing")
                    continue
                missing_joints = sorted(set(joint_set) - set(joints))
                if missing_joints:
                    errors.append(
                        f"frame {number}: {role} missing joints: {', '.join(missing_joints)}"
                    )
                for joint, vec in joints.items():
                    if joint in joint_set and not _finite_vec3(vec):
                        errors.append(f"frame {number}: {role}.{joint} must be finite vec3")

        if frame_numbers != sorted(frame_numbers) or len(set(frame_numbers)) != len(frame_numbers):
            errors.append("frame numbers must be unique and strictly increasing")

    if frame_numbers:
        first_frame, last_frame = frame_numbers[0], frame_numbers[-1]
    else:
        first_frame, last_frame = 0, -1

    contacts = data.get("contacts")
    if not isinstance(contacts, list):
        errors.append("contacts must be an array")
        contacts = []
    for index, contact in enumerate(contacts):
        if not isinstance(contact, dict):
            errors.append(f"contact[{index}] must be an object")
            continue
        start, end = contact.get("start"), contact.get("end")
        if not isinstance(start, int) or not isinstance(end, int) or start > end:
            errors.append(f"contact[{index}] has invalid start/end")
        elif frame_numbers and (start < first_frame or end > last_frame):
            errors.append(f"contact[{index}] lies outside frame range")
        for endpoint in ("a", "b"):
            ref = str(contact.get(endpoint, ""))
            if "." not in ref:
                errors.append(f"contact[{index}].{endpoint} must be role.joint")
                continue
            role, joint = ref.split(".", 1)
            if role not in ROLES | {"environment"}:
                errors.append(f"contact[{index}].{endpoint} has invalid role {role}")
            if role in ROLES and joint_set and joint not in joint_set:
                errors.append(f"contact[{index}].{endpoint} references unknown joint {joint}")

    events = data.get("events")
    if not isinstance(events, list):
        errors.append("events must be an array")
        events = []
    event_frames: dict[str, int] = {}
    for index, event in enumerate(events):
        if not isinstance(event, dict):
            errors.append(f"event[{index}] must be an object")
            continue
        event_id, frame = event.get("id"), event.get("frame")
        if not isinstance(frame, int) or (frame_numbers and frame not in set(frame_numbers)):
            errors.append(f"event[{index}] references a frame not present in frames")
        if isinstance(event_id, str) and event_id not in event_frames:
            event_frames[event_id] = frame

    previous = -1
    for event_id in EVENT_ORDER:
        if event_id not in event_frames:
            errors.append(f"mandatory event missing: {event_id}")
            continue
        current = event_frames[event_id]
        if isinstance(current, int) and current < previous:
            errors.append("mandatory event phases are out of order")
        if isinstance(current, int):
            previous = current
    if not TERMINAL_EVENTS.intersection(event_frames):
        errors.append("one terminal event is required: tap, escape, or intervention")
    if "recovery" not in event_frames:
        errors.append("mandatory event missing: recovery")

    provenance = data.get("provenance")
    if not isinstance(provenance, dict):
        errors.append("provenance must be an object")
    else:
        restricted = {
            str(item).lower() for item in provenance.get("restricted_components_used", [])
        }
        shipping_eligible = provenance.get("shipping_eligible")
        if restricted.intersection(RESEARCH_OR_RESTRICTED) and shipping_eligible is True:
            errors.append("research/restricted components cannot be marked shipping_eligible")
        if provenance.get("source_type") == "owned_video" and provenance.get("consent_recorded") is not True:
            errors.append("owned_video requires consent_recorded=true")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("motion", type=Path)
    args = parser.parse_args()
    try:
        data = json.loads(args.motion.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    errors = validate(data)
    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1
    print(f"PASS: {args.motion} conforms to ctt_paired_motion_v1 structural contract")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
