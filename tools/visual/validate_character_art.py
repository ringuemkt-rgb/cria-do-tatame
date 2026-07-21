#!/usr/bin/env python3
"""Valida o lote canônico de arte de personagens e o vertical slice animado."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops

from normalize_sprite_strip_to_anchor import keep_largest_alpha_component


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "data/visual/character_art_manifest_v01.json"
POSE_CATALOG_PATH = ROOT / "data/visual/character_action_pose_catalog_v01.json"
ANIMATION_BATCH_PATH = ROOT / "data/visual/character_animation_batch_v02.json"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def validate_rgba_asset(
    path: Path,
    expected_size: tuple[int, int],
    label: str,
    errors: list[str],
) -> None:
    if not path.is_file():
        errors.append(f"{label}: arquivo ausente: {path.relative_to(ROOT)}")
        return
    with Image.open(path) as image:
        if image.size != expected_size:
            errors.append(f"{label}: tamanho {image.size}, esperado {expected_size}")
        rgba = image.convert("RGBA")
        alpha_min, alpha_max = rgba.getchannel("A").getextrema()
        if alpha_min != 0 or alpha_max != 255:
            errors.append(f"{label}: faixa alpha invalida {(alpha_min, alpha_max)}")
        corners = (
            rgba.getpixel((0, 0))[3],
            rgba.getpixel((rgba.width - 1, 0))[3],
            rgba.getpixel((0, rgba.height - 1))[3],
            rgba.getpixel((rgba.width - 1, rgba.height - 1))[3],
        )
        if any(corners):
            errors.append(f"{label}: cantos nao transparentes {corners}")


def validate_ruan_vertical_slice(errors: list[str]) -> None:
    base = ROOT / "assets/graphics/characters/ruan_macacao/idle_combat_v01"
    required = [
        "raw_sheet.png",
        "clean_sheet.png",
        "spritesheet.png",
        "frames",
        "preview.gif",
        "contact_sheet.png",
        "manifest.json",
        "metadata.json",
        "source_notes.md",
        "import_notes.md",
        "qa_report.md",
    ]
    for name in required:
        if not (base / name).exists():
            errors.append(f"ruan idle_combat: saida obrigatoria ausente: {name}")

    manifest_path = base / "manifest.json"
    if not manifest_path.is_file():
        return
    manifest = load_json(manifest_path)
    if manifest.get("placeholder") is not False:
        errors.append("ruan idle_combat: manifesto ainda marcado como placeholder")
    if manifest.get("runtime_state_initial") != "distancia_media":
        errors.append("ruan idle_combat: estado inicial nao e distancia_media")
    if manifest.get("runtime_state_final") != "distancia_media":
        errors.append("ruan idle_combat: estado final nao e distancia_media")

    frames = sorted((base / "frames").glob("*.png"))
    if len(frames) != 4:
        errors.append(f"ruan idle_combat: {len(frames)} quadros; esperado 4")
        return

    images = [Image.open(path).convert("RGBA") for path in frames]
    for index, image in enumerate(images, start=1):
        if image.size != (256, 256):
            errors.append(f"ruan idle_combat frame {index}: tamanho {image.size}")

    boxes = [image.getchannel("A").getbbox() for image in images]
    if any(box is None for box in boxes):
        errors.append("ruan idle_combat: quadro vazio detectado")
    else:
        concrete = [box for box in boxes if box is not None]
        heights = [box[3] - box[1] for box in concrete]
        bottoms = [box[3] for box in concrete]
        widths = [box[2] - box[0] for box in concrete]
        if max(heights) - min(heights) > 2:
            errors.append(f"ruan idle_combat: deriva de altura {heights}")
        if max(widths) - min(widths) > 2:
            errors.append(f"ruan idle_combat: deriva de largura {widths}")
        if len(set(bottoms)) != 1:
            errors.append(f"ruan idle_combat: linha do chao divergente {bottoms}")

    seed = Image.open(
        ROOT / "assets/graphics/characters/ruan_macacao/seeds/idle_combat_v01.png"
    ).convert("RGBA")
    if ImageChops.difference(images[0], seed).getbbox() is not None:
        errors.append("ruan idle_combat: quadro 01 nao coincide com o seed aprovado")

    with Image.open(base / "spritesheet.png") as sheet:
        if sheet.size != (1024, 256):
            errors.append(f"ruan idle_combat: spritesheet mede {sheet.size}")


def validate_additional_vertical_slices(
    manifest: dict[str, Any],
    characters_by_id: dict[str, dict[str, Any]],
    errors: list[str],
) -> None:
    slices = manifest.get("vertical_slices", [])
    slice_ids = {str(item.get("character_id", "")) for item in slices}
    if slice_ids != set(characters_by_id):
        errors.append(
            f"vertical slices divergentes: slices={sorted(slice_ids)}, "
            f"personagens={sorted(characters_by_id)}"
        )

    for item in slices:
        character_id = str(item.get("character_id", ""))
        spritesheet = ROOT / str(item.get("spritesheet", ""))
        if not spritesheet.is_file():
            errors.append(f"{character_id}/idle: spritesheet ausente")
            continue
        if item.get("sha256") != file_hash(spritesheet):
            errors.append(f"{character_id}/idle: sha256 do spritesheet divergente")
        if character_id == "ruan_macacao":
            continue

        manifest_path = ROOT / str(item.get("manifest", ""))
        if not manifest_path.is_file():
            errors.append(f"{character_id}/idle: manifesto ausente")
            continue
        base = manifest_path.parent
        required = [
            "raw_sheet.png",
            "clean_sheet.png",
            "spritesheet.png",
            "frames",
            "preview.gif",
            "contact_sheet.png",
            "manifest.json",
            "metadata.json",
            "source_notes.md",
            "import_notes.md",
            "qa_report.md",
        ]
        for name in required:
            if not (base / name).exists():
                errors.append(f"{character_id}/idle: saida obrigatoria ausente: {name}")

        animation_manifest = load_json(manifest_path)
        if animation_manifest.get("character_id") != character_id:
            errors.append(f"{character_id}/idle: character_id divergente no manifesto")
        if animation_manifest.get("placeholder") is not False:
            errors.append(f"{character_id}/idle: ainda marcado como placeholder")
        if animation_manifest.get("loop") is not True:
            errors.append(f"{character_id}/idle: loop desativado")

        frames = sorted((base / "frames").glob("*.png"))
        if len(frames) != 4:
            errors.append(f"{character_id}/idle: {len(frames)} quadros; esperado 4")
            continue
        images = [Image.open(path).convert("RGBA") for path in frames]
        boxes = [image.getchannel("A").getbbox() for image in images]
        if any(box is None for box in boxes):
            errors.append(f"{character_id}/idle: quadro vazio")
            continue
        concrete = [box for box in boxes if box is not None]
        heights = [box[3] - box[1] for box in concrete]
        bottoms = [box[3] for box in concrete]
        if max(heights) - min(heights) > 18:
            errors.append(f"{character_id}/idle: deriva de altura {heights}")
        if len(set(bottoms)) != 1:
            errors.append(f"{character_id}/idle: linha do chao divergente {bottoms}")

        for index, image in enumerate(images[1:], start=2):
            cleaned = keep_largest_alpha_component(image, 8)
            alpha_diff = ImageChops.difference(
                image.getchannel("A"), cleaned.getchannel("A")
            )
            if alpha_diff.getbbox() is not None:
                errors.append(f"{character_id}/idle frame {index}: fragmento alfa desconectado")

        seed_path = ROOT / characters_by_id[character_id]["idle_seed"]["path"]
        seed = Image.open(seed_path).convert("RGBA")
        if ImageChops.difference(images[0], seed).getbbox() is not None:
            errors.append(f"{character_id}/idle: quadro 01 nao coincide com o seed")
        with Image.open(spritesheet) as sheet:
            if sheet.size != (1024, 256):
                errors.append(f"{character_id}/idle: spritesheet mede {sheet.size}")


def validate_action_pose_library(
    canon_ids: set[str],
    errors: list[str],
) -> tuple[int, int]:
    if not POSE_CATALOG_PATH.is_file():
        errors.append("biblioteca de poses: catálogo ausente")
        return 0, 0
    catalog = load_json(POSE_CATALOG_PATH)
    entries = list(catalog.get("characters", []))
    pose_ids = {str(entry.get("character_id", "")) for entry in entries}
    if pose_ids != canon_ids:
        errors.append(
            f"biblioteca de poses divergente: poses={sorted(pose_ids)}, "
            f"canon={sorted(canon_ids)}"
        )

    graphic_catalog = load_json(ROOT / "data/visual/graphic_asset_catalog_v01.json")
    required_by_character = {
        str(entry["id"]): set(entry.get("set", [])) - {"portrait", "idle"}
        for entry in graphic_catalog.get("characters", [])
    }
    pose_count = 0
    for entry in entries:
        character_id = str(entry["character_id"])
        declared_actions = [str(item["id"]) for item in entry.get("actions", [])]
        missing_catalog_actions = required_by_character.get(character_id, set()) - set(
            declared_actions
        )
        if missing_catalog_actions:
            errors.append(
                f"{character_id}/poses: catálogo gráfico sem cobertura "
                f"{sorted(missing_catalog_actions)}"
            )
        base = ROOT / "assets/graphics/characters" / character_id / "action_poses_v01"
        manifest_path = base / "manifest.json"
        if not manifest_path.is_file():
            errors.append(f"{character_id}/poses: manifesto ausente")
            continue
        manifest = load_json(manifest_path)
        if manifest.get("runtime_status") != "source_only_until_godot_gate":
            errors.append(f"{character_id}/poses: status de runtime inválido")
        if manifest.get("character_id") != character_id:
            errors.append(f"{character_id}/poses: character_id divergente")
        if int(manifest.get("action_count", -1)) != len(declared_actions):
            errors.append(f"{character_id}/poses: action_count divergente")
        manifest_actions = {
            str(item.get("id", "")): item for item in manifest.get("actions", [])
        }
        if set(manifest_actions) != set(declared_actions):
            errors.append(f"{character_id}/poses: ações do manifesto divergentes")
        for action in entry.get("actions", []):
            action_id = str(action["id"])
            item = manifest_actions.get(action_id)
            if item is None:
                continue
            pose_path = ROOT / str(item.get("path", ""))
            validate_rgba_asset(
                pose_path,
                (512, 512),
                f"{character_id}/poses/{action_id}",
                errors,
            )
            if pose_path.is_file() and item.get("sha256") != file_hash(pose_path):
                errors.append(f"{character_id}/poses/{action_id}: sha256 divergente")
            if pose_path.is_file():
                with Image.open(pose_path) as image:
                    box = image.convert("RGBA").getchannel("A").getbbox()
                    if box is None:
                        errors.append(f"{character_id}/poses/{action_id}: pose vazia")
                    elif box[3] != 492:
                        errors.append(
                            f"{character_id}/poses/{action_id}: âncora inferior {box[3]}"
                        )
            pose_count += 1
        for key in ("source_sheet", "clean_source_sheet", "contact_sheet"):
            path = ROOT / str(manifest.get(key, ""))
            hash_key = f"{key.replace('_sheet', '')}_sha256"
            if key == "source_sheet":
                hash_key = "source_sha256"
            elif key == "clean_source_sheet":
                hash_key = "clean_source_sha256"
            elif key == "contact_sheet":
                hash_key = "contact_sheet_sha256"
            if not path.is_file():
                errors.append(f"{character_id}/poses: {key} ausente")
            elif manifest.get(hash_key) != file_hash(path):
                errors.append(f"{character_id}/poses: {key} sha256 divergente")

    paired_key_count = 0
    for entry in catalog.get("paired_sequences", []):
        sequence_id = str(entry["id"])
        manifest_path = (
            ROOT / "assets/graphics/characters/paired" / sequence_id / "manifest.json"
        )
        if not manifest_path.is_file():
            errors.append(f"{sequence_id}: manifesto pareado ausente")
            continue
        manifest = load_json(manifest_path)
        if set(manifest.get("characters", [])) - canon_ids:
            errors.append(f"{sequence_id}: personagem não canônico")
        declared_states = [str(value) for value in entry.get("states", [])]
        states = list(manifest.get("states", []))
        if [str(item.get("state", "")) for item in states] != declared_states:
            errors.append(f"{sequence_id}: estados pareados divergentes")
        for item in states:
            state = str(item.get("state", ""))
            path = ROOT / str(item.get("path", ""))
            validate_rgba_asset(path, (512, 512), f"{sequence_id}/{state}", errors)
            if path.is_file() and item.get("sha256") != file_hash(path):
                errors.append(f"{sequence_id}/{state}: sha256 divergente")
            paired_key_count += 1
    return pose_count, paired_key_count


def validate_apixel_generated_sources(errors: list[str]) -> int:
    brief_path = ROOT / "data/visual/apixel_production_briefs_v01.json"
    if not brief_path.is_file():
        errors.append("Apixel: brief de produção ausente")
        return 0
    brief = load_json(brief_path)
    validated = 0
    for job in brief.get("jobs", []):
        status = str(job.get("status", ""))
        if not status.startswith("generated_"):
            continue
        job_id = str(job.get("id", ""))
        target = ROOT / str(job.get("target", ""))
        if not target.is_file():
            errors.append(f"Apixel/{job_id}: target ausente")
            continue
        if job.get("sha256") != file_hash(target):
            errors.append(f"Apixel/{job_id}: sha256 divergente")
        if job.get("quality") == "4k":
            with Image.open(target) as image:
                if image.size != (3840, 2160):
                    errors.append(
                        f"Apixel/{job_id}: target {image.size}; esperado (3840, 2160)"
                    )
        validated += 1
    return validated


def validate_action_animation_batch(
    canon_ids: set[str],
    errors: list[str],
) -> tuple[int, int, int]:
    """Valida o lote v02 sem confundir asset aprovado com promoção ao runtime."""

    if not ANIMATION_BATCH_PATH.is_file():
        errors.append("animações v02: catálogo ausente")
        return 0, 0, 0
    catalog = load_json(ANIMATION_BATCH_PATH)
    batch_summary = dict(
        load_json(MANIFEST_PATH).get("action_animation_batch", {})
    )
    if batch_summary.get("catalog") != ANIMATION_BATCH_PATH.relative_to(ROOT).as_posix():
        errors.append("animações v02: referência do catálogo divergente no manifesto raiz")
    if batch_summary.get("catalog_sha256") != file_hash(ANIMATION_BATCH_PATH):
        errors.append("animações v02: hash do catálogo divergente no manifesto raiz")
    if catalog.get("status") != "asset_qa_complete_runtime_test_pending":
        errors.append("animações v02: status global não representa o gate pendente")

    review_board = ROOT / str(catalog.get("review_board", ""))
    if not review_board.is_file():
        errors.append("animações v02: prancha de revisão ausente")
    elif batch_summary.get("review_board_sha256") != file_hash(review_board):
        errors.append("animações v02: hash da prancha de revisão divergente")

    jobs = list(catalog.get("jobs", []))
    if batch_summary.get("pack_count") != len(jobs):
        errors.append("animações v02: pack_count divergente no manifesto raiz")
    seen_jobs: set[tuple[str, str]] = set()
    total_frames = 0
    for job in jobs:
        character_id = str(job.get("character_id", ""))
        source_action_id = str(job.get("source_action_id", ""))
        action_id = str(job.get("action_id", ""))
        job_key = (character_id, source_action_id)
        if job_key in seen_jobs:
            errors.append(f"animações v02: job duplicado {job_key}")
        seen_jobs.add(job_key)
        if character_id not in canon_ids:
            errors.append(f"animações v02/{character_id}: personagem não canônico")

        paired_id = str(job.get("paired_character_id", ""))
        if paired_id and paired_id != "training_mannequin" and paired_id not in canon_ids:
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: par não canônico {paired_id}"
            )

        raw_path = ROOT / str(job.get("raw_chroma", ""))
        anchor_path = ROOT / str(job.get("anchor", ""))
        output_dir = ROOT / str(job.get("output", ""))
        if not raw_path.is_file():
            errors.append(f"animações v02/{character_id}/{source_action_id}: fonte ausente")
        if not anchor_path.is_file():
            errors.append(f"animações v02/{character_id}/{source_action_id}: âncora ausente")

        required = [
            "raw_sheet.png",
            "clean_sheet.png",
            "spritesheet.png",
            "frames",
            "preview.gif",
            "contact_sheet.png",
            "manifest.json",
            "metadata.json",
            "source_notes.md",
            "import_notes.md",
            "qa_report.md",
        ]
        for name in required:
            if not (output_dir / name).exists():
                errors.append(
                    f"animações v02/{character_id}/{source_action_id}: saída ausente {name}"
                )

        manifest_path = output_dir / "manifest.json"
        metadata_path = output_dir / "metadata.json"
        if not manifest_path.is_file() or not metadata_path.is_file():
            continue
        animation_manifest = load_json(manifest_path)
        metadata = load_json(metadata_path)
        expected_fields = {
            "character_id": character_id,
            "source_action_id": source_action_id,
            "action_id": action_id,
            "paired_character_id": paired_id,
            "loop": bool(job.get("loop")),
            "fps": int(job.get("fps", 0)),
            "runtime_context": str(job.get("runtime_context", "")),
            "runtime_state_initial": str(job.get("runtime_state_initial", "")),
            "runtime_state_final": str(job.get("runtime_state_final", "")),
            "qa_status": str(job.get("qa_status", "")),
        }
        for field, expected in expected_fields.items():
            if animation_manifest.get(field) != expected:
                errors.append(
                    f"animações v02/{character_id}/{source_action_id}: {field} divergente"
                )
        if animation_manifest.get("placeholder") is not False:
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: placeholder inválido"
            )
        if animation_manifest.get("candidate_only") is not True:
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: candidate_only inválido"
            )
        if animation_manifest.get("runtime_gate") != "godot_4_2_and_mobile_pending":
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: gate de runtime inválido"
            )
        hash_pairs = (
            ("image", "image_sha256"),
            ("preview", "preview_sha256"),
            ("raw_sheet", "raw_sheet_sha256"),
            ("clean_sheet", "clean_sheet_sha256"),
            ("contact_sheet", "contact_sheet_sha256"),
        )
        for path_field, hash_field in hash_pairs:
            artifact = output_dir / str(animation_manifest.get(path_field, ""))
            if not artifact.is_file():
                errors.append(
                    f"animações v02/{character_id}/{source_action_id}: "
                    f"artefato {path_field} ausente"
                )
            elif animation_manifest.get(hash_field) != file_hash(artifact):
                errors.append(
                    f"animações v02/{character_id}/{source_action_id}: "
                    f"hash de {path_field} divergente"
                )
        if animation_manifest.get("events") != job.get("events", []):
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: eventos divergentes"
            )

        frame_count = int(job.get("frame_count", 0))
        frame_size = int(job.get("frame_size", 0))
        frames = sorted((output_dir / "frames").glob("*.png"))
        if len(frames) != frame_count:
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: "
                f"{len(frames)} quadros; esperado {frame_count}"
            )
            continue
        total_frames += len(frames)
        images: list[Image.Image] = []
        boxes: list[tuple[int, int, int, int] | None] = []
        for index, frame_path in enumerate(frames, start=1):
            validate_rgba_asset(
                frame_path,
                (frame_size, frame_size),
                f"animações v02/{character_id}/{source_action_id}/frame_{index:02d}",
                errors,
            )
            image = Image.open(frame_path).convert("RGBA")
            images.append(image)
            boxes.append(image.getchannel("A").getbbox())
            layout = list(animation_manifest.get("frame_layout", []))
            if index <= len(layout):
                item = dict(layout[index - 1])
                if item.get("path") != f"frames/{index:02d}.png":
                    errors.append(
                        f"animações v02/{character_id}/{source_action_id}: "
                        f"path do frame {index:02d} divergente"
                    )
                if item.get("sha256") != file_hash(frame_path):
                    errors.append(
                        f"animações v02/{character_id}/{source_action_id}: "
                        f"hash do frame {index:02d} divergente"
                    )
        if any(box is None for box in boxes):
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: quadro vazio"
            )
        else:
            bottoms = [box[3] for box in boxes if box is not None]
            if len(set(bottoms)) != 1:
                errors.append(
                    f"animações v02/{character_id}/{source_action_id}: "
                    f"linha do chão divergente {bottoms}"
                )

        if bool(job.get("lock_first_to_anchor")) and anchor_path.is_file():
            anchor = Image.open(anchor_path).convert("RGBA")
            if anchor.size != (frame_size, frame_size):
                anchor = anchor.resize((frame_size, frame_size), Image.Resampling.NEAREST)
            if ImageChops.difference(images[0], anchor).getbbox() is not None:
                errors.append(
                    f"animações v02/{character_id}/{source_action_id}: primeiro quadro não trava na âncora"
                )
        if bool(job.get("lock_last_to_anchor")) and anchor_path.is_file():
            anchor = Image.open(anchor_path).convert("RGBA")
            if anchor.size != (frame_size, frame_size):
                anchor = anchor.resize((frame_size, frame_size), Image.Resampling.NEAREST)
            if ImageChops.difference(images[-1], anchor).getbbox() is not None:
                errors.append(
                    f"animações v02/{character_id}/{source_action_id}: último quadro não trava na âncora"
                )

        atlas_path = output_dir / "spritesheet.png"
        if atlas_path.is_file():
            with Image.open(atlas_path) as atlas:
                if atlas.size != (frame_size * frame_count, frame_size):
                    errors.append(
                        f"animações v02/{character_id}/{source_action_id}: atlas mede {atlas.size}"
                    )
        preview_path = output_dir / "preview.gif"
        if preview_path.is_file():
            with Image.open(preview_path) as preview:
                if getattr(preview, "n_frames", 1) != frame_count:
                    errors.append(
                        f"animações v02/{character_id}/{source_action_id}: GIF com "
                        f"{getattr(preview, 'n_frames', 1)} quadros"
                    )
        if len(animation_manifest.get("frame_layout", [])) != frame_count:
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: frame_layout divergente"
            )
        if metadata.get("frame_count") != frame_count:
            errors.append(
                f"animações v02/{character_id}/{source_action_id}: metadata frame_count divergente"
            )

    animatic_config = dict(catalog.get("paired_animatic", {}))
    animatic_count = 0
    if animatic_config.get("status") != "asset_qa_passed_inbetweens_pending":
        errors.append("animatic v02: status de produção inválido")
    source_manifest_path = ROOT / str(animatic_config.get("source_manifest", ""))
    output_dir = ROOT / str(animatic_config.get("output", ""))
    manifest_path = output_dir / "manifest.json"
    if not source_manifest_path.is_file() or not manifest_path.is_file():
        errors.append("animatic v02: fonte ou manifesto ausente")
    else:
        source_manifest = load_json(source_manifest_path)
        animatic_manifest = load_json(manifest_path)
        source_states = [str(item.get("state", "")) for item in source_manifest.get("states", [])]
        layout_states = [
            str(item.get("state", "")) for item in animatic_manifest.get("frame_layout", [])
        ]
        animatic_count = len(source_states)
        if animatic_manifest.get("sequence_id") != animatic_config.get("id"):
            errors.append("animatic v02: sequence_id divergente")
        if animatic_manifest.get("animatic_only") is not True:
            errors.append("animatic v02: animatic_only inválido")
        if set(animatic_manifest.get("characters", [])) - canon_ids:
            errors.append("animatic v02: personagem não canônico")
        if layout_states != source_states:
            errors.append("animatic v02: ordem dos estados divergente")
        for path_field, hash_field in (
            ("image", "image_sha256"),
            ("preview", "preview_sha256"),
            ("contact_sheet", "contact_sheet_sha256"),
        ):
            artifact = output_dir / str(animatic_manifest.get(path_field, ""))
            if not artifact.is_file():
                errors.append(f"animatic v02: artefato {path_field} ausente")
            elif animatic_manifest.get(hash_field) != file_hash(artifact):
                errors.append(f"animatic v02: hash de {path_field} divergente")
        frames = sorted((output_dir / "frames").glob("*.png"))
        if len(frames) != animatic_count:
            errors.append(
                f"animatic v02: {len(frames)} quadros; esperado {animatic_count}"
            )
        for index, frame_path in enumerate(frames, start=1):
            validate_rgba_asset(
                frame_path,
                (512, 512),
                f"animatic v02/frame_{index:02d}",
                errors,
            )
            if index <= len(animatic_manifest.get("frame_layout", [])):
                item = dict(animatic_manifest["frame_layout"][index - 1])
                if item.get("sha256") != file_hash(frame_path):
                    errors.append(f"animatic v02: hash do frame {index:02d} divergente")
        atlas_path = output_dir / "spritesheet.png"
        if atlas_path.is_file():
            with Image.open(atlas_path) as atlas:
                if atlas.size != (512 * animatic_count, 512):
                    errors.append(f"animatic v02: atlas mede {atlas.size}")
            if (
                batch_summary.get("paired_animatic_spritesheet_sha256")
                != file_hash(atlas_path)
            ):
                errors.append("animatic v02: hash do atlas divergente no manifesto raiz")
        else:
            errors.append("animatic v02: spritesheet ausente")
        for name in ("preview.gif", "contact_sheet.png", "source_notes.md"):
            if not (output_dir / name).is_file():
                errors.append(f"animatic v02: saída ausente {name}")

    if batch_summary.get("frame_count") != total_frames:
        errors.append("animações v02: frame_count divergente no manifesto raiz")
    if batch_summary.get("paired_animatic_frame_count") != animatic_count:
        errors.append("animatic v02: contagem divergente no manifesto raiz")
    return len(jobs), total_frames, animatic_count


def main() -> None:
    errors: list[str] = []
    manifest = load_json(MANIFEST_PATH)
    canon_data = load_json(ROOT / "data/characters.json")
    canon_ids = {
        item["id"] for item in canon_data.get("characters", []) if item.get("canon") is True
    }
    entries = manifest.get("characters", [])
    manifest_ids = {item.get("id") for item in entries}
    if manifest_ids != canon_ids:
        errors.append(
            f"elenco divergente: manifesto={sorted(manifest_ids)}, canon={sorted(canon_ids)}"
        )

    for entry in entries:
        character_id = str(entry.get("id", ""))
        for field in ("model_sheet", "dialogue_portrait", "idle_seed"):
            asset = entry.get(field, {})
            path = ROOT / str(asset.get("path", ""))
            if not path.is_file():
                errors.append(f"{character_id}/{field}: arquivo ausente")
                continue
            expected_hash = asset.get("sha256")
            if expected_hash and file_hash(path) != expected_hash:
                errors.append(f"{character_id}/{field}: sha256 divergente")

        model_path = ROOT / entry["model_sheet"]["path"]
        if model_path.is_file():
            with Image.open(model_path) as model:
                if model.width < 1500 or model.height < 900:
                    errors.append(f"{character_id}/model_sheet: resolucao insuficiente {model.size}")

        validate_rgba_asset(
            ROOT / entry["dialogue_portrait"]["path"],
            (512, 512),
            f"{character_id}/dialogue_portrait",
            errors,
        )
        validate_rgba_asset(
            ROOT / entry["idle_seed"]["path"],
            (256, 256),
            f"{character_id}/idle_seed",
            errors,
        )

    characters_by_id = {str(entry["id"]): entry for entry in entries}
    validate_ruan_vertical_slice(errors)
    validate_additional_vertical_slices(manifest, characters_by_id, errors)
    pose_count, paired_key_count = validate_action_pose_library(canon_ids, errors)
    apixel_source_count = validate_apixel_generated_sources(errors)
    animation_pack_count, animation_frame_count, animatic_frame_count = (
        validate_action_animation_batch(canon_ids, errors)
    )
    report = {
        "ok": not errors,
        "manifest": str(MANIFEST_PATH.relative_to(ROOT)),
        "canonical_characters": len(canon_ids),
        "model_sheets": len(entries),
        "dialogue_portraits": len(entries),
        "animation_seeds": len(entries),
        "vertical_slices": len(manifest.get("vertical_slices", [])),
        "action_key_poses": pose_count,
        "paired_combat_keys": paired_key_count,
        "priority_action_packs": animation_pack_count,
        "priority_action_frames": animation_frame_count,
        "paired_animatic_frames": animatic_frame_count,
        "apixel_4k_sources": apixel_source_count,
        "errors": errors,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
