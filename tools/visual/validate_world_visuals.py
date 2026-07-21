#!/usr/bin/env python3
"""Valida os contratos visuais da Arena do Dique e do mapa semiaberto."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
ARENA_BASE = ROOT / "assets/graphics/arenas/arena_do_dique_v01"
MAP_BASE = ROOT / "assets/graphics/world/baixo_sul_map_v01"
HUB_BASE = ROOT / "assets/graphics/hubs/terreiro_da_luta_v01"
MAP_DATA = ROOT / "data/visual/world_map_art_v01.json"
CANONICAL_HUBS = {"itubera", "zambiapunga", "camamu_manguezal", "salvador"}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def check_file(path: Path, label: str, errors: list[str]) -> bool:
    if not path.is_file():
        errors.append(f"{label}: ausente: {path.relative_to(ROOT)}")
        return False
    return True


def check_image(
    path: Path,
    expected_size: tuple[int, int],
    expected_hash: str,
    label: str,
    errors: list[str],
) -> None:
    if not check_file(path, label, errors):
        return
    with Image.open(path) as image:
        if image.size != expected_size:
            errors.append(f"{label}: resolução {image.size}; esperada {expected_size}")
    if sha256(path) != expected_hash:
        errors.append(f"{label}: SHA-256 divergente")


def validate_arena(errors: list[str]) -> None:
    manifest_path = ARENA_BASE / "manifest.json"
    if not check_file(manifest_path, "arena/manifest", errors):
        return
    manifest = load_json(manifest_path)
    if manifest.get("arena_id") != "arena_do_dique":
        errors.append("arena: arena_id não canônico")
    if manifest.get("candidate_only") is not True:
        errors.append("arena: gate de candidato artístico foi removido antes do teste")
    canvas = tuple(manifest.get("canvas", []))
    if canvas != (1920, 1080):
        errors.append(f"arena: canvas inválido {canvas}")
    source = ROOT / str(manifest.get("source", ""))
    if check_file(source, "arena/source", errors) and sha256(source) != manifest.get("source_sha256"):
        errors.append("arena/source: SHA-256 divergente")
    for layer in manifest.get("layers", []):
        check_image(
            ARENA_BASE / str(layer.get("path", "")),
            (1920, 1080),
            str(layer.get("sha256", "")),
            f"arena/layer/{layer.get('id', '')}",
            errors,
        )
    check_image(
        ARENA_BASE / str(manifest.get("occlusion_map", "")),
        (1920, 1080),
        str(manifest.get("occlusion_map_sha256", "")),
        "arena/occlusion",
        errors,
    )
    check_image(
        ARENA_BASE / str(manifest.get("preview", "")),
        (1280, 720),
        str(manifest.get("preview_sha256", "")),
        "arena/preview",
        errors,
    )
    for required in (
        "collision_map.json",
        "lighting_profile.tres",
        "ambience_profile.json",
        "source_notes.md",
        "qa_report.md",
    ):
        check_file(ARENA_BASE / required, f"arena/{required}", errors)
    collision = load_json(ARENA_BASE / "collision_map.json")
    points = collision.get("playable_polygon", [])
    if len(points) < 4 or any(len(point) != 2 for point in points):
        errors.append("arena/collision: polígono jogável inválido")
    for point in points:
        if any(not 0.0 <= float(value) <= 1.0 for value in point):
            errors.append("arena/collision: coordenada fora de 0..1")


def validate_world_map(errors: list[str]) -> None:
    manifest_path = MAP_BASE / "manifest.json"
    if not check_file(manifest_path, "mapa/manifest", errors):
        return
    manifest = load_json(manifest_path)
    mapping = load_json(MAP_DATA)
    if manifest.get("map_id") != mapping.get("map_id"):
        errors.append("mapa: map_id diverge entre arte e dados")
    if manifest.get("world_model") != "semi_open_dense_hubs":
        errors.append("mapa: modelo deve permanecer semiaberto com hubs densos")
    if manifest.get("candidate_only") is not True:
        errors.append("mapa: gate de candidato foi removido antes da revisão geográfica")
    source = ROOT / str(manifest.get("source", ""))
    if check_file(source, "mapa/source", errors) and sha256(source) != manifest.get("source_sha256"):
        errors.append("mapa/source: SHA-256 divergente")
    check_image(
        MAP_BASE / str(manifest.get("image", "")),
        (1920, 1080),
        str(manifest.get("image_sha256", "")),
        "mapa/plate",
        errors,
    )
    check_image(
        MAP_BASE / str(manifest.get("preview", "")),
        (1280, 720),
        str(manifest.get("preview_sha256", "")),
        "mapa/preview",
        errors,
    )
    check_file(MAP_BASE / "source_notes.md", "mapa/source_notes", errors)
    nodes = mapping.get("node_positions", {})
    if set(nodes) != CANONICAL_HUBS:
        errors.append(f"mapa: hubs divergentes: {sorted(nodes)}")
    for hub_id, position in nodes.items():
        if len(position) != 2 or any(not 0.0 <= float(value) <= 1.0 for value in position):
            errors.append(f"mapa/{hub_id}: posição normalizada inválida")
    for route in mapping.get("route_pairs", []):
        if len(route) != 2 or any(hub_id not in nodes for hub_id in route):
            errors.append(f"mapa: rota inválida {route}")


def validate_terreiro(errors: list[str]) -> None:
    manifest_path = HUB_BASE / "manifest.json"
    if not check_file(manifest_path, "terreiro/manifest", errors):
        return
    manifest = load_json(manifest_path)
    if manifest.get("hub_id") != "terreiro_da_luta":
        errors.append("terreiro: hub_id inválido")
    if manifest.get("candidate_only") is not True:
        errors.append("terreiro: gate de candidato foi removido antes do teste")
    source = ROOT / str(manifest.get("source", ""))
    if check_file(source, "terreiro/source", errors) and sha256(source) != manifest.get("source_sha256"):
        errors.append("terreiro/source: SHA-256 divergente")
    check_image(
        HUB_BASE / str(manifest.get("image", "")),
        (1920, 1080),
        str(manifest.get("image_sha256", "")),
        "terreiro/environment",
        errors,
    )
    check_image(
        HUB_BASE / str(manifest.get("preview", "")),
        (1280, 720),
        str(manifest.get("preview_sha256", "")),
        "terreiro/preview",
        errors,
    )
    for required in ("collision_map.json", "source_notes.md", "qa_report.md"):
        check_file(HUB_BASE / required, f"terreiro/{required}", errors)
    collision = load_json(HUB_BASE / "collision_map.json")
    points = collision.get("walkable_polygon", [])
    if len(points) < 4:
        errors.append("terreiro/collision: área caminhável incompleta")
    for point in points:
        if len(point) != 2 or any(not 0.0 <= float(value) <= 1.0 for value in point):
            errors.append("terreiro/collision: coordenada inválida")
    anchors = collision.get("interaction_anchors", {})
    if not {"mestre_dende", "tinker_bell", "tatame_training"}.issubset(anchors):
        errors.append("terreiro/collision: âncoras narrativas obrigatórias ausentes")


def main() -> int:
    errors: list[str] = []
    if not MAP_DATA.is_file():
        errors.append("data/visual/world_map_art_v01.json ausente")
    else:
        validate_arena(errors)
        validate_world_map(errors)
        validate_terreiro(errors)
    if errors:
        for error in errors:
            print(f"ERRO: {error}")
        print(f"Visuais de mundo reprovados: {len(errors)} problema(s).")
        return 1
    print("Visuais de mundo aprovados: Arena do Dique, Terreiro e mapa íntegros; gates preservados.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
