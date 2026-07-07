#!/usr/bin/env python3
from __future__ import annotations

import os
import sys

ENV_NAME = "HF_TOKEN"


def main() -> int:
    value = os.environ.get(ENV_NAME)
    if not value:
        print("Variavel HF_TOKEN nao encontrada no ambiente local.")
        return 1
    print("Credencial local detectada. Nenhum valor sensivel foi exibido.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
