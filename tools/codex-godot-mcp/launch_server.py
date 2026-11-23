#!/usr/bin/env python3
"""Codex MCP stdio launcher. Do not print status to stdout."""
from __future__ import annotations
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
BIN = HERE / ".local" / "bin" / ("open-godot-mcp-server.exe" if os.name == "nt" else "open-godot-mcp-server")


def run() -> int:
    if not (ROOT / "project.godot").is_file():
        print("CRIA MCP: project.godot missing", file=sys.stderr)
        return 2
    if not BIN.is_file():
        print("CRIA MCP: local server missing. Run install.py --install", file=sys.stderr)
        return 2
    if os.name != "nt" and not os.access(BIN, os.X_OK):
        print("CRIA MCP: binary is not executable", file=sys.stderr)
        return 2
    os.chdir(ROOT)
    os.execv(str(BIN), [str(BIN), "--godot-port", "6505"])
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
