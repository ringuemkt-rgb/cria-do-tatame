#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = ROOT / "data/combat/bjj_completion_gate_v1.json"


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def count_collection(payload, *keys):
    for key in keys:
        value = payload.get(key)
        if isinstance(value, list):
            return len(value), value
    return 0, []


def build_report():
    contract = load(CONTRACT)
    full_path = ROOT / contract["authorities"]["full_graph"]
    report = {
        "status": "BLOCKED_ON_SOURCE",
        "full_graph_exists": full_path.exists(),
        "counts": {"positions": 0, "techniques": 0, "chains": 0},
        "blockers": [],
        "errors": [],
        "full_ready": False,
    }
    if not full_path.exists():
        report["blockers"].append({"code": "full_bjj_kg_missing", "path": str(full_path.relative_to(ROOT))})
        return report

    graph = load(full_path)
    p_count, _positions = count_collection(graph, "positions", "posicoes")
    t_count, techniques = count_collection(graph, "techniques", "tecnicas")
    c_count, chains = count_collection(graph, "chains", "cadeias")
    report["counts"] = {"positions": p_count, "techniques": t_count, "chains": c_count}

    minimum = contract["minimum_targets"]
    for key, actual in report["counts"].items():
        expected = int(minimum[key])
        if actual < expected:
            report["blockers"].append({"code": f"{key}_below_minimum", "actual": actual, "expected": expected})

    required = set(contract["required_technique_fields"])
    technique_ids = set()
    for index, tech in enumerate(techniques):
        if not isinstance(tech, dict):
            report["errors"].append({"code": "technique_not_object", "index": index})
            continue
        tech_id = str(tech.get("id", ""))
        if tech_id:
            if tech_id in technique_ids:
                report["errors"].append({"code": "duplicate_technique_id", "id": tech_id})
            technique_ids.add(tech_id)
        missing = sorted(field for field in required if field not in tech)
        if missing:
            report["errors"].append({"code": "technique_missing_fields", "id": tech_id or index, "fields": missing})
        prior = tech.get("authoring_prior")
        if not isinstance(prior, (int, float)) or not 0.0 <= float(prior) <= 1.0:
            report["errors"].append({"code": "invalid_authoring_prior", "id": tech_id or index})
        for relation in tech.get("counters", []):
            if not isinstance(relation, dict):
                report["errors"].append({"code": "counter_not_object", "id": tech_id or index})
                continue
            missing_counter = [k for k in contract["required_dimensions"]["counter"] if k not in relation]
            if missing_counter:
                report["errors"].append({"code": "counter_missing_semantics", "id": tech_id or index, "fields": missing_counter})

    for chain in chains:
        if not isinstance(chain, dict):
            report["errors"].append({"code": "chain_not_object"})
            continue
        steps = chain.get("steps", chain.get("technique_ids", []))
        if not isinstance(steps, list) or len(steps) < 2:
            report["errors"].append({"code": "chain_too_short", "id": chain.get("id")})
            continue
        unknown = [step for step in steps if isinstance(step, str) and step not in technique_ids]
        if unknown:
            report["errors"].append({"code": "chain_unknown_technique", "id": chain.get("id"), "unknown": unknown})

    if report["errors"]:
        report["status"] = "FAIL"
    elif report["blockers"]:
        report["status"] = "BLOCKED_ON_SOURCE"
    else:
        report["status"] = "READY_FOR_EXPERT_AND_CALIBRATION_REVIEW"
        report["full_ready"] = True
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--full", action="store_true")
    parser.add_argument("--report")
    args = parser.parse_args()
    report = build_report()
    text = json.dumps(report, ensure_ascii=False, indent=2)
    if args.report:
        Path(args.report).write_text(text + "\n", encoding="utf-8")
    print(text)
    if report["status"] == "FAIL":
        return 1
    if args.full and not report["full_ready"]:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
