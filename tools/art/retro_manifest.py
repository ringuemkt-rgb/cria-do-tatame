#!/usr/bin/env python3
"""Retro-indexa 100% dos binários no manifest_v2 + sidecars mínimos.

Phase 0.5 cleanup utility. This is deliberately conservative:
- every discovered binary is candidate-only;
- shipping is always false;
- historical provenance is never upgraded to a stronger claim;
- unknown rights remain pending and non-commercial.
"""
from __future__ import annotations

import hashlib
import json
import pathlib

BIN = {".png", ".gif", ".jpg", ".jpeg", ".webp", ".ase", ".aseprite", ".wav", ".ogg", ".mp3"}
ROOT = pathlib.Path(".")
MAN = pathlib.Path("assets/manifest_v2.json")
REPORT = pathlib.Path("reports/repo/retro_manifest_report.json")


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def binary_paths() -> list[pathlib.Path]:
    return [
        p
        for p in sorted(ROOT.rglob("*"))
        if p.is_file() and ".git" not in p.parts and p.suffix.lower() in BIN
    ]


def main() -> int:
    if MAN.exists():
        man = json.loads(MAN.read_text(encoding="utf-8"))
    else:
        man = {
            "$schema": "schemas/manifest_v2.schema.json",
            "version": 2,
            "policy": {
                "default_status": "candidate",
                "default_shipping": False,
                "reference_is_runtime": False,
                "required_sidecars": ["license", "provenance", "qa"],
                "audio_status": "audio_pending",
            },
            "assets": [],
        }

    assets = man.setdefault("assets", [])
    by_path = {
        item.get("path"): item
        for item in assets
        if isinstance(item, dict) and isinstance(item.get("path"), str)
    }

    discovered = binary_paths()
    created_provenance = 0
    created_license = 0

    for path in discovered:
        rel = path.as_posix()
        digest = sha256(path)

        provenance = path.with_name(path.name + ".provenance.json")
        if not provenance.exists():
            provenance.write_text(
                json.dumps(
                    {
                        "asset": rel,
                        "sha256": digest,
                        "source": "historical",
                        "generator": "unknown",
                        "prompt_ref": None,
                        "creation_date": None,
                        "human_gate": "pending",
                        "shipping": False,
                    },
                    indent=2,
                    ensure_ascii=False,
                )
                + "\n",
                encoding="utf-8",
            )
            created_provenance += 1

        license_sidecar = path.with_name(path.name + ".license.json")
        if not license_sidecar.exists():
            license_sidecar.write_text(
                json.dumps(
                    {
                        "asset": rel,
                        "license": "internal-use",
                        "rights_status": "pending",
                        "commercial": False,
                        "shipping": False,
                    },
                    indent=2,
                    ensure_ascii=False,
                )
                + "\n",
                encoding="utf-8",
            )
            created_license += 1

        item = by_path.get(rel)
        if item is None:
            item = {
                "path": rel,
                "sha256": digest,
                "sidecars": [".provenance", ".license"],
                "status": "candidate",
                "shipping": False,
            }
            assets.append(item)
            by_path[rel] = item
        else:
            item["sha256"] = digest
            item["shipping"] = False
            if item.get("status") not in {
                "reference_candidate",
                "candidate",
                "candidate_integrated",
                "approved",
            }:
                item["status"] = "candidate"
            item["sidecars"] = [".provenance", ".license"]

    assets.sort(key=lambda item: item.get("path", ""))
    MAN.write_text(json.dumps(man, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    indexed = {item.get("path") for item in assets if isinstance(item, dict)}
    discovered_set = {path.as_posix() for path in discovered}
    missing = sorted(discovered_set - indexed)
    extra = sorted(indexed - discovered_set)

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    report = {
        "schema": "phase0_5_retro_manifest_report_v1",
        "discovered_binary_count": len(discovered),
        "indexed_binary_count": len(discovered_set & indexed),
        "manifest_entry_count": len(assets),
        "coverage_percent": 100.0 if not discovered else round(100 * len(discovered_set & indexed) / len(discovered), 4),
        "created_provenance_sidecars": created_provenance,
        "created_license_sidecars": created_license,
        "missing_from_manifest": missing,
        "stale_manifest_entries": extra,
        "shipping_true_count": sum(1 for item in assets if item.get("shipping") is True),
    }
    REPORT.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(json.dumps(report, indent=2, ensure_ascii=False))
    if missing or report["shipping_true_count"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
