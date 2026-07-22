#!/usr/bin/env python3
"""Open Pixel Forge for Cria do Tatame.

A local-first asset candidate generator aligned with the existing production queue.
It never promotes generated candidates into shipping asset directories automatically.

Backends:
- plan: deterministic dry-run only
- comfyui: local ComfyUI HTTP API
- diffusers: local Hugging Face Diffusers pipeline

Canon and safety:
- reads the queue generated from data/visual/production_manifest_v02.json
- blocks forbidden legacy identifiers and real-brand prompts
- paired grappling techniques are always marked for manual biomechanical QA
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

try:
    import requests
except Exception:  # pragma: no cover
    requests = None

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = ROOT / "data" / "visual" / "open_pixel_forge_config_v01.json"
DEFAULT_QUEUE = ROOT / "tools" / "ai_asset_pipeline" / "generated_queue" / "production_queue_v02.jsonl"
DEFAULT_OUTPUT = ROOT / "tools" / "ai_asset_pipeline" / "generated_outputs" / "open_pixel_forge"
FORBIDDEN_TERMS = ("caio ravel", "ruan cria", "ravel brand", "ufc", "ibjjf")
NEGATIVE_PROMPT = (
    "blurry, anti-aliased edges, mixed pixel sizes, distorted anatomy, extra limbs, extra fingers, "
    "floating feet, inconsistent costume, unreadable silhouette, watermark, embedded text, real brand, "
    "real athlete, commercial league logo, gore"
)


class ForgeError(RuntimeError):
    """Expected pipeline failure with a user-actionable message."""


@dataclass(frozen=True)
class ForgeConfig:
    provider: str
    comfyui_url: str
    checkpoint: str
    lora_name: str
    lora_strength: float
    width: int
    height: int
    steps: int
    cfg: float
    sampler_name: str
    scheduler: str
    seed: int
    batch_size: int
    poll_seconds: float
    timeout_seconds: int
    downscale_factor: int
    palette_colors: int
    remove_background: bool
    model_id: str
    device: str
    dtype: str

    @classmethod
    def from_dict(cls, raw: dict[str, Any]) -> "ForgeConfig":
        provider = os.getenv("CRIA_FORGE_PROVIDER", str(raw.get("provider", "comfyui"))).strip().lower()
        return cls(
            provider=provider,
            comfyui_url=os.getenv("COMFYUI_URL", str(raw.get("comfyui_url", "http://127.0.0.1:8188"))).rstrip("/"),
            checkpoint=os.getenv("COMFYUI_CHECKPOINT", str(raw.get("checkpoint", "sd_xl_base_1.0.safetensors"))),
            lora_name=os.getenv("COMFYUI_PIXEL_LORA", str(raw.get("lora_name", "pixel-art-xl.safetensors"))),
            lora_strength=float(os.getenv("COMFYUI_LORA_STRENGTH", raw.get("lora_strength", 0.9))),
            width=int(os.getenv("CRIA_FORGE_WIDTH", raw.get("width", 1024))),
            height=int(os.getenv("CRIA_FORGE_HEIGHT", raw.get("height", 1024))),
            steps=int(os.getenv("CRIA_FORGE_STEPS", raw.get("steps", 28))),
            cfg=float(os.getenv("CRIA_FORGE_CFG", raw.get("cfg", 6.5))),
            sampler_name=str(raw.get("sampler_name", "dpmpp_2m")),
            scheduler=str(raw.get("scheduler", "karras")),
            seed=int(os.getenv("CRIA_FORGE_SEED", raw.get("seed", 437042))),
            batch_size=max(1, int(raw.get("batch_size", 1))),
            poll_seconds=max(0.25, float(raw.get("poll_seconds", 1.0))),
            timeout_seconds=max(30, int(raw.get("timeout_seconds", 900))),
            downscale_factor=max(1, int(raw.get("downscale_factor", 8))),
            palette_colors=max(8, min(256, int(raw.get("palette_colors", 48)))),
            remove_background=bool(raw.get("remove_background", False)),
            model_id=os.getenv("CRIA_FORGE_MODEL_ID", str(raw.get("model_id", "stabilityai/stable-diffusion-xl-base-1.0"))),
            device=os.getenv("CRIA_FORGE_DEVICE", str(raw.get("device", "auto"))),
            dtype=os.getenv("CRIA_FORGE_DTYPE", str(raw.get("dtype", "float16"))),
        )


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise ForgeError(f"arquivo JSON ausente: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ForgeError(f"JSON invalido em {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ForgeError(f"objeto JSON esperado em {path}")
    return value


def read_jsonl(path: Path) -> Iterator[dict[str, Any]]:
    if not path.exists():
        raise ForgeError(f"fila ausente: {path}. Execute primeiro: npm run assets:queue")
    with path.open("r", encoding="utf-8") as handle:
        for line_no, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                value = json.loads(line)
            except json.JSONDecodeError as exc:
                raise ForgeError(f"JSONL invalido em {path}:{line_no}: {exc}") from exc
            if not isinstance(value, dict):
                raise ForgeError(f"objeto esperado em {path}:{line_no}")
            yield value


def stable_seed(base_seed: int, task_id: str, candidate_index: int) -> int:
    digest = hashlib.sha256(f"{base_seed}:{task_id}:{candidate_index}".encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big") % 2_147_483_647


def safe_slug(value: str) -> str:
    output = []
    for char in value.lower():
        if char.isalnum() or char in {"-", "_"}:
            output.append(char)
        else:
            output.append("_")
    return "".join(output).strip("_") or "asset"


def validate_prompt(prompt: str) -> None:
    lowered = prompt.lower()
    blocked = [term for term in FORBIDDEN_TERMS if term in lowered]
    if blocked:
        raise ForgeError(f"prompt bloqueado por canon/licenca: {', '.join(blocked)}")


def task_dimensions(task: dict[str, Any], config: ForgeConfig) -> tuple[int, int]:
    kind = str(task.get("kind", ""))
    if kind == "ui_screen":
        return 1280, 720
    if kind == "arena_package":
        return 1536, 864
    return config.width, config.height


def build_prompt(task: dict[str, Any]) -> str:
    base = str(task.get("prompt", "")).strip()
    task_id = str(task.get("task_id", "unknown"))
    kind = str(task.get("kind", "unknown"))
    suffixes = [
        "canonical protagonist is Ruan Macacao Silva when relevant",
        "Brazilian jiu-jitsu positional mechanics",
        "single coherent action",
        "stable face, costume, body mass and palette",
        "pixel-perfect nearest-neighbor edges",
        "transparent or simple chroma background for isolated assets",
        f"production task {task_id}",
        f"asset kind {kind}",
    ]
    if kind == "paired_technique_animation":
        suffixes.extend(
            [
                "two synchronized athletes with explicit contact points",
                "safe technical grappling depiction",
                "no injury spectacle",
                "keyframe concept only; manual biomechanical cleanup required",
            ]
        )
    prompt = f"{base}. " + ". ".join(suffixes)
    validate_prompt(prompt)
    return prompt


def comfyui_workflow(config: ForgeConfig, prompt: str, width: int, height: int, seed: int, filename_prefix: str) -> dict[str, Any]:
    workflow: dict[str, Any] = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": config.checkpoint}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEGATIVE_PROMPT, "clip": ["1", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": width, "height": height, "batch_size": config.batch_size}},
        "5": {
            "class_type": "KSampler",
            "inputs": {
                "seed": seed,
                "steps": config.steps,
                "cfg": config.cfg,
                "sampler_name": config.sampler_name,
                "scheduler": config.scheduler,
                "denoise": 1.0,
                "model": ["1", 0],
                "positive": ["2", 0],
                "negative": ["3", 0],
                "latent_image": ["4", 0]
            }
        },
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": filename_prefix, "images": ["6", 0]}}
    }
    if config.lora_name:
        workflow["8"] = {
            "class_type": "LoraLoader",
            "inputs": {
                "model": ["1", 0],
                "clip": ["1", 1],
                "lora_name": config.lora_name,
                "strength_model": config.lora_strength,
                "strength_clip": config.lora_strength
            }
        }
        workflow["2"]["inputs"]["clip"] = ["8", 1]
        workflow["3"]["inputs"]["clip"] = ["8", 1]
        workflow["5"]["inputs"]["model"] = ["8", 0]
    return workflow


class ComfyUIProvider:
    def __init__(self, config: ForgeConfig):
        if requests is None:
            raise ForgeError("requests nao instalado")
        self.config = config
        self.session = requests.Session()

    def healthcheck(self) -> None:
        try:
            response = self.session.get(f"{self.config.comfyui_url}/system_stats", timeout=10)
            response.raise_for_status()
        except Exception as exc:
            raise ForgeError(f"ComfyUI indisponivel em {self.config.comfyui_url}. Inicie o servidor local antes da geracao.") from exc

    def generate(self, prompt: str, output_dir: Path, width: int, height: int, seed: int, prefix: str) -> list[Path]:
        workflow = comfyui_workflow(self.config, prompt, width, height, seed, prefix)
        try:
            response = self.session.post(
                f"{self.config.comfyui_url}/prompt",
                json={"prompt": workflow, "client_id": "cria-open-pixel-forge"},
                timeout=30
            )
            response.raise_for_status()
            prompt_id = str(response.json()["prompt_id"])
        except Exception as exc:
            raise ForgeError(f"falha ao enviar workflow ao ComfyUI: {exc}") from exc

        deadline = time.monotonic() + self.config.timeout_seconds
        history: dict[str, Any] | None = None
        while time.monotonic() < deadline:
            response = self.session.get(f"{self.config.comfyui_url}/history/{prompt_id}", timeout=30)
            response.raise_for_status()
            payload = response.json()
            if prompt_id in payload:
                history = payload[prompt_id]
                break
            time.sleep(self.config.poll_seconds)
        if history is None:
            raise ForgeError(f"timeout aguardando job ComfyUI {prompt_id}")

        output_dir.mkdir(parents=True, exist_ok=True)
        downloaded: list[Path] = []
        for node_output in history.get("outputs", {}).values():
            for image in node_output.get("images", []):
                filename = str(image.get("filename", ""))
                if not filename:
                    continue
                query = urllib.parse.urlencode(
                    {
                        "filename": filename,
                        "subfolder": str(image.get("subfolder", "")),
                        "type": str(image.get("type", "output"))
                    }
                )
                image_response = self.session.get(f"{self.config.comfyui_url}/view?{query}", timeout=60)
                image_response.raise_for_status()
                destination = output_dir / safe_slug(Path(filename).stem + ".png")
                destination.write_bytes(image_response.content)
                downloaded.append(destination)
        if not downloaded:
            raise ForgeError(f"ComfyUI concluiu {prompt_id}, mas nao retornou imagens")
        return downloaded


class DiffusersProvider:
    def __init__(self, config: ForgeConfig):
        self.config = config
        try:
            import torch
            from diffusers import DiffusionPipeline
        except Exception as exc:  # pragma: no cover
            raise ForgeError("backend diffusers requer torch e diffusers instalados") from exc
        self.torch = torch
        dtype = torch.float16 if config.dtype == "float16" else torch.float32
        device = config.device
        if device == "auto":
            device = "cuda" if torch.cuda.is_available() else "cpu"
        self.device = device
        self.pipe = DiffusionPipeline.from_pretrained(config.model_id, torch_dtype=dtype)
        if config.lora_name:
            self.pipe.load_lora_weights(config.lora_name)
        self.pipe.to(device)

    def healthcheck(self) -> None:
        return

    def generate(self, prompt: str, output_dir: Path, width: int, height: int, seed: int, prefix: str) -> list[Path]:
        output_dir.mkdir(parents=True, exist_ok=True)
        generator = self.torch.Generator(device=self.device).manual_seed(seed)
        result = self.pipe(
            prompt=prompt,
            negative_prompt=NEGATIVE_PROMPT,
            width=width,
            height=height,
            num_inference_steps=self.config.steps,
            guidance_scale=self.config.cfg,
            generator=generator,
            num_images_per_prompt=self.config.batch_size
        )
        paths: list[Path] = []
        for index, image in enumerate(result.images):
            path = output_dir / f"{safe_slug(prefix)}_{index:02d}.png"
            image.save(path)
            paths.append(path)
        return paths


def postprocess_image(source: Path, destination: Path, config: ForgeConfig) -> dict[str, Any]:
    with Image.open(source) as image:
        image = image.convert("RGBA")
        original_size = image.size
        if config.remove_background:
            try:
                from rembg import remove
                image = remove(image)
            except Exception as exc:  # pragma: no cover
                raise ForgeError("remove_background habilitado, mas rembg nao esta disponivel") from exc
        if config.downscale_factor > 1:
            target = (max(1, image.width // config.downscale_factor), max(1, image.height // config.downscale_factor))
            image = image.resize(target, Image.Resampling.NEAREST)
        image = ImageEnhance.Contrast(image).enhance(1.08)
        alpha = image.getchannel("A")
        rgb = image.convert("RGB").quantize(colors=config.palette_colors, method=Image.Quantize.MEDIANCUT).convert("RGBA")
        rgb.putalpha(alpha)
        destination.parent.mkdir(parents=True, exist_ok=True)
        rgb.save(destination, format="PNG", optimize=False)
        return {
            "source": str(source),
            "output": str(destination),
            "original_size": list(original_size),
            "final_size": list(rgb.size),
            "palette_colors": config.palette_colors,
            "downscale_factor": config.downscale_factor,
            "background_removed": config.remove_background
        }


def write_candidate_package(task: dict[str, Any], raw_paths: list[Path], task_dir: Path, config: ForgeConfig, seeds: list[int]) -> None:
    processed_dir = task_dir / "processed"
    processed: list[dict[str, Any]] = []
    for index, source in enumerate(raw_paths):
        destination = processed_dir / f"candidate_{index:02d}.png"
        processed.append(postprocess_image(source, destination, config))

    metadata = {
        "schema_version": "1.0.0",
        "status": "candidate_only",
        "task": task,
        "provider": config.provider,
        "seeds": seeds,
        "processed": processed,
        "manual_qa_required": true,
        "biomechanical_qa_required": task.get("kind") == "paired_technique_animation",
        "promotion_blocked": true,
        "promotion_reason": "generated candidates require canon, visual, license, pivot and runtime QA"
    }
    (task_dir / "metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    (task_dir / "import_notes.md").write_text(
        "# Import notes\n\n"
        "Este pacote e candidato. Nao copiar automaticamente para `assets/graphics`.\n\n"
        "1. Selecionar e limpar frames no Pixelorama ou LibreSprite.\n"
        "2. Fixar pivo, linha de contato e proporcoes.\n"
        "3. Para grappling, revisar atacante/defensor e criar `sync_map.json`.\n"
        "4. Gerar atlas e preview.\n"
        "5. Testar em escala real no Godot e em Android.\n",
        encoding="utf-8"
    )
    (task_dir / "qa_report.md").write_text(
        "# QA report\n\n"
        "- [ ] Canon aprovado\n"
        "- [ ] Licenca/modelo registrados\n"
        "- [ ] Silhueta legivel em 25%\n"
        "- [ ] Anatomia e massa consistentes\n"
        "- [ ] Pivo e contato documentados\n"
        "- [ ] Hitbox/hurtbox/grabbox revisados\n"
        "- [ ] Tecnica pareada revisada biomecanicamente\n"
        "- [ ] Importacao nearest no Godot\n"
        "- [ ] Teste em aparelho Android\n",
        encoding="utf-8"
    )


def validate_configuration(config: ForgeConfig, queue_path: Path) -> dict[str, Any]:
    if config.provider not in {"plan", "comfyui", "diffusers"}:
        raise ForgeError(f"provider invalido: {config.provider}")
    if config.width % 8 or config.height % 8:
        raise ForgeError("width e height precisam ser multiplos de 8")
    tasks = list(read_jsonl(queue_path))
    if not tasks:
        raise ForgeError("fila de producao vazia")
    ids: set[str] = set()
    kinds: dict[str, int] = {}
    for task in tasks:
        task_id = str(task.get("task_id", ""))
        if not task_id or task_id in ids:
            raise ForgeError(f"task_id ausente ou duplicado: {task_id!r}")
        ids.add(task_id)
        validate_prompt(build_prompt(task))
        kind = str(task.get("kind", "unknown"))
        kinds[kind] = kinds.get(kind, 0) + 1
    return {"ok": true, "provider": config.provider, "tasks": len(tasks), "by_kind": kinds}


def select_tasks(tasks: Iterable[dict[str, Any]], kinds: set[str], target: str, limit: int | None) -> list[dict[str, Any]]:
    output: list[dict[str, Any]] = []
    for task in tasks:
        if kinds and str(task.get("kind", "")) not in kinds:
            continue
        if target and str(task.get("target", "")) != target:
            continue
        output.append(task)
        if limit is not None and len(output) >= limit:
            break
    return output


def provider_for(config: ForgeConfig):
    if config.provider == "comfyui":
        return ComfyUIProvider(config)
    if config.provider == "diffusers":
        return DiffusersProvider(config)
    return None


def run(args: argparse.Namespace) -> int:
    load_dotenv(ROOT / ".env")
    config = ForgeConfig.from_dict(read_json(args.config))
    validation = validate_configuration(config, args.queue)
    if args.validate_only:
        print(json.dumps(validation, ensure_ascii=False, indent=2))
        return 0

    selected = select_tasks(read_jsonl(args.queue), set(args.kind or []), args.target, args.limit)
    if not selected:
        raise ForgeError("nenhuma tarefa corresponde aos filtros")

    plan = []
    for task in selected:
        plan.append(
            {
                "task_id": task["task_id"],
                "kind": task.get("kind"),
                "target": task.get("target"),
                "dimensions": list(task_dimensions(task, config)),
                "candidate_count": args.candidates,
                "manual_qa_required": true,
                "biomechanical_qa_required": task.get("kind") == "paired_technique_animation"
            }
        )
    if args.dry_run or config.provider == "plan":
        print(json.dumps({"ok": true, "mode": "plan", "tasks": plan}, ensure_ascii=False, indent=2))
        return 0

    provider = provider_for(config)
    if provider is None:
        raise ForgeError("provider real nao configurado")
    provider.healthcheck()
    args.output.mkdir(parents=True, exist_ok=True)
    summary: list[dict[str, Any]] = []
    for task in selected:
        task_id = str(task["task_id"])
        task_dir = args.output / safe_slug(task_id)
        raw_dir = task_dir / "raw"
        if task_dir.exists() and not args.force:
            summary.append({"task_id": task_id, "status": "skipped_existing", "output": str(task_dir)})
            continue
        if task_dir.exists():
            shutil.rmtree(task_dir)
        raw_dir.mkdir(parents=True, exist_ok=True)
        prompt = build_prompt(task)
        width, height = task_dimensions(task, config)
        raw_paths: list[Path] = []
        seeds: list[int] = []
        for candidate_index in range(args.candidates):
            seed = stable_seed(config.seed, task_id, candidate_index)
            seeds.append(seed)
            prefix = f"cria/{safe_slug(task_id)}/candidate_{candidate_index:02d}"
            raw_paths.extend(provider.generate(prompt, raw_dir, width, height, seed, prefix))
        write_candidate_package(task, raw_paths, task_dir, config, seeds)
        summary.append({"task_id": task_id, "status": "candidate_generated", "images": len(raw_paths), "output": str(task_dir)})

    run_report = {
        "schema_version": "1.0.0",
        "provider": config.provider,
        "generated_at_epoch": int(time.time()),
        "results": summary
    }
    report_path = args.output / f"local_run_{int(time.time())}.json"
    report_path.write_text(json.dumps(run_report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"ok": true, "report": str(report_path), "results": summary}, ensure_ascii=False, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Local-first open pixel asset forge for Cria do Tatame")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--queue", type=Path, default=DEFAULT_QUEUE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--kind", action="append", choices=["character_animation", "paired_technique_animation", "arena_package", "ui_screen"])
    parser.add_argument("--target", default="")
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--candidates", type=int, default=1)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--force", action="store_true")
    return parser


def main() -> int:
    try:
        args = build_parser().parse_args()
        if args.limit is not None and args.limit < 1:
            raise ForgeError("--limit precisa ser >= 1")
        if args.candidates < 1 or args.candidates > 8:
            raise ForgeError("--candidates precisa ficar entre 1 e 8")
        return run(args)
    except ForgeError as exc:
        print(json.dumps({"ok": false, "error": str(exc)}, ensure_ascii=False, indent=2), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
