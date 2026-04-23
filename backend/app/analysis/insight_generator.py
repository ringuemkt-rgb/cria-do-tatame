"""Geração de insights técnicos em pt-BR."""

from app.schemas.analysis import FightEvent, MatchContext


class TechnicalInsightEngine:
    templates = {
        "guard_pass_complete": [
            "✅ Passagem de guarda técnica com controle de quadril e cabeça alinhada.",
            "🔍 Boa progressão: pressão alta + quebra de postura antes da passagem.",
            "⚠️ Atenção: braço exposto durante a passagem. Risco de triângulo.",
        ],
        "sweep_success": [
            "✅ Raspagem executada com timing excelente e transferência de peso limpa.",
            "🔍 Excelente alavanca: ombro no solo + quadril elevado.",
            "⚠️ Base estreita no final da raspagem. Possível contra-raspagem.",
        ],
        "submission_attempt": [
            "🔍 Finalização bem montada: isolamento de membro + controle de postura.",
            "⚠️ Falta de pressão contínua. Defesa adversária recuperando espaço.",
            "✅ Sequência de transição impecável: guarda → costas → mata-leão.",
        ],
    }

    def generate(self, event: FightEvent, context: MatchContext) -> str:
        opcoes = self.templates.get(event.tipo, ["🔍 Evento técnico detectado."])

        indice = 0
        if event.confianca < 0.6 and len(opcoes) > 1:
            indice = 1
        if event.biomecanica_flags and len(opcoes) > 2:
            indice = 2

        base_msg = opcoes[indice]

        if event.biomecanica_flags:
            alertas = ", ".join(event.biomecanica_flags)
            base_msg += f" | 🦴 Ajustes biomecânicos: {alertas}."

        if context.modalidade in {"bjj_gi", "bjj_nogi"}:
            base_msg += " (Referência CBJJ/IBJJF)"

        return base_msg
