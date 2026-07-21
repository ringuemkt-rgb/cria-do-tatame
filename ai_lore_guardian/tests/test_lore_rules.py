from __future__ import annotations

import unittest

from ai_lore_guardian.lore_rules import CanonIndex, CanonValidator
from ai_lore_guardian.schemas import CharacterSchema, MissionSchema, TechniqueSchema
from ai_lore_guardian.settings import load_settings


class CanonValidatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        settings = load_settings()
        cls.index = CanonIndex.load()
        cls.validator = CanonValidator(cls.index, settings["validation"])

    def test_canon_index_loads_primary_collections(self) -> None:
        self.assertIn("ruan_macacao", self.index.characters)
        self.assertIn("terreiro_da_luta", self.index.arenas)
        self.assertIn("grip_de_ferro", self.index.techniques)
        self.assertIn("terreiro", self.index.factions)
        self.assertEqual(20, len(self.index.fingerprint))

    def test_ruan_requires_exact_silverback_symbol(self) -> None:
        model = CharacterSchema(
            id="ruan_macacao",
            name='Ruan "Macacão" Silva',
            role="protagonist",
            origin="Ituberá, Baixo Sul da Bahia",
            region="Baixo Sul da Bahia",
            style="pressao_pesada_top_game",
            symbol="Outro símbolo",
            narrative_function="Protagonista central da campanha e protetor de sua comunidade.",
        )
        errors, _ = self.validator.validate(model)
        self.assertIn("protagonist_symbol_conflict", {error.code for error in errors})

    def test_unknown_technique_is_blocked(self) -> None:
        model = TechniqueSchema(
            id="golpe_inventado",
            name="Golpe Inventado",
            category="transicao",
            entry_state="PLAYER_STANDING_NEUTRAL",
            exit_state="PLAYER_TOP_GUARD",
            mechanic_summary="Transição abstrata representada somente como mecânica segura de jogo.",
            risk="baixo",
            gamified=True,
        )
        errors, _ = self.validator.validate(model)
        self.assertIn("unknown_technique", {error.code for error in errors})

    def test_valid_mission_references_pass(self) -> None:
        model = MissionSchema.model_validate(
            {
                "id": "candidate_sparring_davi",
                "title": "Leitura no Terreiro",
                "act": 1,
                "difficulty": 2,
                "region": "Ituberá, Baixo Sul da Bahia",
                "arena_id": "terreiro_da_luta",
                "faction_id": "terreiro",
                "opponent_id": "davi_relampago",
                "summary": "Ruan testa disciplina e leitura de ritmo em um sparring seguro no Terreiro.",
                "objectives": ["Concluir a disputa respeitando o tap e a arbitragem"],
                "technique_ids": ["grip_de_ferro", "sprawl"],
                "requirements": ["act1_primeiro_treino"],
                "rewards": {"xp": 50, "honra": 1},
                "moral_consequence": {
                    "dilemma": "Buscar aplausos rápidos ou preservar o aprendizado coletivo do treino.",
                    "axis": ["honra", "hype"],
                    "on_accept": "Ruan prioriza a equipe e recebe confiança do Terreiro.",
                    "on_refuse": "Ruan busca exposição e perde parte da confiança do grupo.",
                },
            }
        )
        errors, _ = self.validator.validate(model)
        self.assertEqual([], errors)

    def test_external_mission_requires_justification(self) -> None:
        model = MissionSchema.model_validate(
            {
                "id": "candidate_salvador",
                "title": "Circuito em Salvador",
                "act": 2,
                "difficulty": 4,
                "region": "Salvador - Bahia",
                "arena_id": "arena_do_dique",
                "faction_id": "circuito_oficial",
                "opponent_id": "davi_relampago",
                "summary": "Ruan enfrenta o peso do circuito oficial mantendo o vínculo com sua origem.",
                "objectives": ["Concluir a luta oficial com disciplina"],
                "technique_ids": ["sprawl"],
                "rewards": {"xp": 100, "legado": 1},
                "moral_consequence": {
                    "dilemma": "Aceitar a pressão do espetáculo ou defender os valores do Terreiro.",
                    "axis": ["legado", "honra"],
                    "on_accept": "Ruan ganha espaço no circuito sem romper com sua equipe.",
                    "on_refuse": "Ruan preserva a autonomia, mas perde visibilidade institucional.",
                },
            }
        )
        errors, _ = self.validator.validate(model)
        self.assertIn("missing_region_justification", {error.code for error in errors})


if __name__ == "__main__":
    unittest.main()
