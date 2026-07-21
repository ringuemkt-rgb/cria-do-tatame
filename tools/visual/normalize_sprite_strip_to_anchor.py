#!/usr/bin/env python3
"""Normaliza uma tira de sprites pela escala e pelo pivô de um seed aprovado.

O normalizador genérico do pipeline preenche o quadro disponível. Para personagens,
isso pode fazer os quadros gerados parecerem maiores que o seed já aprovado. Este
utilitário usa a caixa alfa do seed como autoridade de escala, centro e linha do
chão, preservando o primeiro quadro exatamente quando solicitado.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Normaliza uma tira horizontal usando um seed como ancora visual."
    )
    parser.add_argument("--input", required=True, help="Tira PNG RGBA de entrada.")
    parser.add_argument("--anchor", required=True, help="Seed PNG RGBA aprovado.")
    parser.add_argument("--out-dir", required=True, help="Diretorio dos quadros finais.")
    parser.add_argument("--frames", required=True, type=int, help="Quantidade de quadros.")
    parser.add_argument("--frame-size", type=int, default=256, help="Lado do quadro final.")
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=8,
        help="Alpha minimo considerado conteudo visivel.",
    )
    parser.add_argument(
        "--lock-frame1",
        action="store_true",
        help="Mantem o seed aprovado exatamente como primeiro quadro.",
    )
    return parser.parse_args()


def alpha_bbox(image: Image.Image, threshold: int) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
    return alpha.getbbox()


def keep_largest_alpha_component(image: Image.Image, threshold: int = 8) -> Image.Image:
    """Mantem o corpo conectado principal e remove vazamentos de slots vizinhos.

    O componente principal e identificado pelo pixel opaco mais proximo do centro
    do slot, ponto que pertence ao torso em todas as poses aprovadas. O flood-fill
    puro evita depender de OpenCV no ambiente de producao.
    """
    rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    mask = rgba[:, :, 3] > threshold
    opaque = np.argwhere(mask)
    if opaque.size == 0:
        return Image.fromarray(rgba, mode="RGBA")
    center = np.array([image.height / 2.0, image.width / 2.0])
    distances = np.sum((opaque - center) ** 2, axis=1)
    start_y, start_x = opaque[int(np.argmin(distances))]

    keep = np.zeros(mask.shape, dtype=bool)
    queue: deque[tuple[int, int]] = deque([(int(start_y), int(start_x))])
    keep[start_y, start_x] = True
    while queue:
        y, x = queue.popleft()
        for ny in range(max(0, y - 1), min(image.height, y + 2)):
            for nx in range(max(0, x - 1), min(image.width, x + 2)):
                if mask[ny, nx] and not keep[ny, nx]:
                    keep[ny, nx] = True
                    queue.append((ny, nx))

    rgba[~keep] = 0
    return Image.fromarray(rgba, mode="RGBA")


def split_horizontal(strip: Image.Image, frame_count: int) -> list[Image.Image]:
    if frame_count < 1:
        raise ValueError("--frames deve ser maior que zero")
    step = strip.width / frame_count
    return [
        strip.crop(
            (
                round(index * step),
                0,
                round((index + 1) * step),
                strip.height,
            )
        )
        for index in range(frame_count)
    ]


def main() -> None:
    args = parse_args()
    if args.frame_size < 1:
        raise SystemExit("--frame-size deve ser maior que zero")

    strip = Image.open(args.input).convert("RGBA")
    anchor = Image.open(args.anchor).convert("RGBA")
    if anchor.size != (args.frame_size, args.frame_size):
        raise SystemExit(
            f"Seed deve medir {args.frame_size}x{args.frame_size}; recebido {anchor.size}."
        )

    anchor_box = alpha_bbox(anchor, args.alpha_threshold)
    if anchor_box is None:
        raise SystemExit("Seed nao possui conteudo alfa visivel.")

    slots = split_horizontal(strip, args.frames)
    contents: list[Image.Image | None] = []
    for slot in slots:
        slot = keep_largest_alpha_component(slot, args.alpha_threshold)
        box = alpha_bbox(slot, args.alpha_threshold)
        contents.append(slot.crop(box) if box is not None else None)

    visible = [content for content in contents if content is not None]
    if not visible:
        raise SystemExit("Nenhum sprite foi detectado na tira de entrada.")

    anchor_height = anchor_box[3] - anchor_box[1]
    max_width = max(content.width for content in visible)
    max_height = max(content.height for content in visible)
    anchor_center_x = (anchor_box[0] + anchor_box[2]) / 2.0
    anchor_ground_y = anchor_box[3]
    available_width = 2.0 * min(anchor_center_x, args.frame_size - anchor_center_x)
    # A altura corporal governa a escala. A largura so limita quando o gesto
    # realmente ultrapassaria o canvas; mãos abertas não devem encolher o corpo.
    shared_scale = min(anchor_height / max_height, available_width / max_width)

    # O centro e a linha do chao do seed sao o contrato de alinhamento.
    output_dir = Path(args.out_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for index, content in enumerate(contents, start=1):
        if index == 1 and args.lock_frame1:
            frame = anchor.copy()
        else:
            frame = Image.new("RGBA", (args.frame_size, args.frame_size), (0, 0, 0, 0))
            if content is not None:
                width = max(1, round(content.width * shared_scale))
                height = max(1, round(content.height * shared_scale))
                resized = content.resize((width, height), Image.Resampling.NEAREST)
                left = round(anchor_center_x - width / 2.0)
                top = round(anchor_ground_y - height)
                frame.alpha_composite(resized, (left, top))
        frame.save(output_dir / f"{index:02d}.png", optimize=True)

    print(
        "Sprite strip normalizado: "
        f"frames={args.frames}, escala={shared_scale:.4f}, "
        f"pivo=({anchor_center_x:.1f},{anchor_ground_y})"
    )


if __name__ == "__main__":
    main()
