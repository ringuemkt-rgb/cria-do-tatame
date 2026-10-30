#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    q = json.loads((ROOT / "data/visual/visual_production_queue_v1.json").read_text(encoding="utf-8"))
    errors: list[str] = []
    if q.get("shipping") is True:
        errors.append("queue_shipping_must_be_false")
    lotes = q.get("lotes", [])
    if not lotes or lotes[0].get("id") != "L01_identity_and_hub":
        errors.append("lote01_must_be_first")
    files = lotes[0].get("files", [])
    if len(files) != 10:
        errors.append("lote01_must_have_10_files")
    names = [f.get("file") for f in files]
    if "identity__ruan_macacao__v1.png" not in names:
        errors.append("missing_ruan_identity")
    if "map_base__itubera_02__v1.png" not in names:
        errors.append("missing_itubera_base")
    if any(f.get("bake_hud") is True for f in files):
        errors.append("hud_baked")
    sidecar = ROOT / "assets/sidecar.template.json"
    if not sidecar.is_file():
        errors.append("missing_sidecar_template")
    if errors:
        print("FAIL")
        print("\n".join(errors))
        return 1
    print("OK visual_production_queue_v1")
    return 0


if __name__ == "__main__":
    sys.exit(main())
