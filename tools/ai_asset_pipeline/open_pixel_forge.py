#!/usr/bin/env python3
"""Local ComfyUI asset forge aligned with Cria do Tatame's production queue.

Generated files are candidates only. Promotion into assets/graphics is intentionally manual.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
import time
import urllib.parse
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Iterator

from dotenv import load_dotenv
from PIL import Image, ImageEnhance
import requests

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = ROOT / "data/visual/open_pixel_forge_config_v01.json"
DEFAULT_QUEUE = ROOT / "tools/ai_asset_pipeline/generated_queue/production_queue_v02.jsonl"
DEFAULT_OUTPUT = ROOT / "tools/ai_asset_pipeline/generated_outputs/open_pixel_forge"
FORBIDDEN = ("caio ravel", "ruan cria", "ravel brand", "ufc", "ibjjf")
NEGATIVE = (
    "blurry, anti-aliased, mixed pixel sizes, distorted anatomy, extra limbs, extra fingers, "
    "floating feet, inconsistent costume, unreadable silhouette, watermark, embedded text, "
    "real brand, real athlete, commercial league logo, gore"
)


class ForgeError(RuntimeError):
    pass


@dataclass(frozen=True)
class Config:
    provider: str
    url: str
    checkpoint: str
    lora: str
    lora_strength: float
    width: int
    height: int
    steps: int
    cfg: float
    sampler: str
    scheduler: str
    seed: int
    batch: int
    poll: float
    timeout: int
    downscale: int
    colors: int
    remove_background: bool

    @classmethod
    def load(cls, raw: dict[str, Any]) -> "Config":
        env = os.environ
        return cls(
            provider=env.get("CRIA_FORGE_PROVIDER", str(raw.get("provider", "plan"))).lower(),
            url=env.get("COMFYUI_URL", str(raw.get("comfyui_url", "http://127.0.0.1:8188"))).rstrip("/"),
            checkpoint=env.get("COMFYUI_CHECKPOINT", str(raw.get("checkpoint", "sd_xl_base_1.0.safetensors"))),
            lora=env.get("COMFYUI_PIXEL_LORA", str(raw.get("lora_name", "pixel-art-xl.safetensors"))),
            lora_strength=float(env.get("COMFYUI_LORA_STRENGTH", raw.get("lora_strength", 0.9))),
            width=int(env.get("CRIA_FORGE_WIDTH", raw.get("width", 1024))),
            height=int(env.get("CRIA_FORGE_HEIGHT", raw.get("height", 1024))),
            steps=int(env.get("CRIA_FORGE_STEPS", raw.get("steps", 28))),
            cfg=float(env.get("CRIA_FORGE_CFG", raw.get("cfg", 6.5))),
            sampler=str(raw.get("sampler_name", "dpmpp_2m")),
            scheduler=str(raw.get("scheduler", "karras")),
            seed=int(env.get("CRIA_FORGE_SEED", raw.get("seed", 437042))),
            batch=max(1, int(raw.get("batch_size", 1))),
            poll=max(0.25, float(raw.get("poll_seconds", 1.0))),
            timeout=max(30, int(raw.get("timeout_seconds", 900))),
            downscale=max(1, int(raw.get("downscale_factor", 8))),
            colors=max(8, min(256, int(raw.get("palette_colors", 48)))),
            remove_background=bool(raw.get("remove_background", False)),
        )


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise ForgeError(f"arquivo ausente: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ForgeError(f"JSON invalido em {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ForgeError(f"objeto JSON esperado em {path}")
    return value


def read_queue(path: Path) -> Iterator[dict[str, Any]]:
    if not path.exists():
        raise ForgeError(f"fila ausente: {path}; execute npm run assets:queue")
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            task = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ForgeError(f"JSONL invalido em {path}:{line_no}: {exc}") from exc
        if not isinstance(task, dict):
            raise ForgeError(f"objeto esperado em {path}:{line_no}")
        yield task


def slug(value: str) -> str:
    return "".join(c if c.isalnum() or c in "-_" else "_" for c in value.lower()).strip("_") or "asset"


def seed_for(base: int, task_id: str, index: int) -> int:
    digest = hashlib.sha256(f"{base}:{task_id}:{index}".encode()).digest()
    return int.from_bytes(digest[:8], "big") % 2_147_483_647


def prompt_for(task: dict[str, Any]) -> str:
    kind = str(task.get("kind", ""))
    prompt = (
        f"{task.get('prompt', '')}. Canonical protagonist Ruan Macacao Silva when relevant. "
        "Brazilian jiu-jitsu positional mechanics. Stable face, costume, body mass, palette and ground contact. "
        "Pixel-perfect nearest-neighbor edges. Single coherent action. No embedded text."
    )
    if kind == "paired_technique_animation":
        prompt += (
            " Two synchronized athletes, explicit grips and contact points, safe technical grappling, "
            "keyframe candidate only, manual biomechanical cleanup required."
        )
    blocked = [term for term in FORBIDDEN if term in prompt.lower()]
    if blocked:
        raise ForgeError(f"prompt bloqueado por canon/licenca: {', '.join(blocked)}")
    return prompt


def dimensions(task: dict[str, Any], cfg: Config) -> tuple[int, int]:
    kind = task.get("kind")
    if kind == "ui_screen":
        return 1280, 720
    if kind == "arena_package":
        return 1536, 864
    return cfg.width, cfg.height


def workflow(cfg: Config, prompt: str, width: int, height: int, seed: int, prefix: str) -> dict[str, Any]:
    graph: dict[str, Any] = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": cfg.checkpoint}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEGATIVE, "clip": ["1", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": width, "height": height, "batch_size": cfg.batch}},
        "5": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": cfg.steps, "cfg": cfg.cfg, "sampler_name": cfg.sampler,
            "scheduler": cfg.scheduler, "denoise": 1.0, "model": ["1", 0],
            "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]
        }},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["6", 0]}},
    }
    if cfg.lora:
        graph["8"] = {"class_type": "LoraLoader", "inputs": {
            "model": ["1", 0], "clip": ["1", 1], "lora_name": cfg.lora,
            "strength_model": cfg.lora_strength, "strength_clip": cfg.lora_strength
        }}
        graph["2"]["inputs"]["clip"] = ["8", 1]
        graph["3"]["inputs"]["clip"] = ["8", 1]
        graph["5"]["inputs"]["model"] = ["8", 0]
    return graph


class ComfyUI:
    def __init__(self, cfg: Config):
        self.cfg = cfg
        self.http = requests.Session()

    def healthcheck(self) -> None:
        try:
            response = self.http.get(f"{self.cfg.url}/system_stats", timeout=10)
            response.raise_for_status()
        except requests.RequestException as exc:
            raise ForgeError(f"ComfyUI indisponivel em {self.cfg.url}") from exc

    def generate(self, graph: dict[str, Any], output_dir: Path) -> list[Path]:
        try:
            response = self.http.post(
                f"{self.cfg.url}/prompt",
                json={"prompt": graph, "client_id": "cria-open-pixel-forge"},
                timeout=30,
            )
            response.raise_for_status()
            prompt_id = str(response.json()["prompt_id"])
        except (requests.RequestException, KeyError, ValueError) as exc:
            raise ForgeError(f"falha ao enviar workflow: {exc}") from exc

        deadline = time.monotonic() + self.cfg.timeout
        history: dict[str, Any] | None = None
        while time.monotonic() < deadline:
            response = self.http.get(f"{self.cfg.url}/history/{prompt_id}", timeout=30)
            response.raise_for_status()
            payload = response.json()
            if prompt_id in payload:
                history = payload[prompt_id]
                break
            time.sleep(self.cfg.poll)
        if history is None:
            raise ForgeError(f"timeout no job {prompt_id}")

        output_dir.mkdir(parents=True, exist_ok=True)
        paths: list[Path] = []
        for node in history.get("outputs", {}).values():
            for item in node.get("images", []):
                query = urllib.parse.urlencode({
                    "filename": item.get("filename", ""),
                    "subfolder": item.get("subfolder", ""),
                    "type": item.get("type", "output"),
                })
                response = self.http.get(f"{self.cfg.url}/view?{query}", timeout=60)
                response.raise_for_status()
                path = output_dir / f"raw_{len(paths):02d}.png"
                path.write_bytes(response.content)
                paths.append(path)
        if not paths:
            raise ForgeError(f"job {prompt_id} terminou sem imagens")
        return paths


def postprocess(source: Path, destination: Path, cfg: Config) -> dict[str, Any]:
    with Image.open(source) as image:
        image = image.convert("RGBA")
        original = image.size
        if cfg.remove_background:
            try:
                from rembg import remove
            except ImportError as exc:
                raise ForgeError("rembg nao instalado") from exc
            image = remove(image)
        if cfg.downscale > 1:
            image = image.resize(
                (max(1, image.width // cfg.downscale), max(1, image.height // cfg.downscale)),
                Image.Resampling.NEAREST,
            )
        image = ImageEnhance.Contrast(image).enhance(1.08)
        alpha = image.getchannel("A")
        image = image.convert("RGB").quantize(colors=cfg.colors).convert("RGBA")
        image.putalpha(alpha)
        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination)
        return {"source": str(source), "output": str(destination), "original": list(original), "final": list(image.size)}


def write_package(task: dict[str, Any], raw: list[Path], task_dir: Path, cfg: Config, seeds: list[int]) -> None:
    processed = [
        postprocess(path, task_dir / "processed" / f"candidate_{index:02d}.png", cfg)
        for index, path in enumerate(raw)
    ]
    metadata = {
        "schema_version": "1.0.0",
        "status": "candidate_only",
        "task": task,
        "provider": cfg.provider,
        "seeds": seeds,
        "processed": processed,
        "manual_qa_required": True,
        "biomechanical_qa_required": task.get("kind") == "paired_technique_animation",
        "promotion_blocked": True,
    }
    (task_dir / "metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    (task_dir / "import_notes.md").write_text(
        "# Import notes\n\nCandidato apenas; nao promover automaticamente.\n\n"
        "1. Limpar no Pixelorama ou LibreSprite.\n2. Fixar pivo, contato e proporcoes.\n"
        "3. Grappling: separar atacante/defensor e criar sync_map.json.\n"
        "4. Gerar atlas e testar no Godot/Android.\n",
        encoding="utf-8",
    )
    (task_dir / "qa_report.md").write_text(
        "# QA\n\n- [ ] Canon\n- [ ] Licenca/modelo\n- [ ] Silhueta mobile\n"
        "- [ ] Anatomia\n- [ ] Pivo e contato\n- [ ] Hitbox/hurtbox/grabbox\n"
        "- [ ] Sincronizacao biomecanica\n- [ ] Godot nearest\n- [ ] Android\n",
        encoding="utf-8",
    )


def validate(cfg: Config, queue_path: Path) -> dict[str, Any]:
    if cfg.provider not in {"plan", "comfyui"}:
        raise ForgeError(f"provider invalido: {cfg.provider}")
    if cfg.width % 8 or cfg.height % 8:
        raise ForgeError("dimensoes precisam ser multiplos de 8")
    tasks = list(read_queue(queue_path))
    ids: set[str] = set()
    kinds: dict[str, int] = {}
    for task in tasks:
        task_id = str(task.get("task_id", ""))
        if not task_id or task_id in ids:
            raise ForgeError(f"task_id ausente ou duplicado: {task_id!r}")
        ids.add(task_id)
        prompt_for(task)
        kind = str(task.get("kind", "unknown"))
        kinds[kind] = kinds.get(kind, 0) + 1
    return {"ok": True, "provider": cfg.provider, "tasks": len(tasks), "by_kind": kinds}


def select(tasks: Iterable[dict[str, Any]], kinds: set[str], target: str, limit: int | None) -> list[dict[str, Any]]:
    output = []
    for task in tasks:
        if kinds and task.get("kind") not in kinds:
            continue
        if target and task.get("target") != target:
            continue
        output.append(task)
        if limit is not None and len(output) >= limit:
            break
    return output


def run(args: argparse.Namespace) -> int:
    load_dotenv(ROOT / ".env")
    cfg = Config.load(read_json(args.config))
    report = validate(cfg, args.queue)
    if args.validate_only:
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0

    tasks = select(read_queue(args.queue), set(args.kind or []), args.target, args.limit)
    if not tasks:
        raise ForgeError("nenhuma tarefa corresponde aos filtros")
    plan = [{
        "task_id": task["task_id"], "kind": task.get("kind"), "target": task.get("target"),
        "dimensions": list(dimensions(task, cfg)), "candidates": args.candidates,
        "biomechanical_qa_required": task.get("kind") == "paired_technique_animation"
    } for task in tasks]
    if args.dry_run or cfg.provider == "plan":
        print(json.dumps({"ok": True, "mode": "plan", "tasks": plan}, ensure_ascii=False, indent=2))
        return 0

    client = ComfyUI(cfg)
    client.healthcheck()
    results = []
    for task in tasks:
        task_id = str(task["task_id"])
        task_dir = args.output / slug(task_id)
        if task_dir.exists() and not args.force:
            results.append({"task_id": task_id, "status": "skipped_existing"})
            continue
        if task_dir.exists():
            shutil.rmtree(task_dir)
        raw_dir = task_dir / "raw"
        width, height = dimensions(task, cfg)
        seeds: list[int] = []
        raw: list[Path] = []
        for index in range(args.candidates):
            seed = seed_for(cfg.seed, task_id, index)
            seeds.append(seed)
            graph = workflow(cfg, prompt_for(task), width, height, seed, f"cria/{slug(task_id)}/{index:02d}")
            raw.extend(client.generate(graph, raw_dir))
        write_package(task, raw, task_dir, cfg, seeds)
        results.append({"task_id": task_id, "status": "candidate_generated", "images": len(raw)})

    args.output.mkdir(parents=True, exist_ok=True)
    report_path = args.output / f"local_run_{int(time.time())}.json"
    report_path.write_text(json.dumps({"schema_version": "1.0.0", "results": results}, indent=2), encoding="utf-8")
    print(json.dumps({"ok": True, "report": str(report_path), "results": results}, ensure_ascii=False, indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Open Pixel Forge local para Cria do Tatame")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--queue", type=Path, default=DEFAULT_QUEUE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--kind", action="append", choices=["character_animation", "paired_technique_animation", "arena_package", "ui_screen"])
    parser.add_argument("--target", default="")
    parser.add_argument("--limit", type=int)
    parser.add_argument("--candidates", type=int, default=1)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    try:
        if args.limit is not None and args.limit < 1:
            raise ForgeError("--limit precisa ser >= 1")
        if not 1 <= args.candidates <= 8:
            raise ForgeError("--candidates precisa ficar entre 1 e 8")
        return run(args)
    except (ForgeError, requests.RequestException) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
