from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "cosmetics" / "nft"
CATALOG = ROOT / "data" / "nft" / "nft_catalog_v01.json"
SIZE = 512

ASSETS = {
    "rashguard_gorila_prata.png": ((12, 15, 20, 255), (205, 212, 222, 255), "gorilla"),
    "patch_terreiro_raiz.png": ((25, 17, 9, 255), (212, 175, 55, 255), "root"),
    "mural_tinker_analista.png": ((10, 20, 34, 255), (105, 183, 255, 255), "eye"),
    "poster_arena_dique.png": ((35, 14, 14, 255), (220, 59, 50, 255), "arena"),
}


def chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)


def write_png(path: Path, pixels: bytearray) -> None:
    stride = SIZE * 4
    raw = b"".join(b"\x00" + bytes(pixels[y * stride:(y + 1) * stride]) for y in range(SIZE))
    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def paint_asset(path: Path, background: tuple[int, int, int, int], accent: tuple[int, int, int, int], motif: str) -> None:
    pixels = bytearray(background * (SIZE * SIZE))

    def set_pixel(x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if 0 <= x < SIZE and 0 <= y < SIZE:
            index = (y * SIZE + x) * 4
            pixels[index:index + 4] = bytes(color)

    def rectangle(x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int, int]) -> None:
        for y in range(max(0, y0), min(SIZE, y1)):
            for x in range(max(0, x0), min(SIZE, x1)):
                set_pixel(x, y, color)

    def circle(cx: int, cy: int, radius: int, color: tuple[int, int, int, int], inner: int = 0) -> None:
        outer2 = radius * radius
        inner2 = inner * inner
        for y in range(cy - radius, cy + radius + 1):
            for x in range(cx - radius, cx + radius + 1):
                distance = (x - cx) ** 2 + (y - cy) ** 2
                if inner2 <= distance <= outer2:
                    set_pixel(x, y, color)

    rectangle(20, 20, 492, 32, accent)
    rectangle(20, 480, 492, 492, accent)
    rectangle(20, 20, 32, 492, accent)
    rectangle(480, 20, 492, 492, accent)
    circle(256, 220, 126, accent, 110)

    if motif == "gorilla":
        circle(256, 215, 82, accent)
        circle(223, 195, 15, background)
        circle(289, 195, 15, background)
        rectangle(220, 248, 292, 264, background)
        rectangle(155, 366, 357, 392, accent)
    elif motif == "root":
        rectangle(248, 105, 264, 335, accent)
        for offset in (42, 78, 112):
            for step in range(70):
                set_pixel(256 - step, 170 + offset + step // 2, accent)
                set_pixel(256 + step, 170 + offset + step // 2, accent)
        rectangle(154, 370, 358, 394, accent)
    elif motif == "eye":
        for x in range(125, 388):
            half = int(72 * (1.0 - abs(x - 256) / 132.0))
            for thickness in range(8):
                set_pixel(x, 220 - half + thickness, accent)
                set_pixel(x, 220 + half - thickness, accent)
        circle(256, 220, 48, accent)
        circle(256, 220, 18, background)
        rectangle(140, 370, 372, 394, accent)
    else:
        circle(256, 230, 125, accent, 110)
        rectangle(180, 180, 332, 292, accent)
        rectangle(194, 194, 318, 278, background)
        rectangle(248, 180, 264, 292, accent)
        rectangle(180, 228, 332, 244, accent)
        rectangle(126, 370, 386, 394, accent)

    write_png(path, pixels)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for filename, (background, accent, motif) in ASSETS.items():
        paint_asset(OUT / filename, background, accent, motif)
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    for item in catalog.get("items", []):
        asset_path = str(item.get("asset_path", ""))
        if asset_path.endswith(".svg"):
            item["asset_path"] = asset_path.removesuffix(".svg") + ".png"
    catalog["version"] = "1.0.2"
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for path in sorted(OUT.glob("*.png")):
        print(path.relative_to(ROOT), path.stat().st_size)


if __name__ == "__main__":
    main()
