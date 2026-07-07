import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
data_dir = root / "data"

ok = True
for path in sorted(data_dir.glob("*.json")):
    try:
        json.loads(path.read_text(encoding="utf-8"))
        print("OK", path)
    except Exception as exc:
        ok = False
        print("FAIL", path, exc)

if not ok:
    raise SystemExit(1)

print("JSON validation complete")
