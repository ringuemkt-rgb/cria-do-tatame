# CRIA Motion Factory V1

## Status

`ACTIVE_OFFLINE_AUTHORING_PIPELINE`

The Motion Factory is an **offline authoring** layer for CRIA DO TATAME. It uses a pinned `mixamo-llm-mocap` checkout to turn rights-cleared combat plates into measurable retarget references, pair-spacing evidence, mesh-contact evidence and Sprite Forge V2 handoff packages.

It is not a Godot runtime dependency and it never changes BJJ legality, combat state, score, winner, canon or release status. Every generated/retargeted artifact remains `shipping=false` until the normal CRIA rights, visual, gameplay and human-review gates pass.

## Why this exists

The existing Grappling Motion Lab is the evidence and capture authority. Sprite Forge V2 is the 2D manufacturing authority. The missing layer was a reproducible bridge that can:

- recover motion from a locked-camera plate;
- retarget to measured Mixamo-style rigs;
- preserve/measure root motion;
- handle two performers in one scene;
- measure pair spacing, strike/entry reach and limb intrusion;
- check real evaluated mesh contact in Blender;
- render side-by-side evidence before 2D sprite production.

The upstream implementation is pinned to:

- source: `squall01337/mixamo-llm-mocap`
- revision: `00dfd5385506022d533c84f6737a09f5f4392623`
- repository code license: MIT

Changing that revision requires a new technical and license audit.

## License boundary

The upstream repository code is MIT, but the complete toolchain is not one MIT blob. The adapter therefore keeps every dependency external and license-gated.

Review separately before production use:

- Adobe Mixamo character terms;
- GVHMR code and pretrained checkpoint terms;
- SMPL-X body-model terms;
- Blender and Blender MCP terms;
- source-media rights and athlete releases.

CRIA does not redistribute Mixamo characters, GVHMR checkpoints, SMPL-X assets or raw capture through this repository.

## Authority chain

```text
BJJ graph / rules / reducer
        ↓
Grappling Motion Lab
        ↓
Motion Factory V1
        ↓
reviewed 3D motion reference
        ↓
Sprite Forge V2
        ↓
128x128 normalized paired sprites
        ↓
Godot runtime visual QA
        ↓
human approval
```

Motion Factory is visual/authoring evidence only.

## Ruan × Davi first slice

The first production backlog is `data/motion/ruan_davi_motion_slice_v1.json`.

It covers the existing golden chain and its representative defense/alternate branches:

- `t001` standing neutral → half guard top;
- `slice_sprawl` defense → front headlock;
- `t025` half guard top → side control;
- `t049` knee-shield counter;
- `slice_side_to_mount` side control → mount high;
- `t057` mount → submission;
- `t005` standing neutral → closed guard.

These are obligations, not claims that footage or mocap already exists. Initial status stays `CAPTURE_PENDING`.

## Capture strategy

For commercial production, prefer CRIA-owned capture with releases. The Grappling Motion Lab multiview package remains the gold source for biomechanical claims.

A locked-camera pair plate may be produced specifically for the Mixamo retarget loop when:

- both performers are rights-cleared;
- both bodies remain visible as much as possible;
- performers do not cross screen sides during the paired plate;
- clothing colors are easy to distinguish;
- T-pose bookends are recorded for retarget setup;
- raw files stay outside Git and are referenced by SHA-256.

Single-view output is never promoted into gold biomechanical truth.

## Pinned checkout

Keep the upstream project outside the CRIA repository:

```bash
git clone https://github.com/squall01337/mixamo-llm-mocap.git ../mixamo-llm-mocap
cd ../mixamo-llm-mocap
git checkout 00dfd5385506022d533c84f6737a09f5f4392623
```

Install its heavy dependencies separately according to its audited documentation. Do not add them to the Godot project or Android build.

## Adapter

CRIA calls the external checkout through:

```text
tools/motion_factory/run_mixamo_llm_mocap.py
```

### Estimate one performer

```bash
python tools/motion_factory/run_mixamo_llm_mocap.py \
  --upstream-root ../mixamo-llm-mocap \
  --gvhmr-python ../mixamo-llm-mocap/tools/GVHMR/.venv/bin/python \
  estimate \
  --video /external/capture/ruan_davi_t001.mp4 \
  --out /external/derived/ruan_t001_landmarks.json \
  --person left
```

Run again for `--person right` on a paired plate.

### Analyze landmarks

```bash
python tools/motion_factory/run_mixamo_llm_mocap.py \
  --upstream-root ../mixamo-llm-mocap \
  --gvhmr-python ../mixamo-llm-mocap/tools/GVHMR/.venv/bin/python \
  analyze \
  --landmarks /external/derived/ruan_t001_landmarks.json
```

The numeric analysis informs the beat sheet. It does not approve the beat sheet automatically.

### Retarget and QA one reviewed spec

```bash
python tools/motion_factory/run_mixamo_llm_mocap.py \
  --upstream-root ../mixamo-llm-mocap \
  --gvhmr-python ../mixamo-llm-mocap/tools/GVHMR/.venv/bin/python \
  single \
  --spec /external/specs/ruan_t001.json
```

### Retarget and QA a pair

```bash
python tools/motion_factory/run_mixamo_llm_mocap.py \
  --upstream-root ../mixamo-llm-mocap \
  --gvhmr-python ../mixamo-llm-mocap/tools/GVHMR/.venv/bin/python \
  pair \
  --left-spec /external/specs/ruan_t001.json \
  --right-spec /external/specs/davi_t001.json
```

The pair pass runs both single-character QA loops and then adds `compare_pair.py` plus real Blender mesh-contact checking.

## Ten animation gates

Every candidate is evaluated against:

1. `ANIM_QA_01_SKELETON_INTEGRITY`
2. `ANIM_QA_02_FOOT_CONTACT`
3. `ANIM_QA_03_ROOT_DISPLACEMENT`
4. `ANIM_QA_04_SILHOUETTE_READABILITY`
5. `ANIM_QA_05_STRIKE_OR_ENTRY_REACH`
6. `ANIM_QA_06_PAIR_SPACING`
7. `ANIM_QA_07_MESH_COLLISION`
8. `ANIM_QA_08_SPRITE_PIVOT_CONSISTENCY`
9. `ANIM_QA_09_GAMEPLAY_TIMING`
10. `ANIM_QA_10_ANDROID_SPRITE_BUDGET`

Numeric success alone never promotes the asset. If a human visual review and a proxy disagree on collision, the real evaluated meshes and subsequent manual review take precedence over the cheap proxy.

## 3D → 2D handoff

The shipping renderer remains premium 2D/pixel art.

```text
reviewed retarget
→ canonical camera/key-pose render
→ six-phase contact map
→ identity-locked Ruan/Davi references
→ Sprite Forge V2
→ shared scale/pivot normalization
→ paired preview
→ Godot
```

Motion Factory must not dump generic Mixamo-looking characters into the game. Character identity is reconstructed through the established Sprite Forge pipeline.

## CI

Structural gates run with:

```bash
python tools/motion_factory/validate_motion_factory_v1.py
python -m unittest discover -s tests -p 'test_motion_factory_v1.py'
python tools/ci/validate_external_tool_registry_v1.py
python tools/combat/validate_grappling_motion_lab_v1.py
```

GitHub Actions runs the same checks through `.github/workflows/motion-factory-v1.yml`.

## Definition of done for one technique

A Motion Factory unit is complete only when:

```text
rights-cleared capture exists
+ source hashes exist
+ beat/action spec received human review
+ retarget completed on both roles when paired
+ clip QA passed
+ reference comparison reviewed
+ pair spacing/reach reviewed
+ mesh contact reviewed
+ preview reviewed
+ Sprite Forge V2 package produced
+ Godot runtime evidence captured
+ human visual approval granted
```

Until then, `shipping=false` remains mandatory.
