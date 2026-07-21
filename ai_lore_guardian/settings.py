"""Carregamento centralizado e seguro das configurações YAML."""

from __future__ import annotations

import os
from copy import deepcopy
from pathlib import Path
from typing import Any

import yaml


PACKAGE_ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = PACKAGE_ROOT.parent
DEFAULT_CONFIG_PATH = PACKAGE_ROOT / "config.yaml"


class ConfigurationError(RuntimeError):
    """Indica configuração ausente, insegura ou estruturalmente inválida."""


def _require_mapping(value: Any, key: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ConfigurationError(f"A seção '{key}' precisa ser um objeto YAML.")
    return value


def load_settings(path: Path | None = None) -> dict[str, Any]:
    """Carrega YAML e aplica somente overrides ambientais documentados."""

    config_path = (path or DEFAULT_CONFIG_PATH).resolve()
    try:
        raw = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as exc:
        raise ConfigurationError(f"Não foi possível carregar {config_path}: {exc}") from exc
    config = deepcopy(_require_mapping(raw, "root"))
    for section in ("server", "validation", "models", "rag", "security"):
        _require_mapping(config.get(section), section)

    server = config["server"]
    models = config["models"]
    rag = config["rag"]
    server["host"] = os.getenv("CRIA_LORE_HOST", str(server["host"]))
    server["port"] = int(os.getenv("CRIA_LORE_PORT", str(server["port"])))
    models["allow_downloads"] = os.getenv(
        "CRIA_ALLOW_MODEL_DOWNLOADS", str(models.get("allow_downloads", False))
    ).lower() in {"1", "true", "yes", "sim"}
    models["llm"]["runtime_model"] = os.getenv(
        "CRIA_LLM_MODEL", str(models["llm"]["runtime_model"])
    )
    models["llm"]["base_url"] = os.getenv(
        "CRIA_OLLAMA_URL", str(models["llm"]["base_url"])
    ).rstrip("/")

    for path_key in ("persist_directory", "lexical_index_path"):
        candidate = Path(str(rag[path_key]))
        rag[path_key] = str((PROJECT_ROOT / candidate).resolve()) if not candidate.is_absolute() else str(candidate.resolve())

    if not bool(config["security"].get("allow_remote", False)) and server["host"] not in {
        "127.0.0.1",
        "localhost",
        "::1",
    }:
        raise ConfigurationError("security.allow_remote=false exige bind em loopback.")
    return config
