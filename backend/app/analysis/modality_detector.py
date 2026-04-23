"""Detector leve de modalidade com heurísticas dos primeiros segundos."""

from app.schemas.analysis import ModalityResult


class ModalityDetector:
    """Combina sinais visuais/temporais para inferir modalidade rapidamente."""

    def detect_from_signals(self, sinais: dict[str, float]) -> ModalityResult:
        """Detecta modalidade usando sinais sintéticos para etapa inicial da API."""

        gi = sinais.get("gi", 0.0)
        rashguard = sinais.get("rashguard", 0.0)
        ground = sinais.get("ground_time_ratio", 0.0)
        strikes = sinais.get("strikes_detected", 0.0)
        cage = sinais.get("cage", 0.0)

        if gi > 0.7 and ground > 0.6:
            return ModalityResult(modality="bjj_gi", confidence=0.92)
        if rashguard > 0.7 and ground > 0.5:
            return ModalityResult(modality="bjj_nogi", confidence=0.89)
        if strikes > 5 and ground < 0.3:
            return ModalityResult(modality="mma" if cage > 0.5 else "boxe", confidence=0.95)

        return ModalityResult(modality="unknown", confidence=0.0, requires_manual=True)
