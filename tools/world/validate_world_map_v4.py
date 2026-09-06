#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "data/world/world_map_v4.json"
INFO = ROOT / "data/world/arena_info_v1.json"

EXPECTED_PAGES = {f"{i:02d}" for i in range(1, 11)}
EXPECTED_MUNICIPALITIES = {
    "itubera", "nilo_pecanha", "valenca", "camamu", "cairu", "itacare", "marau",
    "igrapiuna", "taperoa", "ibirapitanga", "teolandia", "pirai_do_norte",
    "tancredo_neves", "salvador",
}


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    for path in (MAP, INFO):
        if not path.exists():
            errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
    if errors:
        print(json.dumps({"ok": False, "errors": errors, "warnings": warnings}, ensure_ascii=False, indent=2))
        return 1

    try:
        world = json.loads(MAP.read_text(encoding="utf-8"))
        info = json.loads(INFO.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"JSON invalido: {exc}")
        print(json.dumps({"ok": False, "errors": errors, "warnings": warnings}, ensure_ascii=False, indent=2))
        return 1

    pages = world.get("pages", [])
    anchors = world.get("municipal_anchors", [])
    nodes = world.get("nodes", [])
    routes = world.get("routes", [])
    aliases = world.get("aliases", {})

    page_ids = [str(x.get("id", "")) for x in pages]
    if set(page_ids) != EXPECTED_PAGES or len(page_ids) != 10:
        errors.append(f"paginas esperadas 01..10; recebido {page_ids}")
    if len(set(page_ids)) != len(page_ids):
        errors.append("page ids duplicados")

    anchor_ids = [str(x.get("id", "")) for x in anchors]
    if set(anchor_ids) != EXPECTED_MUNICIPALITIES or len(anchor_ids) != 14:
        errors.append("municipal_anchors deve conter exatamente os 14 municipios canonicos")

    node_ids = [str(x.get("id", "")) for x in nodes]
    if len(nodes) != 36:
        errors.append(f"world_map_v4 deve declarar 36 gameplay nodes; recebeu {len(nodes)}")
    if len(set(node_ids)) != len(node_ids):
        errors.append("node ids duplicados")

    counts = world.get("counts", {})
    expected_counts = {"pages": 10, "municipal_anchors": 14, "gameplay_nodes": 36, "routes": 12}
    if counts != expected_counts:
        errors.append(f"counts divergente: {counts}")

    for page in pages:
        base = str(page.get("base", ""))
        if not base.startswith("res://assets/arenas/base/") or not base.endswith(".png"):
            errors.append(f"base invalida em pagina {page.get('id')}: {base}")

    valid_pages = set(page_ids)
    for item in anchors + nodes:
        pos = item.get("pos")
        if not isinstance(pos, list) or len(pos) != 2:
            errors.append(f"{item.get('id')} sem pos normalizada [x,y]")
        else:
            try:
                x, y = float(pos[0]), float(pos[1])
                if not (0.0 <= x <= 1.0 and 0.0 <= y <= 1.0):
                    errors.append(f"{item.get('id')} pos fora de 0..1: {pos}")
            except (TypeError, ValueError):
                errors.append(f"{item.get('id')} pos nao numerica: {pos}")
        if str(item.get("pagina", "")) not in valid_pages:
            errors.append(f"{item.get('id')} referencia pagina inexistente")
        if "target_page" in item and str(item["target_page"]) not in valid_pages:
            errors.append(f"{item.get('id')} target_page inexistente")

    endpoint_ids = set(anchor_ids) | set(node_ids)
    for route in routes:
        for key in ("from", "to"):
            if str(route.get(key, "")) not in endpoint_ids:
                errors.append(f"rota referencia endpoint fantasma: {route}")
        if route.get("bloqueavel_por_mare"):
            warnings.append(f"rota {route.get('from')}->{route.get('to')} depende de TideSystem (EPIC45)")

    by_node = {str(x["id"]): x for x in nodes}
    canonical_assertions = {
        "arena_do_dique": ("itubera", "02"),
        "quartel_cacaueira": ("itubera", "02"),
        "ponte_do_saici": ("itubera", "02"),
        "quartel_pf": ("valenca", "04"),
        "budokan": ("valenca", "04"),
        "dojo_tigre_branco": ("camamu", "05"),
        "ferro_velho_lapa": ("salvador", "10"),
        "comando_pmba": ("salvador", "10"),
    }
    for node_id, expected in canonical_assertions.items():
        node = by_node.get(node_id)
        if not node:
            errors.append(f"node canonico ausente: {node_id}")
            continue
        got = (str(node.get("mun", "")), str(node.get("pagina", "")))
        if got != expected:
            errors.append(f"{node_id} localizacao invalida: {got}, esperado {expected}")

    if "ponte_do_saci" in by_node:
        errors.append("ponte_do_saci nao pode existir como node canonico; usar alias")
    if aliases.get("ponte_do_saci") != "ponte_do_saici":
        errors.append("alias ponte_do_saci -> ponte_do_saici ausente")
    if world.get("migracao", {}).get("arena_do_dique", {}).get("para") != "itubera":
        errors.append("migracao Arena do Dique -> Itubera ausente")

    panels = info.get("arenas", [])
    panel_ids = [str(x.get("id", "")) for x in panels]
    if len(panels) != 36 or int(info.get("count", -1)) != 36:
        errors.append(f"arena_info_v1 deve conter 36 paineis; recebeu {len(panels)}")
    if set(panel_ids) != set(node_ids):
        missing = sorted(set(node_ids) - set(panel_ids))
        extra = sorted(set(panel_ids) - set(node_ids))
        errors.append(f"arena_info e nodes divergentes; missing={missing} extra={extra}")

    for panel in panels:
        for field in ("id", "nome", "mun", "tipo", "emblema", "descricao", "ecossistema", "servicos", "personagens", "lock"):
            if field not in panel:
                errors.append(f"painel {panel.get('id')} sem campo {field}")
        if not isinstance(panel.get("servicos", []), list):
            errors.append(f"painel {panel.get('id')} servicos nao-lista")
        if not isinstance(panel.get("personagens", []), list):
            errors.append(f"painel {panel.get('id')} personagens nao-lista")

    report = {
        "ok": not errors,
        "errors": errors,
        "warnings": sorted(set(warnings)),
        "counts": {
            "pages": len(pages),
            "municipal_anchors": len(anchors),
            "gameplay_nodes": len(nodes),
            "panels": len(panels),
            "routes": len(routes),
        },
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
