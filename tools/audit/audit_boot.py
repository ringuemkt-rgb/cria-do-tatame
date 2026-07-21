#!/usr/bin/env python3
# Auditoria estática de boot + duplicação. Sem Godot, sem rede, determinístico.
# Uso: python tools/audit/audit_boot.py <raiz_do_projeto>
import os, re, sys, json, glob
ROOT = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
PROJECT = os.path.join(ROOT, "project.godot")
report = {"autoloads": [], "missing": [], "scenes_refs_missing": [], "main_scene": None, "ok": True}
def read(p):
    try:
        with open(p, encoding="utf-8") as f: return f.read()
    except Exception: return ""
godot = read(PROJECT)
m_main = re.search(r'run/main_scene\s*=\s*"([^"]+)"', godot)
if m_main:
    report["main_scene"] = m_main.group(1)
    mp = os.path.join(ROOT, m_main.group(1).replace("res://", ""))
    if not os.path.exists(mp):
        report["missing"].append(("main_scene", m_main.group(1))); report["ok"] = False
in_auto = False
for line in godot.splitlines():
    if line.strip() == "[autoload]": in_auto = True; continue
    if line.startswith("[") and line.strip() != "[autoload]": in_auto = False
    if in_auto and "=" in line:
        name, val = line.split("=", 1)
        path = re.search(r'"?\*?res://([^"]+)"?', val.strip())
        if path:
            fp = os.path.join(ROOT, path.group(1)); exists = os.path.exists(fp)
            report["autoloads"].append({"name": name.strip(), "path": path.group(1), "exists": exists})
            if not exists:
                report["missing"].append(("autoload", name.strip(), path.group(1))); report["ok"] = False
for tscn in glob.glob(os.path.join(ROOT, "**", "*.tscn"), recursive=True):
    for ref in re.findall(r'path="res://([^"]+)"', read(tscn)):
        if not os.path.exists(os.path.join(ROOT, ref)):
            report["scenes_refs_missing"].append({"scene": os.path.relpath(tscn, ROOT), "ref": ref}); report["ok"] = False
def has(rel): return os.path.exists(os.path.join(ROOT, rel))
report["dup_candidates"] = [
    {"pair": "CombatManager vs TransitionManager", "both_present": has("src/autoloads/combat_manager.gd") and has("src/combat/transition_manager.gd")},
    {"pair": "AudioManager vs CombatAudio", "both_present": has("src/autoloads/audio_manager.gd") and has("src/audio/combat_audio_manager.gd")},
]
print(json.dumps(report, indent=2, ensure_ascii=False))
sys.exit(0 if report["ok"] and not report["scenes_refs_missing"] else 1)
