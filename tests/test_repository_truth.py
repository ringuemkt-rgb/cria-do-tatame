from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "data/production/supreme_build_contract_v01.json"
GATE_STATUS_PATH = ROOT / "data/production/release_gate_status_v01.json"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_every_json_file_is_parseable() -> None:
    paths = sorted((ROOT / "data").rglob("*.json"))
    assert paths
    for path in paths:
        load(path)


def test_release_ledger_covers_the_contract_exactly() -> None:
    contract = load(CONTRACT_PATH)
    ledger = load(GATE_STATUS_PATH)
    assert set(ledger["gates"]) == set(contract["release_gates"])


def test_passed_release_gate_requires_traceable_evidence() -> None:
    ledger = load(GATE_STATUS_PATH)
    allowed = set(ledger["policy"]["status_values"])
    for gate_id, gate in ledger["gates"].items():
        assert gate["status"] in allowed, gate_id
        if gate["status"] == "passed":
            evidence = gate.get("evidence")
            assert isinstance(evidence, dict), gate_id
            assert evidence.get("commit_sha"), gate_id
            assert evidence.get("checked_at"), gate_id
            assert evidence.get("url") or evidence.get("artifact"), gate_id
