#!/usr/bin/env python3
from __future__ import annotations

import base64
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data/visual/brand_identity_v01.json"
LOGO_PATH = ROOT / "assets/branding/logo_oficial_cria_do_tatame.svg"
SOF_MARKERS = {
    0xC0,
    0xC1,
    0xC2,
    0xC3,
    0xC5,
    0xC6,
    0xC7,
    0xC9,
    0xCA,
    0xCB,
    0xCD,
    0xCE,
    0xCF,
}


def read_text(path: Path) -> str:
    if not path.is_file():
        raise AssertionError(f"arquivo obrigatório ausente: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def load_contract() -> dict:
    return json.loads(read_text(CONTRACT_PATH))


def jpeg_dimensions(binary: bytes) -> tuple[int, int]:
    assert binary.startswith(b"\xff\xd8"), "JPEG sem marcador SOI"
    assert binary.endswith(b"\xff\xd9"), "JPEG sem marcador EOI"
    cursor = 2
    while cursor + 3 < len(binary):
        if binary[cursor] != 0xFF:
            cursor += 1
            continue
        while cursor < len(binary) and binary[cursor] == 0xFF:
            cursor += 1
        if cursor >= len(binary):
            break
        marker = binary[cursor]
        cursor += 1
        if marker == 0xD9:
            break
        if marker == 0x01 or 0xD0 <= marker <= 0xD7:
            continue
        assert cursor + 2 <= len(binary), "segmento JPEG truncado"
        segment_length = int.from_bytes(binary[cursor : cursor + 2], "big")
        assert segment_length >= 2, "comprimento de segmento JPEG inválido"
        if marker in SOF_MARKERS:
            assert cursor + 7 <= len(binary), "segmento SOF truncado"
            height = int.from_bytes(binary[cursor + 3 : cursor + 5], "big")
            width = int.from_bytes(binary[cursor + 5 : cursor + 7], "big")
            return width, height
        cursor += segment_length
    raise AssertionError("JPEG sem marcador SOF reconhecido")


def validate_contract() -> None:
    contract = load_contract()
    logo = contract["official_logo"]
    canon = contract["canonical_elements"]
    reconciliation = contract["canon_reconciliation"]
    legal = contract["legal_and_shipping"]

    assert contract["status"] == "canonical_source_with_legal_cleanup_pending"
    assert contract["approved_by_creator"] is True
    assert logo["asset_path"] == "res://assets/branding/logo_oficial_cria_do_tatame.svg"
    assert logo["source_upload"]["original_dimensions_px"] == [1536, 1536]
    assert re.fullmatch(r"[0-9a-f]{64}", logo["source_upload"]["original_sha256"])
    assert canon["mascot"] == "gorila Silverback adulto"
    assert canon["crown"] == "coroa dourada central acima da cabeça"
    assert canon["primary_wordmark"] == "CRIA DO TATAME"
    assert canon["japanese_text"] == "柔術"
    assert canon["palette"] == ["#000000", "#F2F2F2", "#B8860B", "#F2C230"]
    assert reconciliation["protagonist"] == "Ruan Macacão Silva"
    assert reconciliation["cria_is_not_protagonist_official_nickname"] is True
    assert reconciliation["silverback_is_project_symbol"] is True
    assert legal["current_source_contains_third_party_mark"] is True
    assert legal["shipping_status"] == "legal_cleanup_required"
    assert legal["do_not_publish_commercially_before_cleanup"] is True


def validate_embedded_logo() -> None:
    contract = load_contract()
    svg = read_text(LOGO_PATH)
    assert '<title id="title">Logo oficial Cria do Tatame</title>' in svg
    assert 'width="512" height="512" viewBox="0 0 512 512"' in svg
    match = re.search(r"href=\"data:image/jpeg;base64,([^\"]+)\"", svg)
    assert match is not None, "SVG não contém JPEG oficial embutido"
    payload = match.group(1).strip()
    payload += "=" * (-len(payload) % 4)
    binary = base64.b64decode(payload, validate=True)
    digest = hashlib.sha256(binary).hexdigest()
    derivative = contract["official_logo"]["repository_derivative"]
    expected = derivative["embedded_jpeg_sha256"]
    assert digest == expected, f"hash do logo divergente: {digest} != {expected}"
    assert len(binary) >= 50_000, "derivativo visual parece truncado"
    assert list(jpeg_dimensions(binary)) == derivative["dimensions_px"]


def validate_governance_links() -> None:
    agents = read_text(ROOT / "AGENTS.md")
    decisions = read_text(ROOT / "docs/DECISIONS.md")
    index = read_text(ROOT / "docs/INDEX.md")
    governance = json.loads(read_text(ROOT / "data/production/repository_governance_v01.json"))

    assert "data/visual/brand_identity_v01.json" in agents
    assert "assets/branding/logo_oficial_cria_do_tatame.svg" in agents
    assert "## D12 — Logo e identidade oficial" in decisions
    assert "Ruan “Macacão” Silva" in decisions
    assert "brand_identity_v01.json" in index
    required = governance["required_governance_files"]
    assert "data/visual/brand_identity_v01.json" in required
    assert "assets/branding/logo_oficial_cria_do_tatame.svg" in required
    protected = governance["protected_invariants"]
    assert protected["official_logo"] == "res://assets/branding/logo_oficial_cria_do_tatame.svg"
    assert protected["brand_mascot"] == "silverback"
    assert protected["protagonist_id"] == "ruan_macacao"


def main() -> int:
    checks = [validate_contract, validate_embedded_logo, validate_governance_links]
    errors: list[str] = []
    for check in checks:
        try:
            check()
        except Exception as exc:  # noqa: BLE001 - CLI agrega todas as falhas
            errors.append(f"{check.__name__}: {exc}")
    if errors:
        print("[BrandIdentityV1] FALHOU")
        for error in errors:
            print(f" - {error}")
        return 1
    print("[BrandIdentityV1] OK - logo, JPEG, hash, dimensões e cânone validados")
    return 0


if __name__ == "__main__":
    sys.exit(main())
