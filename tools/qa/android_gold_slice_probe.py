#!/usr/bin/env python3
"""Physical Android evidence probe for the Cria do Tatame gold slice.

This script collects machine evidence through adb but deliberately cannot self-certify
touch comfort, readability, gameplay feel or sustained FPS. Those remain human/device
review gates and are loaded from an explicit checklist when provided.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PACKAGE = "com.criadotatame.pressao"
ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "reports/android/gold_slice_device_report_v1.json"
DEFAULT_CHECKLIST = ROOT / "data/qa/android_gold_slice_manual_checklist_v1.json"


def run(cmd: list[str], timeout: int = 30, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=timeout,
        check=check,
        encoding="utf-8",
        errors="replace",
    )


def adb_args(serial: str | None, *args: str) -> list[str]:
    out = ["adb"]
    if serial:
        out += ["-s", serial]
    out += list(args)
    return out


def adb(serial: str | None, *args: str, timeout: int = 30) -> tuple[int, str]:
    result = run(adb_args(serial, *args), timeout=timeout)
    combined = (result.stdout or "") + (result.stderr or "")
    return result.returncode, combined.strip()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def connected_devices() -> list[str]:
    result = run(["adb", "devices"])
    devices: list[str] = []
    for line in result.stdout.splitlines()[1:]:
        fields = line.strip().split()
        if len(fields) >= 2 and fields[1] == "device":
            devices.append(fields[0])
    return devices


def shell(serial: str, command: str, timeout: int = 30) -> str:
    _code, output = adb(serial, "shell", command, timeout=timeout)
    return output


def prop(serial: str, name: str) -> str:
    return shell(serial, f"getprop {name}").strip()


def package_installed(serial: str) -> bool:
    output = shell(serial, f"pm path {PACKAGE}")
    return "package:" in output


def launch(serial: str) -> dict[str, Any]:
    adb(serial, "logcat", "-c")
    code, output = adb(
        serial,
        "shell",
        "monkey",
        "-p",
        PACKAGE,
        "-c",
        "android.intent.category.LAUNCHER",
        "1",
        timeout=20,
    )
    return {"ok": code == 0 and "No activities found" not in output, "output": output}


def fatal_log_entries(text: str) -> list[str]:
    markers = [
        "FATAL EXCEPTION",
        f"ANR in {PACKAGE}",
        "Fatal signal",
        "SIGSEGV",
        "SIGABRT",
        "CRASH",
    ]
    lines = []
    for line in text.splitlines():
        if any(marker.lower() in line.lower() for marker in markers):
            lines.append(line[-1200:])
    return lines[-80:]


def load_manual(path: Path | None) -> dict[str, Any]:
    if path is None or not path.exists():
        return {"provided": False, "checks": {}}
    raw = json.loads(path.read_text(encoding="utf-8"))
    checks = raw.get("checks", {})
    return {"provided": True, "checks": checks, "source": str(path)}


def manual_pass(manual: dict[str, Any]) -> bool:
    if not manual.get("provided"):
        return False
    checks = manual.get("checks", {})
    required = [
        "landscape_ok",
        "safe_area_ok",
        "touch_ok",
        "text_readable",
        "menu_to_terreiro_ok",
        "pre_fight_ok",
        "combat_ok",
        "result_ok",
        "cria_live_ok",
        "week_advance_ok",
        "save_restart_ok",
        "sustained_fps_45_or_better",
        "no_severe_thermal",
        "audio_balance_ok",
    ]
    return all(checks.get(key) is True for key in required)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--serial")
    parser.add_argument("--install", action="store_true")
    parser.add_argument("--sample-seconds", type=int, default=20)
    parser.add_argument("--manual-checklist", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    if shutil.which("adb") is None:
        raise SystemExit("adb_not_found")

    devices = connected_devices()
    serial = args.serial
    if serial is None:
        if len(devices) != 1:
            raise SystemExit(f"expected_exactly_one_device_without_serial; found={devices}")
        serial = devices[0]
    elif serial not in devices:
        raise SystemExit(f"requested_device_not_ready:{serial}")

    install_result: dict[str, Any] = {"requested": args.install, "ok": package_installed(serial)}
    apk_info: dict[str, Any] = {}
    if args.apk:
        if not args.apk.is_file():
            raise SystemExit(f"apk_not_found:{args.apk}")
        apk_info = {
            "path": str(args.apk),
            "bytes": args.apk.stat().st_size,
            "sha256": sha256(args.apk),
        }
        if args.install:
            code, output = adb(serial, "install", "-r", str(args.apk), timeout=180)
            install_result = {
                "requested": True,
                "ok": code == 0 and "Success" in output,
                "output": output[-4000:],
            }

    launch_result = launch(serial)
    time.sleep(max(3, args.sample_seconds))

    pid = shell(serial, f"pidof {PACKAGE}").strip()
    meminfo = shell(serial, f"dumpsys meminfo {PACKAGE}", timeout=30)
    gfxinfo = shell(serial, f"dumpsys gfxinfo {PACKAGE} framestats", timeout=30)
    battery = shell(serial, "dumpsys battery", timeout=30)
    thermal = shell(serial, "dumpsys thermalservice", timeout=30)
    display_size = shell(serial, "wm size", timeout=20)
    display_density = shell(serial, "wm density", timeout=20)
    package_dump = shell(serial, f"dumpsys package {PACKAGE}", timeout=30)
    logcat = shell(serial, "logcat -d -v threadtime", timeout=45)
    fatals = fatal_log_entries(logcat)

    manual_path = args.manual_checklist if args.manual_checklist else DEFAULT_CHECKLIST
    manual = load_manual(manual_path if manual_path.exists() else None)

    automatic = {
        "device_connected": True,
        "package_installed": package_installed(serial),
        "launch_ok": bool(launch_result["ok"]),
        "process_alive_after_sample": bool(pid),
        "fatal_log_entries_zero": len(fatals) == 0,
    }
    automatic_pass = all(automatic.values())
    physical_gate_pass = automatic_pass and manual_pass(manual)

    report = {
        "$schema": "cria.android_gold_slice_device_report.v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "package": PACKAGE,
        "serial": serial,
        "device": {
            "manufacturer": prop(serial, "ro.product.manufacturer"),
            "model": prop(serial, "ro.product.model"),
            "device": prop(serial, "ro.product.device"),
            "android": prop(serial, "ro.build.version.release"),
            "api": prop(serial, "ro.build.version.sdk"),
            "abi": prop(serial, "ro.product.cpu.abi"),
            "gpu": prop(serial, "ro.hardware.egl"),
            "display_size": display_size,
            "display_density": display_density,
        },
        "apk": apk_info,
        "install": install_result,
        "launch": launch_result,
        "automatic_checks": automatic,
        "manual_review": manual,
        "physical_gate_pass": physical_gate_pass,
        "release_ready": False,
        "release_ready_reason": (
            "physical_gold_slice_gate_passed_but_release_still_requires_repository_release_ledger"
            if physical_gate_pass
            else "physical_gold_slice_gate_incomplete"
        ),
        "evidence": {
            "pid": pid,
            "meminfo": meminfo[-30000:],
            "gfxinfo_framestats": gfxinfo[-50000:],
            "battery": battery[-12000:],
            "thermal": thermal[-12000:],
            "package_dump": package_dump[-20000:],
            "fatal_log_entries": fatals,
            "logcat_tail": "\n".join(logcat.splitlines()[-500:]),
        },
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Android physical evidence: {args.output}")
    print(f"automatic_pass={automatic_pass} manual_pass={manual_pass(manual)} physical_gate_pass={physical_gate_pass}")
    return 0 if automatic_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
