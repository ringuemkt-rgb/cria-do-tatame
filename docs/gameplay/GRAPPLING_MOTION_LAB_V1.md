# CRIA Grappling Motion Lab V1

## Purpose

The Motion Lab is the evidence and authoring layer between real grappling movement and CRIA's paired pixel animation system.

It is **not** combat authority. `BJJGraphReducerV2` and verified rules remain authoritative. Computer vision, pose reconstruction, motion generation and Blender previews are measurement/authoring aids only.

## Design target

A final CRIA technique should be able to answer all of these questions:

1. What authoritative position did the exchange start from?
2. Which grips, ties, frames, hooks, wedges and support points were present?
3. What changed during anticipation, entry, establishment, stabilization, response and recovery?
4. Which observations are visible, reconstructed, inferred or still unknown?
5. Which rule profile determines legality and scoring?
6. Which source footage supports the physical binding and is that footage usable for the target purpose?
7. Which paired animation visualizes the accepted transition?
8. Does the animation preserve contact, pivot, silhouette and endpoint state in Godot?

If any answer is fabricated, the package is not ready.

## Why multiview

BJJ and submission grappling create severe self-occlusion and mutual occlusion. A single camera often cannot see the far arm, knee line, heel exposure, underhook or the exact topology of a body lock.

Gold capture therefore uses 4–8 synchronized cameras, with six as the working default. Multi-view reconstruction is used to reduce ambiguity, not to manufacture certainty.

## Canonical pipeline

```text
rights intake
  -> immutable source hash
  -> normalized media
  -> synchronization/calibration
  -> athlete masks (optional)
  -> 2D pose candidates
  -> multi-view 3D reconstruction
  -> contact candidates
  -> six-phase segmentation
  -> expert annotation
  -> biomechanical review
  -> rules cross-check
  -> versioned evidence package
  -> authoring/previsualization
  -> paired pixel animation
  -> Godot visual QA
```

## Tool choices

### Preferred research/authoring candidates

- **Pose2Sim** — multi-camera markerless kinematics, calibration, triangulation/reprojection and OpenSim handoff. Current upstream package declares BSD-3-Clause.
- **OpenSim** — optional musculoskeletal/kinematic analysis. Core is Apache-2.0.
- **MMPose / RTMPose** — 2D and whole-body pose candidates. Code is Apache-2.0; checkpoints/datasets remain separately audited.
- **SAM 2** — optional athlete mask propagation and occlusion support. Never a source of contact truth.
- **CVAT Community** — preferred expert video annotation UI; community code is MIT, with component-specific terms reviewed separately.
- **DVC** — dataset/pipeline versioning and reproducibility; Apache-2.0.
- **FiftyOne** — dataset inspection/error analysis candidate.

### External executables

- **FFmpeg** for media normalization, with the exact build/license configuration audited.
- **Blender** for offline motion inspection, retargeting and canonical-camera reference rendering. Blender is not embedded in the game runtime.

### Research/reference only by default

- ViCoS BJJ dataset — CC BY-NC-SA 4.0.
- InterGen/InterHuman — noncommercial dataset path.
- CoShMDM — noncommercial research terms surfaced.
- Interact2Ar — academic/non-profit noncommercial research terms surfaced.
- BlendAnything — current repository LICENSE explicitly limits use to academic/non-profit noncommercial research; additionally depends on motion/model/data sources with their own terms.
- FreeMoCap — AGPL path with separate commercial licensing advertised; do not make it an embedded commercial dependency without a deliberate legal/architecture decision.
- SMPL-X assets — do not make the commercial CRIA pipeline depend on them by default.

The authoritative classification lives in `data/research/motion_tool_registry_v1.json`; actual reuse authorization lives in `data/production/external_tool_registry_v1.json`.

## Evidence states

Use explicit uncertainty. A contact can be:

- expert-observed;
- multiview-reconstructed and expert-accepted;
- model candidate;
- occluded/unknown;
- rejected.

Never convert `UNKNOWN` to a plausible value merely to complete an animation sheet.

## Phase evidence

Every technique uses exactly six phases:

```text
anticipation -> entry -> establish -> stabilize -> response -> recovery
```

For each phase store the time span, athlete identity confidence, pose confidence, occlusion, contact edges and contact continuity. `contact_continuity` remains `UNKNOWN` unless reviewed evidence supports a value.

## Contact graph

The physical state is relational. Important edge families include:

```text
grip / frame / hook / post / wedge / pin
head_control / chest_contact / hip_contact
leg_entanglement / foot_contact / mat_support
```

An edge does not mean perfect continuity. Continuity is separately reviewed.

## Motion-clip metadata

`assets/schemas/grappling_motion_clip_v1.schema.json` defines one clip record. Git stores metadata, hashes and references only. Raw video, masks, dense keypoints, reconstructed 3D and embedding files belong in a controlled data store.

The clip record keeps rights, camera/hash metadata, time span, modality, rules context, technique label status, two athlete tracks, six-phase spans, derived artifact references, occlusion metrics, expert review and provenance.

## Capture session

Start from `data/research/grappling_capture_session_template_v1.json`.

The template deliberately contains no fake release IDs, hashes, calibration results or completed QA. `capture_complete=false` is the correct initial state.

A real session cannot be promoted without athlete releases, recording rights, hashed camera files, camera calibration and session QA.

## Scaling to thousands of clips

Large volume is handled through **active learning**, not by pretending every imported video is knowledge.

Priority order:

1. high uncertainty;
2. high occlusion;
3. model disagreement;
4. identity switches;
5. rare position/counter;
6. golden-chain coverage gaps;
7. high-value production techniques.

Models may prelabel. Experts decide final technique, phase/contact acceptance and rule interpretation.

## Conditioning research

BJJ is not represented adequately by a single energy meter forever. Motion Lab captures evidence for a future fatigue layer with separate candidates for:

- global gas;
- forearm/grip fatigue;
- upper-body isometric load;
- trunk isometric load;
- hip/leg dynamic load;
- respiratory recovery;
- local fatigue.

GI and No-Gi are calibrated separately. No numeric parameter becomes empirical truth before F3 calibration.

## 3D to pixel art

The target production chain is:

```text
rights-cleared reviewed motion
  -> normalized paired skeleton/contact topology
  -> canonical camera/key poses
  -> Ruan/Davi identity lock
  -> Sprite Forge V2 coherent strip
  -> shared scale/pivot/contact normalization
  -> paired preview
  -> Godot integration
  -> visual evidence
  -> human approval
```

This preserves the hand-authored pixel-art identity while benefiting from real movement measurement.

## Quality gates

Motion Lab infrastructure must fail when:

- shipping is claimed by research metadata;
- public URL is treated as permission;
- noncommercial data is allowed into commercial training/derivation;
- own capture omits releases or recording rights;
- gold multiview capture is defined below four cameras;
- canonical six phases diverge;
- hidden contacts are treated as facts;
- contact continuity is inferred from edge presence;
- model output is allowed to define rules or combat state;
- raw media is committed into the research metadata tree;
- tool/source/version provenance is missing from final evidence.

## Current state

At V1 infrastructure creation, the source ledger remains intentionally empty. No claim is made that CRIA has already ingested or learned from thousands of fight videos.

The next real evidence milestone is a rights-cleared pilot capture for the Gold Slice techniques, beginning with the Ruan/Davi double-leg → half guard → body-lock pass chain and its sprawl/knee-shield branches.
