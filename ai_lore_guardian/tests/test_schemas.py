from __future__ import annotations

import unittest

from pydantic import ValidationError

from ai_lore_guardian.schemas import MissionSchema, ValidateRequest


class SchemaTests(unittest.TestCase):
    def test_unknown_envelope_field_is_rejected(self) -> None:
        with self.assertRaises(ValidationError):
            ValidateRequest.model_validate(
                {
                    "content_type": "mission",
                    "payload": {},
                    "strict_mode": True,
                    "invented_switch": True,
                }
            )

    def test_mission_without_moral_consequence_is_rejected(self) -> None:
        with self.assertRaises(ValidationError):
            MissionSchema.model_validate(
                {
                    "id": "mission_without_choice",
                    "title": "Missão sem escolha",
                    "act": 1,
                    "difficulty": 1,
                    "region": "Baixo Sul da Bahia",
                    "arena_id": "terreiro_da_luta",
                    "faction_id": "terreiro",
                    "opponent_id": "davi_relampago",
                    "summary": "Uma missão deliberadamente incompleta para comprovar o bloqueio do schema.",
                    "objectives": ["Treinar"],
                    "rewards": {"xp": 1},
                }
            )


if __name__ == "__main__":
    unittest.main()
