import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
REPORTS = ROOT / "reports" / "cria_forge"

REQUIRED = ["id", "name_ptbr", "family", "state_from", "state_to_success", "state_to_defended"]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def validate():
    errors = []
    for path in DATA.rglob("*.json"):
        try:
            read_json(path)
        except Exception as exc:
            errors.append(f"JSON invalido: {path}: {exc}")
    catalog = DATA / "techniques" / "technique_catalog_v05.json"
    if catalog.exists():
        for item in read_json(catalog).get("techniques", []):
            for field in REQUIRED:
                if field not in item:
                    errors.append(f"{item.get('id', 'sem_id')} sem campo {field}")
    else:
        errors.append("catalogo de tecnicas nao encontrado")
    REPORTS.mkdir(parents=True, exist_ok=True)
    report = REPORTS / "validation_report.md"
    if errors:
        report.write_text("# Validation Report\n\n" + "\n".join(f"- {e}" for e in errors), encoding="utf-8")
        return 1
    report.write_text("# Validation Report\n\nVALIDATION OK\n", encoding="utf-8")
    return 0


def technique_pack(technique_id):
    catalog = read_json(DATA / "techniques" / "technique_catalog_v05.json")
    match = None
    for item in catalog.get("techniques", []):
        if item.get("id") == technique_id:
            match = item
            break
    if match is None:
        raise SystemExit(f"Tecnica nao encontrada: {technique_id}")
    out = REPORTS / "techniques" / technique_id
    out.mkdir(parents=True, exist_ok=True)
    sprite_request = {
        "character_id": "ruan_macacao",
        "technique_id": technique_id,
        "name_ptbr": match.get("name_ptbr"),
        "style": "HD Pixel Art 2.5D Regional Premium",
        "actions": ["leitura", "entrada", "contato", "controle", "estabilizacao", "transicao"],
        "requirements": ["silhueta clara", "pegada visivel", "base coerente", "fundo transparente"]
    }
    write_json(out / "sprite_request.json", sprite_request)
    (out / "qa_report.md").write_text("# QA Report\n\n- Canon: pendente\n- BJJ: pendente\n- Arte: pendente\n- Godot: pendente\n", encoding="utf-8")
    print(str(out))


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("validate")
    tech = sub.add_parser("technique")
    tech.add_argument("technique_id")
    args = parser.parse_args()
    if args.cmd == "validate":
        raise SystemExit(validate())
    if args.cmd == "technique":
        technique_pack(args.technique_id)


if __name__ == "__main__":
    main()
