#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
PROTOCOL_PATH = ROOT / "docs/ART_PROTOCOL.md"
TOKENS_PATH = ROOT / "data/art_tokens.json"
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$")
HEX_RE = re.compile(r"#[0-9A-Fa-f]{6}\b")

EXPECTED_PALETTE = {
    "preto-tatame": "#0B0B0C",
    "ouro-cria": "#E8A317",
    "ouro-claro": "#F2B705",
    "branco-giz": "#F4EFE6",
    "cinza-grunge": "#1A1A1C",
    "verde-mangue": "#2F5D3A",
    "azul-agua": "#1E6E7C",
    "vermelho-perigo": "#C0392B",
    "roxo-evento": "#8E44AD",
    "ocre-terra": "#8A5A2B",
}
EXPECTED_TYPE_FUNCTIONS = {"logo", "title_hud", "body", "numbers"}
EXPECTED_WORLD_ZONES = ["Topbar", "LeftRail", "Center", "RightRail", "BottomBar"]
EXPECTED_HUD_BARS = ["gas", "positional_control", "grip", "flow"]
REQUIRED_PROHIBITIONS = {
    "gradient_indigo_violet_pink",
    "screen_glassmorphism",
    "font_inter",
    "font_roboto",
    "font_arial",
    "cream_terracotta_serif_system",
    "single_acid_neon_on_near_black",
    "three_equal_cards_row_layout",
    "branded_glasses",
    "japanese_as_headline",
    "console_platform_hud",
    "salvador_as_playable_node",
    "sao_paulo_as_playable_node",
    "itacare_as_playable_node",
    "arena_drawn_as_city",
    "woman_without_function",
    "weapon_as_mechanic_or_reward",
}
REQUIRED_FILES = {
    "docs/ART_PROTOCOL.md",
    "data/art_tokens.json",
    "tools/validate_art_protocol.py",
    "tests/test_art_protocol.py",
}


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def warn(self, message: str) -> None:
        self.warnings.append(message)

    def assert_true(self, condition: bool, message: str) -> None:
        if not condition:
            self.error(message)


def read_text(path: Path) -> str:
    if not path.is_file():
        raise FileNotFoundError(path.relative_to(ROOT))
    return path.read_text(encoding="utf-8")


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(read_text(path))
    if not isinstance(value, dict):
        raise TypeError(f"raiz JSON deve ser objeto: {path.relative_to(ROOT)}")
    return value


def iter_globs(patterns: Iterable[str]) -> Iterable[Path]:
    seen: set[Path] = set()
    for pattern in patterns:
        for path in ROOT.glob(pattern):
            if path.is_file() and path not in seen:
                seen.add(path)
                yield path


def get_exception_rules(tokens: dict[str, Any], relative: str) -> set[str]:
    rules: set[str] = set()
    for item in tokens["validation"].get("migration_exceptions", []):
        if item.get("path") == relative:
            rules.update(item.get("rules", []))
    return rules


def validate_required_files(report: Report) -> None:
    for relative in sorted(REQUIRED_FILES):
        report.assert_true((ROOT / relative).is_file(), f"arquivo obrigatório ausente: {relative}")


def validate_tokens(report: Report, tokens: dict[str, Any]) -> None:
    version = tokens.get("protocol_version")
    report.assert_true(isinstance(version, str) and SEMVER_RE.fullmatch(version or "") is not None, "protocol_version não é SemVer")
    report.assert_true(tokens.get("schema_version") == "1.0.0", "schema_version deve ser 1.0.0")
    report.assert_true(tokens.get("status") == "canonical", "status deve ser canonical")

    changelog = tokens.get("changelog", [])
    report.assert_true(isinstance(changelog, list) and bool(changelog), "changelog obrigatório")
    if isinstance(changelog, list) and changelog:
        report.assert_true(changelog[-1].get("version") == version, "última entrada do changelog deve corresponder à versão atual")

    palette = tokens.get("palette", {})
    palette_tokens = palette.get("tokens", {})
    report.assert_true(set(palette_tokens) == set(EXPECTED_PALETTE), "paleta deve conter exatamente os dez tokens mestres")
    for name, expected_hex in EXPECTED_PALETTE.items():
        item = palette_tokens.get(name, {})
        report.assert_true(item.get("hex") == expected_hex, f"hex divergente para {name}")
        report.assert_true(bool(item.get("use")), f"{name} sem lista de uso")
        report.assert_true(bool(item.get("forbidden")), f"{name} sem lista de proibições")
        report.assert_true(bool(item.get("contrast_with_branco_giz")), f"{name} sem contraste documentado")

    report.assert_true(
        palette.get("ratio") == {"preto_tatame": 60, "neutro": 30, "ouro_cria": 10},
        "proporção mestre deve ser 60/30/10",
    )

    typography = tokens.get("typography", {})
    functions = typography.get("functions", {})
    report.assert_true(set(functions) == EXPECTED_TYPE_FUNCTIONS, "tipografia deve ter exatamente quatro funções")
    report.assert_true(functions.get("logo", {}).get("families") == ["Cria Brush Custom"], "logo deve usar Cria Brush Custom")
    report.assert_true(functions.get("title_hud", {}).get("families") == ["Saira Condensed", "Oswald"], "título/HUD divergente")
    report.assert_true(functions.get("body", {}).get("families") == ["Hanken Grotesk", "Spline Sans"], "corpo divergente")
    report.assert_true(functions.get("numbers", {}).get("families") == ["Saira", "Space Mono"], "números divergentes")
    report.assert_true(functions.get("body", {}).get("minimum_mobile_px") == 12, "corpo mobile mínimo deve ser 12 px")
    report.assert_true(functions.get("numbers", {}).get("minimum_bar_px") == 14, "número de barra mínimo deve ser 14 px")

    mascot = tokens.get("mascot", {})
    required = mascot.get("required", {})
    report.assert_true(mascot.get("id") == "silverback", "mascote deve ser silverback")
    report.assert_true(required.get("attire") == "gi preto", "Silverback deve usar gi preto")
    report.assert_true(required.get("glasses") == "óculos dourado genérico sem logotipo", "óculos devem ser genéricos")
    report.assert_true(required.get("values_ring") == ["DISCIPLINA", "FOCO", "RESPEITO", "EVOLUÇÃO"], "anel de valores divergente")
    report.assert_true(
        set(mascot.get("required_variants", []))
        == {"logo_cheio", "cabeca_com_oculos", "cabeca_mono_circulo", "triangulo_favicon"},
        "variações obrigatórias do mascote divergentes",
    )

    composition = tokens.get("composition", {})
    report.assert_true(composition.get("world_screen_zones") == EXPECTED_WORLD_ZONES, "tela de mundo deve ter cinco zonas")
    report.assert_true(composition.get("grid_tracks") == 3, "grid deve ter três trilhos")
    report.assert_true(composition.get("center_never_hidden") is True, "centro nunca pode sumir")

    hud = tokens.get("combat_hud", {})
    bars = [item.get("id") for item in hud.get("fixed_bars", [])]
    report.assert_true(bars == EXPECTED_HUD_BARS, "HUD deve ter Gás, Controle, Pegada e Fluxo")
    report.assert_true(hud.get("arena_card_modifiers_required") == 4, "arena card deve ter quatro modificadores")
    report.assert_true(hud.get("timing_states") == ["CEDO", "PERFEITO", "TARDE"], "estados de timing divergentes")
    report.assert_true(hud.get("submission_flow") == ["SETUP", "LOCK", "FINISH"], "fluxo de finalização divergente")
    report.assert_true(hud.get("console_platform_icons_forbidden") is True, "ícones de console devem ser bloqueados")

    pixel = tokens.get("pixel_art", {})
    report.assert_true(pixel.get("texture_filter") == "nearest", "filtro deve ser nearest")
    report.assert_true(pixel.get("integer_scale_required") is True, "escala inteira obrigatória")
    report.assert_true(pixel.get("pixel_snap_required") is True, "pixel snap obrigatório")
    report.assert_true(pixel.get("base_resolution") == [640, 360], "resolução base divergente")
    report.assert_true(pixel.get("contact_shadow_required") is True, "sombra de contato obrigatória")
    report.assert_true(pixel.get("occlusion_mask_required") is True, "máscara de oclusão obrigatória")

    budget = tokens.get("mobile_budget", {})
    report.assert_true(budget.get("parallax_layers_max") == 4, "máximo de quatro paralaxes")
    report.assert_true(budget.get("draw_calls_target_max") == 40, "alvo máximo de 40 draw calls")
    report.assert_true(budget.get("animated_background_sprites_max") == 12, "máximo de 12 sprites animados")
    report.assert_true(budget.get("crowd_states") == ["idle", "pressure", "climax"], "plateia deve ter três estados")

    fields = tokens.get("iconography", {}).get("required_node_fields", [])
    report.assert_true(fields == ["icon_type", "state", "narrative_detail"], "campos obrigatórios de nó divergentes")

    missing = sorted(REQUIRED_PROHIBITIONS - set(tokens.get("hard_prohibitions", [])))
    report.assert_true(not missing, f"proibições obrigatórias ausentes: {missing}")


def parse_protocol_metadata(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for key in ("status", "version", "last_reviewed", "owner"):
        match = re.search(rf">\s*\*\*{key}:\*\*\s*(.+)", text)
        if match:
            result[key] = match.group(1).strip().rstrip()
    return result


def validate_protocol_document(report: Report, tokens: dict[str, Any], text: str) -> None:
    metadata = parse_protocol_metadata(text)
    report.assert_true(metadata.get("status") == "CANONICAL", "status do documento deve ser CANONICAL")
    report.assert_true(metadata.get("version") == tokens.get("protocol_version"), "versão do documento e tokens diverge")
    report.assert_true(metadata.get("last_reviewed") == tokens.get("last_reviewed"), "last_reviewed diverge")
    report.assert_true(metadata.get("owner") == tokens.get("owner"), "owner diverge")

    for block in range(1, 11):
        report.assert_true(f"# BLOCO {block} —" in text, f"BLOCO {block} ausente")
    for marker in ("## M1 —", "## M2 —", "## M3 —", "## M4 —", "## M5 —", "## M6 —"):
        report.assert_true(marker in text, f"mecanismo ausente: {marker}")
    report.assert_true("# CHECKLIST DE CONFORMIDADE POR ASSET" in text, "checklist de asset ausente")

    for phrase in (
        "O nome do token é a verdade",
        "DISCIPLINA · FOCO · RESPEITO · EVOLUÇÃO",
        "SETUP → LOCK → FINISH",
        "Salvador, São Paulo ou Itacaré como nó jogável",
        "óculos dourado genérico",
    ):
        report.assert_true(phrase in text, f"frase obrigatória ausente: {phrase}")


def validate_references(report: Report, tokens: dict[str, Any]) -> None:
    for relative, needles in {
        "README.md": ["docs/ART_PROTOCOL.md", "data/art_tokens.json"],
        "docs/INDEX.md": ["ART_PROTOCOL.md", "art_tokens.json", "validate_art_protocol.py"],
        "docs/06_AI_LORE_GUARDIAN.md": ["ART_PROTOCOL.md", "art_tokens.json"],
    }.items():
        text = read_text(ROOT / relative)
        for needle in needles:
            report.assert_true(needle in text, f"{relative} não referencia {needle}")

    contract = load_json(ROOT / "data/visual/visual_canon_contract_v2.json")
    art_protocol = contract.get("art_protocol", {})
    report.assert_true(art_protocol.get("path") == "docs/ART_PROTOCOL.md", "contrato visual não aponta para ART_PROTOCOL")
    report.assert_true(art_protocol.get("tokens") == "data/art_tokens.json", "contrato visual não aponta para art_tokens")
    report.assert_true(art_protocol.get("version") == tokens.get("protocol_version"), "versão diverge no contrato visual")
    report.assert_true(art_protocol.get("visual_execution_precedence") is True, "precedência visual não está ativa")

    package = load_json(ROOT / "package.json")
    scripts = package.get("scripts", {})
    report.assert_true(scripts.get("validate:art-protocol") == "python tools/validate_art_protocol.py", "script ausente")
    report.assert_true("validate:art-protocol" in scripts.get("quality", ""), "quality não executa validate:art-protocol")

    governance = load_json(ROOT / "data/production/repository_governance_v01.json")
    required = set(governance.get("required_governance_files", []))
    report.assert_true(REQUIRED_FILES.issubset(required), "governança não exige todos os arquivos")
    protected = governance.get("protected_invariants", {})
    report.assert_true(protected.get("art_protocol") == "docs/ART_PROTOCOL.md", "invariante art_protocol ausente")
    report.assert_true(protected.get("art_tokens") == "data/art_tokens.json", "invariante art_tokens ausente")
    report.assert_true(protected.get("art_protocol_version") == tokens.get("protocol_version"), "versão protegida divergente")
    report.assert_true(protected.get("combat_hud_fixed_bars") == EXPECTED_HUD_BARS, "barras protegidas divergentes")


def scan_hex_and_fonts(report: Report, tokens: dict[str, Any]) -> None:
    validation = tokens.get("validation", {})
    allowed_hex = {value.upper() for value in EXPECTED_PALETTE.values()}
    exception_paths = set(validation.get("raw_hex_exceptions", []))
    forbidden_fonts = {name.lower() for name in tokens["typography"].get("forbidden_families", [])}

    for path in iter_globs(validation.get("theme_globs", [])):
        relative = path.relative_to(ROOT).as_posix()
        if relative in exception_paths:
            continue
        try:
            text = read_text(path)
        except UnicodeDecodeError:
            continue

        for raw_hex in HEX_RE.findall(text):
            if raw_hex.upper() not in allowed_hex:
                report.error(f"R1: hex sem token em {relative}: {raw_hex}")

        lowered = text.lower()
        for font in forbidden_fonts:
            if re.search(rf"\b{re.escape(font)}\b", lowered):
                report.error(f"R3: família proibida em {relative}: {font}")


def validate_world_screens(report: Report, tokens: dict[str, Any]) -> None:
    found = 0
    for path in iter_globs(tokens.get("validation", {}).get("world_scene_globs", [])):
        text = read_text(path)
        relative = path.relative_to(ROOT).as_posix()
        if "WorldMapScreen" not in text and 'text = "MAPA DO BAIXO SUL"' not in text:
            continue
        found += 1
        if "R4" in get_exception_rules(tokens, relative):
            report.warn(f"R4 em migração: {relative}")
            continue
        missing = [zone for zone in EXPECTED_WORLD_ZONES if f'name="{zone}"' not in text and f'name = "{zone}"' not in text]
        if missing:
            report.error(f"R4: {relative} sem zonas {missing}")
    report.assert_true(found >= 1, "nenhuma tela de mundo localizada")


def walk_json(value: Any) -> Iterable[dict[str, Any]]:
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk_json(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_json(child)


def validate_protocol_marked_map_nodes(report: Report, tokens: dict[str, Any]) -> None:
    required = tokens["iconography"]["required_node_fields"]
    for path in ROOT.glob("data/world/**/*.json"):
        try:
            data = load_json(path)
        except (json.JSONDecodeError, TypeError):
            continue
        for item in walk_json(data):
            if not item.get("art_protocol_version"):
                continue
            if not (item.get("node_id") or item.get("node_type") or item.get("municipality_id")):
                continue
            missing = [field for field in required if not item.get(field)]
            if missing:
                report.error(f"R8: nó protocolado em {path.relative_to(ROOT)} sem {missing}")


def validate_arena_cards(report: Report, tokens: dict[str, Any]) -> None:
    data = load_json(ROOT / tokens["validation"]["arena_data_path"])
    arenas = data.get("arenas", [])
    report.assert_true(isinstance(arenas, list), "data/arenas.json sem lista arenas")
    required_count = tokens["combat_hud"]["arena_card_modifiers_required"]
    legacy = 0

    for arena in arenas:
        if not isinstance(arena, dict):
            report.error("registro de arena inválido")
            continue
        if not (arena.get("art_protocol_version") or arena.get("protocol_enforced") is True):
            legacy += 1
            continue
        modifiers = arena.get("modifiers", {})
        if not isinstance(modifiers, dict) or len(modifiers) != required_count:
            report.error(f"R6: arena {arena.get('id')} deve declarar exatamente {required_count} modificadores")
    if legacy:
        report.warn(f"arenas legadas fora de enforcement total: {legacy}; novas arenas devem declarar art_protocol_version")


def previous_file_content(path: str) -> str | None:
    try:
        commits = subprocess.run(
            ["git", "log", "--format=%H", "--", path],
            cwd=ROOT,
            check=True,
            text=True,
            capture_output=True,
        ).stdout.splitlines()
        if len(commits) < 2:
            return None
        return subprocess.run(
            ["git", "show", f"{commits[1]}:{path}"],
            cwd=ROOT,
            check=True,
            text=True,
            capture_output=True,
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def validate_version_bump(report: Report, tokens: dict[str, Any], protocol_text: str) -> None:
    previous_tokens_text = previous_file_content("data/art_tokens.json")
    if previous_tokens_text is not None and previous_tokens_text != read_text(TOKENS_PATH):
        previous = json.loads(previous_tokens_text)
        if previous.get("protocol_version") == tokens.get("protocol_version"):
            report.error("M1: art_tokens.json mudou sem bump de protocol_version")

    previous_doc = previous_file_content("docs/ART_PROTOCOL.md")
    if previous_doc is not None and previous_doc != protocol_text:
        previous_version = parse_protocol_metadata(previous_doc).get("version")
        current_version = parse_protocol_metadata(protocol_text).get("version")
        if previous_version == current_version:
            report.error("M1: ART_PROTOCOL.md mudou sem bump de versão")


def validate_asset_manifest(report: Report, tokens: dict[str, Any], path: Path) -> None:
    data = load_json(path)
    report.assert_true(data.get("art_protocol_version") == tokens.get("protocol_version"), "asset usa versão diferente")

    unknown_colors = sorted(set(data.get("color_tokens", [])) - set(EXPECTED_PALETTE))
    report.assert_true(not unknown_colors, f"asset usa tokens desconhecidos: {unknown_colors}")

    unknown_functions = sorted(set(data.get("font_functions", [])) - set(tokens["typography"]["functions"]))
    report.assert_true(not unknown_functions, f"asset usa funções tipográficas desconhecidas: {unknown_functions}")

    asset_type = data.get("asset_type")
    if asset_type == "world_screen":
        report.assert_true(data.get("screen_zones") == EXPECTED_WORLD_ZONES, "tela de mundo sem cinco zonas")
    if asset_type == "combat_hud":
        report.assert_true(data.get("fixed_bars") == EXPECTED_HUD_BARS, "HUD sem quatro barras fixas")
    if asset_type == "map_node":
        missing = [field for field in tokens["iconography"]["required_node_fields"] if not data.get(field)]
        report.assert_true(not missing, f"nó sem campos: {missing}")
    if asset_type == "arena":
        modifiers = data.get("modifiers", [])
        report.assert_true(isinstance(modifiers, list) and len(modifiers) == 4, "arena deve apresentar quatro modificadores")

    report.assert_true(not data.get("detected_prohibitions", []), "asset contém proibição dura")


def run(asset: Path | None = None) -> Report:
    report = Report()
    try:
        validate_required_files(report)
        tokens = load_json(TOKENS_PATH)
        protocol_text = read_text(PROTOCOL_PATH)
        validate_tokens(report, tokens)
        validate_protocol_document(report, tokens, protocol_text)
        validate_references(report, tokens)
        scan_hex_and_fonts(report, tokens)
        validate_world_screens(report, tokens)
        validate_protocol_marked_map_nodes(report, tokens)
        validate_arena_cards(report, tokens)
        validate_version_bump(report, tokens, protocol_text)
        if asset is not None:
            validate_asset_manifest(report, tokens, asset)
    except (FileNotFoundError, json.JSONDecodeError, TypeError, KeyError) as exc:
        report.error(f"falha estrutural: {exc}")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Valida o ART_PROTOCOL do Cria do Tatame.")
    parser.add_argument("--asset", type=Path, help="Manifesto JSON de asset para /ARTE-CHECK automatizável.")
    args = parser.parse_args()

    asset = args.asset
    if asset is not None and not asset.is_absolute():
        asset = ROOT / asset

    report = run(asset)
    if report.warnings:
        print("[ART_PROTOCOL] AVISOS")
        for warning in report.warnings:
            print(f" - {warning}")

    if report.errors:
        print("[ART_PROTOCOL] FALHOU")
        for error in report.errors:
            print(f" - {error}")
        return 1

    print("[ART_PROTOCOL] OK")
    print("- protocolo e tokens: 1.0.0")
    print("- paleta: 10 tokens; proporção 60/30/10")
    print("- tipografia: 4 funções")
    print("- HUD: Gás, Controle, Pegada, Fluxo")
    print("- pixel art: nearest, escala inteira, pixel snap")
    print("- orçamento: 4 paralaxes, 40 draw calls, 12 sprites animados")
    print("- checks manuais continuam obrigatórios para composição, cultura, anatomia e device")
    return 0


if __name__ == "__main__":
    sys.exit(main())
