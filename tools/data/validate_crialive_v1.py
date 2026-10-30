#!/usr/bin/env python3
from __future__ import annotations
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]

def main() -> int:
    p = ROOT / "data/social/crialive_v1.json"
    d = json.loads(p.read_text(encoding="utf-8"))
    err = []
    if d.get("not_autoload") is not True:
        err.append("must_not_be_autoload")
    if d.get("authorities", {}).get("combat") != "CombatManager":
        err.append("combat_authority")
    if len(d.get("loops", [])) != 5:
        err.append("need_5_loops")
    if err:
        print("FAIL"); print("\n".join(err)); return 1
    print("OK crialive_v1"); return 0

if __name__ == "__main__":
    raise SystemExit(main())
