#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

ARQUIVOS_OBRIGATORIOS = [
    "project.godot",
    "data/characters.json",
    "data/arenas.json",
    "data/techniques.json",
    "data/combat_deck_schema.json",
    "data/ruan_deck_inicial.json",
    "data/gameplay/complete_game_flow_v01.json",
    "data/story/campaign_cinematics_v01.json",
    "data/ai/rival_ai_profiles_v01.json",
    "src/autoloads/SignalBus.gd",
    "src/autoloads/DataRegistry.gd",
    "src/autoloads/DeckManager.gd",
    "src/autoloads/WorldState.gd",
    "src/autoloads/SaveManager.gd",
    "src/autoloads/CombatManager.gd",
    "src/combat/CombatStateMachine.gd",
    "src/combat/TechniqueResolver.gd",
    "src/combat/TechniqueClashResolver.gd",
    "src/combat/FrameDataSystem.gd",
    "scenes/main_menu/MainMenu.tscn",
    "scenes/hubs/TerreiroDaLuta.tscn",
    "scenes/combat/CombatArenaBase.tscn",
    "scenes/ui/CombatHUD.tscn",
    "scenes/ui/CombatDeckHUD.tscn",
    "scenes/ui/DeckBuilder.tscn",
    "tools/generate_all_assets.py",
    "tools/cria_forge.py",
    "tools/integrate_assets_godot.py",
]

AUTOLOADS = ["SignalBus", "DataRegistry", "DeckManager", "WorldState", "SaveManager", "CombatManager", "GameFlowManager", "CutsceneRuntime"]
ESTADOS_OBRIGATORIOS = [
    "PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_CLINCH", "PLAYER_BOTTOM_CLINCH", "PLAYER_TOP_GUARD", "PLAYER_BOTTOM_GUARD",
    "PLAYER_TOP_SIDE", "PLAYER_BOTTOM_SIDE", "PLAYER_TOP_MOUNT", "PLAYER_BOTTOM_MOUNT", "PLAYER_BACK_ATTACK",
    "PLAYER_BACK_DEFENSE", "PLAYER_SUBMISSION_ATTACK", "PLAYER_SUBMISSION_DEFENSE", "RESET"
]


def ler_json(rel: str):
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


def main() -> int:
    erros: list[str] = []
    avisos: list[str] = []

    for rel in ARQUIVOS_OBRIGATORIOS:
        if not (ROOT / rel).exists():
            erros.append(f"arquivo ausente: {rel}")

    project = (ROOT / "project.godot").read_text(encoding="utf-8") if (ROOT / "project.godot").exists() else ""
    for autoload in AUTOLOADS:
        if autoload not in project:
            erros.append(f"autoload nao registrado: {autoload}")

    chars_path = ROOT / "data/characters.json"
    if chars_path.exists():
        chars = ler_json("data/characters.json").get("characters", [])
        by_id = {item.get("id"): item for item in chars}
        ruan = by_id.get("ruan_macacao")
        if not ruan:
            erros.append("ruan_macacao ausente em characters.json")
        else:
            if ruan.get("canon") is not True:
                erros.append("ruan_macacao precisa ter canon=true")
            texto_ruan = json.dumps(ruan, ensure_ascii=False).lower()
            if "caio" in texto_ruan or "ravel" in texto_ruan:
                erros.append("termo legado proibido dentro do protagonista")

    tech_path = ROOT / "data/techniques.json"
    if tech_path.exists():
        techniques = ler_json("data/techniques.json").get("techniques", [])
        if len(techniques) < 10:
            avisos.append("catalogo de tecnicas tem menos de 10 tecnicas")
        for item in techniques:
            for campo in ["id", "entry_state", "exit_state", "gas_cost", "base_chance"]:
                if campo not in item:
                    erros.append(f"tecnica {item.get('id', 'sem_id')} sem {campo}")
            if item.get("entry_state") not in ESTADOS_OBRIGATORIOS:
                erros.append(f"tecnica {item.get('id')} com entry_state invalido: {item.get('entry_state')}")

    sm_path = ROOT / "src/combat/CombatStateMachine.gd"
    if sm_path.exists():
        texto = sm_path.read_text(encoding="utf-8")
        for estado in ESTADOS_OBRIGATORIOS:
            if estado not in texto:
                erros.append(f"estado ausente na state machine: {estado}")

    scenes_path = ROOT / "data/story/campaign_cinematics_v01.json"
    if scenes_path.exists():
        cenas = ler_json("data/story/campaign_cinematics_v01.json").get("cutscenes", [])
        if len(cenas) < 5:
            avisos.append("menos de 5 cenas cinematograficas cadastradas")

    report = {"ok": len(erros) == 0, "erros": erros, "avisos": avisos}
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not erros else 1


if __name__ == "__main__":
    sys.exit(main())
