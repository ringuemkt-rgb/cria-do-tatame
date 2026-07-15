#!/usr/bin/env python3
"""Auditoria integral e determinística do repositório Cria do Tatame.

Executa sem dependências externas e valida contratos que normalmente escapam de
smoke tests isolados: caminhos res://, cenas, autoloads, sinais, DataRegistry,
save, dados, segredos e exportação.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "full_game_audit"
TEXT_EXTENSIONS = {".gd", ".tscn", ".tres", ".cfg", ".godot", ".json", ".py", ".md", ".yml", ".yaml", ".ps1", ".sh"}
RESOURCE_EXTENSIONS = {".gd", ".tscn", ".tres", ".cfg", ".godot", ".json"}
SKIP_PARTS = {".git", ".godot", "builds", "reports", "__pycache__", ".venv", "node_modules"}
RES_RE = re.compile(r"res://[A-Za-z0-9_@./\-À-ÿ]+")
AUTOLOAD_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)="\*?res://([^"]+)"$', re.MULTILINE)
SIGNAL_DECL_RE = re.compile(r"^signal\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)
SIGNAL_EMIT_RE = re.compile(r"SignalBus\.([A-Za-z_][A-Za-z0-9_]*)\.emit\s*\(")
HAS_SIGNAL_RE = re.compile(r"SignalBus\.has_signal\(\s*[\"']([A-Za-z_][A-Za-z0-9_]*)[\"']\s*\)")
DATA_FILE_RE = re.compile(r'"([A-Za-z_][A-Za-z0-9_]*)"\s*:\s*"(res://[^"]+)"')
FUNC_RE = re.compile(r"^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", re.MULTILINE)
CLASS_NAME_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)
EXT_RESOURCE_RE = re.compile(r'^\[ext_resource[^\]]*path="([^"]+)"[^\]]*id="([^"]+)"', re.MULTILINE)
NODE_RE = re.compile(r'^\[node\s+name="([^"]+)"\s+type="([^"]+)"(?:\s+parent="([^"]*)")?[^\]]*\]$', re.MULTILINE)
SECRET_PATTERNS = [
    re.compile(r"sk-or-v1-[A-Za-z0-9_-]{20,}"),
    re.compile(r"hf_[A-Za-z0-9]{20,}"),
    re.compile(r"HFAK[A-Za-z0-9]{20,}"),
    re.compile(r"(?i)(api[_-]?key|secret|password)\s*[:=]\s*[\"'][^\"']{16,}[\"']"),
]
PLACEHOLDER_RE = re.compile(r"(?i)\b(TODO|FIXME|NOT_IMPLEMENTED|PLACEHOLDER_ONLY|raise\s+NotImplementedError)\b")


class Audit:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.metrics: dict[str, Any] = {}

    def error(self, message: str) -> None:
        self.errors.append(message)

    def warn(self, message: str) -> None:
        self.warnings.append(message)


def all_files() -> list[Path]:
    return [
        path
        for path in ROOT.rglob("*")
        if path.is_file() and not any(part in SKIP_PARTS for part in path.relative_to(ROOT).parts)
    ]


def text_files() -> list[Path]:
    return [path for path in all_files() if path.suffix.lower() in TEXT_EXTENSIONS]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="strict")


def clean_resource(raw: str) -> str:
    return raw.removeprefix("res://").rstrip(".,;:)'\"]}")


def parse_json(path: Path, audit: Audit) -> Any | None:
    try:
        return json.loads(read_text(path))
    except Exception as exc:  # noqa: BLE001
        audit.error(f"JSON inválido: {path.relative_to(ROOT)}: {exc}")
        return None


def walk_json(value: Any, location: str = "$") -> Iterable[tuple[str, Any]]:
    yield location, value
    if isinstance(value, dict):
        for key, child in value.items():
            yield from walk_json(child, f"{location}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk_json(child, f"{location}[{index}]")


def audit_file_system(audit: Audit, files: list[Path]) -> None:
    rels = [str(path.relative_to(ROOT)).replace("\\", "/") for path in files]
    lowered: defaultdict[str, list[str]] = defaultdict(list)
    for rel in rels:
        lowered[rel.lower()].append(rel)
    for variants in lowered.values():
        if len(set(variants)) > 1:
            audit.error(f"colisão de caminho por maiúsculas/minúsculas: {', '.join(sorted(variants))}")
    symlinks = [path for path in ROOT.rglob("*") if path.is_symlink()]
    for path in symlinks:
        try:
            path.resolve().relative_to(ROOT.resolve())
        except ValueError:
            audit.error(f"link simbólico sai do repositório: {path.relative_to(ROOT)}")
    audit.metrics["files"] = len(files)
    audit.metrics["gd_scripts"] = sum(path.suffix == ".gd" for path in files)
    audit.metrics["scenes"] = sum(path.suffix == ".tscn" for path in files)
    audit.metrics["json_files"] = sum(path.suffix == ".json" for path in files)


def audit_json(audit: Audit) -> dict[str, Any]:
    parsed: dict[str, Any] = {}
    global_ids: defaultdict[str, list[str]] = defaultdict(list)
    for path in sorted((ROOT / "data").rglob("*.json")):
        data = parse_json(path, audit)
        if data is None:
            continue
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        parsed[rel] = data
        for location, value in walk_json(data):
            if not isinstance(value, list):
                continue
            ids = [str(item.get("id", "")) for item in value if isinstance(item, dict) and item.get("id")]
            duplicates = [item_id for item_id, count in Counter(ids).items() if count > 1]
            for item_id in duplicates:
                audit.error(f"ID duplicado no mesmo catálogo: {rel}:{location} -> {item_id}")
            for item_id in ids:
                global_ids[item_id].append(f"{rel}:{location}")
    # IDs repetidos entre catálogos podem ser aliases legítimos; apenas sinalizar quando aparecem muitas vezes.
    for item_id, locations in sorted(global_ids.items()):
        if len(locations) >= 5:
            audit.warn(f"ID aparece em muitos catálogos ({len(locations)}): {item_id}")
    audit.metrics["indexed_ids"] = len(global_ids)
    return parsed


def audit_project(audit: Audit) -> dict[str, str]:
    project = ROOT / "project.godot"
    if not project.exists():
        audit.error("project.godot ausente")
        return {}
    text = read_text(project)
    main_match = re.search(r'^run/main_scene="res://([^"]+)"$', text, re.MULTILINE)
    if not main_match:
        audit.error("run/main_scene não definido")
    elif not (ROOT / main_match.group(1)).exists():
        audit.error(f"main scene inexistente: {main_match.group(1)}")
    autoloads = {name: path for name, path in AUTOLOAD_RE.findall(text)}
    if len(autoloads) < 8:
        audit.error(f"quantidade anormal de autoloads: {len(autoloads)}")
    for name, rel in autoloads.items():
        target = ROOT / rel
        if not target.exists():
            audit.error(f"autoload {name} aponta para arquivo ausente: {rel}")
    names: defaultdict[str, list[str]] = defaultdict(list)
    for path in sorted(ROOT.rglob("*.gd")):
        if any(part in SKIP_PARTS for part in path.relative_to(ROOT).parts):
            continue
        for name in CLASS_NAME_RE.findall(read_text(path)):
            names[name].append(str(path.relative_to(ROOT)))
    for name, paths in names.items():
        if len(paths) > 1:
            audit.error(f"class_name duplicado {name}: {', '.join(paths)}")
        if name in autoloads:
            audit.error(f"class_name colide com autoload {name}: {', '.join(paths)}")
    audit.metrics["autoloads"] = len(autoloads)
    return autoloads


def audit_resource_references(audit: Audit, files: list[Path]) -> None:
    checked = 0
    for path in files:
        if path.suffix.lower() not in RESOURCE_EXTENSIONS:
            continue
        try:
            text = read_text(path)
        except UnicodeDecodeError:
            continue
        for raw in sorted(set(RES_RE.findall(text))):
            rel = clean_resource(raw)
            if not rel or "{" in rel or "%" in rel:
                continue
            checked += 1
            if not (ROOT / rel).exists():
                audit.error(f"recurso res:// ausente: {path.relative_to(ROOT)} -> {raw}")
    audit.metrics["resource_references_checked"] = checked


def audit_scenes(audit: Audit) -> None:
    node_total = 0
    for path in sorted((ROOT / "scenes").rglob("*.tscn")):
        text = read_text(path)
        ext_ids: list[str] = []
        for raw_path, resource_id in EXT_RESOURCE_RE.findall(text):
            ext_ids.append(resource_id)
            if raw_path.startswith("res://") and not (ROOT / clean_resource(raw_path)).exists():
                audit.error(f"ext_resource ausente: {path.relative_to(ROOT)} -> {raw_path}")
        duplicates = [item for item, count in Counter(ext_ids).items() if count > 1]
        for resource_id in duplicates:
            audit.error(f"ext_resource id duplicado em {path.relative_to(ROOT)}: {resource_id}")
        seen_nodes: set[tuple[str, str]] = set()
        nodes = NODE_RE.findall(text)
        node_total += len(nodes)
        if not nodes:
            audit.error(f"cena sem node raiz: {path.relative_to(ROOT)}")
        for name, _node_type, parent in nodes:
            key = (parent, name)
            if key in seen_nodes:
                audit.error(f"node duplicado no mesmo parent: {path.relative_to(ROOT)} -> {parent}/{name}")
            seen_nodes.add(key)
    audit.metrics["scene_nodes"] = node_total


def audit_signal_contracts(audit: Audit) -> None:
    signal_bus = ROOT / "src/autoloads/SignalBus.gd"
    if not signal_bus.exists():
        audit.error("SignalBus.gd ausente")
        return
    declarations = SIGNAL_DECL_RE.findall(read_text(signal_bus))
    duplicate_declarations = [name for name, count in Counter(declarations).items() if count > 1]
    for name in duplicate_declarations:
        audit.error(f"sinal declarado em duplicidade: {name}")
    declared = set(declarations)
    emitted: defaultdict[str, list[str]] = defaultdict(list)
    checked: defaultdict[str, list[str]] = defaultdict(list)
    for path in sorted(ROOT.rglob("*.gd")):
        if any(part in SKIP_PARTS for part in path.relative_to(ROOT).parts):
            continue
        text = read_text(path)
        rel = str(path.relative_to(ROOT))
        for name in SIGNAL_EMIT_RE.findall(text):
            emitted[name].append(rel)
        for name in HAS_SIGNAL_RE.findall(text):
            checked[name].append(rel)
    for name, paths in sorted(emitted.items()):
        if name not in declared:
            audit.error(f"emissão de SignalBus não declarado: {name} em {', '.join(sorted(set(paths)))}")
    for name, paths in sorted(checked.items()):
        if name not in declared:
            audit.error(f"has_signal consulta sinal não declarado: {name} em {', '.join(sorted(set(paths)))}")
    unused = sorted(declared - set(emitted))
    if unused:
        audit.warn(f"sinais sem emissão direta detectada ({len(unused)}): {', '.join(unused[:20])}")
    audit.metrics["signals_declared"] = len(declared)
    audit.metrics["signals_emitted"] = len(emitted)


def audit_data_registry(audit: Audit) -> None:
    path = ROOT / "src/autoloads/DataRegistry.gd"
    if not path.exists():
        audit.error("DataRegistry.gd ausente")
        return
    text = read_text(path)
    entries = DATA_FILE_RE.findall(text)
    keys = [key for key, _ in entries]
    for key, raw_path in entries:
        rel = clean_resource(raw_path)
        if not (ROOT / rel).exists():
            audit.error(f"DataRegistry {key} aponta para arquivo ausente: {raw_path}")
        if not re.search(rf"\b{re.escape(key)}\s*=\s*_load_(?:raw|keyed)\(\s*[\"']{re.escape(key)}[\"']\s*\)", text):
            audit.error(f"DataRegistry declara {key}, mas load_all não o carrega")
    duplicates = [key for key, count in Counter(keys).items() if count > 1]
    for key in duplicates:
        audit.error(f"chave duplicada em DataRegistry.DATA_FILES: {key}")
    audit.metrics["data_registry_entries"] = len(entries)


def methods_in(path: Path) -> set[str]:
    return set(FUNC_RE.findall(read_text(path))) if path.exists() else set()


def audit_save_contracts(audit: Audit, autoloads: dict[str, str]) -> None:
    save_path = ROOT / "src/autoloads/SaveManager.gd"
    if not save_path.exists():
        audit.error("SaveManager.gd ausente")
        return
    text = read_text(save_path)
    version_match = re.search(r"const\s+SAVE_VERSION\s*:?=\s*(\d+)", text)
    if not version_match:
        audit.error("SaveManager sem SAVE_VERSION")
    elif int(version_match.group(1)) < 4:
        audit.error(f"SAVE_VERSION regressivo: {version_match.group(1)}")
    for required in ("_write_atomic_json", "save_game", "load_game", "delete_save"):
        if required not in methods_in(save_path):
            audit.error(f"SaveManager sem método obrigatório: {required}")
    manager_calls = re.findall(r'has_node\("/root/([A-Za-z_][A-Za-z0-9_]*)"\).*?\n(?:.|\n){0,240}?\b\1\.(to_dict|load_from_dict)\(', text)
    for manager, method in manager_calls:
        rel = autoloads.get(manager)
        if not rel:
            audit.error(f"SaveManager usa singleton não registrado: {manager}")
            continue
        available = methods_in(ROOT / rel)
        if method not in available:
            audit.error(f"SaveManager chama {manager}.{method}(), mas método não existe em {rel}")
    if '".tmp"' not in text or '".bak"' not in text:
        audit.error("SaveManager perdeu estratégia de arquivo temporário/backup")


def audit_export(audit: Audit) -> None:
    path = ROOT / "export_presets.cfg"
    if not path.exists():
        audit.error("export_presets.cfg ausente")
        return
    text = read_text(path)
    if 'name="Android Debug"' not in text:
        audit.error("preset Android Debug ausente")
    if 'package/unique_name="com.criadotatame.pressao"' not in text:
        audit.error("package Android inesperado ou ausente")
    if 'architectures/arm64-v8a=true' not in text:
        audit.error("Android arm64-v8a não habilitado")
    if 'export_filter="all_resources"' not in text:
        audit.warn("preset não exporta todos os recursos; revisar filtros")
    icon_fields = re.findall(r'^launcher_icons/[^=]+="([^"]*)"$', text, re.MULTILINE)
    if icon_fields and not any(icon_fields):
        audit.warn("ícones Android ainda não configurados")
    if 'permissions/internet=true' in text:
        audit.warn("APK solicita INTERNET; confirmar necessidade para IA/NFT opcionais")
    build_doc = ROOT / "tools/build/BUILD_ANDROID.md"
    if build_doc.exists():
        doc = read_text(build_doc)
        if '--export-debug "Android"' in doc or 'export/export_presets.cfg' in doc:
            audit.error("BUILD_ANDROID.md está incompatível com o preset real Android Debug")


def audit_secrets_and_placeholders(audit: Audit, files: list[Path]) -> None:
    for path in files:
        if path.suffix.lower() not in TEXT_EXTENSIONS:
            continue
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        if path.name.startswith(".env") and path.name != ".env.example":
            audit.error(f"arquivo de ambiente sensível versionado: {rel}")
        try:
            text = read_text(path)
        except UnicodeDecodeError:
            continue
        if ".example" not in path.name:
            for pattern in SECRET_PATTERNS:
                if pattern.search(text):
                    audit.error(f"possível segredo real versionado: {rel}")
                    break
        if path.suffix.lower() in {".gd", ".py"} and PLACEHOLDER_RE.search(text):
            audit.warn(f"marcador de implementação pendente: {rel}")
        if path.suffix.lower() == ".gd" and len(text.strip().splitlines()) <= 2:
            audit.warn(f"script GDScript praticamente vazio: {rel}")


def write_report(audit: Audit) -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "ok": not audit.errors,
        "error_count": len(audit.errors),
        "warning_count": len(audit.warnings),
        "metrics": audit.metrics,
        "errors": sorted(set(audit.errors)),
        "warnings": sorted(set(audit.warnings)),
    }
    (REPORT_DIR / "full_game_audit.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    lines = [
        "# Auditoria integral — Cria do Tatame",
        "",
        f"- Status: {'PASS' if payload['ok'] else 'FAIL'}",
        f"- Erros: {payload['error_count']}",
        f"- Avisos: {payload['warning_count']}",
        "",
        "## Métricas",
        "",
    ]
    lines.extend(f"- {key}: {value}" for key, value in sorted(audit.metrics.items()))
    lines.extend(["", "## Erros", ""])
    lines.extend(f"- {item}" for item in payload["errors"] or ["Nenhum."])
    lines.extend(["", "## Avisos", ""])
    lines.extend(f"- {item}" for item in payload["warnings"] or ["Nenhum."])
    (REPORT_DIR / "full_game_audit.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=False, indent=2))


def main() -> int:
    audit = Audit()
    files = all_files()
    audit_file_system(audit, files)
    audit_json(audit)
    autoloads = audit_project(audit)
    audit_resource_references(audit, files)
    audit_scenes(audit)
    audit_signal_contracts(audit)
    audit_data_registry(audit)
    audit_save_contracts(audit, autoloads)
    audit_export(audit)
    audit_secrets_and_placeholders(audit, files)
    write_report(audit)
    return 0 if not audit.errors else 1


if __name__ == "__main__":
    sys.exit(main())
