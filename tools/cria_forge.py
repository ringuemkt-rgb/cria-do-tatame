#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Dict, Iterable

import requests
from dotenv import load_dotenv
from huggingface_hub import InferenceClient

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"

VOICE_LINES = {
    "ruan_macacao": ["A luta acaba quando alguem bate. A vida comeca quando nao tem mais ninguem olhando."],
    "mestre_dende": ["Forca sem direcao e desperdicio."],
    "davi_relampago": ["Vamos ver se voce evoluiu, Macacao."],
}

MUSIC_PROMPTS = {
    "terreiro_da_luta": "berimbau discreto, agua, madeira, passaros, treino calmo de jiu-jitsu no Baixo Sul",
    "arena_do_dique": "percussao pesada, ginasio oficial, crowd competitivo, tensao esportiva",
    "zambiapunga": "tambores culturais, festa do Baixo Sul, energia quente com tensao narrativa",
}


def fish_key() -> str:
    return os.getenv("FISH_API_KEY", "")


def hf_key() -> str:
    return os.getenv("HF_TOKEN", "")


def write_metadata(path: Path, payload: Dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.with_suffix(path.suffix + ".json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def generate_voice(character_id: str, line: str, dry_run: bool = False) -> Path:
    out = OUT / "dialogues" / character_id / f"{character_id}_line_001.mp3"
    out.parent.mkdir(parents=True, exist_ok=True)
    payload = {"text": line, "model": "s2.1-pro-free", "format": "mp3"}
    if dry_run or not fish_key():
        write_metadata(out, {"mode": "dry_run", "provider": "fish_audio", "payload": payload, "output": str(out)})
        return out
    response = requests.post("https://api.fish.audio/v1/tts", headers={"Authorization": "Bearer " + fish_key()}, json=payload, timeout=120)
    response.raise_for_status()
    out.write_bytes(response.content)
    write_metadata(out, {"mode": "generated", "provider": "fish_audio", "output": str(out)})
    return out


def generate_music(track_id: str, prompt: str, dry_run: bool = False) -> Path:
    out = OUT / "music" / f"{track_id}_loop_v01.wav"
    out.parent.mkdir(parents=True, exist_ok=True)
    if dry_run or not hf_key():
        write_metadata(out, {"mode": "dry_run", "provider": "huggingface", "prompt": prompt, "output": str(out)})
        return out
    client = InferenceClient(token=hf_key())
    audio = client.text_to_audio(prompt=prompt, model="facebook/musicgen-small")
    out.write_bytes(audio)
    write_metadata(out, {"mode": "generated", "provider": "huggingface", "prompt": prompt, "output": str(out)})
    return out


def run(dry_run: bool = False, limit: int = 0) -> None:
    load_dotenv(ROOT / ".env")
    count = 0
    for character_id, lines in VOICE_LINES.items():
        for line in lines:
            generate_voice(character_id, line, dry_run=dry_run)
            count += 1
            if limit and count >= limit:
                return
    for track_id, prompt in MUSIC_PROMPTS.items():
        generate_music(track_id, prompt, dry_run=dry_run)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()
    run(dry_run=args.dry_run, limit=args.limit)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
