#!/usr/bin/env python3
"""Gerador local de imagens para o Cria do Tatame.

Uso:
  1. Configure HF_TOKEN no ambiente local.
  2. Rode build_generation_queue.py.
  3. Rode este script com um arquivo JSONL de fila.

Este script tenta usar diffusers quando instalado. Caso nao esteja instalado,
cria apenas metadados de tarefa para producao manual.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any, Dict, Iterable

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_QUEUE = ROOT / "tools" / "ai_asset_pipeline" / "generated_queue" / "characters.jsonl"
DEFAULT_OUTPUT = ROOT / "tools" / "ai_asset_pipeline" / "generated_outputs"
DEFAULT_MODEL = "nerijs/pixel-art-xl"
NEGATIVE = "blurry, low quality, bad anatomy, unreadable silhouette, random text, watermark, real brand, real logo"


def read_jsonl(path: Path) -> Iterable[Dict[str, Any]]:
    with path.open("r", encoding="utf-8") as file:
        for line in file:
            line = line.strip()
            if line:
                yield json.loads(line)


def build_prompt(task: Dict[str, Any]) -> str:
    if task.get("type") == "character_sprite":
        return (
            f"{task.get('character_id')} {task.get('action')} {task.get('direction')}, "
            f"{task.get('style_anchor', '')}, HD pixel art 2.5D game sprite, transparent background, "
            "clean silhouette, mobile game asset, Baixo Sul da Bahia identity, no real logos"
        )
    if task.get("type") == "arena_layer":
        return (
            f"{task.get('arena_id')} layer {task.get('layer')}, {task.get('mood', '')}, "
            "HD pixel art 2.5D background, cinematic depth, mobile game asset, no real logos"
        )
    return json.dumps(task, ensure_ascii=False)


def metadata_only(task: Dict[str, Any], output_dir: Path) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    target = output_dir / (task.get("output", "task.json").replace("/", "__") + ".json")
    target.write_text(json.dumps({"task": task, "prompt": build_prompt(task), "negative_prompt": NEGATIVE}, ensure_ascii=False, indent=2), encoding="utf-8")
    return target


def generate_with_diffusers(task: Dict[str, Any], output_dir: Path, model_id: str, steps: int, seed: int) -> Path:
    import torch
    from diffusers import AutoPipelineForText2Image

    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.float16 if device == "cuda" else torch.float32
    pipe = AutoPipelineForText2Image.from_pretrained(
        model_id,
        torch_dtype=dtype,
        use_safetensors=True,
        token=os.environ.get("HF_TOKEN"),
    )
    pipe = pipe.to(device)
    generator = torch.Generator(device=device).manual_seed(seed)
    image = pipe(
        prompt=build_prompt(task),
        negative_prompt=NEGATIVE,
        num_inference_steps=steps,
        generator=generator,
        width=1024,
        height=1024,
    ).images[0]
    output_path = output_dir / task.get("output", "asset.png")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)
    return output_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--queue", default=str(DEFAULT_QUEUE))
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--limit", type=int, default=3)
    parser.add_argument("--steps", type=int, default=25)
    parser.add_argument("--seed", type=int, default=4319)
    parser.add_argument("--metadata-only", action="store_true")
    args = parser.parse_args()

    queue = Path(args.queue)
    output_dir = Path(args.output_dir)
    if not queue.exists():
        raise FileNotFoundError(f"Fila nao encontrada: {queue}")

    tasks = list(read_jsonl(queue))[: args.limit]
    results = []
    for index, task in enumerate(tasks):
        if args.metadata_only:
            result = metadata_only(task, output_dir)
        else:
            try:
                result = generate_with_diffusers(task, output_dir, args.model, args.steps, args.seed + index)
            except Exception as exc:
                result = metadata_only({**task, "generation_error": str(exc)}, output_dir)
        results.append(str(result))

    print(json.dumps({"generated": results}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
