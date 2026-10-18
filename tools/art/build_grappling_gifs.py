#!/usr/bin/env python3
"""Encode authored six-pose sheets as review GIFs. Never draws or invents motion."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / 'production/grappling_gifs_v1'
DURATIONS = [700, 700, 900, 1000, 800, 1400]
PHASES = ['anticipation', 'entry', 'establish', 'stabilize', 'response', 'recovery']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(*args):
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', *args], check=True)


def encode(sheet, output, rects):
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='cria-gif-') as scratch:
        folder = Path(scratch)
        for index, (x, y, width, height) in enumerate(rects):
            run('-i', str(sheet), '-vf', f'crop={width}:{height}:{x}:{y}',
                '-frames:v', '1', str(folder / f'{index}.png'))
        lines = ['ffconcat version 1.0']
        for index, duration in enumerate(DURATIONS):
            lines.extend([f"file '{index}.png'", 'option framerate 100', f'duration {duration / 1000:.2f}'])
        lines.append("file '5.png'")
        listing = folder / 'poses.ffconcat'
        listing.write_text('\n'.join(lines) + '\n')
        run('-f', 'concat', '-safe', '0', '-i', str(listing), '-filter_complex',
            '[0:v]scale=384:384:flags=lanczos,split[a][b];'
            '[a]palettegen=stats_mode=full[p];[b][p]paletteuse=dither=bayer:bayer_scale=3',
            '-fps_mode', 'vfr', '-frames:v', '6', '-loop', '0', '-final_delay', '140', str(output))


def build():
    jobs = json.loads((PACKAGE / 'authoring_jobs.json').read_text())['jobs']
    clips = []
    for job in jobs:
        sheet = ROOT / job['source_image']
        with Image.open(sheet) as image:
            width, height = image.size
        if width % 3 or height % 2:
            raise ValueError(f'{sheet}: sheet must divide exactly into 3x2 cells')
        cell_w, cell_h = width // 3, height // 2
        if cell_w != cell_h:
            raise ValueError('Square source cells required; do not distort athletes')
        rects = [[(i % 3) * cell_w + 2, (i // 3) * cell_h + 2, cell_w - 4, cell_h - 4]
                 for i in range(6)]
        output = ROOT / job['gif']
        encode(sheet, output, rects)
        clip = {key: job[key] for key in ['id', 'name', 'family', 'from', 'to', 'bind',
                'source_image', 'gif', 'original_generated_asset', 'visual_observations']}
        with Image.open(output) as image:
            durations = []
            for frame in range(image.n_frames):
                image.seek(frame)
                durations.append(image.info.get('duration', 0))
        clip.update({
            'source_sha256': sha(sheet), 'gif_sha256': sha(output),
            'source_size': [width, height], 'frame_rects': rects,
            'duration_ms': durations, 'intended_duration_ms': DURATIONS,
            'phases': PHASES if job['family'] != 'combat_flow' else [],
            'phase_evidence': 'PLANNED_ONLY_NOT_MEASURED', 'planned_poses': job['poses'],
            'gi': False, 'nogi': True, 'actors': ['ruan_macacao', 'davi_relampago'],
            'animation_class': 'DISCRETE_SIX_POSE_ANIMATIC_NOT_FLUID_ANIMATION',
            'visual_triage': 'REDRAW_REQUIRED', 'biomechanics_review': 'PENDING',
            'expert_reviewer': None, 'rights_review': 'PENDING_GENERATED_ORIGINAL',
            'runtime_binding': 'BLOCKED_PENDING_REVIEW' if job['bind'] else 'BLOCKED_SOURCE_GRAPH_EXTENSION_REQUIRED',
            'runtime_authority': False, 'shipping': False,
            'rules': {'championship_reference': 'adcc_championship_web_2026_10_18',
                      'opens_category_legality': 'UNRESOLVED_BLOCKED',
                      'runtime_rules_change': False},
            'loop_semantics': 'Presentation reset only; no continuous combat transition from final to first pose.'
        })
        clips.append(clip)
        print(job['id'], 'encoded', durations)
    encoder = subprocess.check_output(['ffmpeg', '-version'], text=True).splitlines()[0]
    manifest = {'schema_version': 1, 'status': 'AUTHORING_REVIEW_ONLY', 'shipping': False,
                'encoder_version': encoder, 'frame_extraction': 'ffmpeg crop, no drawn intermediate frames',
                'runtime_authority': False, 'full_graph_claim': False,
                'graph_source': 'data/bjj/bjj_kg_slice_ruan_davi_v1.json',
                'graph_status': 'SLICE_FIXTURE_NONCANONICAL',
                'rules_authority': 'data/combat/bjj_rulesets_verified_v1.json',
                'clips': clips}
    (PACKAGE / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    argparse.ArgumentParser(description=__doc__).parse_args()
    build()
