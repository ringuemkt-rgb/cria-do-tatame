#!/usr/bin/env python3
"""Measure candidate identity atlases; never edit pixels or approve shipping art.

Uses the existing narrative/roster authorities and identity-master schema.
The generated manifest is consumed only by the Godot authoring review scene.
"""
from __future__ import annotations

import argparse
import configparser
import fnmatch
import hashlib
import json
from collections import Counter
from pathlib import Path

from PIL import Image
import jsonschema
import numpy as np
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = Path("production/character_art_v1")
SOURCES = PACKAGE / "authoring_sources.json"
MANIFEST = PACKAGE / "atlas_manifest.json"
ALIASES = {
    "jacare_mangue": "jacare_do_mangue",
    "delegado_montenegro": "montenegro",
    "mestre_viera_arquetipo": "viera",
    "mestre_miyao_arquetipo": "miyao",
    "mestre_galvao_arquetipo": "galvao",
}
EXCLUDED = {"teruko_nishiuchi": "memory_fragments_only", "coro": "no_fixed_body"}
DIRECTIONS = ("front", "side_right", "back")
CHILD_HEIGHTS = {"biel": 64, "pedro_bala": 66, "dandara": 48, "pipoca": 46, "foguete": 56}
NO_GI = {"oni_da_lapa", "oni_do_sul", "byaku", "viera", "miyao", "galvao"}
GI = {"ruan_macacao", "davi_relampago", "leoa", "mestre_dende", "kenzo_kuroi",
      "jacare_do_mangue", "mateus_predador", "verao_velho", "ruan_do_avesso", "degodo", "pipoca"}


def read(path: str | Path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def write(path: Path, value) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def authorities():
    bible_path = "data/narrative/character_bible_v1.json"
    fixes_path = "data/narrative/narrative_v3_fixes_characters.json"
    bible = read(bible_path)
    fixes = read(fixes_path)
    people = {}
    for path, records in ((bible_path, bible["characters"]), (fixes_path, fixes["characters"])):
        for record in records:
            source_id = record["id"]
            identity = ALIASES.get(source_id, source_id)
            assert identity not in people, f"Duplicate canonical person: {identity}"
            people[identity] = {**record, "source_id": source_id, "canon_refs": [
                "data/narrative/canon_v3.json", f"{path}#{source_id}"]}
    for override in fixes["character_overrides"]:
        entry = people[override["id"]]
        for field in override["supersedes_fields"]:
            entry[field] = override[field]
        entry["canon_refs"].append(f"{fixes_path}#character_overrides/{override['id']}")
    roster = {fighter["id"]: fighter for fighter in read("data/combat/roster_v3.json")["fighters"]}
    assert set(roster) <= set(people), "Roster has no narrative identity"
    return people, roster


def rect_inside(inner, outer) -> bool:
    x, y, w, h = inner
    ox, oy, ow, oh = outer
    return w > 0 and h > 0 and x >= ox and y >= oy and x + w <= ox + ow and y + h <= oy + oh


def source_regions(image, rows):
    """Detect actual isolated bodies; never assume the provider obeyed a grid."""
    alpha = np.asarray(image.getchannel("A"))
    labels, _ = ndimage.label(alpha >= 192, structure=np.ones((3, 3)))
    areas = np.bincount(labels.ravel())
    areas[0] = 0
    bodies = np.flatnonzero(areas >= 500)
    assert len(bodies) == rows * 3, f"Expected {rows*3} isolated bodies, found {len(bodies)}; regenerate spacing"
    objects = ndimage.find_objects(labels)
    bounds = []
    for label in bodies:
        ys, xs = objects[label - 1]
        bounds.append([xs.start, ys.start, xs.stop-xs.start, ys.stop-ys.start])
    bounds.sort(key=lambda rect: rect[1])
    ordered = []
    for row in range(rows):
        ordered.extend(sorted(bounds[row*3:(row+1)*3], key=lambda rect: rect[0]))
    return ordered


def measured_frame(image, bounds, direction):
    bx, by, bw, bh = bounds
    x, y = max(0, bx-2), max(0, by-2)
    ex, ey = min(image.width, bx+bw+2), min(image.height, by+bh+2)
    region = [x, y, ex-x, ey-y]
    x, y, width, height = region
    # Read-only measurement of one region, never saves or changes source art.
    pixels = image.crop((x, y, x + width, y + height))
    alpha = pixels.getchannel("A")
    histogram = alpha.histogram()
    count = width * height
    partial = sum(histogram[1:255])
    return {
        "direction": direction,
        "source_rect": region,
        "content_rect": bounds,
        "segmentation": "isolated_opaque_body_component",
        "measurement_alpha_threshold": 192,
        "partial_alpha_fraction": round(partial / count, 6),
        "source_edge_touch": bx == 0 or by == 0 or bx+bw == image.width or by+bh == image.height,
    }


def measure():
    sources = read(SOURCES)
    people, roster = authorities()
    expected = set(people) - set(EXCLUDED)
    seen = set()
    atlases, characters = [], []
    for atlas in sources["atlases"]:
        relative = Path(atlas["image"])
        assert relative.parts[:3] == ("assets", "candidates", "characters"), relative
        path = ROOT / relative
        image = Image.open(path)
        assert image.mode == "RGBA", f"RGBA required: {path}"
        assert image.getchannel("A").getextrema() == (0, 255), f"True alpha missing: {path}"
        width, height = image.size
        cols, rows = atlas["columns"], atlas["rows"]
        assert cols == 3 and rows == len(atlas["members"])
        regions = source_regions(image, rows)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        atlases.append({"id": atlas["id"], "image": str(relative), "size_px": [width, height],
                        "sha256": digest, "grid": [cols, rows], "shipping": False})
        for row, identity in enumerate(atlas["members"]):
            assert identity in expected and identity not in seen, f"Invalid/duplicate person {identity}"
            seen.add(identity)
            person = people[identity]
            frames = [measured_frame(image, regions[row*3+col], direction)
                      for col, direction in enumerate(DIRECTIONS)]
            # Signature is a proposal sampled from visible pixels, not a palette cleanup.
            x, y, w, h = frames[0]["content_rect"]
            front = image.crop((x, y, x+w, y+h))
            front_pixels = front.get_flattened_data() if hasattr(front, "get_flattened_data") else front.getdata()
            colors = Counter(tuple(min(255, (channel // 32)*32 + 16) for channel in rgba[:3])
                             for rgba in front_pixels if rgba[3] >= 192)
            palette = ["#%02X%02X%02X" % rgb for rgb, _ in colors.most_common(8)]
            refs = list(person["canon_refs"])
            if identity in roster:
                refs.append("data/combat/roster_v3.json#" + identity)
            aliases = [person["source_id"]] if person["source_id"] != identity else []
            if identity == "leoa":
                aliases.append("leoa_quilombola")
            variant = "nogi" if identity in NO_GI else "gi" if identity in GI else "civil"
            pose_refs = {"turnaround": str(relative), "front_combat_pose": None,
                         "back_view": str(relative), "side_view": str(relative)}
            empty_refs = dict.fromkeys(pose_refs)
            identity_master = {
                "character_id": identity, "canon_refs": refs, "master_status": "PENDING",
                "palette_signature": {"colors": palette, "notes": "Sampled proposal; no pixel palette normalization."},
                "silhouette_signature": {"reference_asset": str(relative),
                    "body_ratio_notes": person["visual"]["silhueta"]},
                "asymmetry_contract": {"horizontal_mirror_safe": False,
                    "notes": "Use authored right-facing view only. Review patches, props, knee support, towel and grips before authoring left."},
                "variants": {"gi": pose_refs if variant == "gi" else empty_refs,
                             "nogi": pose_refs if variant == "nogi" else empty_refs},
                "human_reviewer": None, "rights_status": "PENDING", "shipping": False,
            }
            identity_path = PACKAGE / "identities" / f"{identity}.json"
            characters.append({
                "character_id": identity, "aliases": aliases,
                "display_name": roster.get(identity, {}).get("display_name", person["nome"]),
                "kind": "fighter" if identity in roster else "support",
                "narrative_role": person["papel"], "source_character_id": person["source_id"],
                "canon_refs": refs, "atlas_id": atlas["id"], "image": str(relative), "row": row,
                "appearance_variant": variant, "frames": frames,
                "preview_frame_px": [128, 128], "preview_pivot_px": [64, 96],
                "preview_body_height_px": CHILD_HEIGHTS.get(identity, 56 if identity == "dona_zefa" else 72),
                "identity_master": str(identity_path), "palette_proposal": palette,
                "master_status": "PENDING", "rights_status": "PENDING", "human_review": "PENDING",
                "animation_status": "NOT_AUTHORED", "normalization_status": "PENDING_PIXEL_CLEANUP",
                "shipping": False, "_identity_master": identity_master,
            })
    assert seen == expected, f"Missing characters: {sorted(expected - seen)}"
    manifest = {"schema_version": 1, "status": "CANDIDATE_AUTHORING_PACKAGE", "shipping": False,
        "source_authority": "data/narrative/canon_v3.json", "gameplay_authority": False,
        "consumer": "tools/art/CharacterAtlasReview.tscn", "directions": list(DIRECTIONS),
        "character_count": len(characters), "fighter_count": len(roster),
        "frame_count": sum(len(c["frames"]) for c in characters), "atlases": atlases,
        "excluded_non_corporeal": EXCLUDED, "characters": characters}
    return manifest


def validate(manifest):
    schema = read("assets/schemas/character_identity_master_v2.schema.json")
    people, roster = authorities()
    assert manifest["shipping"] is False and manifest["gameplay_authority"] is False
    assert {c["character_id"] for c in manifest["characters"]} == set(people) - set(EXCLUDED)
    assert {c["character_id"] for c in manifest["characters"] if c["kind"] == "fighter"} == set(roster)
    aliases = set()
    warnings = Counter()
    for character in manifest["characters"]:
        assert character["shipping"] is False
        assert character["animation_status"] == "NOT_AUTHORED"
        assert character["preview_frame_px"] == [128, 128] and character["preview_pivot_px"] == [64, 96]
        for alias in [character["character_id"]] + character["aliases"]:
            assert alias not in aliases, f"Duplicate alias {alias}"
            aliases.add(alias)
        master = read(character["identity_master"])
        jsonschema.validate(master, schema)
        assert master["character_id"] == character["character_id"]
        assert master["master_status"] == "PENDING" and master["human_reviewer"] is None
        assert [f["direction"] for f in character["frames"]] == list(DIRECTIONS)
        for frame in character["frames"]:
            assert rect_inside(frame["content_rect"], frame["source_rect"])
            if frame["source_edge_touch"]:
                warnings["source_edge_touch"] += 1
            if frame["partial_alpha_fraction"] > 0:
                warnings["source_has_partial_alpha"] += 1
    for atlas in manifest["atlases"]:
        image_path = ROOT / atlas["image"]
        assert hashlib.sha256(image_path.read_bytes()).hexdigest() == atlas["sha256"]
    # all_resources export would otherwise bundle unreviewed source art.
    presets = configparser.ConfigParser()
    presets.read(ROOT / "export_presets.cfg")
    for section in presets.sections():
        if section.endswith(".options"):
            continue
        filters = presets[section].get("exclude_filter", "").strip('"').split(",")
        for path in [a["image"] for a in manifest["atlases"]] + [
            "production/character_art_v1/atlas_manifest.json", "tools/art/CharacterAtlasReview.tscn"]:
            assert any(fnmatch.fnmatchcase(path, pattern) for pattern in filters), f"Candidate would export in {section}: {path}"
    return {"ok": True, "characters": manifest["character_count"], "frames": manifest["frame_count"],
            "fighters": manifest["fighter_count"], "source_warnings": dict(warnings),
            "shipping_ready": False, "reason": "Source atlases need pixel cleanup, directional/identity/rights review and animation."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Measure original source pixels and write candidate sidecars")
    args = parser.parse_args()
    if args.write:
        manifest = measure()
        for character in manifest["characters"]:
            write(Path(character["identity_master"]), character.pop("_identity_master"))
        write(MANIFEST, manifest)
    print(json.dumps(validate(read(MANIFEST)), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
