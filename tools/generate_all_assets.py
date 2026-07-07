#!/usr/bin/env python3
"""CRIA DO TATAME - Sistema completo de geracao de assets.

Canon: Ruan "Macacao" Silva.
Estilo: HD Pixel Art 2.5D Regional Premium.

A credencial e lida por HF_TOKEN no ambiente local ou .env nao versionado.
O script nunca imprime nem grava token.
"""

from __future__ import annotations

import argparse
import json
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

from dotenv import load_dotenv
from PIL import Image, ImageEnhance

try:
    from huggingface_hub import InferenceClient
except Exception:  # pragma: no cover
    InferenceClient = None

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUT = ROOT / "assets"
NEGATIVE_PROMPT = (
    "blurry, low quality, distorted anatomy, extra limbs, unreadable silhouette, "
    "random text, watermark, real brand, real team logo, real athlete, Caio Ravel, Ravel brand"
)


@dataclass
class AssetModelConfig:
    pixel_art: str = "nerijs/pixel-art-xl"
    spritesheet: str = "Onodofthenorth/SD_PixelArt_SpriteSheet_Generator"
    music: str = "facebook/musicgen-small"
    sfx: str = "stabilityai/stable-audio-open-1.0"


class CriaTatameAssetGenerator:
    def __init__(self, output_dir: Path, dry_run: bool = False, delay: float = 1.0):
        load_dotenv(ROOT / ".env")
        self.output_dir = output_dir
        self.dry_run = dry_run
        self.delay = delay
        self.models = AssetModelConfig()
        self.token = os.getenv("HF_TOKEN", "")
        self.client = InferenceClient(token=self.token) if InferenceClient and self.token and not dry_run else None
        self.style = {
            "background": "#0A0A0A",
            "panel": "#1A1A1A",
            "gold": "#B8860B",
            "white": "#F2F2F2",
            "red": "#D92323",
            "blue": "#1E3A5F",
        }
        self._ensure_dirs()

    def _ensure_dirs(self) -> None:
        for rel in ["sprites", "backgrounds", "ui", "audio/music", "audio/sfx", "generated_metadata"]:
            (self.output_dir / rel).mkdir(parents=True, exist_ok=True)

    def _read_json(self, path: Path) -> Dict[str, Any]:
        if not path.exists():
            return {}
        return json.loads(path.read_text(encoding="utf-8"))

    def _write_metadata(self, asset_id: str, payload: Dict[str, Any]) -> Path:
        safe = asset_id.replace("/", "__").replace(" ", "_")
        path = self.output_dir / "generated_metadata" / f"{safe}.json"
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        return path

    def build_style_prompt(self) -> str:
        return (
            "HD pixel art 2.5D, professional mobile game asset, Baixo Sul da Bahia identity, "
            f"dark premium background {self.style['background']}, burned gold accents {self.style['gold']}, "
            "clean silhouette, high contrast, game-ready, original fictional universe"
        )

    def generate_pixel_art(self, prompt: str, output_path: Path, width: int = 1024, height: int = 1024, downscale: int = 4) -> bool:
        full_prompt = f"{prompt}, {self.build_style_prompt()}"
        metadata = {"prompt": full_prompt, "negative_prompt": NEGATIVE_PROMPT, "width": width, "height": height, "output": str(output_path)}
        if self.dry_run or self.client is None:
            self._write_metadata(str(output_path), {**metadata, "mode": "dry_run"})
            return False
        try:
            image = self.client.text_to_image(
                prompt=full_prompt,
                model=self.models.pixel_art,
                negative_prompt=NEGATIVE_PROMPT,
                width=width,
                height=height,
                guidance_scale=7.5,
                num_inference_steps=30,
            )
            if downscale > 1:
                image = image.resize((max(1, width // downscale), max(1, height // downscale)), Image.Resampling.NEAREST)
            image = ImageEnhance.Contrast(image).enhance(1.15)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            image.save(output_path, format="PNG")
            self._write_metadata(str(output_path), {**metadata, "mode": "generated"})
            return True
        except Exception as exc:
            self._write_metadata(str(output_path), {**metadata, "mode": "failed", "error": str(exc)})
            return False

    def canonical_characters(self) -> List[Dict[str, Any]]:
        manifest = self._read_json(ROOT / "data" / "ai" / "asset_manifest_v01.json")
        characters = []
        for char_id, data in manifest.get("characters", {}).items():
            if "caio" in char_id.lower() or "ravel" in char_id.lower():
                continue
            characters.append({"id": char_id, **data})
        return characters

    def canonical_arenas(self) -> List[Dict[str, Any]]:
        manifest = self._read_json(ROOT / "data" / "ai" / "asset_manifest_v01.json")
        return [{"id": arena_id, **data} for arena_id, data in manifest.get("arenas", {}).items()]

    def generate_character_sprites(self, limit: Optional[int] = None) -> None:
        count = 0
        for char in self.canonical_characters():
            char_id = char["id"]
            anchor = char.get("style_anchor", "fictional Brazilian jiu-jitsu character")
            actions = char.get("actions", ["idle"])
            directions = char.get("directions", ["side_right"])
            for action in actions:
                for direction in directions:
                    prompt = (
                        f"{char_id}, {anchor}, action {action}, direction {direction}, "
                        "jiu-jitsu sport pose, transparent background, no real logo"
                    )
                    out = self.output_dir / "sprites" / char_id / f"{char_id}_{action}_{direction}_v01.png"
                    self.generate_pixel_art(prompt, out, 1024, 1024, 8)
                    count += 1
                    time.sleep(self.delay)
                    if limit and count >= limit:
                        return

    def generate_arena_backgrounds(self, limit: Optional[int] = None) -> None:
        count = 0
        for arena in self.canonical_arenas():
            arena_id = arena["id"]
            mood = arena.get("mood", "Baixo Sul arena")
            for layer in arena.get("layers", []):
                prompt = f"{arena_id}, {mood}, layer {layer}, parallax game background, no text, no real logo"
                out = self.output_dir / "backgrounds" / arena_id / f"{arena_id}_{layer}.png"
                self.generate_pixel_art(prompt, out, 1920, 1080, 4)
                count += 1
                time.sleep(self.delay)
                if limit and count >= limit:
                    return

    def generate_ui_assets(self, limit: Optional[int] = None) -> None:
        elements = {
            "button_normal": "dark mobile game button, burned gold border, clean UI",
            "button_pressed": "pressed dark mobile game button, gold highlight",
            "hp_bar": "segmented health bar, red and dark frame, readable mobile UI",
            "gas_bar": "segmented gas stamina bar, blue, readable mobile UI",
            "guard_bar": "guard integrity bar, white and gold, readable mobile UI",
            "focus_bar": "focus bar, purple, mental timing meter",
            "moral_bar": "moral bar, golden confidence meter",
            "control_meter": "positional control meter, gold and black",
            "grip_integrity": "grip integrity icon and meter, cloth grip symbol",
            "cria_live_notification": "social media notification icon for Cria Live",
            "world_map_pin": "Baixo Sul world map pin, gold and blue",
        }
        for idx, (asset_id, desc) in enumerate(elements.items()):
            if limit and idx >= limit:
                break
            out = self.output_dir / "ui" / f"{asset_id}.png"
            self.generate_pixel_art(desc, out, 512, 512, 2)
            time.sleep(self.delay)

    def generate_audio_metadata(self) -> None:
        manifest = self._read_json(ROOT / "data" / "ai" / "asset_manifest_v01.json")
        audio = manifest.get("audio", {})
        for track in audio.get("music_tracks", []):
            self._write_metadata(f"audio_music_{track}", {"type": "music", "id": track, "model": self.models.music, "output": f"assets/audio/music/{track}_loop_v01.ogg"})
        for sfx in audio.get("sfx", []):
            self._write_metadata(f"audio_sfx_{sfx}", {"type": "sfx", "id": sfx, "model": self.models.sfx, "output": f"assets/audio/sfx/{sfx}.wav"})

    def run_all(self, limit: Optional[int] = None) -> None:
        print("CRIA DO TATAME — GERADOR DE ASSETS")
        print("Canon: Ruan Macacao Silva | Estilo: HD Pixel Art 2.5D")
        if self.dry_run:
            print("Modo: dry-run metadata")
        elif not self.client:
            print("Modo: metadata por falta de HF_TOKEN local")
        self.generate_character_sprites(limit=limit)
        self.generate_arena_backgrounds(limit=limit)
        self.generate_ui_assets(limit=limit)
        self.generate_audio_metadata()
        print("Pipeline concluido. Confira assets/generated_metadata e assets gerados.")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default=str(DEFAULT_OUT))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--delay", type=float, default=1.0)
    args = parser.parse_args()
    generator = CriaTatameAssetGenerator(Path(args.output_dir), dry_run=args.dry_run, delay=args.delay)
    generator.run_all(limit=args.limit)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
