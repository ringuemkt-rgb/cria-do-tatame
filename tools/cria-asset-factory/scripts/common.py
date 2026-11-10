"""Deterministic candidate-only operations. Never authorizes shipping."""
from __future__ import annotations
import hashlib
import json
import re
import shutil
from pathlib import Path

from PIL import Image

SIZE = (128, 128)
PIVOT = [64, 96]
FPS = 12
BASE_PALETTE = (
    "#0B0B0D", "#C9971C", "#EDE6D6", "#1E3A5F", "#2D5016",
    "#B85C38", "#D4A574", "#8B0000", "#4B0082",
)
FACTIONS = {"ALE": "#FF9408", "LEM": "#4A6741", "NTM": "#3FE3F5"}
PHASES = ("anticipation", "entry", "establish", "stabilize", "response", "recovery")
CHARACTERS = {"ruan_macacao", "davi_relampago", "mestre_dende", "cassio_molho",
              "jacare_mangue", "oni_da_lapa", "delegado_montenegro"}
ANIMATIONS = {"idle_combat", "walk", "dash", "guard", "hit_light", "hit_medium",
              "hit_heavy", "clinch", "ground_top", "ground_bottom", "victory",
              "defeat", "world_idle"}
IDENT = re.compile(r"^[a-z][a-z0-9_]*$")


def safe_id(value: str) -> str:
    if not IDENT.fullmatch(value):
        raise ValueError(f"invalid snake_case ID: {value!r}")
    return value


def output_dir(path: Path) -> Path:
    path = Path(path).expanduser().resolve()
    if path == Path(path.anchor) or path == Path.home().resolve():
        raise ValueError("refusing broad output path")
    if path.exists() and any(path.iterdir()):
        raise FileExistsError(f"output directory must be empty: {path}")
    path.mkdir(parents=True, exist_ok=True)
    return path


def json_write(path: Path, value: dict) -> None:
    if value.get("shipping") is not False:
        raise ValueError("only shipping=false candidates may be written")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read(path: Path) -> dict:
    result = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(result, dict):
        raise ValueError(f"JSON must contain object: {path}")
    return result


def candidate(kind: str, **extra) -> dict:
    result = {
        "schema": "cria.asset_factory.candidate.v1",
        "kind": kind,
        "shipping": False,
        "qa_status": "pending",
        "human_approved": False,
        "scene_verified": False,
        "gameplay_authority": False,
        "pivot": PIVOT[:],
    }
    result.update(extra)
    if result.get("shipping") is not False:
        raise ValueError("shipping cannot be enabled")
    return result


def pngs(folder: Path) -> list[Path]:
    result = sorted(Path(folder).glob("*.png"))
    if not result:
        raise ValueError(f"no source PNG frames: {folder}")
    return result


def rgb_palette(faction: str | None = None) -> list[tuple[int, int, int]]:
    if faction and faction not in FACTIONS:
        raise ValueError(f"unknown faction {faction}")
    colors = list(BASE_PALETTE) + ([FACTIONS[faction]] if faction else [])
    return [tuple(bytes.fromhex(x[1:])) for x in colors]


def snap(source: Image.Image, faction: str | None = None) -> Image.Image:
    colors = rgb_palette(faction)
    rgba = source.convert("RGBA")
    out = Image.new("RGBA", rgba.size)
    lut: dict[tuple[int, int, int], tuple[int, int, int]] = {}
    pixels = []
    for r, g, b, a in rgba.getdata():
        if a < 128:
            pixels.append((0, 0, 0, 0))
            continue
        rgb = (r, g, b)
        if rgb not in lut:
            lut[rgb] = min(colors, key=lambda c: sum((c[i] - rgb[i]) ** 2 for i in range(3)))
        pixels.append((*lut[rgb], 255))
    out.putdata(pixels)
    return out


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sidecars(png: Path, origin: str, license_id: str) -> None:
    shared = {"shipping": False, "qa_status": "pending", "asset_sha256": sha(png)}
    json_write(png.with_suffix(".license.json"), {
        **shared, "license_id": license_id, "rights_reviewed": False,
        "commercial_use_cleared": False,
    })
    json_write(png.with_suffix(".provenance.json"), {
        **shared, "source": origin, "source_evidence": "PENDING_REVIEW",
    })
    json_write(png.with_suffix(".qa.json"), {
        **shared, "pivot": PIVOT[:], "human_approved": False,
        "scene_verified": False,
    })


def copy_frame(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
