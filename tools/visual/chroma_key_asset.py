#!/usr/bin/env python3
"""Converte fonte com chroma plano em PNG RGBA limpo e reproduzivel."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Remove chroma verde ou ciano de um asset.")
    parser.add_argument("input", help="PNG RGB/RGBA com fundo cromatico plano.")
    parser.add_argument("output", help="PNG RGBA de saida.")
    parser.add_argument("--key", choices=("green", "cyan"), default="green")
    parser.add_argument(
        "--threshold",
        type=int,
        default=15,
        help="Diferenca minima entre canais para classificar o chroma.",
    )
    parser.add_argument("--size", type=int, help="Redimensiona para um quadrado NxN.")
    return parser.parse_args()


def remove_chroma(image: Image.Image, key: str, threshold: int) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    rgb = rgba[:, :, :3].astype(np.int16)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    if key == "green":
        chroma = ((green - red) > threshold) & ((green - blue) > threshold)
        spill = green > np.maximum(red, blue)
        rgba[:, :, 1] = np.where(spill, np.maximum(red, blue), green).astype(np.uint8)
    else:
        chroma = ((green - red) > threshold) & ((blue - red) > threshold)
        spill = (green > red) & (blue > red)
        rgba[:, :, 1] = np.where(spill, red, green).astype(np.uint8)
        rgba[:, :, 2] = np.where(spill, red, blue).astype(np.uint8)

    rgba[:, :, 3] = np.where(chroma, 0, rgba[:, :, 3]).astype(np.uint8)
    rgba[chroma, :3] = 0
    return Image.fromarray(rgba, mode="RGBA")


def main() -> None:
    args = parse_args()
    if not 0 <= args.threshold <= 255:
        raise SystemExit("--threshold deve estar entre 0 e 255")
    if args.size is not None and args.size < 1:
        raise SystemExit("--size deve ser maior que zero")

    output = remove_chroma(Image.open(args.input), args.key, args.threshold)
    if args.size is not None:
        output = output.resize((args.size, args.size), Image.Resampling.NEAREST)

    # Fontes aprovadas devem deixar os quatro cantos completamente transparentes.
    corners = (
        output.getpixel((0, 0))[3],
        output.getpixel((output.width - 1, 0))[3],
        output.getpixel((0, output.height - 1))[3],
        output.getpixel((output.width - 1, output.height - 1))[3],
    )
    if any(corners):
        raise SystemExit(f"Chroma incompleto: alpha dos cantos={corners}")

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path, optimize=True)
    print(f"Asset RGBA gerado: {output_path} ({output.width}x{output.height})")


if __name__ == "__main__":
    main()
