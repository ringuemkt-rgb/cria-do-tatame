"""Validate every JSON document shipped with the game.

The old validator only inspected files directly below ``data/``. Most game
content lives in nested catalog folders, so malformed production data could
pass the default quality gate. Keep this script dependency-free because it is
used locally and in GitHub Actions.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_ROOTS = (ROOT / "data", ROOT / "schemas")


def json_files() -> list[Path]:
    return sorted(
        path
        for folder in JSON_ROOTS
        if folder.exists()
        for path in folder.rglob("*.json")
        if path.is_file()
    )


def main() -> int:
    paths = json_files()
    if not paths:
        print("FAIL no JSON files found in data/ or schemas/")
        return 1

    failures: list[str] = []
    for path in paths:
        relative = path.relative_to(ROOT)
        try:
            json.loads(path.read_text(encoding="utf-8"))
            print("OK", relative)
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            failures.append(f"{relative}: {exc}")
            print("FAIL", relative, exc)

    print(f"Validated {len(paths)} JSON file(s); failures={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
