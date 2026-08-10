#!/usr/bin/env python3
"""Validate the local-only, vector-source Neplex Vectorizer integration."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PROFILE_PATH = ROOT / "data" / "production" / "neplex_vectorizer_profile_v01.json"
SOP_PATH = ROOT / "data" / "production" / "ai_production_sop_v01.json"
SCHEMA_PATH = ROOT / "schemas" / "neplex_vectorizer_profile.schema.json"
ADAPTER_PATH = ROOT / "tools" / "visual" / "neplex_vectorizer_adapter.py"
PACKAGE_VERSION = "0.1.0"
PACKAGE_GIT_HEAD = "dd96eea07d1eb6c0c796801a385efbf53d512591"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise AssertionError(f"{path.relative_to(ROOT)} must contain an object")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_adapter():
    spec = importlib.util.spec_from_file_location("neplex_vectorizer_adapter", ADAPTER_PATH)
    require(spec is not None and spec.loader is not None, "cannot load vectorizer adapter")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def expect_rejected(adapter, svg: str, label: str) -> None:
    try:
        adapter.audit_svg_text(svg, "ui_icon", (64, 64))
    except adapter.AdapterError:
        return
    raise AssertionError(f"unsafe SVG accepted: {label}")


def main() -> int:
    profile = load_json(PROFILE_PATH)
    sop = load_json(SOP_PATH)
    schema = load_json(SCHEMA_PATH)
    adapter = load_adapter()

    require(profile.get("$schema") == "neplex_vectorizer_profile_v1", "invalid vectorizer profile schema")
    require(profile.get("status") == "approved_vector_source_candidate_tool", "unsafe vectorizer adoption status")
    source = profile.get("source", {})
    require(source.get("repository") == "https://github.com/neplextech/vectorizer", "unofficial vectorizer source")
    require(source.get("package") == "@neplex/vectorizer", "wrong npm package")
    require(source.get("package_version") == PACKAGE_VERSION, "npm package is not pinned")
    require(source.get("package_git_head") == PACKAGE_GIT_HEAD, "published package commit changed")
    require(source.get("license") == "MIT", "vectorizer license decision changed")
    for key in [
        "license_sha256",
        "tarball_sha256",
        "package_json_sha256",
        "cli_sha256",
        "index_sha256",
        "bindings_sha256",
    ]:
        value = str(source.get(key, ""))
        require(len(value) == 64 and all(char in "0123456789abcdef" for char in value), f"invalid {key}")
    require(str(source.get("npm_integrity", "")).startswith("sha512-"), "npm integrity is not pinned")

    dependency = profile.get("dependency_policy", {})
    require(dependency.get("runtime_dependency") is False, "vectorizer cannot enter the game runtime")
    require(dependency.get("runtime_network_required") is False, "runtime network cannot be introduced")
    require(dependency.get("vendored_into_game") is False, "native package cannot be vendored into the game")
    require(dependency.get("global_install_allowed") is False, "global install must remain blocked")
    require(dependency.get("package_scripts_allowed") is False, "package scripts must remain blocked")
    require(dependency.get("online_playground_for_project_assets") is False, "project art cannot enter hosted playground")

    adoption = profile.get("adoption", {})
    approved = set(adoption.get("approved_asset_classes", []))
    blocked = set(adoption.get("blocked_asset_classes", []))
    require(
        approved == {"faction_emblem", "style_emblem", "ui_icon", "logo_mark", "accessibility_diagram"},
        "vector asset allowlist changed",
    )
    require(
        {
            "fighter_sprite",
            "paired_grappling_frame",
            "animation_sheet",
            "tileset",
            "arena_background",
            "crowd_sprite",
            "card_illustration",
            "pixel_font",
        }
        <= blocked,
        "pixel-art blocklist is incomplete",
    )

    execution = profile.get("execution", {})
    require(execution.get("adapter") == "tools/visual/neplex_vectorizer_adapter.py", "wrong adapter path")
    require(execution.get("candidate_output_root") == "production/candidates/neplex_vectorizer", "unsafe output root")
    require(execution.get("candidate_state") == "candidate_vector_source", "SVG cannot start as shipping art")
    require(execution.get("promotion_allowed") is False, "adapter cannot promote SVG")
    require(execution.get("source_rights_required") is True, "source rights gate is mandatory")
    require(execution.get("local_execution_required") is True, "local-only gate is mandatory")
    require(execution.get("allowed_svg_elements") == ["svg", "g", "path"], "SVG element allowlist changed")
    require(execution.get("active_svg_constructs_allowed") is False, "active SVG cannot be allowed")

    godot = profile.get("godot_policy", {})
    require(godot.get("source_svg_retained") is True, "scalable source should be retained")
    require(godot.get("svg_runtime_authority") is False, "SVG cannot bypass runtime asset review")
    require(godot.get("size_specific_png_bake_required") is True, "runtime PNG bake is mandatory")
    require(godot.get("runtime_plugin_added") is False, "vectorizer must not add a second runtime path")
    require(godot.get("pixel_assets_may_be_vectorized") is False, "pixel assets cannot be vectorized")

    playground = profile.get("playground_audit", {})
    require(playground.get("client_side_worker_processing") is True, "playground execution model changed")
    require(playground.get("image_upload_request_observed") is False, "unexpected image upload was observed")
    require(playground.get("vercel_analytics_present") is True, "playground telemetry disclosure missing")

    tools = {str(item.get("id", "")): item for item in sop.get("toolchain_decisions", [])}
    decision = tools.get("neplex_vectorizer", {})
    require(decision.get("decision") == "approved_vector_source_candidate_tool", "SOP adoption is too broad")
    require(decision.get("package_version") == PACKAGE_VERSION, "SOP package pin diverged")
    require(decision.get("package_git_head") == PACKAGE_GIT_HEAD, "SOP git pin diverged")
    require(decision.get("runtime_dependency") is False, "SOP introduced runtime dependency")
    require(decision.get("profile") == "data/production/neplex_vectorizer_profile_v01.json", "SOP profile path changed")

    require(schema.get("$id") == "neplex_vectorizer_profile.schema.json", "wrong vectorizer JSON schema")
    require(ADAPTER_PATH.is_file(), "vectorizer adapter is missing")
    require(set(adapter.VECTOR_PROFILES) == approved, "adapter and profile allowlists diverged")

    candidate = adapter.candidate_output_dir("ui_vector_01", "lem_emblem")
    require(
        str(candidate).endswith("production/candidates/neplex_vectorizer/ui_vector_01/lem_emblem"),
        "candidate path is not deterministic",
    )
    try:
        adapter.candidate_output_dir("../escape", "lem_emblem")
    except adapter.AdapterError:
        pass
    else:
        raise AssertionError("unsafe candidate path was accepted")

    safe_svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64">'
        '<g transform="translate(0 0)"><path fill="#d9a441" d="M0 0h64v64H0Z"/></g></svg>'
    )
    metrics = adapter.audit_svg_text(safe_svg, "ui_icon", (64, 64))
    require(metrics.get("paths") == 1, "safe SVG path count failed")
    require(metrics.get("colors") == ["#d9a441"], "safe SVG color audit failed")
    require(metrics.get("active_constructs") is False, "safe SVG marked active")

    unsafe_samples = {
        "script": '<svg width="64" height="64"><script>alert(1)</script><path d="M0 0Z" fill="#000000"/></svg>',
        "event": '<svg width="64" height="64" onload="x"><path d="M0 0Z" fill="#000000"/></svg>',
        "external image": '<svg width="64" height="64"><image href="https://example.com/x"/></svg>',
        "foreign object": '<svg width="64" height="64"><foreignObject/></svg>',
        "css url": '<svg width="64" height="64"><path style="fill:url(https://x)" d="M0 0Z"/></svg>',
        "text": '<svg width="64" height="64"><text>Cria</text><path d="M0 0Z" fill="#000000"/></svg>',
    }
    for label, svg in unsafe_samples.items():
        expect_rejected(adapter, svg, label)

    command = adapter.build_vectorize_command(
        Path("/tmp/vectorizer"),
        ROOT / "tests" / "fixture.png",
        candidate / "lem_emblem.svg",
        "faction_emblem",
    )
    joined = " ".join(command)
    for required in [
        "--preset poster",
        "--mode polygon",
        "--optimize",
        "--optimize-preset safe",
        "--multipass",
        "--multipass-iterations 3",
    ]:
        require(required in joined, f"required vectorizer flag missing: {required}")

    adapter_source = ADAPTER_PATH.read_text(encoding="utf-8")
    require("shell=True" not in adapter_source, "adapter cannot execute through a shell")
    require("subprocess.run(command, check=True" in adapter_source, "adapter execution must fail closed")
    require("--source-rights-confirmed" in adapter_source, "source rights acknowledgement missing")
    require("--acknowledge-vector-source-only" in adapter_source, "vector-source acknowledgement missing")
    require("--acknowledge-local-cli-only" in adapter_source, "local-only acknowledgement missing")

    smoke = profile.get("audit_snapshot", {}).get("published_package_smoke", {})
    require(smoke.get("runs") == 2 and smoke.get("result") == "pass", "published package smoke evidence changed")
    require(smoke.get("active_construct_scan") == "pass", "SVG active construct smoke failed")
    require(smoke.get("input_bytes") == 736 and smoke.get("output_bytes") == 187, "smoke size evidence changed")
    adapter_smoke = profile.get("audit_snapshot", {}).get("adapter_smoke", {})
    require(adapter_smoke.get("result") == "pass", "adapter smoke evidence changed")
    require(adapter_smoke.get("artifact_state") == "candidate_vector_source", "adapter smoke promoted SVG")
    require(adapter_smoke.get("intake_written") is True, "adapter smoke did not write intake")
    require(adapter_smoke.get("active_constructs") is False, "adapter smoke emitted active SVG")

    print(
        "[neplex-vectorizer] ok: MIT npm pin, local-only CLI, vector allowlist, "
        "active-SVG rejection, candidate root and PNG runtime bake validated"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
