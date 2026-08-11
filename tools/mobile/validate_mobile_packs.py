#!/usr/bin/env python3
"""Offline structural gate for the mobile asset-pack subsystem."""

from __future__ import annotations

import ast
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "data" / "mobile" / "asset_packs_v1.json"
RUNTIME = ROOT / "data" / "mobile" / "packs_runtime.json"
BUILDER = ROOT / "tools" / "mobile" / "pack_builder.py"
LOADER = ROOT / "src" / "mobile" / "PackLoader.gd"


def main() -> int:
    errors: list[str] = []
    try:
        config = json.loads(CONFIG.read_text(encoding="utf-8"))
        runtime = json.loads(RUNTIME.read_text(encoding="utf-8"))
        ast.parse(BUILDER.read_text(encoding="utf-8"), filename=str(BUILDER))
        loader = LOADER.read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError, SyntaxError) as exc:
        errors.append(str(exc))
        config, runtime, loader = {}, {}, ""
    packs = config.get("packs", []) if isinstance(config, dict) else []
    ids = [entry.get("id") for entry in packs if isinstance(entry, dict)]
    expected = {
        "base", "personagens_lem", "personagens_ntm", "personagens_ale",
        "arenas_pratigi", "arenas_dique", "arenas_lapa", "arenas_terreiro_mapa",
        "tecnicas_quedas_raspagens", "tecnicas_passagens_transicoes",
        "tecnicas_finalizacoes_escapes", "audio_sfx", "audio_vozes", "audio_musica",
        "crialive_mapa_ui",
    }
    if set(ids) != expected or len(ids) != len(expected):
        errors.append("asset pack catalog must contain the 15 canonical unique packs")
    if config.get("base_max_mb") != 100 or config.get("pack_max_mb") != 50:
        errors.append("mobile pack budgets must be base=100 MB and optional=50 MB")
    by_id = {entry.get("id"): entry for entry in packs if isinstance(entry, dict)}
    if by_id.get("base", {}).get("obrigatorio") is not True:
        errors.append("base pack must be mandatory")
    for pack_id, entry in by_id.items():
        if pack_id != "base" and entry.get("deps") != ["base"]:
            errors.append(f"{pack_id} must depend on base")
        if not entry.get("selectors"):
            errors.append(f"{pack_id} has no deterministic selectors")
    if runtime.get("status") not in {"not_built", "built_not_published", "published"}:
        errors.append("packs_runtime has an invalid lifecycle status")
    required_loader_fragments = [
        "FileAccess.get_sha256", "ZIPReader.new", "zip_path_traversal",
        "HTTPRequest.RESULT_SUCCESS", "RELEASE_PREFIX", ".installed.json",
    ]
    for fragment in required_loader_fragments:
        if fragment not in loader:
            errors.append(f"PackLoader is missing safety integration: {fragment}")
    if "permissions/internet=true" not in (ROOT / "export_presets.cfg").read_text(encoding="utf-8"):
        errors.append("Android export does not enable INTERNET permission")
    shell = ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "configure_dvc_drive.sh"
    parsed_shell = subprocess.run(["bash", "-n", str(shell)], check=False, capture_output=True, text=True)
    if parsed_shell.returncode != 0:
        errors.append(f"DVC config shell parse failed: {parsed_shell.stderr.strip()}")
    print(json.dumps({"ok": not errors, "errors": errors, "packs": len(ids)}, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
