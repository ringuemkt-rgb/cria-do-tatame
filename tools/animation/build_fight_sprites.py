#!/usr/bin/env python3
"""Build candidate paired fight sprite packs; never promotes to shipping paths.

Default mode creates deterministic visible placeholders and schema-valid manifests.
HF mode is explicit, research-only and fail-closed on token/license/provenance.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import struct
import sys
import urllib.request
import zlib
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT = ROOT / "assets/source/generated_candidates/fight_sprites"
FRAME_W = 256
FRAME_H = 192
PHASES = ["anticipation", "entry", "establish", "stabilize", "response", "recovery", "release", "reset"]


def load_techniques() -> list[dict[str, Any]]:
    sources = [
        ROOT / "data/combat/harmony_contract_v1.json",
        ROOT / "data/techniques.json",
        ROOT / "data/techniques_dynamic_grapple_v03.json",
    ]
    found: dict[str, dict[str, Any]] = {}
    for path in sources:
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        candidates = data.get("techniques", [])
        if isinstance(candidates, dict):
            candidates = [{"id": key, **value} for key, value in candidates.items()]
        for item in candidates:
            technique_id = str(item.get("id") or item.get("technique_id") or "").strip()
            if technique_id:
                found.setdefault(technique_id, item)
    return [found[key] for key in sorted(found)]


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)


def write_placeholder_sheet(path: Path, frames: int = 8) -> None:
    width, height = FRAME_W * frames, FRAME_H
    pixels = bytearray(width * height * 4)

    def fill_rect(x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int, int]) -> None:
        for y in range(max(0, y0), min(height, y1)):
            for x in range(max(0, x0), min(width, x1)):
                offset = (y * width + x) * 4
                pixels[offset : offset + 4] = bytes(color)

    for frame in range(frames):
        base_x = frame * FRAME_W
        fill_rect(base_x, 0, base_x + FRAME_W, FRAME_H, (11, 11, 13, 255))
        fill_rect(base_x + 8, 8, base_x + FRAME_W - 8, FRAME_H - 8, (18, 19, 23, 255))
        shift = min(frame * 5, 28)
        fill_rect(base_x + 48 + shift, 62, base_x + 90 + shift, 148, (242, 194, 48, 255))
        fill_rect(base_x + 158 - shift, 66, base_x + 198 - shift, 148, (46, 143, 226, 255))
        fill_rect(base_x + 38 + shift, 144, base_x + 102 + shift, 154, (243, 240, 234, 255))
        fill_rect(base_x + 146 - shift, 144, base_x + 210 - shift, 154, (243, 240, 234, 255))
        fill_rect(base_x + 12, 172, base_x + FRAME_W - 12, 176, (74, 103, 65, 255))

    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y * stride : (y + 1) * stride])
    payload = b"\x89PNG\r\n\x1a\n"
    payload += png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    payload += png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    payload += png_chunk(b"IEND", b"")
    path.write_bytes(payload)


def request_hf_image(model: str, prompt: str, token: str) -> bytes:
    request = urllib.request.Request(
        f"https://api-inference.huggingface.co/models/{model}",
        data=json.dumps({"inputs": prompt}).encode("utf-8"),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        content_type = response.headers.get("Content-Type", "")
        body = response.read()
    if "image" not in content_type or not body.startswith(b"\x89PNG"):
        raise RuntimeError(f"HF did not return PNG image ({content_type})")
    return body


def write_manifest(pack: Path, fighter_id: str, rival_id: str, technique_id: str, mode: str, frames: int = 8) -> None:
    layout = []
    for index in range(frames):
        layout.append({
            "state": PHASES[index],
            "x": index * FRAME_W,
            "y": 0,
            "w": FRAME_W,
            "h": FRAME_H,
            "fps": 12,
            "loop": False,
            "events": ["release"] if PHASES[index] == "release" else [],
        })
    manifest = {
        "$schema": "cria_paired_animation_manifest_v2",
        "status": "candidate_not_shipping",
        "character_id": fighter_id,
        "defender_id": rival_id,
        "technique_id": technique_id,
        "image": "sprite_sheet.png",
        "frame_layout": layout,
        "pivot": [FRAME_W // 2, 154],
        "paired": True,
        "tap_release_required": True,
        "runtime_authority": "CombatManager",
        "generator_mode": mode,
    }
    (pack / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build_pack(args: argparse.Namespace, technique: dict[str, Any]) -> None:
    technique_id = str(technique.get("id") or technique.get("technique_id"))
    pack = args.output / args.fighter / technique_id
    pack.mkdir(parents=True, exist_ok=True)
    sheet = pack / "sprite_sheet.png"
    mode = args.mode
    if mode == "hf":
        token = os.environ.get("HF_TOKEN", "")
        if not token or not args.ack_research_only or args.model_license.upper() in {"", "UNRESOLVED", "UNKNOWN"}:
            raise RuntimeError("HF mode requires HF_TOKEN, --ack-research-only and a resolved --model-license")
        prompt = (
            f"paired Brazilian Jiu-Jitsu pose guide, {technique_id}, two fictional athletes, "
            "HD pixel art 2.5D, fixed side camera, safe technical release, transparent background"
        )
        sheet.write_bytes(request_hf_image(args.hf_model, prompt, token))
    else:
        write_placeholder_sheet(sheet)
    write_manifest(pack, args.fighter, args.rival, technique_id, mode)
    notes = {
        "status": "candidate_not_shipping",
        "source": "deterministic_placeholder" if mode == "placeholder" else args.hf_model,
        "model_license": "not_applicable" if mode == "placeholder" else args.model_license,
        "source_sha256": hashlib.sha256(sheet.read_bytes()).hexdigest(),
        "human_gates": ["BJJ", "animation", "art", "rights"],
        "promotion": "forbidden",
        "label": "derivado visual, nunca evidência" if mode == "hf" else "placeholder técnico",
    }
    (pack / "source_notes.json").write_text(json.dumps(notes, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fighter", default="ruan_macacao")
    parser.add_argument("--rival", default="davi_relampago")
    parser.add_argument("--technique")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--mode", choices=("placeholder", "hf"), default="placeholder")
    parser.add_argument("--hf-model", default="artificialguybr/PixelArtRedmond")
    parser.add_argument("--model-license", default="UNRESOLVED")
    parser.add_argument("--ack-research-only", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    techniques = load_techniques()
    if args.technique:
        techniques = [item for item in techniques if (item.get("id") or item.get("technique_id")) == args.technique]
    if not techniques:
        print("No techniques found", file=sys.stderr)
        return 1
    print(json.dumps({"mode": args.mode, "fighter": args.fighter, "techniques": len(techniques), "output": str(args.output)}))
    if args.dry_run:
        return 0
    for technique in techniques:
        build_pack(args, technique)
        print(f"candidate:{technique.get('id') or technique.get('technique_id')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
