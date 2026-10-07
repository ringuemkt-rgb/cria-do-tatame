#!/usr/bin/env python3
"""Materialize existing P1 verbatim plus data-driven candidate COMMANDS.

Counts follow Production OS v03; no filler is invented to reach 580.
This creates authoring instructions, never generated or approved assets.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from derive_production_manifest_v03 import CONTRACT_PATH, Derivator, ROOT, load_json

QA = ["canon_id", "source_provenance", "rights_review", "human_review", "identity_lock",
      "modality", "biomechanics_when_applicable", "scale", "pivot_anchor", "alpha_edges",
      "frame_count", "paired_sync_when_applicable", "mobile_readability",
      "safe_area_when_applicable", "godot_integration", "shipping_gate"]


def source_records(root: Path, requirement: dict) -> dict:
    """Carry actual authoring data without guessing missing roster fields."""
    out = {}
    source_id = requirement["source_id"]
    for reference in requirement["source_refs"]:
        path = root / reference.split("#", 1)[0]
        if path.suffix != ".json" or not path.is_file():
            continue
        data = load_json(path)
        if isinstance(data, dict) and data.get("character_id") == source_id:
            out[reference] = data
        elif isinstance(data, dict):
            for key, rows in data.items():
                if isinstance(rows, list):
                    for row in rows:
                        if isinstance(row, dict) and str(row.get("id", row.get("source_id", ""))) == source_id:
                            out[f"{reference}#{key}:{source_id}"] = row
    return out


def build_commands(root: Path = ROOT) -> tuple[list[dict], dict]:
    derived = Derivator(root, load_json(root / CONTRACT_PATH.relative_to(ROOT))).run()
    requirements = [r for r in derived["requirements"] if r["scope"] != "P1_GOLD_SLICE"]
    commands = []
    for index, req in enumerate(requirements, 21):
        # Numeric compatibility with the request; stable identity is requirement_id.
        candidate = "production/candidates/expanded/" + req["requirement_id"].replace(":", "/") + "/"
        commands.append({"command_number": index, "requirement_id": req["requirement_id"],
                         "category": req["category"], "kind": req["kind"],
                         "source_id": req["source_id"], "scope": req["scope"],
                         "auth": req["source_refs"], "metadata": req.get("metadata", {}),
                         "source_records": source_records(root, req), "blockers": req["blockers"],
                         "qa": QA, "out": candidate, "shipping": False})
    return commands, derived


def render(command: dict, batch: int, total: int) -> str:
    spec = {key: command[key] for key in ("requirement_id", "source_id", "kind", "scope", "metadata", "source_records", "blockers")}
    return (f"#CMD {command['command_number']:03d} | {command['category']} | lote {batch}/{total}\n"
            "STYLE: cria-art-direction@1.0.0\n"
            f"AUTH: {'; '.join(command['auth'])}\n"
            f"SPEC: {json.dumps(spec, ensure_ascii=False, sort_keys=True)}\n"
            "MOTION: derive from the authoritative action/layer; paired techniques require six synchronized phases.\n"
            "MOBILE: 128x128 RGBA sprites, shared pivot [64,96], nearest-neighbor; world/UI use their own contract.\n"
            f"QA: {'; '.join(command['qa'])}; unresolved blockers prevent promotion.\n"
            f"OUT: {command['out']} + metadata/sidecar; shipping=false\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=ROOT / "production/generated/commands")
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    commands, derived = build_commands()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    p1_path = ROOT / "production/p1/CRIA_ART_P1_COMMANDS_V1.md"
    p1_bytes = p1_path.read_bytes()
    (args.out_dir / "commands_p1_verbatim.md").write_bytes(p1_bytes)
    (args.out_dir / "commands_expanded.jsonl").write_text(
        "".join(json.dumps(c, ensure_ascii=False, sort_keys=True) + "\n" for c in commands), encoding="utf-8")
    (args.out_dir / "commands_expanded.txt").write_text(
        "\n".join(render(c, i, len(commands)) for i, c in enumerate(commands, 1)), encoding="utf-8")
    summary = {"p1_verbatim_sha256": hashlib.sha256(p1_bytes).hexdigest(),
               "p1_command_count": derived["source_snapshot"]["p1_commands"],
               "expanded_command_count": len(commands), "first_number": 21,
               "last_number": 20 + len(commands), "derivation_sha256": derived["derivation_sha256"],
               "source_blockers": derived["source_blockers"], "shipping": False,
               "generated_assets": 0, "human_approved_assets": 0}
    (args.out_dir / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 2 if args.require_complete and derived["source_blockers"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
