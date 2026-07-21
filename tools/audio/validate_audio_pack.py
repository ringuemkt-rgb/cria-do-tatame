#!/usr/bin/env python3
"""Valida integridade, formato e contrato do áudio do vertical slice."""

from __future__ import annotations

import hashlib
import json
import shutil
import struct
import subprocess
import wave
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "assets/audio/audio_pack_manifest_v01.json"
CATALOG_PATH = ROOT / "data/audio/audio_event_catalog_v01.json"
EXPECTED_EVENT_COUNT = 28
EXPECTED_CATEGORIES = {"combat": 16, "ui": 4, "ambience": 5, "crowd": 2, "music": 1}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def probe_audio(path: Path) -> dict[str, Any]:
    command = [
        "ffprobe",
        "-v",
        "error",
        "-select_streams",
        "a:0",
        "-show_entries",
        "stream=codec_name,sample_rate,channels,duration",
        "-of",
        "json",
        str(path),
    ]
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    payload = json.loads(result.stdout)
    streams = payload.get("streams", [])
    return streams[0] if streams else {}


def validate_event(entry: dict[str, Any], errors: list[str]) -> None:
    event_id = str(entry.get("event_id", ""))
    required = ("source", "game", "metadata", "loudness_report", "license")
    paths: dict[str, Path] = {}
    for key in required:
        value = str(entry.get(key, ""))
        path = ROOT / value
        paths[key] = path
        if not value or not path.is_file():
            errors.append(f"{event_id}: arquivo obrigatório ausente em {key}: {value}")
    if any(not path.is_file() for path in paths.values()):
        return

    if sha256(paths["source"]) != entry.get("source_sha256"):
        errors.append(f"{event_id}: SHA-256 da fonte divergente")
    if sha256(paths["game"]) != entry.get("game_sha256"):
        errors.append(f"{event_id}: SHA-256 do OGG divergente")

    metadata = load_json(paths["metadata"])
    loudness = load_json(paths["loudness_report"])
    if metadata.get("event_id") != event_id:
        errors.append(f"{event_id}: event_id divergente nos metadados")
    if metadata.get("category") != entry.get("category"):
        errors.append(f"{event_id}: categoria divergente nos metadados")
    if metadata.get("generation") != "deterministic_original_synthesis":
        errors.append(f"{event_id}: origem não está marcada como síntese original")
    if metadata.get("source_sha256") != entry.get("source_sha256"):
        errors.append(f"{event_id}: hash da fonte diverge entre manifesto e metadados")
    if metadata.get("game_sha256") != entry.get("game_sha256"):
        errors.append(f"{event_id}: hash do jogo diverge entre manifesto e metadados")

    processing = loudness.get("runtime_processing", {})
    expected_serial = int.from_bytes(hashlib.sha256(event_id.encode("utf-8")).digest()[:4], "little") or 1
    game_header = paths["game"].read_bytes()[:27]
    actual_serial = struct.unpack("<I", game_header[14:18])[0] if game_header[:4] == b"OggS" else -1
    if processing.get("binary_reproducibility") != "fixed_serial_and_recalculated_crc":
        errors.append(f"{event_id}: OGG não declara reprodutibilidade binária")
    if int(processing.get("ogg_serial", -1)) != expected_serial or actual_serial != expected_serial:
        errors.append(f"{event_id}: serial OGG determinístico divergente")

    with wave.open(str(paths["source"]), "rb") as stream:
        if stream.getframerate() != 48_000:
            errors.append(f"{event_id}: fonte não está em 48 kHz")
        if stream.getnchannels() != 2:
            errors.append(f"{event_id}: fonte não está em estéreo")
        if stream.getsampwidth() != 2:
            errors.append(f"{event_id}: fonte não está em PCM 16-bit")
        frame_count = stream.getnframes()
        duration = frame_count / max(1, stream.getframerate())
        first_frame = struct.unpack("<hh", stream.readframes(1))
        stream.setpos(max(0, frame_count - 1))
        last_frame = struct.unpack("<hh", stream.readframes(1))
    declared_duration = float(metadata.get("duration_seconds", 0.0))
    if abs(duration - declared_duration) > 0.01:
        errors.append(f"{event_id}: duração fonte/metadados diverge")
    if bool(metadata.get("loop")) and duration < 8.0:
        errors.append(f"{event_id}: loop curto demais ({duration:.2f}s)")
    if bool(metadata.get("loop")):
        seam_delta = max(abs(first_frame[0] - last_frame[0]), abs(first_frame[1] - last_frame[1])) / 32767.0
        if seam_delta > 0.08:
            errors.append(f"{event_id}: emenda de loop pode estalar ({seam_delta:.3f})")
    if float(loudness.get("peak_dbfs", 0.0)) > -1.5:
        errors.append(f"{event_id}: pico excede -1.5 dBFS")

    probe = probe_audio(paths["game"])
    if probe.get("codec_name") != "vorbis":
        errors.append(f"{event_id}: runtime não usa Vorbis")
    if int(probe.get("sample_rate", 0)) != 48_000:
        errors.append(f"{event_id}: OGG não está em 48 kHz")
    if int(probe.get("channels", 0)) != 2:
        errors.append(f"{event_id}: OGG não está em estéreo")
    ogg_duration = float(probe.get("duration", 0.0))
    if abs(ogg_duration - duration) > 0.08:
        errors.append(f"{event_id}: duração OGG/fonte diverge")

    license_text = paths["license"].read_text(encoding="utf-8").lower()
    if "no external samples" not in license_text:
        errors.append(f"{event_id}: declaração de origem/licença incompleta")


def main() -> int:
    errors: list[str] = []
    if shutil.which("ffprobe") is None:
        errors.append("ffprobe não encontrado")
    if not MANIFEST_PATH.is_file():
        errors.append("manifesto de áudio ausente")
    if not CATALOG_PATH.is_file():
        errors.append("catálogo de áudio ausente")
    if errors:
        for error in errors:
            print(f"ERRO: {error}")
        return 1

    manifest = load_json(MANIFEST_PATH)
    catalog = load_json(CATALOG_PATH)
    entries = list(manifest.get("events", []))
    catalog_events = list(catalog.get("events", []))
    if manifest.get("event_count") != EXPECTED_EVENT_COUNT or len(entries) != EXPECTED_EVENT_COUNT:
        errors.append(f"quantidade de eventos inválida: {len(entries)}")
    if len(catalog_events) != EXPECTED_EVENT_COUNT:
        errors.append(f"catálogo tem {len(catalog_events)} eventos")

    ids = [str(entry.get("event_id", "")) for entry in entries]
    catalog_ids = [str(entry.get("id", "")) for entry in catalog_events]
    if len(ids) != len(set(ids)):
        errors.append("IDs duplicados no manifesto")
    if set(ids) != set(catalog_ids):
        errors.append("IDs do manifesto e catálogo divergem")
    category_counts = Counter(str(entry.get("category", "")) for entry in entries)
    if dict(category_counts) != EXPECTED_CATEGORIES:
        errors.append(f"distribuição por categoria divergente: {dict(category_counts)}")

    aliases: set[str] = set(ids)
    catalog_by_id = {str(item.get("id", "")): item for item in catalog_events}
    for entry in entries:
        validate_event(entry, errors)
        event_id = str(entry.get("event_id", ""))
        catalog_event = catalog_by_id.get(event_id, {})
        runtime_path = str(catalog_event.get("path", ""))
        if not runtime_path.startswith("res://") or not (ROOT / runtime_path.removeprefix("res://")).is_file():
            errors.append(f"{event_id}: caminho res:// inválido")
        for alias in catalog_event.get("aliases", []):
            alias = str(alias)
            if alias in aliases:
                errors.append(f"{event_id}: alias duplicado: {alias}")
            aliases.add(alias)
        if not 1 <= int(catalog_event.get("max_polyphony", 0)) <= 8:
            errors.append(f"{event_id}: polifonia fora do limite mobile")

    if errors:
        for error in errors:
            print(f"ERRO: {error}")
        print(f"Áudio reprovado: {len(errors)} problema(s).")
        return 1
    print(
        "Áudio aprovado: "
        f"{len(entries)} eventos, 48 kHz estéreo, OGG íntegro, hashes e licenças verificados."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
