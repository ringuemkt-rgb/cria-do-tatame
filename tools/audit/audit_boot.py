#!/usr/bin/env python3
import glob
import json
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
PROJECT = os.path.join(ROOT, "project.godot")
report = {
    "autoloads": [],
    "missing": [],
    "scenes_refs_missing": [],
    "main_scene": None,
    "ok": True,
}


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except Exception:
        return ""


godot = read(PROJECT)
match = re.search(r'run/main_scene\s*=\s*"([^"]+)"', godot)
if match:
    report["main_scene"] = match.group(1)
    if not os.path.exists(os.path.join(ROOT, match.group(1).replace("res://", ""))):
        report["missing"].append(("main_scene", match.group(1)))
        report["ok"] = False

in_autoload = False
for line in godot.splitlines():
    if line.strip() == "[autoload]":
        in_autoload = True
        continue
    if line.startswith("[") and line.strip() != "[autoload]":
        in_autoload = False
    if in_autoload and "=" in line:
        name, value = line.split("=", 1)
        path_match = re.search(r'"?\*?res://([^"]+)"?', value.strip())
        if path_match:
            exists = os.path.exists(os.path.join(ROOT, path_match.group(1)))
            report["autoloads"].append(
                {"name": name.strip(), "path": path_match.group(1), "exists": exists}
            )
            if not exists:
                report["missing"].append(("autoload", name.strip(), path_match.group(1)))
                report["ok"] = False

for scene in glob.glob(os.path.join(ROOT, "**", "*.tscn"), recursive=True):
    for ref in re.findall(r'path="res://([^"]+)"', read(scene)):
        if not os.path.exists(os.path.join(ROOT, ref)):
            report["scenes_refs_missing"].append(
                {"scene": os.path.relpath(scene, ROOT), "ref": ref}
            )
            report["ok"] = False

print(json.dumps(report, indent=2, ensure_ascii=False))
sys.exit(0 if report["ok"] and not report["scenes_refs_missing"] else 1)
