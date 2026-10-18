#!/usr/bin/env python3
"""Check media integrity and fail-closed review boundaries, not BJJ biomechanics."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / 'production/grappling_gifs_v1'


def validate():
    manifest = json.loads((PACKAGE / 'manifest.json').read_text())
    jobs = json.loads((PACKAGE / 'authoring_jobs.json').read_text())['jobs']
    graph = json.loads((ROOT / manifest['graph_source']).read_text())
    techniques = {entry['id']: entry for entry in graph['techniques']}
    checks = 0

    def require(condition, message):
        nonlocal checks
        checks += 1
        if not condition:
            raise ValueError(message)

    require(manifest['shipping'] is False and manifest['runtime_authority'] is False,
            'Review package must not become runtime authority')
    require(manifest['full_graph_claim'] is False, 'Incomplete source cannot satisfy full graph')
    clips = manifest['clips']
    require(len(clips) == 13 and len({x['id'] for x in clips}) == 13, 'Expected 13 unique clips')
    require({x['id'] for x in clips} == {x['id'] for x in jobs}, 'Authoring provenance coverage')
    for clip in clips:
        label = clip['id']
        for path_key, hash_key in [('source_image', 'source_sha256'), ('gif', 'gif_sha256')]:
            path = ROOT / clip[path_key]
            require(path.is_file(), f'{label}: missing {path_key}')
            require(hashlib.sha256(path.read_bytes()).hexdigest() == clip[hash_key], f'{label}: {hash_key}')
        with Image.open(ROOT / clip['source_image']) as sheet:
            require(list(sheet.size) == clip['source_size'], f'{label}: source dimensions')
            require(len(clip['frame_rects']) == 6, f'{label}: six source poses')
            rect_hashes = []
            for x, y, width, height in clip['frame_rects']:
                require(x >= 0 and y >= 0 and x + width <= sheet.width and y + height <= sheet.height,
                        f'{label}: region outside source')
                require(width == height and width > 0, f'{label}: preserve aspect ratio')
                rect_hashes.append(hashlib.sha256(sheet.crop((x, y, x+width, y+height)).tobytes()).hexdigest())
            require(len(set(rect_hashes)) == 6, f'{label}: duplicated source pose')
        with Image.open(ROOT / clip['gif']) as animation:
            require(animation.format == 'GIF' and animation.n_frames == 6, f'{label}: six-frame GIF')
            require(animation.size == (384, 384), f'{label}: fixed output size')
            require(animation.info.get('loop') == 0, f'{label}: review presentation loop')
            durations, frame_hashes = [], []
            for index in range(animation.n_frames):
                animation.seek(index)
                durations.append(animation.info.get('duration'))
                frame_hashes.append(hashlib.sha256(animation.convert('RGB').tobytes()).hexdigest())
            require(durations == clip['duration_ms'] == clip['intended_duration_ms'], f'{label}: frame timing')
            require(len(set(frame_hashes)) == 6, f'{label}: GIF did not animate distinct poses')
            require(sum(durations) == 5500, f'{label}: intended 5.5 second duration')
        require(not clip['shipping'] and not clip['runtime_authority'], f'{label}: authoring only')
        require(clip['biomechanics_review'] == 'PENDING' and clip['expert_reviewer'] is None,
                f'{label}: no inferred expert approval')
        require(clip['visual_triage'] == 'REDRAW_REQUIRED' and len(clip['visual_observations']) > 0,
                f'{label}: retain observed visual issues')
        require(clip['nogi'] and not clip['gi'], f'{label}: NO-GI variant')
        require(clip['rules']['opens_category_legality'] == 'UNRESOLVED_BLOCKED', f'{label}: no blanket ADCC eligibility')
        for binding in clip['bind']:
            require(binding in techniques, f'{label}: nonexistent graph technique')
        if len(clip['bind']) == 1:
            technique = techniques[clip['bind'][0]]
            require((clip['from'], clip['to']) == (technique['from'], technique['to']), f'{label}: source topology')
        require(clip['runtime_binding'].startswith('BLOCKED_'), f'{label}: unreviewed binding')
    flow = json.loads((PACKAGE / 'flow.json').read_text())
    golden = json.loads((ROOT / flow['existing_flow']['source']).read_text())
    require(flow['existing_flow']['success_chain_ids'] == [x['technique_id'] for x in golden['success_chain']], 'Flow must reference existing golden chain')
    require(flow['proposed_guard_flow']['status'] == 'UNREGISTERED_DRAFT_NOT_EXECUTABLE', 'Guard proposals must stay explicit')
    export = (ROOT / 'export_presets.cfg').read_text()
    exclusions = [line for line in export.splitlines() if line.startswith('exclude_filter=')]
    for exclude in exclusions:
        require('assets/candidates/grappling/gifs_v1/*' in exclude, 'Do not ship raw candidate assets')
        require('production/grappling_gifs_v1/*' in exclude, 'Do not ship authoring metadata')
        require('tools/art/GrapplingGifReview.*' in exclude, 'Do not ship review scene')
    require(len(exclusions) == 2, 'Validate both export presets')
    print(f'{checks} checks passed; 13 GIFs / 78 poses; no biomechanical approval asserted')


if __name__ == '__main__':
    validate()
