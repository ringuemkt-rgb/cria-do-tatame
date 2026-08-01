from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def test_logo_contract_preserves_creator_approved_identity() -> None:
    contract = load("data/visual/brand_identity_v01.json")
    canon = contract["canonical_elements"]
    assert contract["approved_by_creator"] is True
    assert canon["mascot"] == "gorila Silverback adulto"
    assert canon["primary_wordmark"] == "CRIA DO TATAME"
    assert canon["palette"] == ["#000000", "#F2F2F2", "#B8860B", "#F2C230"]
    assert contract["canon_reconciliation"]["protagonist"] == "Ruan Macacão Silva"


def test_source_is_blocked_for_commercial_shipping_until_cleanup() -> None:
    legal = load("data/visual/brand_identity_v01.json")["legal_and_shipping"]
    assert legal["current_source_contains_third_party_mark"] is True
    assert legal["shipping_status"] == "legal_cleanup_required"
    assert legal["do_not_publish_commercially_before_cleanup"] is True


def test_validator_cli_passes() -> None:
    result = subprocess.run(
        [sys.executable, "tools/audit/validate_brand_identity_v01.py"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
