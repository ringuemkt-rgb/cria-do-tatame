#!/usr/bin/env python3
"""Write candidate-only metadata; never claim human review or game integration."""
from __future__ import annotations
import argparse
from pathlib import Path
try:
    from .common import PIVOT, candidate, json_write, safe_id
except ImportError:
    from common import PIVOT, candidate, json_write, safe_id


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--kind", required=True)
    ap.add_argument("--id", required=True)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--origin", default="UNKNOWN")
    ap.add_argument("--license", default="UNKNOWN")
    args = ap.parse_args()
    data = candidate(args.kind, id=safe_id(args.id), origin=args.origin,
                     license_id=args.license, rights_reviewed=False,
                     pivot=PIVOT[:], qa_status="pending")
    json_write(args.out, data)
    print(args.out)


if __name__ == "__main__":
    main()
