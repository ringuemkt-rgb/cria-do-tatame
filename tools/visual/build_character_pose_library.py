#!/usr/bin/env python3
"""Extrai e normaliza key poses canônicas geradas em folhas cromáticas.

O script não promove nenhuma pose para o runtime. Ele produz fontes RGBA
reprodutíveis, hashes e pranchas de QA para que a animação possa ser feita e
testada no Godot sem perder identidade, escala ou rastreabilidade.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from collections import deque
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageDraw

from chroma_key_asset import remove_chroma
from normalize_sprite_strip_to_anchor import alpha_bbox, keep_largest_alpha_component


ROOT = Path(__file__).resolve().parents[2]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Constrói a biblioteca RGBA de key poses.")
    parser.add_argument(
        "--catalog",
        default="data/visual/character_action_pose_catalog_v01.json",
        help="Catálogo relativo à raiz do repositório.",
    )
    parser.add_argument("--pose-size", type=int, default=512)
    parser.add_argument("--margin", type=int, default=20)
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def checker(size: tuple[int, int], cell: int = 24) -> Image.Image:
    image = Image.new("RGBA", size, (232, 235, 238, 255))
    draw = ImageDraw.Draw(image)
    colors = ((232, 235, 238, 255), (207, 213, 219, 255))
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            draw.rectangle(
                (x, y, min(size[0], x + cell), min(size[1], y + cell)),
                fill=colors[((x // cell) + (y // cell)) % 2],
            )
    return image


def grid_crop(
    image: Image.Image,
    index: int,
    columns: int,
    rows: int,
    overlap_ratio: float = 0.08,
    isolate_component: bool = True,
) -> Image.Image:
    """Recorta uma célula e, quando pedido, isola a pose central.

    Folhas individuais usam isolamento para rejeitar vazamentos entre células.
    Sequências pareadas preservam todos os componentes da célula, pois os dois
    lutadores podem estar separados em estados como distância e reset.
    """
    column = index % columns
    row = index // columns
    cell_width = image.width / columns
    cell_height = image.height / rows
    overlap_x = round(cell_width * overlap_ratio)
    overlap_y = round(cell_height * overlap_ratio)
    left = max(0, round(column * cell_width) - overlap_x)
    top = max(0, round(row * cell_height) - overlap_y)
    right = min(image.width, round((column + 1) * cell_width) + overlap_x)
    bottom = min(image.height, round((row + 1) * cell_height) + overlap_y)
    cropped = image.crop((left, top, right, bottom))
    if not isolate_component:
        return cropped
    return keep_largest_alpha_component(cropped, 8)


def normalize_pose(source: Image.Image, size: int, margin: int) -> Image.Image:
    box = alpha_bbox(source, 8)
    if box is None:
        raise ValueError("Célula sem conteúdo alfa.")
    content = source.crop(box)
    available = size - 2 * margin
    scale = min(available / content.width, available / content.height)
    width = max(1, round(content.width * scale))
    height = max(1, round(content.height * scale))
    resized = content.resize((width, height), Image.Resampling.NEAREST)
    output = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    output.alpha_composite(resized, (round((size - width) / 2), size - margin - height))
    return output


def keep_significant_alpha_components(
    image: Image.Image,
    threshold: int = 8,
    max_components: int = 2,
    min_relative_area: float = 0.15,
) -> Image.Image:
    """Mantém um par separado e remove fragmentos vazados de células vizinhas."""
    rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    mask = rgba[:, :, 3] > threshold
    visited = np.zeros(mask.shape, dtype=bool)
    components: list[list[tuple[int, int]]] = []
    height, width = mask.shape
    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            queue: deque[tuple[int, int]] = deque([(y, x)])
            visited[y, x] = True
            component: list[tuple[int, int]] = []
            while queue:
                cy, cx = queue.popleft()
                component.append((cy, cx))
                for ny in range(max(0, cy - 1), min(height, cy + 2)):
                    for nx in range(max(0, cx - 1), min(width, cx + 2)):
                        if mask[ny, nx] and not visited[ny, nx]:
                            visited[ny, nx] = True
                            queue.append((ny, nx))
            components.append(component)
    if not components:
        return Image.fromarray(rgba, mode="RGBA")
    components.sort(key=len, reverse=True)
    minimum = len(components[0]) * min_relative_area
    selected = [
        component
        for component in components[:max_components]
        if len(component) >= minimum
    ]
    keep = np.zeros(mask.shape, dtype=bool)
    for component in selected:
        ys, xs = zip(*component)
        keep[np.asarray(ys), np.asarray(xs)] = True
    rgba[~keep] = 0
    return Image.fromarray(rgba, mode="RGBA")


def build_contact_sheet(
    poses: list[tuple[str, Image.Image]],
    pose_size: int,
    columns: int = 3,
) -> Image.Image:
    rows = math.ceil(len(poses) / columns)
    label_height = 32
    gap = 12
    width = columns * pose_size + (columns - 1) * gap
    height = rows * (pose_size + label_height) + (rows - 1) * gap
    board = Image.new("RGBA", (width, height), (18, 20, 24, 255))
    draw = ImageDraw.Draw(board)
    for index, (action_id, pose) in enumerate(poses):
        x = (index % columns) * (pose_size + gap)
        y = (index // columns) * (pose_size + label_height + gap)
        tile = checker((pose_size, pose_size))
        tile.alpha_composite(pose)
        board.alpha_composite(tile, (x, y))
        draw.text((x + 8, y + pose_size + 8), action_id, fill=(242, 242, 242, 255))
    return board


def build_character(entry: dict[str, Any], pose_size: int, margin: int) -> dict[str, Any]:
    character_id = str(entry["character_id"])
    source_path = ROOT / str(entry["source_sheet"])
    if not source_path.is_file():
        raise FileNotFoundError(source_path)
    clean = remove_chroma(Image.open(source_path), str(entry["key"]), 15)
    output_dir = ROOT / "assets" / "graphics" / "characters" / character_id / "action_poses_v01"
    poses_dir = output_dir / "poses"
    poses_dir.mkdir(parents=True, exist_ok=True)
    clean_path = output_dir / "clean_source_sheet.png"
    clean.save(clean_path, optimize=True)

    columns = int(entry["grid"]["columns"])
    rows = int(entry["grid"]["rows"])
    actions = list(entry["actions"])
    if len(actions) > columns * rows:
        raise ValueError(f"{character_id}: ações excedem a grade declarada")

    built: list[tuple[str, Image.Image]] = []
    manifest_actions: list[dict[str, Any]] = []
    for index, action in enumerate(actions):
        action_id = str(action["id"])
        cell = grid_crop(clean, index, columns, rows)
        pose = normalize_pose(cell, pose_size, margin)
        pose_path = poses_dir / f"{action_id}.png"
        pose.save(pose_path, optimize=True)
        box = alpha_bbox(pose, 8)
        if box is None:
            raise ValueError(f"{character_id}/{action_id}: pose vazia")
        built.append((action_id, pose))
        manifest_actions.append(
            {
                "id": action_id,
                "path": pose_path.relative_to(ROOT).as_posix(),
                "sha256": sha256(pose_path),
                "alpha_bbox": list(box),
                "runtime_aliases": list(action.get("runtime_aliases", [])),
                "status": "source_pose_asset_qa_passed_runtime_animation_pending",
            }
        )

    contact_path = output_dir / "contact_sheet.png"
    build_contact_sheet(built, pose_size).save(contact_path, optimize=True)
    manifest = {
        "version": "1.0.0",
        "character_id": character_id,
        "source_sheet": source_path.relative_to(ROOT).as_posix(),
        "source_sha256": sha256(source_path),
        "clean_source_sheet": clean_path.relative_to(ROOT).as_posix(),
        "clean_source_sha256": sha256(clean_path),
        "pose_size": [pose_size, pose_size],
        "anchor": "bottom_center",
        "action_count": len(manifest_actions),
        "actions": manifest_actions,
        "contact_sheet": contact_path.relative_to(ROOT).as_posix(),
        "contact_sheet_sha256": sha256(contact_path),
        "runtime_status": "source_only_until_godot_gate",
    }
    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output_dir / "source_notes.md").write_text(
        "# Fonte das poses\n\n"
        "Folha gerada pela ferramenta de imagem integrada da OpenAI usando apenas a "
        "folha-modelo e o seed canônicos do próprio projeto. O chroma foi removido "
        "deterministicamente; cada pose foi isolada e normalizada para 512x512 RGBA.\n\n"
        "Estas imagens são key poses de produção. Não são spritesheets finais e não "
        "podem substituir placeholders antes da animação e do teste no Godot 4.2+.\n",
        encoding="utf-8",
    )
    return manifest


def build_paired_sequence(entry: dict[str, Any], pose_size: int, margin: int) -> dict[str, Any]:
    sequence_id = str(entry["id"])
    source_path = ROOT / str(entry["source_sheet"])
    clean = remove_chroma(Image.open(source_path), str(entry["key"]), 15)
    output_dir = ROOT / "assets" / "graphics" / "characters" / "paired" / sequence_id
    poses_dir = output_dir / "keys"
    poses_dir.mkdir(parents=True, exist_ok=True)
    clean_path = output_dir / "clean_source_sheet.png"
    clean.save(clean_path, optimize=True)
    columns = int(entry["grid"]["columns"])
    rows = int(entry["grid"]["rows"])
    built: list[tuple[str, Image.Image]] = []
    states: list[dict[str, Any]] = []
    for index, state_value in enumerate(entry["states"]):
        state = str(state_value)
        cell = grid_crop(
            clean,
            index,
            columns,
            rows,
            overlap_ratio=0.0,
            isolate_component=False,
        )
        separated_pair = state in {"distancia_media", "reset"}
        cell = keep_significant_alpha_components(
            cell,
            max_components=2 if separated_pair else 1,
        )
        pose = normalize_pose(cell, pose_size, margin)
        path = poses_dir / f"{index + 1:02d}_{state}.png"
        pose.save(path, optimize=True)
        box = alpha_bbox(pose, 8)
        if box is None:
            raise ValueError(f"{sequence_id}/{state}: key pose vazia")
        built.append((state, pose))
        states.append(
            {
                "index": index,
                "state": state,
                "path": path.relative_to(ROOT).as_posix(),
                "sha256": sha256(path),
                "alpha_bbox": list(box),
            }
        )
    contact_path = output_dir / "contact_sheet.png"
    build_contact_sheet(built, pose_size, columns=4).save(contact_path, optimize=True)
    manifest = {
        "version": "1.0.0",
        "sequence_id": sequence_id,
        "characters": list(entry["characters"]),
        "source_sheet": source_path.relative_to(ROOT).as_posix(),
        "source_sha256": sha256(source_path),
        "clean_source_sheet": clean_path.relative_to(ROOT).as_posix(),
        "clean_source_sha256": sha256(clean_path),
        "pose_size": [pose_size, pose_size],
        "states": states,
        "contact_sheet": contact_path.relative_to(ROOT).as_posix(),
        "contact_sheet_sha256": sha256(contact_path),
        "runtime_status": "biomechanical_key_source_runtime_animation_pending",
    }
    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output_dir / "source_notes.md").write_text(
        "# Sequência pareada Ruan × Davi\n\n"
        "Sete key poses geradas conjuntamente pela ferramenta de imagem integrada da "
        "OpenAI, usando somente folhas-modelo e seeds canônicos do projeto. O recorte "
        "preserva dois componentes nos estados separados (`distancia_media` e `reset`) "
        "e um componente conectado nas fases de contato.\n\n"
        "A sequência comunica biomecânica e eventos do vertical slice, mas ainda exige "
        "frames intermediários, composição no atlas e teste mecânico no Godot 4.2+.\n",
        encoding="utf-8",
    )
    return manifest


def main() -> None:
    args = parse_args()
    if args.pose_size < 64:
        raise SystemExit("--pose-size deve ser no mínimo 64")
    if args.margin < 0 or args.margin * 2 >= args.pose_size:
        raise SystemExit("--margin inválido")
    catalog_path = ROOT / args.catalog
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    characters = [
        build_character(entry, args.pose_size, args.margin)
        for entry in catalog["characters"]
    ]
    paired = [
        build_paired_sequence(entry, args.pose_size, args.margin)
        for entry in catalog.get("paired_sequences", [])
    ]
    output = {
        "ok": True,
        "character_count": len(characters),
        "pose_count": sum(int(item["action_count"]) for item in characters),
        "paired_sequence_count": len(paired),
        "paired_key_count": sum(len(item["states"]) for item in paired),
    }
    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
