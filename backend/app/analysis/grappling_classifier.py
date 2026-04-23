"""Classificador leve de ações de grappling (baseline de produção)."""


class GrapplingClassifier:
    taxonomy = {
        "takedown_attempt": "Tentativa de queda",
        "takedown_complete": "Queda executada",
        "guard_pull": "Puxada para guarda",
        "sweep_attempt": "Tentativa de raspagem",
        "sweep_success": "Raspagem finalizada",
        "guard_pass_attempt": "Tentativa de passagem",
        "guard_pass_complete": "Guarda passada",
        "mount_established": "Montada consolidada",
        "back_control": "Pegada nas costas",
        "submission_attempt": "Tentativa de finalização",
        "submission_defense": "Defesa de finalização",
        "stalling": "Evitação de combate",
        "illegal_grip": "Pegada irregular",
    }

    def classify_window(self, action_probs: dict[str, float]) -> dict[str, str | float]:
        """Mapeia distribuição de probabilidades para melhor ação técnica."""

        if not action_probs:
            return {"codigo": "unknown", "rotulo": "Sem evento", "confianca": 0.0}

        codigo = max(action_probs, key=action_probs.get)
        return {
            "codigo": codigo,
            "rotulo": self.taxonomy.get(codigo, "Evento desconhecido"),
            "confianca": float(action_probs[codigo]),
        }
