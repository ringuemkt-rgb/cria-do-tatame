---
name: cria-grappling-motion-lab
description: Use for CRIA DO TATAME grappling motion capture, video corpus intake, pose/contact reconstruction, biomechanical annotation, motion-reference production, dataset QA and handoff into Grappling Runtime and Sprite Forge. Rights, source provenance and expert review are fail-closed.
---

# CRIA Grappling Motion Lab V1

## Mission

Convert lawful, traceable grappling footage into reviewed biomechanical evidence and animation references for CRIA DO TATAME without allowing video, computer vision, motion generation or rendering to redefine the combat simulation.

The primary shipping renderer remains premium 2D pixel art. 3D reconstruction, musculoskeletal analysis and motion generation are offline authoring/QA tools unless a separate game-design decision changes the renderer.

## Authority order

1. `data/combat/bjj_rulesets_verified_v1.json` — legality/scoring.
2. authoritative BJJ graph + `BJJGraphReducerV2` — combat state.
3. `CriaGrapplingRuntimeV1` — reducer-to-physical/motion bridge.
4. reviewed `grappling_physical_bindings_*` — physical/contact evidence.
5. `data/research/grappling_video_corpus_contract_v1.json` — source-rights policy.
6. `data/research/grappling_motion_lab_contract_v1.json` — capture/processing workflow.
7. expert-approved clip observations.
8. pose/action/segmentation model output.
9. generated motion/previsualization.

Never invert this order.

## Non-negotiable rights rule

A public URL is not permission.

Never build an automatic downloader for broadcast fights, subscription instructionals, social-media clips or other third-party footage merely because the media is viewable online.

Before processing a source, create a source-ledger record and classify rights. Training rights, source-media rights, code license, checkpoint license and dataset license are separate questions.

Preferred commercial corpus:

```text
CRIA-owned multiview capture
+ athlete releases
+ recording rights
+ location permission when needed
+ immutable file hashes
+ calibration
+ session QA
```

## Capture standard

Gold capture uses 4–8 synchronized cameras; six is the working default.

Prefer:

- 60 fps minimum for ordinary technique capture;
- 120 fps for fast entries/scrambles when equipment permits;
- fixed focus/exposure when practical;
- crossing camera angles to reduce mutual occlusion;
- full mat/scale reference;
- high-contrast, unbranded or rights-cleared wardrobe;
- explicit GI or No-Gi recording metadata.

Capture each selected technique as:

1. normal competition-speed repetition;
2. controlled instructional-speed repetition;
3. primary defense/counter;
4. representative failure branch.

For submissions, never force end range for visual reference. Stop on pain or discomfort and follow the recorded tap/safety protocol.

## Session calibration

Every gold multiview session needs:

- camera intrinsics;
- camera extrinsics;
- distortion coefficients;
- metric scale reference;
- mat coordinate system;
- synchronization method;
- measured synchronization error;
- calibration bundle hash.

No calibration means no gold 3D biomechanical claim.

## Processing pipeline

```text
M00 rights intake
 ↓
M01 immutable ingest / SHA256
 ↓
M02 FFmpeg normalization
 ↓
M03 synchronization + camera calibration
 ↓
M04 optional athlete segmentation (SAM2)
 ↓
M05 2D pose candidates (RTMPose/MMPose or audited equivalent)
 ↓
M06 multiview 3D reconstruction (Pose2Sim; OpenSim optional)
 ↓
M07 contact candidates
 ↓
M08 six-phase segmentation
 ↓
M09 expert annotation (CVAT or equivalent)
 ↓
M10 biomechanical review
 ↓
M11 rules cross-check
 ↓
M12 version/index (DVC/content hashes + Parquet/DuckDB)
 ↓
M13 authoring/previsualization reference
 ↓
M14 Sprite Forge V2 paired pixel production
 ↓
M15 Godot visual QA + human approval
```

Automation may prelabel. Automation may never final-approve.

## Six-phase evidence

The motion lab uses the same canonical phase vocabulary as the grappling runtime:

1. `anticipation`
2. `entry`
3. `establish`
4. `stabilize`
5. `response`
6. `recovery`

Each reviewed phase stores:

- time/frame span;
- athlete identity confidence;
- pose confidence;
- occlusion status;
- connection edges or explicit `UNKNOWN`;
- contact continuity or explicit `UNKNOWN`;
- review status.

Do not infer perfect contact continuity from the mere presence of a contact edge.

## Occlusion policy

Grappling is a high-occlusion domain. Hidden limbs, grips, hooks and wedges are common.

Rules:

- hidden is not absent;
- hidden is not present;
- model interpolation is not fact;
- a low-confidence grip/contact becomes `UNKNOWN`;
- a single broadcast view is not gold 3D biomechanical authority;
- multiview agreement plus expert review is preferred for animation key states.

Keep uncertainty in the data model. Do not clean it away for prettier datasets.

## Tool policy

Use `data/research/motion_tool_registry_v1.json` for research classification and `data/production/external_tool_registry_v1.json` as the only source-reuse authority.

Preferred candidates currently include Pose2Sim, OpenSim, MMPose/RTMPose, SAM2, CVAT Community, DVC and FiftyOne, subject to exact revision/checkpoint audits before production adoption.

Restricted/research-only examples include noncommercial datasets and motion generators such as ViCoS BJJ, InterGen/InterHuman, CoShMDM, Interact2Ar and the current BlendAnything license.

FreeMoCap is useful research/reference software but its AGPL/commercial-license posture means it is not a default embedded CRIA dependency.

Never assume a permissive repository license covers model weights, training data or example media.

## Biomechanical review

Where observable, annotate:

- support points and base quality;
- projected center of mass;
- hip, shoulder and head orientation;
- inside position;
- frames and wedges;
- underhook/overhook state;
- grip/tie topology;
- off-balance direction;
- pressure vector;
- mobility freedom;
- pinned segments;
- leg-entanglement topology;
- knee-line state;
- heel exposure;
- submission danger.

These are evidence fields, not animation decoration.

## Conditioning evidence

Do not model BJJ with one undifferentiated stamina number forever.

Research and calibrate separately:

- whole-body gas;
- forearm/grip fatigue;
- upper-body isometric load;
- trunk isometric load;
- hip/leg dynamic load;
- respiratory recovery;
- local fatigue.

GI and No-Gi require separate calibration. Until F3, values remain `UNCALIBRATED` tuning candidates.

## Annotation strategy

Use active learning to make large-scale review feasible.

Prioritize clips with:

- high uncertainty;
- high occlusion;
- model disagreement;
- identity switches;
- rare positions/counters;
- gaps in the golden chain;
- high-value shipping techniques.

A target of thousands of clips means thousands of ledger-backed, reviewable units. It does not mean counting unreviewed URLs or raw downloaded videos as knowledge.

## 3D-to-pixel handoff

3D/mocap is a measurement/reference layer.

Recommended handoff:

```text
reviewed multiview motion
→ normalized paired skeleton/contact graph
→ canonical camera render / key-pose sheet
→ character identity lock
→ Sprite Forge V2
→ shared pivot/scale/contact normalization
→ paired preview
→ Godot
```

Do not ship raw mocap or generic generated human motion if it breaks the established pixel-art identity.

## Output requirements

Every motion clip package must be metadata-addressable through `grappling_motion_clip_v1.schema.json` and contain only references/hashes in Git. Raw footage and heavy derived files belong in a controlled data store, not the source repository.

Every final physical binding must be traceable back to:

- source IDs;
- rights classification;
- clip/time spans;
- tool versions;
- expert reviewer;
- rules reviewer;
- phase evidence;
- provenance hashes.

Every final animation must additionally pass Sprite Forge and visual runtime QA.

## Commands

```bash
python tools/combat/validate_grappling_motion_lab_v1.py
python -m unittest discover -s tests -p 'test_grappling_motion_lab_v1.py'
npm run quality
```

## Definition of done

Motion Lab V1 infrastructure is done when contracts, schemas, tool policy, capture template, validators and CI are green.

A technique is not motion-complete until a rights-cleared source package exists, phase/contact evidence is reviewed, the physical binding is approved, the paired animation exists, Sprite Forge passes, Godot visual evidence exists and human review approves it.
