"""Configuração de logs estruturados em JSON."""

import logging
import sys

from pythonjsonlogger.json import JsonFormatter


def configure_logging() -> None:
    """Configura logger raiz em formato JSON para observabilidade."""

    handler = logging.StreamHandler(sys.stdout)
    formatter = JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s",
        rename_fields={"asctime": "timestamp", "levelname": "level"},
    )
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(handler)
    root_logger.setLevel(logging.INFO)
