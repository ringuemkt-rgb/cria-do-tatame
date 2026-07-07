#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict


@dataclass
class RouteDecision:
    provider: str
    reason: str
    model: str


class SmartRouter:
    def route(self, task_type: str, payload: Dict[str, Any] | None = None) -> RouteDecision:
        payload = payload or {}
        task = task_type.lower().strip()
        if task in ["sprite", "spritesheet", "background", "ui", "image"]:
            return RouteDecision("huggingface", "geracao visual bruta", "nerijs/pixel-art-xl")
        if task in ["music", "sfx", "ambience"]:
            return RouteDecision("huggingface", "musica e SFX", "facebook/musicgen-small")
        if task in ["voice", "dialogue_voice", "cutscene_voice", "tts"]:
            return RouteDecision("fish_audio", "voz de personagem", "s2.1-pro-free")
        if task in ["prompt_qa", "asset_qa", "balance", "narrative_check"]:
            return RouteDecision("llm_qa", "QA textual e balanceamento", payload.get("model", "qa-text-model"))
        return RouteDecision("huggingface", "rota padrao", payload.get("model", "nerijs/pixel-art-xl"))


if __name__ == "__main__":
    router = SmartRouter()
    for item in ["sprite", "music", "voice", "asset_qa"]:
        decision = router.route(item)
        print(f"{item}: {decision.provider} | {decision.model}")
