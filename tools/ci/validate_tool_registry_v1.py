#!/usr/bin/env python3
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "data/production/tool_registry_v1.json"


def fail(message: str) -> None:
    print(f"TOOL_REGISTRY_FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    allowed = set(data.get("allowed_statuses", []))
    tools = data.get("tools", [])
    if not tools:
        fail("registry has no tools")

    ids = [str(row.get("id", "")) for row in tools]
    if any(not tool_id for tool_id in ids):
        fail("tool without id")
    if len(ids) != len(set(ids)):
        fail("duplicate tool ids")

    for row in tools:
        tool_id = row["id"]
        status = row.get("status")
        if status not in allowed:
            fail(f"{tool_id}: invalid status {status}")
        if row.get("shipping_bypass_allowed") is not False:
            fail(f"{tool_id}: shipping bypass must be false")
        if not row.get("source"):
            fail(f"{tool_id}: missing source")

        if status == "APPROVED_CANDIDATE_GENERATOR":
            if row.get("license_verified_for_registry") is not True:
                fail(f"{tool_id}: approved generator requires verified license metadata")
            if not row.get("pinned_revision"):
                fail(f"{tool_id}: approved generator requires immutable revision")
            forbidden = set(row.get("forbidden_uses", []))
            if "automatic_shipping" not in forbidden:
                fail(f"{tool_id}: approved generator must explicitly forbid automatic_shipping")

        if status in {"REFERENCE_ONLY", "BLOCKED_LICENSE", "BLOCKED_PROVENANCE", "QUARANTINED"}:
            if row.get("source_code_copy_allowed") is not False:
                fail(f"{tool_id}: restricted/reference source must forbid source-code copy")
            if row.get("asset_copy_allowed") is not False:
                fail(f"{tool_id}: restricted/reference source must forbid asset copy")

        if status == "BLOCKED_PROVENANCE" and row.get("asset_copy_allowed") is not False:
            fail(f"{tool_id}: provenance blocker cannot allow asset copy")

    required_ids = {
        "qwen_image_2512",
        "qwen_image_2512_pixel_art_lora",
        "wolfcha",
        "sprite_animator_poirotw66",
        "pixel_srpg_forge",
        "cline_qwen_snes_engine",
        "pixel_life_simulator",
        "miaai_deepseek_v4_1_flash_100_html",
        "miaai_gpt_6_astra_100_html",
    }
    missing = sorted(required_ids - set(ids))
    if missing:
        fail(f"missing audited entries: {', '.join(missing)}")

    print(f"TOOL_REGISTRY_OK tools={len(tools)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
