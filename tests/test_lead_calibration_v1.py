from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "tools" / "audit" / "validate_lead_calibration_v1.py"

spec = importlib.util.spec_from_file_location("validate_lead_calibration_v1", VALIDATOR)
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class LeadCalibrationTests(unittest.TestCase):
    def test_governance_and_human_signature_boundary(self) -> None:
        module.validate_governance()

    def test_canon_is_machine_readable(self) -> None:
        module.validate_canon_data()
        module.validate_factions_and_ui()

    def test_endings_have_one_data_driven_calculator(self) -> None:
        module.validate_endings_are_data_driven()

    def test_hygiene_and_tooling_contracts(self) -> None:
        module.validate_hygiene_and_tools()
