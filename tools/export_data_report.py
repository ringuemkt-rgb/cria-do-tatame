import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
data_dir = root / "data"

for path in sorted(data_dir.glob("*.json")):
    data = json.loads(path.read_text(encoding="utf-8"))
    keys = [k for k, v in data.items() if isinstance(v, list)]
    total = sum(len(data[k]) for k in keys)
    print(f"{path.name}: {total} records")
