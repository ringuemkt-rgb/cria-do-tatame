# CRIA Grappling Engine V2

**Version:** 2.0.0  
**Scope:** gi + no-gi grappling runtime shadow, paired-motion selection and offline motion production  
**Combat authority:** `BJJGraphReducerV2`  
**Runtime target:** Godot 4.3+, Android ARM64 / Windows  
**Heavy ML / physics at runtime:** **no**

## 1. Objective

The objective is not to imitate the rendering technology of a 3D MMA title inside a 2D game. The objective is to reproduce the qualities that matter to grappling:

- continuous body-to-body contact;
- correct attacker/defender synchronization;
- visible grip differences between gi and no-gi;
- varied reactions to the same attack;
- fewer canned transitions;
- fatigue-aware presentation;
- stable pivots and contact points;
- responsive input;
- deterministic replays;
- mobile performance.

The architecture therefore separates **combat truth** from **motion presentation**.

```text
PLAYER INPUT / AI ACTION
          │
          ▼
 BJJGraphReducerV2  ← rules, scoring, legality, RNG
          │
          ├──────── authoritative outcome
          │
          ▼
 CriaGrapplingEngineV2
          │
          ├─ Grip Graph (explicit events only)
          ├─ Microstate projection
          ├─ Reaction ranking
          └─ Motion matching
                    │
                    ▼
            paired sprite clip
                    │
                    ▼
            paired sync timeline
                    │
                    ▼
             Godot presentation
```

The renderer never becomes the referee.

---

## 2. Existing systems preserved

V2 deliberately builds on the repository's existing authorities:

- `src/combat/BJJGraphReducerV2.gd` — deterministic combat state;
- `src/combat/BJJRulesEngineV1.gd` — rules and legality;
- `src/combat/BJJTimingPolicyV1.gd` — defense timing;
- `src/combat/CriaGrapplingRuntimeV1.gd` — current runtime façade;
- `src/combat/GrapplingPhysicalStateV1.gd` — reviewed physical evidence;
- `src/combat/GrapplingConnectionGraphV1.gd` — contact representation;
- `src/animation/BJJMotionBindingV1.gd` — approved motion requirement mapping;
- `data/research/grappling_motion_lab_contract_v1.json` — capture and review pipeline;
- `data/production/motion_factory_v1.json` — offline motion fabrication;
- `data/visual/visual_foundry_profile_v1.json` — 3D→sprite manufacturing;
- Sprite Forge V2 — final pixel asset normalization/QA.

V2 is a new layer, not a competing game engine.

---

## 3. Authority firewall

The following invariants are non-negotiable:

- grip shadow state does not change score;
- motion selection does not change score;
- visual reaction selection does not execute a defense;
- animation cannot change winner;
- animation cannot change RNG;
- generated motion cannot create a legal technique;
- hidden grips are not invented;
- unreviewed contact remains `UNKNOWN`;
- noncommercial research data cannot become a shipping asset;
- the same reducer input/seed must produce the same combat result regardless of which visual clip is selected.

Contract:

```text
data/combat/grappling_engine_v2_contract.json
```

---

## 4. Gi vs no-gi

Gi and no-gi are not treated as a costume toggle.

### 4.1 Shared body-control surfaces

Both modalities can use direct controls such as:

- wrist;
- forearm;
- triceps / upper arm;
- head / neck;
- underhook;
- overhook;
- waist / torso;
- hip;
- thigh / knee;
- shin / ankle.

### 4.2 Gi-only surfaces

Gi adds garment topology:

- collar left/right;
- lapel left/right;
- sleeve left/right;
- belt;
- pants hip/knee/ankle surfaces.

The runtime grip topology lives in:

```text
data/combat/grip_topology_v1.json
src/combat/GrapplingGripGraphV1.gd
```

Rules:

- one active grip per hand;
- maximum two hand grips per athlete;
- establishing a new grip with a hand replaces that hand's previous grip;
- gi-only grips fail closed in no-gi;
- grip integrity is a normalized gameplay/presentation value, not a claim of measured Newtons;
- only explicit gameplay events may establish runtime grips.

This means a no-gi fighter cannot silently acquire a sleeve/collar grip because an animation happens to look similar.

---

## 5. Microstates

Traditional fighting games often map one technique to one animation. Grappling needs a denser representation.

`GrapplingMicroStateV1` projects a small presentation state from authoritative combat data plus explicit/reviewed interaction information.

Current axes:

- position;
- top / bottom / neutral role;
- gi / no-gi;
- six-phase motion stage;
- gas bucket;
- athlete grip signature;
- opponent grip signature;
- reviewed contact signature;
- selected reaction;
- previous motion clip.

Example conceptual states:

```text
side_control
+ bottom athlete
+ no-gi
+ response phase
+ fatigued
+ opponent has underhook/body-lock signature
+ reviewed chest/hip contact
→ frame_hip_escape family
```

This makes a position visually variable without changing its authoritative BJJ state.

---

## 6. Reaction engine

`GrapplingReactionSelectorV1` ranks visual/reaction intents.

It currently knows families such as:

- sprawl;
- whizzer balance;
- pummel for inside position;
- posture recovery;
- hip-escape frame;
- bridge to create space;
- elbow-knee connection;
- back-control hand fight;
- gi grip-break posture;
- no-gi wrist peel/head position;
- technical-standup spacing.

Inputs include:

- attack type;
- current position;
- top/bottom role;
- modality;
- explicit grip signature;
- fatigue bucket.

Outputs are ranked deterministic hints only.

The existing combat intelligence remains responsible for choosing actual game actions.

---

## 7. Sprite motion matching

The repository does **not** ship a 3D motion-matching native plugin.

Instead, `GrapplingMotionMatcherV1` applies motion-matching principles to a compact database of **paired 2D sprite clips**.

### Query features

- technique ID;
- attack type;
- position;
- role;
- gi/no-gi;
- phase;
- reaction ID;
- gas bucket;
- own grip signature;
- opponent grip signature;
- expert-reviewed connection signature;
- previous clip continuity.

### Why this is appropriate for mobile

Runtime selection is a small deterministic weighted search:

```text
query
  ×
compact clip metadata
  ↓
minimum cost
  ↓
paired sprite clip
```

There is:

- no GPU model inference;
- no neural network dependency;
- no runtime humanoid simulation;
- no native motion-matching extension requirement;
- no raw 3D mocap database loaded on Android.

The expensive intelligence happens offline.

Profile:

```text
data/animation/grappling_motion_matching_profile_v1.json
```

---

## 8. Reviewed contact signature

Contact is weighted heavily during motion selection.

A clip with visually incompatible body contact should not win simply because its technique label matches.

Only contacts promoted through the existing physical-evidence path are used as reviewed contact signatures:

```text
capture / authored evidence
→ expert review
→ GrapplingPhysicalStateV1
→ reviewed_connection_signature
→ motion matching
```

Unobserved contact remains an empty/unknown signature.

---

## 9. Paired timeline

Every body-contact grappling animation is treated as one paired product.

Schema:

```text
assets/schemas/grappling_sync_map_v1.schema.json
```

Runtime:

```text
src/animation/GrapplingPairedTimelineV1.gd
```

A sync map contains:

- total duration;
- attacker frame count;
- defender frame count;
- phase spans;
- time-domain sync points;
- contact signatures at reviewed sync points;
- shared pair pivot.

The runtime samples both streams from the same clock.

This prevents a common failure where attacker frame 8 reaches the leg while defender frame 8 has already teleported into the landing pose.

---

## 10. Motion database

Schema for each compiled variant:

```text
assets/schemas/grappling_motion_variant_v1.schema.json
```

Offline compiler:

```bash
python tools/motion_factory/compile_grappling_motion_db_v1.py
```

Runtime loader:

```text
src/animation/GrapplingMotionDBV1.gd
```

The compiler promotes a clip into the shipping database only if all of these are true:

```text
rights_status = COMMERCIAL_DERIVATION_ALLOWED
human_approval = true
asset_status = APPROVED_FINAL
shipping = true
```

Research-only assets therefore cannot accidentally leak into the game database.

The runtime loader repeats this check defensively.

---

## 11. Offline research and physics laboratory

The systems discovered during research are used as **offline engineering references or candidates**, not runtime dependencies.

Registry:

```text
data/research/grappling_engine_research_registry_v1.json
```

### InterAgent

Useful ideas:

- multi-humanoid control;
- interaction graphs;
- relationship-aware control;
- physics-grounded two-agent response.

Potential CRIA use:

```text
paired mocap
→ interaction graph
→ offline policy experiment
→ candidate physical variant
→ expert review
```

### ProtoMotions

Preferred large offline physics-lab candidate for:

- motion imitation;
- physics-based humanoid control;
- generation/testing of failure branches;
- robustness experiments;
- motion-policy benchmarking.

Body-model and simulator asset licenses remain separate gates.

### MimicKit

Useful as a smaller motion-imitation research surface for:

- DeepMimic-style experiments;
- AMP/ASE-style skill priors;
- isolated motion reproduction tests.

### AssistMimic

Valuable architectural reference for continuous human-human force exchange and multi-agent RL, but current CRIA policy blocks code/weights/data reuse until every license/dependency/data layer is cleared.

### Godot motion-matching reference

The public Godot 3D implementation is a useful algorithm reference. CRIA ports the principle, not the dependency, because the game ships pixel art and targets a broader Godot compatibility window.

---

## 12. CRIA-owned grappling dataset

The strongest long-term opportunity is not another generic internet dataset.

It is a rights-cleared CRIA dataset captured specifically for Brazilian Jiu-Jitsu.

### Minimum capture protocol

Existing Motion Lab policy remains authoritative:

- 4–8 synchronized views;
- preferably 6;
- 60 fps standard;
- 120 fps for fast transitions when practical;
- camera calibration;
- mat coordinate system;
- scale reference;
- athlete releases;
- recording rights;
- explicit gi/no-gi label;
- normal-speed repetition;
- controlled-speed repetition;
- defense/counter repetition;
- representative failure branch.

### Dataset dimensions worth capturing

For each high-value technique:

- left/right side;
- gi/no-gi where applicable;
- fresh/fatigued performance style;
- clean success;
- resisted success;
- primary counter;
- failed entry;
- scramble exit;
- common grip families;
- different body-size pairings when safe.

The raw media stays outside Git and is content-addressed through provenance records.

---

## 13. Six-phase production contract

All high-value grappling interactions continue to use:

1. `anticipation`
2. `entry`
3. `establish`
4. `stabilize`
5. `response`
6. `recovery`

This is more useful than treating a double-leg, pass or submission as one opaque clip.

The phases allow:

- better sync;
- defensible contact annotation;
- reaction selection;
- animation interruption policy;
- cleaner Sprite Forge authoring;
- more precise input windows.

---

## 14. Vertical slice production order

Do not expand to the full roster first.

### Fighters

- Ruan Macacão;
- Davi Relâmpago.

### Modes

- gi;
- no-gi.

### Priority interaction families

1. hand fighting → clinch;
2. double/single-leg entry → sprawl or finish;
3. guard-pull branch;
4. closed-guard posture + grip battle;
5. half-guard / knee-cut / body-lock passing family;
6. side-control → mount;
7. mount escape branch;
8. back-control hand fight → mata-leão.

### Variant target

For the highest-value transitions:

- minimum before varied presentation: **3 approved variants**;
- target: **6 approved variants**;
- variation axes should be meaningful, not cosmetic duplicate frames.

---

## 15. Runtime integration example

Conceptual flow:

```gdscript
var result = engine.step(
    engine_state,
    combat_action,
    explicit_grip_events,
    {"phase": "entry"},
    motion_db.all_clips()
)

if result.motion_selection.ok:
    var clip = motion_db.clip(result.motion_selection.clip_id)
    # load the approved attacker/defender sprite streams
    # load clip.sync_map_ref
    # drive both streams from GrapplingPairedTimelineV1
```

The authoritative outcome has already been decided before that visual clip is selected.

---

## 16. Validation

Static contract validation:

```bash
python tools/combat/validate_grappling_engine_v2.py
```

Python tests:

```bash
python -m unittest discover -s tests -p 'test_grappling_engine_v2.py'
```

Godot headless smoke:

```bash
godot --headless --path . --script res://tests/grappling_engine_v2_smoke.gd
```

Global quality gate after package integration:

```bash
npm run quality
```

Dedicated GitHub workflow:

```text
.github/workflows/grappling-engine-v2.yml
```

---

## 17. What V2 intentionally does not claim

V2 does **not** claim that:

- generated motion is biomechanically correct without review;
- a public training video grants asset rights;
- a permissive code license clears model checkpoints or datasets;
- a high-quality motion system alone creates UFC-scale production quality;
- placeholder sprite clips are shipping assets;
- CI green replaces Android device testing.

The engine architecture can be complete while the content library remains under production.

---

## 18. Definition of Done for one gold technique

A technique is gold only when it has:

- canonical BJJ/rules entry;
- approved gi/no-gi availability;
- reviewed source/provenance;
- paired attacker/defender motion;
- reviewed connection/contact data where observable;
- six-phase map;
- shared pivot;
- sync map;
- at least one approved reaction/counter branch when required;
- Sprite Forge pass;
- motion database entry;
- in-engine Godot evidence;
- Android visual/performance evidence;
- human BJJ review;
- human visual approval.

A prompt, generated FBX/GLB, raw spritesheet or green compiler run is not completion.

---

## 19. Long-term opportunities

### Proprietary grappling motion corpus

A commercial-rights-clean BJJ interaction dataset is strategically more valuable than depending on research datasets with unclear or noncommercial terms.

### Physics-assisted variant factory

Use permissive physics frameworks offline to create candidate variations from CRIA-owned capture, then pass those variants through expert/contact QA before pixel compilation.

### Grip-aware style identity

Different fighters can prefer different control signatures without changing the underlying rules engine. This can create recognizable grappling personalities.

### Size and anthropometry variants

A later production layer can tag approved motion variants by coarse body-size pairing so a small-vs-large exchange does not always reuse the same silhouette/contact geometry.

### Telemetry-separated presentation tuning

Log visual clip selection separately from authoritative combat results. Presentation can then be improved without contaminating balance telemetry.

### Active-learning capture queue

Use motion-coverage gaps, high uncertainty, high repetition and frequently selected generic fallbacks to decide what should be captured next.

---

## 20. Architectural summary

```text
                    CRIA GRAPPLING ENGINE V2

          ┌─────────────────────────────────────┐
          │       AUTHORITATIVE GAMEPLAY         │
          │ BJJGraphReducerV2 + Rules + Timing  │
          └──────────────────┬──────────────────┘
                             │ outcome
                             ▼
          ┌─────────────────────────────────────┐
          │          SHADOW INTERACTION          │
          │ Grip Graph + Microstate + Reaction  │
          └──────────────────┬──────────────────┘
                             │ query
                             ▼
          ┌─────────────────────────────────────┐
          │         MOTION MATCHING 2D           │
          │ approved paired clip database       │
          └──────────────────┬──────────────────┘
                             │ clip
                             ▼
          ┌─────────────────────────────────────┐
          │       PAIRED TIMELINE / SPRITES      │
          │ attacker + defender + sync/contact  │
          └──────────────────┬──────────────────┘
                             │
                             ▼
                           GODOT

OFFLINE:
owned multiview capture
→ reconstruction/contact candidates
→ expert review
→ optional physics research
→ paired animation authoring
→ Visual Foundry / Sprite Forge
→ motion DB compiler
→ shipping metadata
```

The design target is a grappling game that feels reactive and physically connected while remaining deterministic, auditable and realistic for Android hardware.
