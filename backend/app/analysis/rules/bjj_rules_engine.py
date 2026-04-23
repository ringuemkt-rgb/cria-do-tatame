"""Motor de regras BJJ (IBJJF/ADCC simplificado para etapa atual)."""

from typing import Literal

from app.schemas.analysis import GrapplingAction


class BJJRulesEngine:
    def __init__(self, modality: Literal["gi", "nogi"]):
        self.modality = modality
        self.points_config = self._load_config()

    def _load_config(self) -> dict[str, int]:
        return {
            "takedown": 2,
            "sweep": 2,
            "guard_pass": 3,
            "knee_on_belly": 2,
            "mount": 4,
            "back_control": 4,
        }

    def validate_action(self, action: GrapplingAction) -> dict[str, str | bool | int | None]:
        """Valida se ação gera ponto/vantagem/penalidade."""

        if action.acao == "illegal_grip" and self.modality == "nogi":
            return {"valid": False, "points": 0, "advantage": False, "penalty": "pegada irregular"}

        if action.acao == "stalling":
            return {"valid": False, "points": 0, "advantage": False, "penalty": "evitação de combate"}

        points = self.points_config.get(action.acao, 0)
        advantage = self.calculate_advantage(action.acao, action.duracao_ms)
        return {"valid": True, "points": points, "advantage": advantage, "penalty": None}

    @staticmethod
    def calculate_advantage(action: str, duration_ms: int) -> bool:
        return duration_ms >= 3000 and action in {"near_pass", "near_back", "near_mount"}
