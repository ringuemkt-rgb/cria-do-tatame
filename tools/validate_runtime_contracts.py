#!/usr/bin/env python3
"""Static runtime audit for Cria do Tatame.

The validator intentionally uses only Python's standard library so it can run
locally and in GitHub Actions before Godot is installed.
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "runtime_audit"

REQUIRED_SCENES = {
    "main_menu": "scenes/main_menu/MainMenu.tscn",
    "hub": "scenes/hubs/TerreiroDaLuta.tscn",
    "combat": "scenes/combat/CombatArenaBase.tscn",
    "result": "scenes/result/ResultScreen.tscn",
    "cria_live": "scenes/ui/CriaLiveUI.tscn",
}

REQUIRED_AUTOLOADS = {
    "SignalBus": "src/autoloads/SignalBus.gd",
    "DataRegistry": "src/autoloads/DataRegistry.gd",
    "WorldState": "src/autoloads/WorldState.gd",
    "SaveManager": "src/autoloads/SaveManager.gd",
    "CombatManager": "src/autoloads/CombatManager.gd",
    "CareerLoop": "src/autoloads/CareerLoop.gd",
    "GameFlowManager": "src/autoloads/GameFlowManager.gd",
    "AudioManager": "src/autoloads/AudioManager.gd",
}

VALID_STATES = {
    "PLAYER_STANDING_NEUTRAL",
    "PLAYER_TOP_CLINCH",
    "PLAYER_BOTTOM_CLINCH",
    "PLAYER_TOP_GUARD",
    "PLAYER_BOTTOM_GUARD",
    "PLAYER_TOP_SIDE",
    "PLAYER_BOTTOM_SIDE",
    "PLAYER_TOP_MOUNT",
    "PLAYER_BOTTOM_MOUNT",
    "PLAYER_BACK_ATTACK",
    "PLAYER_BACK_DEFENSE",
    "PLAYER_SUBMISSION_ATTACK",
    "PLAYER_SUBMISSION_DEFENSE",
    "RESET",
}

VALID_TRANSITIONS = {
    "PLAYER_STANDING_NEUTRAL": {"PLAYER_TOP_CLINCH", "PLAYER_BOTTOM_CLINCH", "PLAYER_TOP_GUARD", "PLAYER_BOTTOM_GUARD", "RESET", "PLAYER_STANDING_NEUTRAL"},
    "PLAYER_TOP_CLINCH": {"PLAYER_STANDING_NEUTRAL", "PLAYER_TOP_GUARD", "PLAYER_TOP_SIDE", "PLAYER_BACK_ATTACK", "RESET", "PLAYER_TOP_CLINCH"},
    "PLAYER_BOTTOM_CLINCH": {"PLAYER_STANDING_NEUTRAL", "PLAYER_BOTTOM_GUARD", "PLAYER_BOTTOM_SIDE", "PLAYER_BACK_DEFENSE", "RESET", "PLAYER_BOTTOM_CLINCH"},
    "PLAYER_TOP_GUARD": {"PLAYER_TOP_SIDE", "PLAYER_TOP_MOUNT", "PLAYER_BOTTOM_GUARD", "PLAYER_STANDING_NEUTRAL", "RESET", "PLAYER_TOP_GUARD"},
    "PLAYER_BOTTOM_GUARD": {"PLAYER_TOP_GUARD", "PLAYER_BOTTOM_SIDE", "PLAYER_SUBMISSION_ATTACK", "PLAYER_STANDING_NEUTRAL", "RESET", "PLAYER_BOTTOM_GUARD"},
    "PLAYER_TOP_SIDE": {"PLAYER_TOP_MOUNT", "PLAYER_BACK_ATTACK", "PLAYER_TOP_GUARD", "PLAYER_SUBMISSION_ATTACK", "RESET", "PLAYER_TOP_SIDE"},
    "PLAYER_BOTTOM_SIDE": {"PLAYER_BOTTOM_GUARD", "PLAYER_BOTTOM_MOUNT", "PLAYER_BACK_DEFENSE", "RESET", "PLAYER_BOTTOM_SIDE"},
    "PLAYER_TOP_MOUNT": {"PLAYER_BACK_ATTACK", "PLAYER_TOP_SIDE", "PLAYER_SUBMISSION_ATTACK", "RESET", "PLAYER_TOP_MOUNT"},
    "PLAYER_BOTTOM_MOUNT": {"PLAYER_BOTTOM_GUARD", "PLAYER_BOTTOM_SIDE", "PLAYER_SUBMISSION_DEFENSE", "RESET", "PLAYER_BOTTOM_MOUNT"},
    "PLAYER_BACK_ATTACK": {"PLAYER_SUBMISSION_ATTACK", "PLAYER_TOP_MOUNT", "PLAYER_TOP_SIDE", "RESET", "PLAYER_BACK_ATTACK"},
    "PLAYER_BACK_DEFENSE": {"PLAYER_BOTTOM_GUARD", "PLAYER_BOTTOM_SIDE", "PLAYER_SUBMISSION_DEFENSE", "RESET", "PLAYER_BACK_DEFENSE"},
    "PLAYER_SUBMISSION_ATTACK": {"RESET", "PLAYER_TOP_MOUNT", "PLAYER_TOP_SIDE", "PLAYER_BACK_ATTACK", "PLAYER_SUBMISSION_ATTACK"},
    "PLAYER_SUBMISSION_DEFENSE": {"RESET", "PLAYER_BOTTOM_GUARD", "PLAYER_BOTTOM_SIDE", "PLAYER_BACK_DEFENSE", "PLAYER_SUBMISSION_DEFENSE"},
    "RESET": {"PLAYER_STANDING_NEUTRAL", "RESET"},
}

SCENE_NODE_CONTRACTS = {
    "scenes/main_menu/MainMenu.tscn": [
        "ContentPanel/Content/MenuButtons/NewGame",
        "ContentPanel/Content/MenuButtons/Continue",
        "ContentPanel/Content/MenuButtons/Options",
        "ContentPanel/Content/OptionsPanel/AudioToggle",
        "ContentPanel/Content/OptionsPanel/Back",
    ],
    "scenes/hubs/TerreiroDaLuta.tscn": [
        "Panel/Status",
        "Panel/NextAction",
        "Panel/Message",
        "Panel/TrainBtn",
        "Panel/FightDaviBtn",
        "Panel/SaveBtn",
    ],
    "scenes/combat/CombatArenaBase.tscn": [
        "Panel/State",
        "Panel/Resources",
        "Panel/Message",
        "Panel/AIHint",
        "Panel/Buttons/Action1",
        "Panel/Buttons/Action5",
    ],
    "scenes/result/ResultScreen.tscn": [
        "Panel/Result",
        "Panel/Details",
        "Panel/Reward",
        "Panel/CriaLive",
        "Panel/BackToHub",
    ],
}

RES_PATH_RE = re.compile(r"res://[A-Za-z0-9_@./\-]+")
CLASS_NAME_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)
AUTOLOAD_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)="\*?res://([^"]+)"$', re.MULTILINE)
NODE_RE = re.compile(r'^\[node name="([^"]+)" type="[^"]+"(?: parent="([^"]*)")?[^\]]*\]$', re.MULTILINE)
SECRET_RE = re.compile(r"(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{20,}")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def load_json(path: Path) -> Any:
    return json.loads(read_text(path))


def scene_node_paths(text: str) -> set[str]:
    paths: set[str] = set()
    for name, parent in NODE_RE.findall(text):
        if parent in ("", "."):
            paths.add(name)
        else:
            paths.add(f"{parent}/{name}")
    return paths


def add(result: dict[str, list[str]], level: str, message: str) -> None:
    result[level].append(message)


def validate_json_files(result: dict[str, list[str]]) -> None:
    for path in sorted((ROOT / "data").rglob("*.json")):
        try:
            load_json(path)
        except Exception as exc:  # noqa: BLE001 - audit should report every parser error
            add(result, "errors", f"JSON invalido: {path.relative_to(ROOT)}: {exc}")


def validate_project(result: dict[str, list[str]]) -> dict[str, str]:
    project_path = ROOT / "project.godot"
    if not project_path.exists():
        add(result, "errors", "project.godot ausente")
        return {}
    text = read_text(project_path)
    if 'run/main_scene="res://scenes/main_menu/MainMenu.tscn"' not in text:
        add(result, "errors", "main scene nao aponta para MainMenu.tscn")
    autoloads = {name: path for name, path in AUTOLOAD_RE.findall(text)}
    for name, expected_path in REQUIRED_AUTOLOADS.items():
        actual = autoloads.get(name)
        if actual != expected_path:
            add(result, "errors", f"autoload {name}: esperado {expected_path}, encontrado {actual}")
        if not (ROOT / expected_path).exists():
            add(result, "errors", f"script de autoload ausente: {expected_path}")
    return autoloads


def validate_global_names(result: dict[str, list[str]], autoloads: dict[str, str]) -> None:
    names: dict[str, list[str]] = defaultdict(list)
    for path in sorted(ROOT.rglob("*.gd")):
        text = read_text(path)
        for name in CLASS_NAME_RE.findall(text):
            names[name].append(str(path.relative_to(ROOT)))
    for name, paths in sorted(names.items()):
        if len(paths) > 1:
            add(result, "errors", f"class_name duplicado {name}: {', '.join(paths)}")
        if name in autoloads:
            add(result, "errors", f"class_name {name} colide com autoload global: {', '.join(paths)}")


def validate_resources(result: dict[str, list[str]]) -> None:
    extensions = {".gd", ".tscn", ".tres", ".cfg", ".godot"}
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or path.suffix not in extensions:
            continue
        text = read_text(path)
        for raw in sorted(set(RES_PATH_RE.findall(text))):
            rel = raw.removeprefix("res://").rstrip(".,;:)")
            if not rel or "{" in rel:
                continue
            target = ROOT / rel
            if not target.exists():
                add(result, "errors", f"recurso referenciado nao existe: {path.relative_to(ROOT)} -> {raw}")


def validate_required_scenes(result: dict[str, list[str]]) -> None:
    for label, rel in REQUIRED_SCENES.items():
        if not (ROOT / rel).exists():
            add(result, "errors", f"cena obrigatoria ausente ({label}): {rel}")
    for rel, expected_nodes in SCENE_NODE_CONTRACTS.items():
        path = ROOT / rel
        if not path.exists():
            continue
        nodes = scene_node_paths(read_text(path))
        for node_path in expected_nodes:
            if node_path not in nodes:
                add(result, "errors", f"contrato de cena quebrado: {rel} sem node {node_path}")


def validate_canon(result: dict[str, list[str]]) -> None:
    path = ROOT / "data" / "characters.json"
    if not path.exists():
        add(result, "errors", "data/characters.json ausente")
        return
    data = load_json(path)
    characters = data.get("characters", [])
    by_id = {str(item.get("id", "")): item for item in characters if isinstance(item, dict)}
    ruan = by_id.get("ruan_macacao")
    if not ruan:
        add(result, "errors", "protagonista ruan_macacao ausente")
        return
    if ruan.get("canon") is not True:
        add(result, "errors", "ruan_macacao precisa ter canon=true")
    serialized = json.dumps(ruan, ensure_ascii=False).lower()
    for forbidden in ("caio ravel", '"caio"', '"ravel"'):
        if forbidden in serialized:
            add(result, "errors", f"termo legado proibido no protagonista: {forbidden}")


def validate_techniques(result: dict[str, list[str]]) -> None:
    path = ROOT / "data" / "techniques.json"
    if not path.exists():
        add(result, "errors", "data/techniques.json ausente")
        return
    data = load_json(path)
    techniques = data.get("techniques", [])
    if len(techniques) < 10:
        add(result, "warnings", "catalogo principal possui menos de 10 tecnicas")
    ids: set[str] = set()
    state_coverage: defaultdict[str, int] = defaultdict(int)
    for item in techniques:
        if not isinstance(item, dict):
            add(result, "errors", "entrada nao-dicionario em techniques.json")
            continue
        technique_id = str(item.get("id", ""))
        if not technique_id:
            add(result, "errors", "tecnica sem id")
            continue
        if technique_id in ids:
            add(result, "errors", f"id de tecnica duplicado: {technique_id}")
        ids.add(technique_id)
        for field in ("entry_state", "exit_state", "base_chance"):
            if field not in item:
                add(result, "errors", f"tecnica {technique_id} sem {field}")
        entry = str(item.get("entry_state", ""))
        exit_state = str(item.get("exit_state", ""))
        if entry not in VALID_STATES:
            add(result, "errors", f"tecnica {technique_id} com entry_state invalido: {entry}")
        else:
            state_coverage[entry] += 1
        if exit_state not in VALID_STATES:
            add(result, "errors", f"tecnica {technique_id} com exit_state invalido: {exit_state}")
        elif entry in VALID_TRANSITIONS and exit_state not in VALID_TRANSITIONS[entry]:
            add(result, "errors", f"transicao invalida em {technique_id}: {entry} -> {exit_state}")
        chance = item.get("base_chance")
        if not isinstance(chance, (int, float)) or not 0.0 <= float(chance) <= 1.0:
            add(result, "errors", f"tecnica {technique_id} com base_chance fora de 0..1")
        cost = item.get("cost", item.get("custo", {}))
        if not isinstance(cost, dict):
            add(result, "errors", f"tecnica {technique_id} com custo invalido")
        else:
            for resource in ("gas", "focus", "foco", "moral"):
                if resource in cost and float(cost[resource]) < 0:
                    add(result, "errors", f"tecnica {technique_id} possui custo negativo: {resource}")
    if state_coverage.get("PLAYER_STANDING_NEUTRAL", 0) == 0:
        add(result, "errors", "nenhuma tecnica disponivel no estado inicial")


def validate_scene_scripts(result: dict[str, list[str]]) -> None:
    contracts = {
        "scenes/main_menu/MainMenu.gd": ["_on_new_game_pressed", "_on_continue_pressed", "_on_options_pressed"],
        "scenes/hubs/TerreiroDaLuta.gd": ["_on_train", "_on_fight_davi", "_on_save"],
        "scenes/combat/CombatArenaBase.gd": ["_refresh_action_buttons", "_on_combat_finished"],
        "scenes/result/ResultScreen.gd": ["_on_cria_live_pressed", "_on_back_pressed"],
        "src/autoloads/CombatManager.gd": ["start_combat", "apply_player_action", "finish_combat", "get_available_techniques"],
        "src/autoloads/SaveManager.gd": ["save_game", "load_game", "has_save"],
    }
    for rel, methods in contracts.items():
        path = ROOT / rel
        if not path.exists():
            add(result, "errors", f"script obrigatorio ausente: {rel}")
            continue
        text = read_text(path)
        for method in methods:
            if not re.search(rf"^func\s+{re.escape(method)}\s*\(", text, re.MULTILINE):
                add(result, "errors", f"contrato de script quebrado: {rel} sem {method}()")


def validate_secrets(result: dict[str, list[str]]) -> None:
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in {".gd", ".py", ".json", ".yml", ".yaml", ".cfg", ".md"}:
            continue
        if any(part in {".git", ".godot"} for part in path.parts):
            continue
        text = read_text(path)
        if SECRET_RE.search(text) and ".example" not in path.name:
            add(result, "warnings", f"possivel segredo versionado: {path.relative_to(ROOT)}")


def write_reports(result: dict[str, list[str]]) -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    summary = {
        "ok": not result["errors"],
        "error_count": len(result["errors"]),
        "warning_count": len(result["warnings"]),
        **result,
    }
    (REPORT_DIR / "runtime_contracts.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    lines = [
        "# Cria do Tatame — Runtime Contract Audit",
        "",
        f"- Status: {'PASS' if summary['ok'] else 'FAIL'}",
        f"- Erros: {summary['error_count']}",
        f"- Avisos: {summary['warning_count']}",
        "",
        "## Erros",
        "",
    ]
    lines.extend(f"- {item}" for item in result["errors"] or ["Nenhum."])
    lines.extend(["", "## Avisos", ""])
    lines.extend(f"- {item}" for item in result["warnings"] or ["Nenhum."])
    (REPORT_DIR / "runtime_contracts.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    result: dict[str, list[str]] = {"errors": [], "warnings": []}
    validate_json_files(result)
    autoloads = validate_project(result)
    validate_global_names(result, autoloads)
    validate_resources(result)
    validate_required_scenes(result)
    validate_canon(result)
    validate_techniques(result)
    validate_scene_scripts(result)
    validate_secrets(result)
    write_reports(result)
    print(json.dumps({"ok": not result["errors"], **result}, ensure_ascii=False, indent=2))
    return 0 if not result["errors"] else 1


if __name__ == "__main__":
    sys.exit(main())
