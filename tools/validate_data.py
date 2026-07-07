import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def main():
    errors = []
    for path in DATA.rglob("*.json"):
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            errors.append(f"Invalid JSON: {path}: {exc}")
    catalog = DATA / "techniques" / "technique_catalog_v05.json"
    if catalog.exists():
        data = json.loads(catalog.read_text(encoding="utf-8"))
        for item in data.get("techniques", []):
            for field in ["id", "name_ptbr", "family", "state_from", "state_to_success"]:
                if field not in item:
                    errors.append(f"Technique missing {field}: {item}")
    else:
        errors.append("Missing technique_catalog_v05.json")
    if errors:
        for err in errors:
            print(err)
        raise SystemExit(1)
    print("VALIDATION OK")


if __name__ == "__main__":
    main()
