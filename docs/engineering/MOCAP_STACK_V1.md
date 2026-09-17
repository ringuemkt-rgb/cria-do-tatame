# MOCAP STACK V1 — Paired Motion / Pixel Art 2.5D

**Status:** prototype offline only  
**Goal:** produce paired BJJ animation candidates with measurable geometry/continuity/contact QA, pixel-art projection, provenance and mandatory human review.

## Non-negotiable rules

1. The project never claims biomechanical perfection. The accepted term is **biomechanically validated candidate with explicit tolerances**.
2. `CombatManager` remains the runtime authority. Castagne is reference material only unless a separately reviewed adapter is approved.
3. AI/mocap tools operate offline; no generative model controls the critical combat loop.
4. Research/non-commercial/restricted tooling may be used only for internal comparison/QA when its terms allow it. It cannot make an asset shipping-eligible by itself.
5. SMPL/SMPL-X-derived production is blocked until an applicable commercial license is recorded in provenance.
6. Raw performer video and sensitive consent documents do not belong in the public Git repository.
7. No automated process may promote a candidate to `assets/aprovados`.

## Canonical production path

```text
owned, consented multi-camera video
  -> RTMPose/MMPose
  -> Pose2Sim
  -> OpenSim
  -> ctt_paired_motion_v1
  -> Blender/glTF authoring
  -> Godot preview (IK only as constrained micro-correction)
  -> skeleton_to_pixel
  -> paired attacker/defender sheets + sync map
  -> Visual QA V2
  -> biomechanics QA
  -> human review
  -> candidate integration
```

## Research cross-check lane

The following systems may be used as internal comparison/research tools when their individual terms permit the intended use:

- FreeMoCap
- OpenCap Core / hosted service under its separate terms
- MAMMA
- EasyMocap
- WHAM
- 4DHumans
- CHI3D
- InterAct
- SBU
- AMASS

They are **not** an alternate shipping path. Research results must never silently convert `shipping_eligible` to true.

## Tool roles

| Tool | Role | Runtime authority? |
|---|---|---|
| RTMPose/MMPose | 2D pose / reprojection QA | No |
| Pose2Sim | multi-camera 3D reconstruction | No |
| OpenSim | kinematic analysis | No |
| Blender | retarget/authoring/export | No |
| Godot | preview/import/runtime | Yes, through existing managers |
| FABRIK/IK | limited contact correction after valid retarget | No independent authority |
| Castagne | frame-data/debug architecture reference | No |
| LimboAI | optional behavior authoring | No result authority; CombatManager validates |
| GrappleMap | positional/taxonomy reference | No timing authority |
| skeleton_to_pixel | project projection/cleanup stage | Offline only |
| Visual QA V2 | deterministic visual candidate QA | No promotion authority |

## Canonical intermediate format

`data/schemas/ctt_paired_motion_v1.schema.json`

The format is deliberately provider-independent. It stores:

- attacker and defender identities;
- a shared joint set;
- synchronized 3D joint frames;
- explicit paired contacts;
- animation phases/events;
- provenance and shipping eligibility.

This prevents a specific mocap vendor/body model from becoming the project's source of truth.

## Prototype technique

The first proof is **armlock from mount — Ruan x Davi**. The prototype package is:

`production/mocap/armlock_mount_v1/prototype.json`

Required capture takes:

1. slow technical demonstration;
2. technical-speed execution;
3. defensive response;
4. escape/recovery path.

The technique is selected because it stresses two-body synchronization, occlusion, arm contact, positional control, defensive response and paired sprite readability.

## Automated gates implemented in this PR

### Structural gate

```bash
python tools/mocap/validate_paired_motion.py \
  tests/fixtures/mocap/armlock_montada_synthetic.json
```

Checks include:

- two actors: attacker + defender;
- complete shared joint set;
- finite 3D coordinates;
- strictly increasing frame numbers;
- valid contact references;
- ordered mandatory animation phases;
- terminal outcome + recovery;
- research/restricted provenance cannot be marked shipping-eligible.

### Geometry/continuity gate

```bash
python tools/mocap/biomechanics_qa.py \
  tests/fixtures/mocap/armlock_montada_synthetic.json
```

Checks include:

- per-joint inter-frame continuity;
- paired contact distances while a contact is active;
- explicit thresholds from `data/manifest/mocap_stack_v1.json`;
- automated result remains `PASS_AUTOMATED_PENDING_HUMAN`.

This is geometry QA, **not clinical validation**.

### Unit tests

```bash
python -m unittest discover -s tests/mocap -p 'test_*.py'
```

The test suite proves that:

- the non-shipping synthetic fixture satisfies the contract;
- restricted components cannot be mislabelled shipping-safe;
- missing mandatory phases fail;
- a valid geometry candidate remains human-pending;
- broken paired contact fails.

## Initial engineering thresholds

These are prototype engineering thresholds, not clinical norms:

- paired contact synchronization target: <= 1 frame;
- median angular error target for selected key joints: <= 10 degrees after real reference data is available;
- pixel pivot drift target: <= 1 px in critical frames;
- normalized inter-frame teleport threshold: <= 0.18.

The angular and pixel metrics are documented targets; this first PR only implements structural/continuity/contact geometry checks because no real capture or pixel sheet exists yet.

## Definition of Done for the real armlock candidate

The prototype cannot be called complete until it has:

- owned/licensed source reference with evidence;
- performer-use authorization recorded outside public Git where appropriate;
- calibrated capture metadata;
- reconstructed paired motion;
- kinematics report;
- retargeted glTF motion;
- attacker spritesheet;
- defender spritesheet;
- sync map;
- visual QA report;
- contact/continuity QA report;
- human biomechanics review;
- Godot import and playable tap/escape path;
- platform smoke evidence required by the repository release gates.

Until then its status stays **candidate/prototype**, never `shipping`.
