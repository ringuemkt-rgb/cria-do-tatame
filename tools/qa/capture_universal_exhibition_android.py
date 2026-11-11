#!/usr/bin/env python3
"""Human-operated Android screenshots for Universal Exhibition candidate QA.

Requires local ADB and one authorized real device. No remote uploads,
no installation, no shipping certification, no modification of game data.
Screenshots alone cannot prove touchscreen, FPS or save persistence.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

PACKAGE = "com.criadotatame.pressao"
STEPS = (
    ("01_exhibition_selection", "Abra a tela Exibição Livre mostrando o elenco."),
    ("02_leoa_vs_jacare_standing", "Inicie Leoa x Jacaré e mostre os lutadores em pé."),
    ("03_leoa_vs_jacare_grappling", "Execute uma técnica e mostre o contato no chão."),
    ("04_miyao_vs_viera", "Mostre Miyao x Viera com a ordem de papéis invertida."),
    ("05_exhibition_result", "Mostre o resultado da exibição sem recompensas."),
    ("06_campaign_after_exhibition", "Volte à campanha e confirme os dados anteriores."),
)


def adb(serial: str | None, *args: str, binary: bool = False):
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd.extend(args)
    proc = subprocess.run(cmd, capture_output=True, check=True)
    return proc.stdout if binary else proc.stdout.decode("utf-8", errors="replace").strip()


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path, help="Existing APK file to record SHA-256; no installation")
    parser.add_argument("--serial", help="Explicit authorized adb serial if multiple devices")
    parser.add_argument("--out", type=Path, help="New output folder outside the game repository")
    args = parser.parse_args()
    if not shutil.which("adb"):
        parser.error("adb executable not installed on this computer")
    if args.apk is not None and not args.apk.is_file():
        parser.error("APK does not exist")
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    dest = (args.out or Path("/tmp") / ("cria-universal-exhibition-" + stamp)).expanduser().resolve()
    if dest.exists():
        parser.error("output folder must not exist; refusing overwrite")
    try:
        if adb(args.serial, "get-state") != "device":
            raise RuntimeError("ADB device is not authorized and ready")
        dest.mkdir(parents=True)
        info = {
            "schema": "cria.universal_exhibition_android_human_qa.v1",
            "status": "PENDING_HUMAN_REVIEW",
            "shipping": False,
            "human_approved": False,
            "visual_qa_passed": False,
            "device_manufacturer": adb(args.serial, "shell", "getprop", "ro.product.manufacturer"),
            "device_model": adb(args.serial, "shell", "getprop", "ro.product.model"),
            "android_version": adb(args.serial, "shell", "getprop", "ro.build.version.release"),
            "abi": adb(args.serial, "shell", "getprop", "ro.product.cpu.abi"),
            "viewport": adb(args.serial, "shell", "wm", "size"),
            "apk_sha256": sha(args.apk.read_bytes()) if args.apk else None,
            "screenshots": {},
            "manual_fps_review": "PENDING",
            "touch_review": "PENDING",
            "save_and_progression_integrity": "PENDING",
            "biomechanics_review": "PENDING",
            "note": "An image is not proof of performance or save integrity; record reviewer and test method."
        }
        (dest / "gfxinfo.txt").write_text(
            adb(args.serial, "shell", "dumpsys", "gfxinfo", PACKAGE), encoding="utf-8"
        )
        for name, instruction in STEPS:
            print("HUMAN:", instruction, flush=True)
            input("When scene is visible, press ENTER to capture (Ctrl+C aborts): ")
            data = adb(args.serial, "exec-out", "screencap", "-p", binary=True)
            if not data.startswith(b"\x89PNG") or len(data) < 100:
                raise RuntimeError("ADB returned an invalid screenshot")
            (dest / (name + ".png")).write_bytes(data)
            info["screenshots"][name] = {"sha256": sha(data), "bytes": len(data)}
        (dest / "qa_pending.json").write_text(
            json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print("Evidence saved locally:", dest)
        print("QA is PENDING. No review or release status changed.")
        return 0
    except (OSError, RuntimeError, subprocess.CalledProcessError, KeyboardInterrupt, EOFError) as exc:
        print("QA collection incomplete:", exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
