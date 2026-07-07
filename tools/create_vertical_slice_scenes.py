#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

FILES = {
    "scenes/boot.tscn": """[gd_scene load_steps=2 format=3]

[ext_resource type=\"Script\" path=\"res://scenes/boot.gd\" id=\"1\"]

[node name=\"Boot\" type=\"Node\"]
script = ExtResource(\"1\")
""",
    "scenes/main_menu.tscn": """[gd_scene load_steps=2 format=3]

[ext_resource type=\"Script\" path=\"res://scenes/main_menu.gd\" id=\"1\"]

[node name=\"MainMenuVS01\" type=\"Control\"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource(\"1\")
""",
    "scenes/hubs/terreiro_da_luta.tscn": """[gd_scene load_steps=2 format=3]

[ext_resource type=\"Script\" path=\"res://scenes/hubs/terreiro_da_luta.gd\" id=\"1\"]

[node name=\"TerreiroDaLutaVS01\" type=\"Control\"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource(\"1\")
""",
}


def main() -> int:
    for rel, content in FILES.items():
        path = ROOT / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_text(content, encoding="utf-8")
            print("criado", rel)
        else:
            print("mantido", rel)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
