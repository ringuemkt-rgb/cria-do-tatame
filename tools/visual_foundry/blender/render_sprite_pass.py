"""Blender headless sprite render pass for Cria Visual Foundry v1.

Example:
  blender -b character.blend -P tools/visual_foundry/blender/render_sprite_pass.py -- \
    --armature RuanRig --actions idle_combat walk_forward baiana \
    --output production/visual_foundry/ruan_macacao/renders

The script intentionally performs rendering only. Pixel cleanup, outline and final
packing remain responsibilities of the existing Sprite Forge pipeline.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import bpy  # type: ignore
except ImportError:  # pragma: no cover - expected outside Blender
    bpy = None


def parse_args() -> argparse.Namespace:
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--armature", required=True)
    parser.add_argument("--actions", nargs="+", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--camera", default="CriaOrthoCamera")
    parser.add_argument("--resolution", type=int, default=1024)
    parser.add_argument("--frame-step", type=int, default=1)
    return parser.parse_args(argv)


def require_blender() -> None:
    if bpy is None:
        raise RuntimeError("render_sprite_pass.py must be executed by Blender")


def configure_scene(camera_name: str, resolution: int) -> None:
    scene = bpy.context.scene
    camera = bpy.data.objects.get(camera_name)
    if camera is None or camera.type != "CAMERA":
        raise RuntimeError(f"missing orthographic camera: {camera_name}")
    if camera.data.type != "ORTHO":
        raise RuntimeError(f"camera {camera_name} must be ORTHO")

    scene.camera = camera
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.film_transparent = True
    scene.render.resolution_x = resolution
    scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "Medium High Contrast"


def attach_action(armature, action_name: str):
    action = bpy.data.actions.get(action_name)
    if action is None:
        raise RuntimeError(f"missing Blender action: {action_name}")
    if armature.animation_data is None:
        armature.animation_data_create()
    armature.animation_data.action = action
    return action


def render_action(armature, action_name: str, output_root: Path, frame_step: int) -> dict:
    action = attach_action(armature, action_name)
    start, end = (int(round(v)) for v in action.frame_range)
    action_dir = output_root / action_name
    action_dir.mkdir(parents=True, exist_ok=True)
    frames = []

    for frame in range(start, end + 1, max(frame_step, 1)):
        bpy.context.scene.frame_set(frame)
        path = action_dir / f"{action_name}_{frame:04d}.png"
        bpy.context.scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        frames.append({"frame": frame, "file": path.name})

    return {
        "action": action_name,
        "start": start,
        "end": end,
        "frame_step": frame_step,
        "frames": frames,
    }


def main() -> int:
    require_blender()
    args = parse_args()
    armature = bpy.data.objects.get(args.armature)
    if armature is None or armature.type != "ARMATURE":
        raise RuntimeError(f"missing armature: {args.armature}")

    configure_scene(args.camera, args.resolution)
    args.output.mkdir(parents=True, exist_ok=True)

    manifest = {
        "schema_version": 1,
        "renderer": "blender",
        "camera": args.camera,
        "resolution": [args.resolution, args.resolution],
        "background": "transparent_rgba",
        "actions": [],
    }
    for action_name in args.actions:
        manifest["actions"].append(
            render_action(armature, action_name, args.output, args.frame_step)
        )

    (args.output / "render_manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"Rendered {len(args.actions)} actions into {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
