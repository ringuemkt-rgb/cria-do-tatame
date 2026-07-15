from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "project.godot"
PRESETS = ROOT / "export_presets.cfg"
EXPECTED_ICON = "res://assets/cosmetics/nft/patch_terreiro_raiz.png"


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _resource_exists(resource_path: str) -> bool:
    assert resource_path.startswith("res://")
    return (ROOT / resource_path.removeprefix("res://")).is_file()


def _setting(text: str, key: str) -> str:
    match = re.search(rf'^{re.escape(key)}="([^"]*)"$', text, re.MULTILINE)
    assert match is not None, f"Configuração ausente: {key}"
    return match.group(1)


def test_project_is_mobile_export_ready() -> None:
    project = _text(PROJECT)
    assert 'renderer/rendering_method="mobile"' in project
    assert 'textures/vram_compression/import_etc2_astc=true' in project
    icon = _setting(project, "config/icon")
    assert icon == EXPECTED_ICON
    assert _resource_exists(icon)


def test_android_debug_preset_is_signed_arm64_and_identified() -> None:
    presets = _text(PRESETS)
    assert 'name="Android Debug"' in presets
    assert 'platform="Android"' in presets
    assert 'package/unique_name="com.criadotatame.pressao"' in presets
    assert 'package/signed=true' in presets
    assert 'architectures/arm64-v8a=true' in presets
    assert 'export_filter="all_resources"' in presets


def test_all_launcher_icons_are_real_resources() -> None:
    presets = _text(PRESETS)
    keys = (
        "launcher_icons/main_192x192",
        "launcher_icons/adaptive_foreground_432x432",
        "launcher_icons/adaptive_background_432x432",
    )
    for key in keys:
        value = _setting(presets, key)
        assert value == EXPECTED_ICON, f"Ícone inesperado em {key}: {value}"
        assert _resource_exists(value), f"Ícone inexistente em {key}: {value}"


def test_android_ci_configuration_is_present() -> None:
    script = ROOT / "tools/build/configure_godot_android_ci.sh"
    assert script.is_file()
    content = _text(script)
    for setting in (
        "export/android/java_sdk_path",
        "export/android/android_sdk_path",
        "export/android/debug_keystore",
        "export/android/debug_keystore_user",
        "export/android/debug_keystore_pass",
    ):
        assert setting in content
