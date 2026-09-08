from __future__ import annotations

import copy
import json
import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools" / "data"
sys.path.insert(0, str(TOOLS))

import validate_bjj_kg_authoring_contract as validator  # noqa: E402


class BJJAuthoringContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads((ROOT / "data/combat/bjj_kg_authoring_contract_v1.json").read_text(encoding="utf-8"))
        cls.rules = json.loads((ROOT / "data/combat/bjj_rulesets_verified_v1.json").read_text(encoding="utf-8"))

    def test_current_contract_passes(self) -> None:
        self.assertEqual(validator.validate(self.contract, self.rules), [])

    def test_rejects_wrong_adcc_mount_and_back_scores(self) -> None:
        rules = copy.deepcopy(self.rules)
        rules["rulesets"]["adcc_championship_current"]["points"]["mount"] = 4
        rules["rulesets"]["adcc_championship_current"]["points"]["back_mount_hooks_or_body_triangle"] = 4
        errors = validator.validate(self.contract, rules)
        self.assertTrue(any("ADCC mount must be 2" in item for item in errors))
        self.assertTrue(any("ADCC back_mount_hooks_or_body_triangle must be 3" in item for item in errors))

    def test_rejects_empirical_claim_before_f3(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["success_model"]["empirical_success_default"] = 0.55
        errors = validator.validate(contract, self.rules)
        self.assertTrue(any("empirical_success must default to null" in item for item in errors))

    def test_rejects_runtime_authority_in_f1(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["runtime_authority"] = True
        errors = validator.validate(contract, self.rules)
        self.assertTrue(any("cannot have runtime authority" in item for item in errors))

    def test_rejects_gi_nogi_as_complete_legality_model(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["legality_model"]["gi_nogi_flags_are_sufficient"] = True
        errors = validator.validate(contract, self.rules)
        self.assertTrue(any("gi/nogi flags alone are insufficient" in item for item in errors))

    def test_rejects_clandestine_striking_authority(self) -> None:
        rules = copy.deepcopy(self.rules)
        rules["rulesets"]["clandestine_cria_v1"]["striking_or_ko_runtime_authority"] = True
        errors = validator.validate(self.contract, rules)
        self.assertTrue(any("striking/KO cannot gain runtime authority" in item for item in errors))


if __name__ == "__main__":
    unittest.main()
