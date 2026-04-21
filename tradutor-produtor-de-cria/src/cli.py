from __future__ import annotations

import argparse
from pathlib import Path


def doctor() -> int:
    root = Path(__file__).resolve().parents[1]
    required = [
        root / "config/branding/boxedecria_config.yaml",
        root / "config/neuromarketing/jung_archetypes.yaml",
        root / "config/instagram/algorithm_secrets.json",
    ]
    missing = [str(p.relative_to(root)) for p in required if not p.exists()]
    if missing:
        print("Missing required files:")
        for item in missing:
            print(f"- {item}")
        return 1
    print("System scaffold OK.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Tradutor e Produtor de Cria")
    parser.add_argument("command", choices=["doctor"], help="Command to execute")
    args = parser.parse_args()

    if args.command == "doctor":
        return doctor()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
