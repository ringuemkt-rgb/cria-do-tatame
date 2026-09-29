#!/usr/bin/env python3
"""Build and test a desktop Godot PCK without downloading export templates.

This is a developer playtest package, not an APK or release certification.
Run npm run quality separately before distributing it.
"""
import argparse
import hashlib
import json
import pathlib
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", default="reports/build/playtest")
    args = parser.parse_args()
    engine = shutil.which(args.godot)
    if not engine:
        parser.error("Godot executable not found")
    engine = str(pathlib.Path(engine).resolve())
    output = pathlib.Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    archive = output / "CriaDoTatame-playtest.zip"
    archive.unlink(missing_ok=True)  # A failed rebuild must not expose an old successful ZIP.
    results = {}

    def run(label, arguments, cwd):
        result = subprocess.run([engine, *arguments], cwd=cwd, capture_output=True,
                                text=True, timeout=180)
        log = result.stdout + result.stderr
        (output / f"{label}.log").write_text(log, encoding="utf-8")
        if result.returncode or re.search(r"^(?:SCRIPT )?ERROR:", log, re.MULTILINE):
            raise RuntimeError(f"{label} failed; see {output / (label + '.log')}")
        results[label] = "passed"
        return log.strip()

    version = run("engine_version", ["--version"], ROOT)
    run("import", ["--headless", "--editor", "--path", str(ROOT), "--import"], ROOT)
    pack = output / "CriaDoTatame.pck"
    run("export", ["--headless", "--path", str(ROOT), "--export-pack",
                   "Windows Desktop Debug", str(pack)], ROOT)
    # An empty working directory prevents missing packed resources from falling
    # back to the source checkout and making a broken distribution look healthy.
    with tempfile.TemporaryDirectory(prefix="cria-packed-test-") as isolated:
        for name in ("runtime_smoke", "full_game_smoke", "progression_os_smoke"):
            log = run(name, ["--headless", "--main-pack", str(pack), "--script",
                             f"res://tests/{name}.gd"], isolated)
            if "PASS" not in log:
                raise RuntimeError(f"{name} exited without a PASS marker")
        run("menu_boot", ["--headless", "--main-pack", str(pack), "--quit-after", "90"], isolated)
    report = {"engine": version, "source_commit": subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "working_tree_dirty": bool(subprocess.check_output(
            ["git", "status", "--porcelain", "--untracked-files=no"], cwd=ROOT, text=True).strip()),
        "sha256": hashlib.sha256(pack.read_bytes()).hexdigest(), "checks": results,
        "release_ready": False, "visual_review": "pending", "android_physical": "pending"}
    (output / "validation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    (output / "LEIA-ME.txt").write_text(
        "CRIA DO TATAME - PACOTE DE TESTE DESKTOP\n\n"
        f"Engine validada: {version}\n"
        "Requer Godot Standard da mesma versao (executavel nao incluido).\n"
        "Extraia este ZIP e abra um terminal nessa pasta.\n"
        'Windows: Godot.exe --main-pack CriaDoTatame.pck --rendering-method gl_compatibility\n'
        'Linux: godot --main-pack CriaDoTatame.pck --rendering-method gl_compatibility\n\n'
        "Use o caminho/nome real do executavel Godot instalado.\n"
        "Escolha NOVO JOGO; use os botoes do Terreiro para treinar, editar o deck e lutar.\n"
        "Teste resultado, avanco de semana, salvar, fechar e CONTINUAR.\n"
        "Para reproduzir QA: godot --headless --main-pack CriaDoTatame.pck "
        "--script res://tests/runtime_smoke.gd\n\n"
        "Nao e APK. Nao e jogo completo nem arte final.\n"
        "Teste automatizado headless nao certifica visual, diversao ou Android fisico.\n",
        encoding="utf-8")
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
        for path in [pack, output / "LEIA-ME.txt", output / "validation.json", *sorted(output.glob("*.log"))]:
            bundle.write(path, path.name)
    print(json.dumps({"archive": str(archive), **report}, indent=2))


if __name__ == "__main__":
    main()
