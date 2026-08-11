#!/usr/bin/env python3
"""Offline quality gate for the optional Drive/Colab/Hugging Face adapter."""

from __future__ import annotations

import ast
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]
LAYOUT_PATH = ROOT / "data" / "ai" / "cloud_drive_layout_v01.json"
MANIFEST_PATH = ROOT / "data" / "ai" / "cloud_asset_manifest_v01.json"
MODEL_REGISTRY_PATH = ROOT / "data" / "ai" / "model_registry_v02.json"
NOTEBOOK_PATH = ROOT / "tools" / "ai_asset_pipeline" / "colab_pipeline.ipynb"

REQUIRED_FILES = [
    LAYOUT_PATH,
    MANIFEST_PATH,
    MODEL_REGISTRY_PATH,
    NOTEBOOK_PATH,
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "drive_client.py",
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "drive_sync.sh",
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "prepare_batch.py",
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "resolve_hf_models.py",
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "requirements-colab.txt",
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "requirements-drive.txt",
    ROOT / "docs" / "production" / "DRIVE_CLOUD_V1.md",
]

EXPECTED_FOLDERS = {
    "models",
    "cache",
    "refs",
    "motions",
    "assets",
    "assets/candidatos",
    "assets/aprovados",
    "audio",
    "audio/sfx",
    "audio/vozes",
    "colab_logs",
    "manifest",
}

PYTHON_FILES = [
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "drive_client.py",
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "prepare_batch.py",
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "resolve_hf_models.py",
    ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "validate_cloud_pipeline.py",
]


def read_json(path: Path, errors: list[str]) -> dict[str, Any]:
    """Read a JSON object and append validation failures to *errors*."""

    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"invalid JSON {path.relative_to(ROOT)}: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"JSON root is not an object: {path.relative_to(ROOT)}")
        return {}
    return value


def validate_layout(errors: list[str]) -> None:
    layout = read_json(LAYOUT_PATH, errors)
    if layout.get("root_folder_name") != "CriaDoTatame":
        errors.append("Drive root must be exactly CriaDoTatame")
    folders = layout.get("folders")
    if not isinstance(folders, list) or set(folders) != EXPECTED_FOLDERS:
        errors.append("Drive folder contract differs from the canonical v1 hierarchy")
    elif len(folders) != len(set(folders)):
        errors.append("Drive folder contract contains duplicates")
    if layout.get("upload_destinations") != ["assets/candidatos"]:
        errors.append("Automated upload must be restricted to assets/candidatos")
    if layout.get("automatic_promotion_to_approved") is not False:
        errors.append("Automatic promotion to approved assets must remain disabled")


def validate_manifest(errors: list[str]) -> None:
    manifest = read_json(MANIFEST_PATH, errors)
    if manifest.get("storage_visibility") != "private":
        errors.append("Cloud asset manifest must declare private storage")
    if manifest.get("provider_ids_versioned") is not False:
        errors.append("Private Drive provider IDs must not be versioned in the public repo")
    assets = manifest.get("assets")
    if not isinstance(assets, dict):
        errors.append("Cloud asset manifest assets must be an object")
        return
    forbidden = {"drive_id", "drive_file_id", "folder_id", "access_token", "refresh_token"}
    for key, entry in assets.items():
        if not isinstance(entry, dict):
            errors.append(f"Manifest entry is not an object: {key}")
            continue
        overlap = forbidden.intersection(entry)
        if overlap:
            errors.append(f"Manifest entry {key} exposes private provider fields: {sorted(overlap)}")
        digest = entry.get("sha256")
        if not isinstance(digest, str) or len(digest) != 64:
            errors.append(f"Manifest entry {key} has invalid sha256")


def validate_models(errors: list[str]) -> None:
    registry = read_json(MODEL_REGISTRY_PATH, errors)
    if registry.get("revision_policy") != "resolve_ref_to_immutable_sha_per_batch":
        errors.append("Model registry must resolve refs to immutable SHAs per batch")
    models = registry.get("models")
    if not isinstance(models, list) or not models:
        errors.append("Model registry has no models")
        return
    ids: set[str] = set()
    commercially_blocked = {"cc-by-nc-4.0", "other", "unverified"}
    for entry in models:
        if not isinstance(entry, dict):
            errors.append("Model registry entry is not an object")
            continue
        model_id = entry.get("id")
        if not isinstance(model_id, str) or "/" not in model_id:
            errors.append(f"Invalid Hugging Face model id: {model_id!r}")
            continue
        if model_id in ids:
            errors.append(f"Duplicate Hugging Face model id: {model_id}")
        ids.add(model_id)
        for field in ("requested_ref", "license", "adoption_status", "source_url"):
            if not entry.get(field):
                errors.append(f"Model {model_id} is missing {field}")
        if (
            entry.get("license") in commercially_blocked
            and entry.get("adoption_status") == "candidate_generation_allowed"
        ):
            errors.append(f"Commercially blocked/unclear model marked allowed: {model_id}")
    required = {
        "Comfy-Org/MiniMax-H3",
        "ByteDance/AnimateDiff-Lightning",
        "Onodofthenorth/SD_PixelArt_SpriteSheet_Generator",
    }
    missing = required - ids
    if missing:
        errors.append(f"Audited model registry is missing: {sorted(missing)}")


def validate_python(errors: list[str]) -> None:
    for path in PYTHON_FILES:
        try:
            ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except (OSError, SyntaxError) as exc:
            errors.append(f"Python parse failed for {path.relative_to(ROOT)}: {exc}")


def validate_shell(errors: list[str]) -> None:
    path = ROOT / "tools" / "ai_asset_pipeline" / "cloud" / "drive_sync.sh"
    result = subprocess.run(["bash", "-n", str(path)], check=False, capture_output=True, text=True)
    if result.returncode != 0:
        errors.append(f"Bash parse failed: {result.stderr.strip()}")


def validate_notebook(errors: list[str]) -> None:
    notebook = read_json(NOTEBOOK_PATH, errors)
    if notebook.get("nbformat") != 4:
        errors.append("Colab notebook must use nbformat 4")
    cells = notebook.get("cells")
    if not isinstance(cells, list) or not cells:
        errors.append("Colab notebook has no cells")
        return
    code = "\n".join(
        "".join(cell.get("source", []))
        for cell in cells
        if isinstance(cell, dict) and cell.get("cell_type") == "code"
    )
    forbidden_fragments = [
        "processar_tecnica(",
        "render_para_drive(",
        "TODO",
        "credentials.json",
        "client_secret.json",
    ]
    for fragment in forbidden_fragments:
        if fragment in code:
            errors.append(f"Notebook contains an unresolved or unsafe fragment: {fragment}")
    required_fragments = [
        "drive.mount(",
        "build_production_queue_v02.py",
        "prepare_batch.py",
        "resolve_hf_models.py",
        "assets/candidatos",
    ]
    for fragment in required_fragments:
        if fragment not in code:
            errors.append(f"Notebook is missing required integration: {fragment}")
    for index, cell in enumerate(cells):
        if isinstance(cell, dict) and cell.get("cell_type") == "code":
            if cell.get("execution_count") is not None or cell.get("outputs"):
                errors.append(f"Notebook code cell {index} contains committed execution state")
            try:
                ast.parse("".join(cell.get("source", [])), filename=f"{NOTEBOOK_PATH}:cell-{index}")
            except SyntaxError as exc:
                errors.append(f"Notebook code cell {index} does not parse: {exc}")


def validate_repo_wiring(errors: list[str]) -> None:
    package_path = ROOT / "package.json"
    package = read_json(package_path, errors)
    scripts = package.get("scripts", {}) if isinstance(package, dict) else {}
    if scripts.get("validate:cloud") != "python tools/ai_asset_pipeline/cloud/validate_cloud_pipeline.py":
        errors.append("package.json does not expose validate:cloud")
    quality = scripts.get("quality", "")
    if "validate:cloud" not in quality:
        errors.append("npm run quality does not include validate:cloud")
    gitignore_path = ROOT / ".gitignore"
    try:
        gitignore = gitignore_path.read_text(encoding="utf-8")
    except OSError as exc:
        errors.append(f"cannot read .gitignore: {exc}")
        return
    required_ignores = [
        "tools/ai_asset_pipeline/cloud/.state/",
        "tools/ai_asset_pipeline/cloud/*.lock",
        "tools/ai_asset_pipeline/cloud/client_secret*.json",
        "tools/ai_asset_pipeline/cloud/token*.json",
    ]
    for rule in required_ignores:
        if rule not in gitignore:
            errors.append(f".gitignore is missing private cloud rule: {rule}")


def main() -> int:
    """Run the complete offline cloud adapter gate."""

    errors: list[str] = []
    for path in REQUIRED_FILES:
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")
    if not errors:
        validate_layout(errors)
        validate_manifest(errors)
        validate_models(errors)
        validate_python(errors)
        validate_shell(errors)
        validate_notebook(errors)
        validate_repo_wiring(errors)
    result = {"ok": not errors, "errors": errors, "checked_files": len(REQUIRED_FILES)}
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
