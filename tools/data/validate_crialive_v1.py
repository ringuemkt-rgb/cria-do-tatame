#!/usr/bin/env python3
"""Compatibility entry point; the social slice validator is authoritative."""
import runpy
from pathlib import Path
if __name__ == "__main__":
    runpy.run_path(str(Path(__file__).resolve().parents[1] / "social/validate_crialive_v1.py"), run_name="__main__")
