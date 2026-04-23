"""Motor unificado de pontuação para modalidade de grappling."""

from collections import defaultdict

from app.analysis.rules.bjj_rules_engine import BJJRulesEngine
from app.schemas.analysis import GrapplingAction


class ScoringEngine:
    def __init__(self, modalidade: str):
        if modalidade not in {"bjj_gi", "bjj_nogi"}:
            raise ValueError("Modalidade ainda não suportada no scoring_engine atual")
        self.modalidade = modalidade
        self.rules = BJJRulesEngine("gi" if modalidade == "bjj_gi" else "nogi")
        self.placar = defaultdict(int)
        self.vantagens = defaultdict(int)
        self.penalidades = defaultdict(int)

    def process_event(self, action: GrapplingAction) -> None:
        resultado = self.rules.validate_action(action)
        atleta = action.atleta

        if resultado["penalty"]:
            self.penalidades[atleta] += 1
            return

        if resultado["valid"] and int(resultado["points"]) > 0:
            self.placar[atleta] += int(resultado["points"])

        if bool(resultado["advantage"]):
            self.vantagens[atleta] += 1

    def snapshot(self) -> dict[str, dict[str, int]]:
        return {
            "placar": {"azul": self.placar["azul"], "branco": self.placar["branco"]},
            "vantagens": {"azul": self.vantagens["azul"], "branco": self.vantagens["branco"]},
            "penalidades": {"azul": self.penalidades["azul"], "branco": self.penalidades["branco"]},
        }
