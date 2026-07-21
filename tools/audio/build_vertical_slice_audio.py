#!/usr/bin/env python3
"""Gera o pacote sonoro original do vertical slice Arena do Dique.

O áudio é síntese determinística própria: nenhum sample, música ou gravação externa é
incorporado. O WAV permanece como fonte e o OGG é a versão de runtime.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import shutil
import struct
import subprocess
import wave
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[2]
SAMPLE_RATE = 48_000
TAU = math.tau


@dataclass(frozen=True)
class Cue:
    cue_id: str
    category: str
    duration: float
    loop: bool = False
    aliases: tuple[str, ...] = field(default_factory=tuple)
    volume_db: float = 0.0
    cooldown_ms: int = 40
    polyphony: int = 4


CUES = (
    Cue("gi_grip_connect", "combat", 0.34, aliases=("grip_de_ferro", "grip_connect"), polyphony=5),
    Cue("gi_grip_break", "combat", 0.28, aliases=("grip_break",)),
    Cue("tatame_contact_light", "combat", 0.42, aliases=("impacto_leve",), polyphony=6),
    Cue("tatame_contact_heavy", "combat", 0.62, aliases=("impacto_pesado", "baiana", "impact"), polyphony=4),
    Cue("sprawl_contact", "combat", 0.48, aliases=("sprawl", "defesa"), polyphony=4),
    Cue("sweep_commit", "combat", 0.52, aliases=("raspagem_tesoura", "raspagem_borboleta")),
    Cue("control_stable", "combat", 0.44, aliases=("corte_joelho", "passagem", "control_start")),
    Cue("defense_perfect", "combat", 0.46, aliases=("defesa_perfeita",)),
    Cue("submission_lock", "combat", 0.58, aliases=("encerramento_tecnico",)),
    Cue("tap_signal", "combat", 0.38, aliases=("tap", "tap_window")),
    Cue("reset_ready", "combat", 0.32, aliases=("reset",)),
    Cue("score_confirm", "combat", 0.42, aliases=("score",)),
    Cue("deck_clash_dominant", "combat", 0.44, polyphony=3, cooldown_ms=120),
    Cue("deck_clash_advantage", "combat", 0.36, polyphony=3, cooldown_ms=100),
    Cue("deck_clash_contested", "combat", 0.28, polyphony=3, cooldown_ms=80),
    Cue("deck_clash_counter", "combat", 0.42, polyphony=3, cooldown_ms=120),
    Cue("button_confirm", "ui", 0.12, aliases=("botao", "botao_click"), polyphony=6, cooldown_ms=25),
    Cue("menu_open", "ui", 0.26),
    Cue("cria_live_notification", "ui", 0.48, aliases=("cria_live",)),
    Cue("save_confirm", "ui", 0.54, aliases=("save_game",)),
    Cue("arena_idle_loop", "ambience", 12.0, loop=True, volume_db=-8.0, polyphony=1, cooldown_ms=500),
    Cue("terreiro_river_loop", "ambience", 14.0, loop=True, volume_db=-9.0, polyphony=1, cooldown_ms=500),
    Cue("salvador_city_loop", "ambience", 14.0, loop=True, volume_db=-10.0, polyphony=1, cooldown_ms=500),
    Cue("zambiapunga_square_loop", "ambience", 14.0, loop=True, volume_db=-9.0, polyphony=1, cooldown_ms=500),
    Cue("mangrove_tide_loop", "ambience", 14.0, loop=True, volume_db=-9.0, polyphony=1, cooldown_ms=500),
    Cue("arena_positive", "crowd", 1.45, aliases=("vitoria_crowd",), volume_db=-3.0, polyphony=2, cooldown_ms=350),
    Cue("arena_tension", "crowd", 1.70, volume_db=-5.0, polyphony=2, cooldown_ms=350),
    Cue("arena_dique_pulse_loop", "music", 60.0 / 92.0 * 24.0, loop=True, aliases=("arena_do_dique", "dique"), volume_db=-6.0, polyphony=1, cooldown_ms=500),
)


def clamp(value: float) -> float:
    return max(-1.0, min(1.0, value))


def env(t: float, duration: float, attack: float = 0.01, release: float = 0.12) -> float:
    attack_gain = min(1.0, t / max(attack, 1e-6))
    release_gain = min(1.0, (duration - t) / max(release, 1e-6))
    return max(0.0, min(attack_gain, release_gain))


def sine(freq: float, t: float, phase: float = 0.0) -> float:
    return math.sin(TAU * freq * t + phase)


def sweep(start: float, end: float, t: float, duration: float) -> float:
    ratio = t / max(duration, 1e-6)
    freq = start + (end - start) * ratio
    return sine(freq, t)


def filtered_noise(rng: random.Random, state: list[float], smoothing: float = 0.78) -> float:
    raw = rng.uniform(-1.0, 1.0)
    state[0] = state[0] * smoothing + raw * (1.0 - smoothing)
    return state[0]


def transient(cue: Cue, index: int, rng: random.Random, noise_state: list[float]) -> tuple[float, float]:
    t = index / SAMPLE_RATE
    e = env(t, cue.duration)
    n = filtered_noise(rng, noise_state)
    cue_id = cue.cue_id
    if cue_id == "gi_grip_connect":
        value = n * 0.48 * e + sine(175.0, t) * 0.18 * env(t, cue.duration, 0.004, 0.18)
    elif cue_id == "gi_grip_break":
        value = n * 0.55 * e + sweep(240.0, 120.0, t, cue.duration) * 0.12 * e
    elif cue_id in ("tatame_contact_light", "sprawl_contact"):
        value = sweep(105.0, 54.0, t, cue.duration) * 0.52 * env(t, cue.duration, 0.003, 0.26) + n * 0.18 * e
    elif cue_id == "tatame_contact_heavy":
        value = sweep(92.0, 38.0, t, cue.duration) * 0.72 * env(t, cue.duration, 0.002, 0.38) + n * 0.24 * e
    elif cue_id == "sweep_commit":
        value = sweep(165.0, 72.0, t, cue.duration) * 0.38 * e + n * 0.28 * e
    elif cue_id == "control_stable":
        value = (sine(92.0, t) + sine(138.0, t) * 0.35) * 0.30 * e + n * 0.12 * e
    elif cue_id == "defense_perfect":
        value = (sine(480.0, t) * 0.32 + sine(720.0, t) * 0.16) * e + n * 0.07 * e
    elif cue_id == "submission_lock":
        value = sweep(155.0, 88.0, t, cue.duration) * 0.44 * e + sine(44.0, t) * 0.24 * e
    elif cue_id == "tap_signal":
        tap_a = env(t, 0.075, 0.001, 0.06) if t < 0.075 else 0.0
        local_b = t - 0.12
        tap_b = env(local_b, 0.09, 0.001, 0.07) if 0.0 <= local_b < 0.09 else 0.0
        value = (tap_a + tap_b) * (sine(210.0, t) * 0.45 + n * 0.22)
    elif cue_id == "reset_ready":
        value = (sine(220.0, t) * 0.22 + sine(330.0, t) * 0.12) * e
    elif cue_id == "score_confirm":
        value = (sine(330.0, t) * 0.24 + sine(495.0, t) * 0.16 + sine(660.0, t) * 0.08) * e
    elif cue_id == "deck_clash_dominant":
        value = (sine(220.0, t) * 0.20 + sine(440.0, t) * 0.19 + sine(660.0, t) * 0.13) * e + n * 0.06 * e
    elif cue_id == "deck_clash_advantage":
        value = (sine(196.0, t) * 0.18 + sweep(330.0, 520.0, t, cue.duration) * 0.19) * e
    elif cue_id == "deck_clash_contested":
        value = (sine(180.0, t) * 0.16 + sine(186.0, t) * 0.16) * e + n * 0.05 * e
    elif cue_id == "deck_clash_counter":
        value = (sweep(480.0, 145.0, t, cue.duration) * 0.27 + sine(73.0, t) * 0.15) * e
    elif cue_id == "button_confirm":
        value = sweep(520.0, 360.0, t, cue.duration) * 0.32 * e
    elif cue_id == "menu_open":
        value = sweep(180.0, 420.0, t, cue.duration) * 0.26 * e + sine(600.0, t) * 0.08 * e
    elif cue_id == "cria_live_notification":
        value = (sine(523.25, t) * 0.22 + sine(659.25, t) * 0.18 + sine(783.99, t) * 0.10) * e
    elif cue_id == "save_confirm":
        value = (sine(261.63, t) * 0.20 + sine(392.0, t) * 0.17 + sine(523.25, t) * 0.12) * e
    elif cue_id in ("arena_positive", "arena_tension"):
        swell = math.sin(math.pi * min(1.0, t / cue.duration))
        tone = 130.0 if cue_id == "arena_positive" else 82.0
        value = n * (0.62 if cue_id == "arena_positive" else 0.44) * swell + sine(tone, t) * 0.08 * swell
    else:
        value = sine(200.0, t) * 0.2 * e
    # `hash()` do Python muda entre processos. Esta fase estável preserva o
    # mesmo arquivo binário em qualquer execução e facilita auditoria por SHA.
    stable_phase = sum((position + 1) * ord(char) for position, char in enumerate(cue_id)) % 13
    pan = math.sin(t * 8.0 + stable_phase) * 0.08
    return clamp(value * (1.0 - pan)), clamp(value * (1.0 + pan))


def ambience(cue: Cue, index: int, rng: random.Random, state: list[float]) -> tuple[float, float]:
    t = index / SAMPLE_RATE
    n = filtered_noise(rng, state, 0.94)
    if cue.cue_id == "terreiro_river_loop":
        murmur = n * (0.13 + 0.025 * sine(0.13, t))
        ventilation = sine(38.0, t) * 0.018 + sine(76.0, t) * 0.008
        distant = sine(880.0, t) * 0.006 * max(0.0, sine(0.19, t))
    elif cue.cue_id == "salvador_city_loop":
        murmur = n * (0.18 + 0.030 * sine(0.23, t))
        ventilation = sine(52.0, t) * 0.020 + sine(104.0, t) * 0.009
        distant = sine(246.0, t) * 0.010 * max(0.0, sine(0.09, t))
    elif cue.cue_id == "zambiapunga_square_loop":
        murmur = n * (0.15 + 0.030 * sine(0.16, t))
        ventilation = sine(74.0, t) * 0.020 + sine(111.0, t) * 0.010
        distant = sine(296.0, t) * 0.009 * max(0.0, sine(0.31, t))
    elif cue.cue_id == "mangrove_tide_loop":
        murmur = n * (0.12 + 0.035 * sine(0.11, t))
        ventilation = sine(33.0, t) * 0.022 + sine(66.0, t) * 0.010
        distant = sine(1240.0, t) * 0.004 * max(0.0, sine(0.27, t))
    else:
        murmur = n * (0.16 + 0.035 * sine(0.17, t))
        ventilation = sine(46.0, t) * 0.025 + sine(92.0, t) * 0.012
        distant = sine(138.0, t) * 0.008 * (0.5 + 0.5 * sine(0.11, t))
    return murmur + ventilation + distant, murmur * 0.94 + ventilation - distant


def music(cue: Cue, index: int, rng: random.Random, state: list[float]) -> tuple[float, float]:
    del rng, state
    t = index / SAMPLE_RATE
    beat = 60.0 / 92.0
    step = int(t / beat) % 8
    local = t % beat
    roots = (55.0, 55.0, 73.42, 55.0, 65.41, 55.0, 49.0, 55.0)
    bass = sine(roots[step], t) * 0.16 + sine(roots[step] * 2.0, t) * 0.035
    bass *= env(local, beat, 0.008, 0.34)
    kick = sweep(88.0, 42.0, local, 0.22) * 0.34 * env(local, 0.22, 0.002, 0.18) if local < 0.22 else 0.0
    off = (t + beat * 0.5) % beat
    rim = sine(320.0, off) * 0.07 * env(off, 0.08, 0.001, 0.06) if off < 0.08 else 0.0
    pulse = sine(110.0, t) * 0.035 * (0.5 + 0.5 * sine(0.25, t))
    return bass + kick + rim + pulse, bass + kick - rim + pulse


def render_samples(cue: Cue) -> list[tuple[float, float]]:
    rng = random.Random(f"cria-do-tatame|{cue.cue_id}|2026-07-20")
    state = [0.0]
    renderer: Callable[[Cue, int, random.Random, list[float]], tuple[float, float]]
    if cue.category == "ambience":
        renderer = ambience
    elif cue.category == "music":
        renderer = music
    else:
        renderer = transient
    sample_count = round(cue.duration * SAMPLE_RATE)
    seam_frames = min(round(0.40 * SAMPLE_RATE), sample_count // 8) if cue.loop else 0
    raw_count = sample_count + seam_frames
    raw_samples = [renderer(cue, index, rng, state) for index in range(raw_count)]
    samples = raw_samples[:sample_count]
    # O começo é cruzado com a continuação imediatamente após o fim. Assim o
    # primeiro sample encontra o último sem estalo quando o Godot repete o OGG.
    for index in range(seam_frames):
        blend = index / max(1, seam_frames - 1)
        future_left, future_right = raw_samples[sample_count + index]
        start_left, start_right = samples[index]
        samples[index] = (
            future_left * (1.0 - blend) + start_left * blend,
            future_right * (1.0 - blend) + start_right * blend,
        )
    peak = max(max(abs(left), abs(right)) for left, right in samples) or 1.0
    gain = min(1.0, 0.82 / peak)
    return [(left * gain, right * gain) for left, right in samples]


def write_wav(path: Path, samples: list[tuple[float, float]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = bytearray()
    for left, right in samples:
        payload.extend(struct.pack("<hh", int(clamp(left) * 32767), int(clamp(right) * 32767)))
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(2)
        stream.setsampwidth(2)
        stream.setframerate(SAMPLE_RATE)
        stream.writeframes(bytes(payload))


def audio_metrics(samples: list[tuple[float, float]]) -> dict[str, float]:
    flat = [value for pair in samples for value in pair]
    peak = max(abs(value) for value in flat)
    rms = math.sqrt(sum(value * value for value in flat) / max(1, len(flat)))
    return {
        "peak_dbfs": round(20.0 * math.log10(max(peak, 1e-12)), 3),
        "rms_dbfs": round(20.0 * math.log10(max(rms, 1e-12)), 3),
    }


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def ogg_crc(payload: bytes | bytearray) -> int:
    """Calcula o CRC não refletido definido pelo contêiner Ogg."""
    register = 0
    for value in payload:
        register ^= value << 24
        for _ in range(8):
            if register & 0x80000000:
                register = ((register << 1) ^ 0x04C11DB7) & 0xFFFFFFFF
            else:
                register = (register << 1) & 0xFFFFFFFF
    return register


def canonicalize_ogg_serial(path: Path, stream_key: str) -> int:
    """Fixa o serial Ogg e recalcula CRC para produzir binário reprodutível."""
    payload = bytearray(path.read_bytes())
    serial = int.from_bytes(hashlib.sha256(stream_key.encode("utf-8")).digest()[:4], "little") or 1
    offset = 0
    pages = 0
    while offset < len(payload):
        if payload[offset : offset + 4] != b"OggS" or offset + 27 > len(payload):
            raise RuntimeError(f"Página Ogg inválida em {path} no offset {offset}")
        segment_count = payload[offset + 26]
        table_end = offset + 27 + segment_count
        if table_end > len(payload):
            raise RuntimeError(f"Tabela Ogg truncada em {path}")
        page_end = table_end + sum(payload[offset + 27 : table_end])
        if page_end > len(payload):
            raise RuntimeError(f"Payload Ogg truncado em {path}")
        payload[offset + 14 : offset + 18] = struct.pack("<I", serial)
        payload[offset + 22 : offset + 26] = b"\x00\x00\x00\x00"
        checksum = ogg_crc(payload[offset:page_end])
        payload[offset + 22 : offset + 26] = struct.pack("<I", checksum)
        offset = page_end
        pages += 1
    if pages == 0:
        raise RuntimeError(f"Arquivo Ogg sem páginas: {path}")
    path.write_bytes(payload)
    return serial


def encode_ogg(source: Path, target: Path, normalize: bool, stream_key: str) -> dict[str, object]:
    command = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-fflags", "+bitexact", "-i", str(source), "-map_metadata", "-1", "-flags:a", "+bitexact",
    ]
    if normalize:
        command += ["-af", "loudnorm=I=-16:TP=-1.5:LRA=7"]
    # O filtro loudnorm trabalha internamente em 192 kHz; forçamos o arquivo
    # final para 48 kHz, contrato de runtime e orçamento mobile do projeto.
    command += ["-ar", str(SAMPLE_RATE), "-c:a", "libvorbis", "-q:a", "5", str(target)]
    subprocess.run(command, check=True, capture_output=True)
    serial = canonicalize_ogg_serial(target, stream_key)
    return {
        "encoder": "ffmpeg libvorbis q5",
        "normalization": "EBU_R128_one_pass_-16_LUFS_-1.5_dBTP" if normalize else "source_peak_preserved",
        "ogg_serial": serial,
        "binary_reproducibility": "fixed_serial_and_recalculated_crc",
    }


def build() -> None:
    if shutil.which("ffmpeg") is None:
        raise SystemExit("ffmpeg não encontrado")
    manifest_entries: list[dict[str, object]] = []
    catalog_events: list[dict[str, object]] = []
    for cue in CUES:
        output = ROOT / "assets/audio" / cue.category / cue.cue_id
        output.mkdir(parents=True, exist_ok=True)
        source_path = output / "source.wav"
        game_path = output / "game.ogg"
        samples = render_samples(cue)
        write_wav(source_path, samples)
        encode_info = encode_ogg(source_path, game_path, cue.loop, cue.cue_id)
        metrics = audio_metrics(samples)
        metadata = {
            "version": "1.0.0",
            "event_id": cue.cue_id,
            "category": cue.category,
            "duration_seconds": round(len(samples) / SAMPLE_RATE, 4),
            "sample_rate": SAMPLE_RATE,
            "channels": 2,
            "loop": cue.loop,
            "loop_start_samples": 0 if cue.loop else None,
            "loop_end_samples": len(samples) if cue.loop else None,
            "aliases": list(cue.aliases),
            "runtime_volume_db": cue.volume_db,
            "cooldown_ms": cue.cooldown_ms,
            "max_polyphony": cue.polyphony,
            "generation": "deterministic_original_synthesis",
            "source_sha256": sha256(source_path),
            "game_sha256": sha256(game_path),
        }
        (output / "metadata.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        loudness = {
            "version": "1.0.0",
            "measurement": "deterministic_PCM_peak_and_RMS",
            **metrics,
            "runtime_processing": encode_info,
            "release_note": "Executar medição EBU R128 de duas passagens antes do master final.",
        }
        (output / "loudness_report.json").write_text(json.dumps(loudness, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        (output / "license.txt").write_text(
            "Original project-generated procedural audio. No external samples, voices, songs or recordings.\n"
            "Final release remains subject to project legal and listening review.\n",
            encoding="utf-8",
        )
        relative = output.relative_to(ROOT).as_posix()
        manifest_entries.append({
            "event_id": cue.cue_id,
            "category": cue.category,
            "source": f"{relative}/source.wav",
            "source_sha256": metadata["source_sha256"],
            "game": f"{relative}/game.ogg",
            "game_sha256": metadata["game_sha256"],
            "metadata": f"{relative}/metadata.json",
            "loudness_report": f"{relative}/loudness_report.json",
            "license": f"{relative}/license.txt",
        })
        catalog_events.append({
            "id": cue.cue_id,
            "category": cue.category,
            "path": f"res://{relative}/game.ogg",
            "loop": cue.loop,
            "volume_db": cue.volume_db,
            "cooldown_ms": cue.cooldown_ms,
            "max_polyphony": cue.polyphony,
            "aliases": list(cue.aliases),
        })
    manifest = {
        "version": "1.0.0",
        "pack_id": "arena_do_dique_vertical_slice_audio_v01",
        "generated_at": "2026-07-20",
        "event_count": len(manifest_entries),
        "events": manifest_entries,
        "status": "asset_qa_pending_listening_and_godot",
    }
    manifest_path = ROOT / "assets/audio/audio_pack_manifest_v01.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    catalog = {
        "version": "1.0.0",
        "pack_manifest": "assets/audio/audio_pack_manifest_v01.json",
        "mobile_simultaneous_voice_limit": 24,
        "events": catalog_events,
        "fallback_policy": "procedural_tone_only_when_file_missing",
    }
    catalog_path = ROOT / "data/audio/audio_event_catalog_v01.json"
    catalog_path.parent.mkdir(parents=True, exist_ok=True)
    catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (ROOT / "assets/audio/README.md").write_text(
        "# Áudio original - vertical slice\n\n"
        "Pacote determinístico sem samples externos. Cada evento contém WAV fonte, OGG de jogo, "
        "metadados, relatório de loudness e licença. O status continua candidato até escuta crítica, "
        "Godot e aparelho Android.\n",
        encoding="utf-8",
    )
    print(json.dumps({"ok": True, "events": len(CUES), "manifest": str(manifest_path.relative_to(ROOT))}, ensure_ascii=False))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.parse_args()
    build()


if __name__ == "__main__":
    main()
