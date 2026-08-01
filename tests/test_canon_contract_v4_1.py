from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "tools" / "audit" / "validate_canon_contract_v4_1.py"

spec = importlib.util.spec_from_file_location("validate_canon_contract_v4_1", VALIDATOR)
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def test_contract_structure() -> None:
    module.validate_contract()


def test_d10_is_display_only_in_legacy_catalog() -> None:
    module.validate_legacy_catalog_display_only()


def test_decisions_are_linked_from_authority_documents() -> None:
    module.validate_document_authority()


def test_runtime_authorities_remain_unchanged() -> None:
    module.validate_runtime_untouched_contract()
