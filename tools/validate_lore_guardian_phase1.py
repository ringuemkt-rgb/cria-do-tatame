#!/usr/bin/env python3
"""Gate leve da Fase 1; não baixa nem carrega modelos de IA."""

from __future__ import annotations

import compileall
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "ai_lore_guardian"
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


def main() -> int:
    errors: list[str] = []
    required = [
        PACKAGE / "config.yaml",
        PACKAGE / "requirements.txt",
        PACKAGE / "schemas.py",
        PACKAGE / "lore_guardian_server.py",
        PACKAGE / "lore_rules.py",
        PACKAGE / "rag_service.py",
    ]
    errors.extend(f"arquivo obrigatório ausente: {path.relative_to(ROOT)}" for path in required if not path.is_file())

    if not compileall.compile_dir(str(PACKAGE), quiet=1, force=True):
        errors.append("falha de compilação Python em ai_lore_guardian/")

    try:
        from ai_lore_guardian.lore_rules import CanonIndex
        from ai_lore_guardian.settings import load_settings

        settings = load_settings()
        index = CanonIndex.load()
        expected_models = {
            "Qwen/Qwen3-4B-GGUF",
            "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF",
            "BAAI/bge-m3",
            "BAAI/bge-reranker-v2-m3",
        }
        configured_models = {
            settings["models"]["llm"]["repository"],
            settings["models"]["code_llm"]["repository"],
            settings["models"]["embeddings"]["repository"],
            settings["models"]["reranker"]["repository"],
        }
        if configured_models != expected_models:
            errors.append("stack de modelos diverge da Ordem de Serviço")
        if not settings["validation"].get("strict_mode") or not settings["validation"].get("fail_closed"):
            errors.append("strict_mode e fail_closed precisam permanecer ativos")
        if index.characters.get("ruan_macacao", {}).get("symbol") != "Gorila Silverback":
            errors.append("símbolo canônico de Ruan diverge de Gorila Silverback")
    except Exception as exc:
        errors.append(f"falha ao carregar configuração/cânone: {type(exc).__name__}: {exc}")

    result = {
        "ok": not errors,
        "errors": errors,
        "phase": 1,
        "package": "ai_lore_guardian",
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
