#!/usr/bin/env python3
"""Create and verify an integrity/region lock for an approved character reference.

Identity Lock protects the approved source reference from silent replacement and
records human-authored identity regions. It is not, by itself, proof that an
action frame matches the character. The downstream identity_match gate requires
comparator evidence plus this lock.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any

from PIL import Image

CANON_DIR_REL = pathlib.Path("data/chars/canon")


def _read_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _region_hash(image: Image.Image, bbox: list[int]) -> str:
    x0, y0, x1, y1 = bbox
    crop = image.crop((x0, y0, x1, y1)).convert("RGBA")
    digest = hashlib.sha256()
    digest.update(f"{crop.width}x{crop.height}:RGBA:".encode("ascii"))
    digest.update(crop.tobytes())
    return digest.hexdigest()


def _validate_bbox(raw: Any, image_size: tuple[int, int], region_id: str) -> list[int]:
    if not isinstance(raw, list) or len(raw) != 4 or not all(isinstance(value, int) for value in raw):
        raise ValueError(f"identity region '{region_id}' requires human-authored integer bbox [x0,y0,x1,y1]")
    x0, y0, x1, y1 = raw
    width, height = image_size
    if not (0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height):
        raise ValueError(f"identity region '{region_id}' bbox outside reference bounds {image_size}")
    return raw


def reference_status(repo_root: pathlib.Path, character_id: str) -> dict[str, Any]:
    canon_path = repo_root / CANON_DIR_REL / f"{character_id}.json"
    canon = _read_json(canon_path)
    reference = canon.get("reference_contract", {})
    reference_path = repo_root / str(reference.get("master_reference", ""))
    regions = reference.get("identity_regions", [])
    bbox_ready = isinstance(regions, list) and bool(regions) and all(
        isinstance(item, dict) and isinstance(item.get("bbox"), list) for item in regions if item.get("required", True)
    )
    return {
        "character_id": character_id,
        "reference": reference_path.relative_to(repo_root).as_posix() if reference_path != repo_root else "",
        "reference_status": reference.get("master_reference_status"),
        "reference_exists": reference_path.is_file(),
        "required_region_bboxes_ready": bbox_ready,
        "lock_ready": reference.get("master_reference_status") == "approved" and reference_path.is_file() and bbox_ready,
    }


def build_lock(repo_root: pathlib.Path, character_id: str) -> tuple[pathlib.Path, dict[str, Any]]:
    canon_path = repo_root / CANON_DIR_REL / f"{character_id}.json"
    canon = _read_json(canon_path)
    reference = canon.get("reference_contract", {})
    if reference.get("master_reference_status") != "approved":
        raise ValueError("master reference is not human-approved")
    ref_rel = reference.get("master_reference")
    if not isinstance(ref_rel, str) or not ref_rel.startswith("assets/chars/ref/"):
        raise ValueError("master_reference must live under assets/chars/ref/")
    ref_path = repo_root / ref_rel
    if not ref_path.is_file():
        raise ValueError(f"master reference missing: {ref_rel}")

    with Image.open(ref_path) as source:
        image = source.convert("RGBA")
    regions = reference.get("identity_regions", [])
    if not isinstance(regions, list) or not regions:
        raise ValueError("identity_regions must be a non-empty list")

    locked_regions: list[dict[str, Any]] = []
    for item in regions:
        if not isinstance(item, dict):
            raise ValueError("identity region must be an object")
        region_id = str(item.get("id", ""))
        required = bool(item.get("required", True))
        bbox = item.get("bbox")
        if bbox is None and not required:
            continue
        validated = _validate_bbox(bbox, image.size, region_id)
        locked_regions.append(
            {
                "id": region_id,
                "required": required,
                "bbox": validated,
                "sha256_rgba": _region_hash(image, validated),
            }
        )

    if not any(item["required"] for item in locked_regions):
        raise ValueError("at least one required identity region must be locked")

    lock = {
        "$schema": "cria.identity_lock.v1",
        "version": "1.0.0",
        "character_id": character_id,
        "reference": ref_rel,
        "reference_sha256": sha256_file(ref_path),
        "reference_size": list(image.size),
        "reference_mode": "RGBA",
        "regions": locked_regions,
        "identity_match_authority": "supporting_evidence_only",
        "human_reference_approval_required": True,
        "shipping": False,
    }
    out = ref_path.with_suffix(".identity_lock.json")
    return out, lock


def verify_lock(repo_root: pathlib.Path, lock_path: pathlib.Path) -> list[str]:
    errors: list[str] = []
    lock = _read_json(lock_path)
    ref_rel = lock.get("reference")
    if not isinstance(ref_rel, str):
        return ["lock reference missing"]
    ref_path = repo_root / ref_rel
    if not ref_path.is_file():
        return [f"reference missing: {ref_rel}"]
    if sha256_file(ref_path) != lock.get("reference_sha256"):
        errors.append("reference_sha256 mismatch")
        return errors
    with Image.open(ref_path) as source:
        image = source.convert("RGBA")
    if list(image.size) != lock.get("reference_size"):
        errors.append("reference_size mismatch")
    for region in lock.get("regions", []):
        if not isinstance(region, dict):
            errors.append("invalid region entry")
            continue
        try:
            bbox = _validate_bbox(region.get("bbox"), image.size, str(region.get("id", "")))
        except ValueError as exc:
            errors.append(str(exc))
            continue
        if _region_hash(image, bbox) != region.get("sha256_rgba"):
            errors.append(f"region hash mismatch: {region.get('id')}")
    if lock.get("shipping") is not False:
        errors.append("identity lock cannot authorize shipping")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--character", default="")
    parser.add_argument("--root", default=".")
    parser.add_argument("--plan", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--verify", default="")
    args = parser.parse_args()
    repo_root = pathlib.Path(args.root).resolve()

    try:
        if args.verify:
            lock_path = repo_root / args.verify
            errors = verify_lock(repo_root, lock_path)
            if errors:
                for error in errors:
                    print("FAIL", error)
                return 1
            print(f"identity lock PASS: {lock_path}")
            return 0
        if not args.character:
            raise ValueError("--character is required unless --verify is used")
        if args.plan:
            print(json.dumps(reference_status(repo_root, args.character), ensure_ascii=False, indent=2))
            return 0
        if not args.write:
            raise ValueError("use --plan or --write")
        out, lock = build_lock(repo_root, args.character)
        out.write_text(json.dumps(lock, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {out}")
        return 0
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"FAIL identity lock: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
