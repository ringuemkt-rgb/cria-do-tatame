#!/usr/bin/env python3
"""Run integration gates with isolated saves and reject hidden Godot errors."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SMOKES = ["runtime_smoke", "full_game_smoke", "bjj_reducer_v2_smoke",
          "combat_manager_bjj_shadow_smoke", "world_route_resolver_smoke",
          "vehicle_service_smoke", "world_travel_two_phase_smoke", "rota_101_simulation_smoke",
          "rota_101_scene_smoke", "travel_detail_panel_smoke", "crialive_v1_smoke",
          "build_all_integration_smoke", "combat_core_v2_smoke", "progression_os_smoke", "terreiro_living_hub_smoke"]
ERROR = re.compile(r"^(?:SCRIPT )?ERROR:", re.MULTILINE)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--out-dir", type=Path, default=ROOT / "reports/build-all/local")
    args = parser.parse_args()
    engine = shutil.which(args.godot)
    if not engine:
        parser.error("Godot executable not found")
    output = args.out_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    checks = []
    source_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    source_tree = subprocess.check_output(["git", "rev-parse", "HEAD^{tree}"], cwd=ROOT, text=True).strip()

    def run(name, command, *, godot=False, allowed=(0,)):
        with tempfile.TemporaryDirectory(prefix="cria-test-save-") as saves:
            environment = {**os.environ, "XDG_DATA_HOME": saves}
            result = subprocess.run(command, cwd=ROOT, env=environment, capture_output=True, text=True, timeout=240)
        log = result.stdout + result.stderr
        log_path = output / f"{name}.log"
        log_path.write_text(log, encoding="utf-8")
        passed = result.returncode in allowed and not (godot and ERROR.search(log))
        row = {"check": name, "passed": bool(passed), "exit_code": result.returncode,
               "log_sha256": hashlib.sha256(log_path.read_bytes()).hexdigest()}
        checks.append(row)
        print(f"{name}: {'PASS' if passed else 'FAIL'} exit={result.returncode}", flush=True)
        return passed

    version = subprocess.check_output([engine, "--version"], text=True).strip()
    run("quality", ["npm", "run", "quality"])
    imported = run("godot_import", [engine, "--headless", "--editor", "--path", ".", "--import"], godot=True)
    if imported:
        for smoke in SMOKES:
            run(smoke, [engine, "--headless", "--path", ".", "--script", f"res://tests/{smoke}.gd"], godot=True)
        parity_path = output / "reducer_parity_report.json"
        parity_path.unlink(missing_ok=True)
        run("parity_diagnostic", [engine, "--headless", "--path", ".", "--script",
             "res://tests/reducer_parity_test.gd", "--", "--report", str(parity_path)], godot=True, allowed=(0, 2))
        parity = json.loads(parity_path.read_text()) if parity_path.exists() else {}
        if parity.get("cases_run") != 50:
            checks.append({"check": "parity_report_has_50_cases", "passed": False})
    else:
        parity = {}
    run("commands", [sys.executable, "tools/ci/gen_commands.py", "--out-dir", str(output / "commands")])
    run("release_gate_report", [sys.executable, "tools/ci/validate_master_release.py"])
    report = {"source_commit": source_commit, "source_tree": source_tree, "godot_version": version,
              "working_tree_dirty": bool(subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"], cwd=ROOT, text=True).strip()),
              "checks": checks, "all_automated_checks_passed": all(c["passed"] for c in checks),
              "parity_100": parity.get("parity_100", False), "release_ready": False,
              "android_physical_tested": False}
    (output / "summary.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return 0 if report["all_automated_checks_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
