#!/usr/bin/env python3
"""Generate deterministic, license-clean placeholder animation packs for Godot."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FRAME = 128
COUNT = 8

CHARACTERS = {
    "ruan_macacao": {"gi": "#eee9dc", "skin": "#8b4f2c", "accent": "#b8860b", "hair": "#15100d", "build": 1.10},
    "davi_relampago": {"gi": "#284f7a", "skin": "#7d4528", "accent": "#e9edf1", "hair": "#111111", "build": 0.92},
    "mestre_dende": {"gi": "#d8d0bd", "skin": "#6f4428", "accent": "#8d6a20", "hair": "#d8d0bd", "build": 1.00},
    "tinker_bell": {"gi": "#17191d", "skin": "#8b4f2c", "accent": "#1e8fa8", "hair": "#14100d", "build": 0.90},
    "cassio_molho": {"gi": "#b43d21", "skin": "#7f482d", "accent": "#f0a51a", "hair": "#17100d", "build": 1.04},
    "kenzo_kuroi": {"gi": "#202433", "skin": "#b47b58", "accent": "#7661ad", "hair": "#101217", "build": 0.96},
    "leoa_quilombola": {"gi": "#3b5030", "skin": "#704025", "accent": "#c79232", "hair": "#18100c", "build": 1.02},
    "oni_da_lapa": {"gi": "#27272a", "skin": "#75452f", "accent": "#b82e36", "hair": "#0e0e0f", "build": 1.22},
}

PACKS = {
    "ruan_macacao": ["idle", "walk", "stance", "grip"],
    "davi_relampago": ["idle", "walk", "defense"],
    "mestre_dende": ["idle", "teaching"],
    "tinker_bell": ["idle", "recording"],
    "cassio_molho": ["idle", "walk", "stance", "provocation"],
    "kenzo_kuroi": ["idle", "walk", "stance", "counter"],
    "leoa_quilombola": ["idle", "walk", "base", "sweep_setup"],
    "oni_da_lapa": ["idle", "walk", "stance", "pressure"],
}

PAIRED = ["grip_fight", "baiana_entry", "cem_quilos_control", "tap_reset"]

def snap(v: float) -> int:
    return int(round(v / 2.0) * 2)

def draw_fighter(im: Image.Image, cid: str, action: str, frame: int, xoff: int = 0, mirror: bool = False, scale: float = 1.0) -> None:
    p = CHARACTERS[cid]
    d = ImageDraw.Draw(im)
    phase = frame / COUNT
    bob = snap((1 if frame % 4 in (1, 2) else 0) * 2)
    walk = snap((frame % 4 - 1.5) * 3) if action == "walk" else 0
    cx = xoff + FRAME // 2 + walk
    cy = 96 + bob
    lean = -5 if action in {"stance", "grip", "defense", "counter", "base", "sweep_setup", "pressure"} else 0
    if mirror:
        lean *= -1
    width = snap(24 * p["build"] * scale)
    torso_h = snap(34 * scale)
    head_r = snap(10 * scale)
    head_y = cy - torso_h - 26
    # shadow
    d.ellipse((cx-width, cy+10, cx+width, cy+17), fill=(0,0,0,70))
    # legs with readable alternation
    stride = snap((6 if frame % 4 in (0, 3) else -4) * scale) if action == "walk" else 0
    d.line((cx-8, cy-12, cx-12-stride, cy+11), fill=p["gi"], width=max(4, snap(7*scale)))
    d.line((cx+8, cy-12, cx+12+stride, cy+11), fill=p["gi"], width=max(4, snap(7*scale)))
    d.line((cx-15-stride, cy+12, cx-7-stride, cy+12), fill=p["skin"], width=max(3, snap(4*scale)))
    d.line((cx+8+stride, cy+12, cx+16+stride, cy+12), fill=p["skin"], width=max(3, snap(4*scale)))
    # torso and belt
    d.polygon([(cx-width+lean, cy-torso_h), (cx+width+lean, cy-torso_h), (cx+width-4, cy-8), (cx-width+4, cy-8)], fill=p["gi"], outline="#111111")
    d.rectangle((cx-width+3, cy-15, cx+width-3, cy-10), fill=p["accent"])
    # head and hair
    d.ellipse((cx-head_r+lean, head_y-head_r, cx+head_r+lean, head_y+head_r), fill=p["skin"], outline="#111111")
    d.pieslice((cx-head_r-2+lean, head_y-head_r-4, cx+head_r+2+lean, head_y+head_r), 180, 360, fill=p["hair"])
    eye = cx + (4 if not mirror else -4) + lean
    d.rectangle((eye, head_y-1, eye+1, head_y), fill="#f2f2f2")
    # arms/actions
    shoulder_y = cy-torso_h+8
    reach = 0
    if action in {"grip", "stance", "defense", "counter", "base", "sweep_setup", "pressure"}: reach = 15 + (frame % 3) * 2
    elif action == "teaching": reach = 10 + frame % 4
    elif action == "recording": reach = 7
    elif action == "provocation": reach = 12 + (frame % 4) * 2
    sign = -1 if mirror else 1
    d.line((cx-width+4+lean, shoulder_y, cx-width-7-sign*reach//3, shoulder_y+18), fill=p["gi"], width=max(4, snap(7*scale)))
    d.line((cx+width-4+lean, shoulder_y, cx+width+sign*reach, shoulder_y+10-(reach//3)), fill=p["gi"], width=max(4, snap(7*scale)))
    d.ellipse((cx+width+sign*reach-3, shoulder_y+6-(reach//3), cx+width+sign*reach+4, shoulder_y+13-(reach//3)), fill=p["skin"])
    if action == "recording":
        d.rounded_rectangle((cx+width+sign*reach-1, shoulder_y-8, cx+width+sign*reach+7, shoulder_y+8), 2, fill="#0b0b0b", outline=p["accent"])

def draw_pair(action: str, frame: int) -> Image.Image:
    im = Image.new("RGBA", (FRAME, FRAME), (0,0,0,0))
    if action == "grip_fight":
        draw_fighter(im, "ruan_macacao", "grip", frame, -22, False, .86)
        draw_fighter(im, "davi_relampago", "defense", frame, 22, True, .86)
    elif action == "baiana_entry":
        draw_fighter(im, "davi_relampago", "defense", frame, 25, True, .82)
        # Ruan lowers progressively to communicate level change.
        temp = Image.new("RGBA", (FRAME, FRAME), (0,0,0,0))
        draw_fighter(temp, "ruan_macacao", "stance", frame, -22 + frame*2, False, .84)
        im.alpha_composite(temp.transform(temp.size, Image.AFFINE, (1,0,0,0,1,frame*3), resample=Image.Resampling.NEAREST))
    else:
        # Ground interaction: broad, stable paired silhouettes.
        d = ImageDraw.Draw(im)
        shift = (frame % 3) * 2
        d.ellipse((20,82,108,100), fill=(0,0,0,65))
        d.rounded_rectangle((38,61+shift,102,86+shift), 8, fill=CHARACTERS["davi_relampago"]["gi"], outline="#111111")
        d.ellipse((92,62+shift,111,81+shift), fill=CHARACTERS["davi_relampago"]["skin"], outline="#111111")
        d.rounded_rectangle((24,43-shift,82,70-shift), 8, fill=CHARACTERS["ruan_macacao"]["gi"], outline="#111111")
        d.ellipse((20,42-shift,40,62-shift), fill=CHARACTERS["ruan_macacao"]["skin"], outline="#111111")
        d.rectangle((35,62-shift,76,67-shift), fill=CHARACTERS["ruan_macacao"]["accent"])
        if action == "tap_reset" and frame in {2,4,6}:
            d.line((93,55,106,45), fill=CHARACTERS["davi_relampago"]["skin"], width=5)
            d.ellipse((103,41,111,49), fill=CHARACTERS["davi_relampago"]["skin"])
    return im

def write_pack(character_id: str, action: str, frames: list[Image.Image], paired: bool = False) -> dict:
    base = ROOT / "assets" / "sprites" / character_id / action
    base.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (FRAME * COUNT, FRAME), (0,0,0,0))
    for i, frame in enumerate(frames): sheet.alpha_composite(frame, (i*FRAME, 0))
    sheet.save(base / "sprite_sheet.png", optimize=True)
    durations = 140 if action == "idle" else 100
    frames[0].save(base / "preview.gif", save_all=True, append_images=frames[1:], duration=durations, loop=0, disposal=2, transparency=0)
    events = []
    if action == "grip_fight": events = [{"frame":3,"name":"grip_connect"}]
    elif action == "baiana_entry": events = [{"frame":2,"name":"weight_commit"},{"frame":6,"name":"off_balance"}]
    elif action == "cem_quilos_control": events = [{"frame":5,"name":"control_stable"}]
    elif action == "tap_reset": events = [{"frame":2,"name":"tap_window"},{"frame":7,"name":"reset_ready"}]
    manifest = {
        "version":"1.0.0", "character_id":character_id, "action_id":action,
        "paired_character_id":"davi_relampago" if paired else "", "image":"sprite_sheet.png",
        "preview":"preview.gif", "placeholder":True, "license":"CC0-1.0 project-generated",
        "interaction_origin":{"x":64,"y":96}, "events":events,
        "frame_layout":[{"index":i,"state":action,"x":i*FRAME,"y":0,"w":FRAME,"h":FRAME,"duration_ms":durations,"pivot":{"x":64,"y":96}} for i in range(COUNT)]
    }
    (base / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    (base / "source_notes.md").write_text("# Source notes\n\nPlaceholder vetorial/pixel determinístico gerado no próprio projeto. Sem modelo externo, marca ou captura protegida. Substituir por arte final revisada sem alterar o contrato do manifesto.\n", encoding="utf-8")
    return {"character_id":character_id,"action_id":action,"manifest":str(base.relative_to(ROOT)/"manifest.json"),"placeholder":True}

def generate() -> None:
    catalog=[]
    for cid, actions in PACKS.items():
        for action in actions:
            frames=[]
            for i in range(COUNT):
                im=Image.new("RGBA",(FRAME,FRAME),(0,0,0,0)); draw_fighter(im,cid,action,i); frames.append(im)
            catalog.append(write_pack(cid,action,frames))
    for action in PAIRED:
        catalog.append(write_pack("ruan_macacao",action,[draw_pair(action,i) for i in range(COUNT)],True))
    out={"version":"1.0.0","format":"godot_absolute_rect_atlas","generated_placeholders":True,"entries":catalog}
    path=ROOT/"data/visual/character_animation_catalog_v01.json"
    path.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

def validate() -> None:
    catalog=json.loads((ROOT/"data/visual/character_animation_catalog_v01.json").read_text(encoding="utf-8"))
    assert len(catalog["entries"]) == sum(len(actions) for actions in PACKS.values()) + len(PAIRED)
    for entry in catalog["entries"]:
        mp=ROOT/entry["manifest"]; m=json.loads(mp.read_text(encoding="utf-8")); base=mp.parent
        assert (base/m["image"]).is_file() and (base/m["preview"]).is_file()
        assert len(m["frame_layout"]) == COUNT
        with Image.open(base/m["image"]) as im: assert im.size == (FRAME*COUNT,FRAME)
    print(f"Animation pack validated: {len(catalog['entries'])} packs")

def main() -> None:
    ap=argparse.ArgumentParser(); ap.add_argument("--validate-only",action="store_true"); args=ap.parse_args()
    if not args.validate_only: generate()
    validate()

if __name__ == "__main__": main()
