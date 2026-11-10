"""Safe repository contract checks; does not create any images."""
from __future__ import annotations
import importlib.util
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("cria_quality_gate", HERE / "scripts/quality_gate.py")
assert spec is not None and spec.loader is not None
quality = importlib.util.module_from_spec(spec)
spec.loader.exec_module(quality)


class GoldSliceContractTests(unittest.TestCase):
    def test_canonical_transitions(self):
        errors = []
        quality.check_catalog(quality.ROOT, errors)
        self.assertFalse(errors, "\n".join(errors))

    def test_style_lock(self):
        errors = []
        quality.check_style(quality.ROOT, errors)
        self.assertFalse(errors, "\n".join(errors))

    def test_no_duplicate_runtime(self):
        errors = []
        quality.check_no_runtime_duplication(errors)
        self.assertFalse(errors, "\n".join(errors))

    def test_shipping_guard(self):
        errors = []
        quality.require_false({"shipping": True, "qa_status": "pending"}, HERE, errors)
        self.assertTrue(errors)


if __name__ == "__main__":
    unittest.main()
