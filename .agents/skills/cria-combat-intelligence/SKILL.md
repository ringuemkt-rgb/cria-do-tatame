---
name: cria-combat-intelligence
description: Use for CRIA DO TATAME grappling simulation, BJJ/NO-GI/ADCC combat design, fighter identity, tactical AI, video evidence research, paired motion semantics, calibration and combat QA. Rules and deterministic simulation remain authoritative; ML/video/LLMs are evidence and authoring aids only.
---

# CRIA Combat Intelligence OS v1

## Mission

Build a combat system where the player is doing grappling rather than selecting canned grappling animations.

The system must make Brazilian Jiu-Jitsu, submission grappling, wrestling and NO-GI/ADCC exchanges readable, responsive, tactically deep and rules-correct while remaining compatible with CRIA's 2D premium pixel-art renderer.

The simulation must be rich enough that a future 3D or hybrid renderer could visualize the same fight state without rewriting gameplay rules.

## Authority order

1. `data/combat/bjj_rulesets_verified_v1.json` — legality/scoring authority.
2. `data/combat/bjj_completion_gate_v1.json` — full BJJ completion authority.
3. authoritative BJJ graph/reducer sources.
4. `data/combat/combat_intelligence_contract_v1.json` — enriched authoring/calibration semantics.
5. fighter/canon data.
6. `data/research/grappling_video_corpus_contract_v1.json` — evidence intake policy.
7. accepted expert-reviewed observations.
8. ML/video output.
9. this skill.

Never let a model, video classifier, animation or LLM override items 1–5.

## Core separation

```text
INPUT
  ↓
INTENT / CONTROL MAPPING
  ↓
DETERMINISTIC COMBAT SIMULATION  ← sole state authority
  ↓
RULES / SCORE / CLOCK
  ↓
TACTICAL AI + FIGHTER IDENTITY   ← proposes actions only
  ↓
AUTHORITATIVE RESULTING STATE
  ↓
ANIMATION BINDING / AUDIO / CAMERA / HUD
```

Render state is not combat state.

Animation playback cannot grant a sweep, pass, takedown, score or submission. It visualizes a transition already accepted by the simulation.

## Why the existing reducer stays

`BJJGraphReducerV2` already gives CRIA valuable properties:

- seeded determinism;
- position/role legality;
- gas costs;
- rules filtering;
- counter timing;
- stabilization before scoring;
- replayable logs.

Do not replace it with a neural network or physics sandbox.

Combat Intelligence v1 enriches the state and planning around the reducer and creates a migration path for a future reducer v3 only after tests prove parity.

## Grappling state model

### Contest state

Track independently from athlete pose:

- ruleset;
- regulation/overtime/finished;
- phase clock;
- positive-scoring phase versus no-positive-points phase;
- mat zone and out-of-bounds restart context;
- score;
- penalties/negative points;
- pending stabilization events.

This is mandatory for ADCC-style strategy because the same technical exchange has different strategic value before and after positive scoring activates.

### Athlete state

Each athlete state should support:

- posture;
- support points and base quality;
- center-of-mass projection estimate;
- hip/shoulder/head orientation;
- inside position;
- frames and wedges;
- grip/tie graph and grip integrity;
- underhook/overhook/head-control state;
- leg-entanglement topology;
- knee-line and heel exposure;
- off-balance/kuzushi;
- pressure direction;
- mobility freedom;
- pinned segments;
- submission-danger components;
- gas;
- isometric load;
- local fatigue;
- decision confidence.

Unknown is a valid state. Never hallucinate an occluded limb or grip into certainty.

### Interaction state

Model the two athletes as a contact graph, not as two independent pose skeletons.

Important edges include:

- grip/tie;
- frame;
- hook;
- post;
- wedge;
- pin;
- head control;
- chest/hip contact;
- leg entanglement;
- mat support.

This graph is the bridge between biomechanics, gameplay and paired animation.

## Technique model

A CRIA technique is a structured causal transition.

Minimum dimensions:

```text
TECHNIQUE
├── from / to
├── attacker/defender roles
├── rules + GI/NO-GI legality
├── preconditions
├── entry cues
├── required grips/ties/connections
├── body alignment
├── weight shift
├── force direction
├── attacker objective
├── defender responses
├── counter branches
├── success topology
├── failure topology
├── energy/isometric cost
├── risk profile
├── score event + stabilization
├── six paired animation phases
└── recovery state
```

A generic prompt such as `perform armbar attack` is never a technique definition.

## Six-phase paired motion contract

Every combat animation remains aligned with the canonical BJJ phases:

1. `anticipation` — setup/intention; cancel or counter opportunity still exists;
2. `entry` — committed level/angle/grip/tie change;
3. `establish` — required contact topology is obtained;
4. `stabilize` — control is made score-valid where rules require it;
5. `response` — defender frame/counter/escape branch resolves;
6. `recovery` — both bodies settle into the authoritative resulting state.

The attacker and defender are one animation system with two visual bodies. Their timelines are not authored independently.

## Real-time grappling contact

Adapt the useful principle of real-time contact systems without cloning proprietary implementation.

For grappling, contact windows mean:

- a grip/tie can become valid over a short timing range rather than one magic frame;
- feet/knees/elbows/posts must coincide with the intended support topology;
- a takedown entry can be redirected if the defender wins head/hip/inside position during the response window;
- animation blending may correct small visual spacing errors but cannot override the state graph;
- major contact mismatch is a QA failure, not something to hide with interpolation.

Prioritize responsive input-to-state timing over longer cinematic clips.

## Fighter identity — CRIA Rhythm

Do not express fighter identity only through ratings.

A fighter identity profile should influence preferred:

- range;
- ties/grips;
- takedown families;
- guard families;
- passing families;
- top-control patterns;
- scramble frequency;
- submission families;
- pace;
- counter tendency;
- risk tolerance;
- late-match strategy.

`Cria Rhythm` rewards coherent execution of the fighter's game plan. It may affect confidence, transition efficiency or planning priority, but never legality or guaranteed outcomes.

Examples:

- Ruan: pressure, grip/control, top-game, progressive positional consolidation;
- Davi: timing, counter, scramble, redirecting overcommitment.

Two fighters with similar numeric technique values should still make different decisions.

## Tactical AI stack

Use a hybrid architecture:

### Layer 0 — hard rules

Filter impossible/illegal actions first.

### Layer 1 — statechart

Manage match phase and tactical macro-state:

- neutral standing;
- grip/tie battle;
- takedown exchange;
- guard engagement;
- passing/control;
- scramble;
- submission offense/defense;
- boundary restart;
- late-score strategy.

### Layer 2 — utility planner

Score legal candidates using:

- expected position value;
- scoring value under current clock phase;
- finish opportunity;
- counter exposure;
- energy and isometric cost;
- boundary risk;
- opponent tendencies;
- fighter-style fit;
- chain continuation value;
- escape urgency.

### Layer 3 — short-horizon chain search

Evaluate likely action→counter→continuation branches rather than one move at a time.

### Layer 4 — optional offline learning

RL/self-play or behavior cloning may help calibrate policies offline. It never becomes rules authority and must pass deterministic evaluation before use.

### LLM boundary

LLMs are acceptable for:

- annotation assistance;
- research-query generation;
- coach/commentary drafts;
- living-world dialogue.

Never put an LLM in the frame-by-frame inner combat loop.

## Evidence-first video laboratory

Do not claim that CRIA has learned from a video until that video exists in the source ledger and its derived observations have passed the review contract.

Pipeline:

```text
RIGHTS LEDGER
  ↓
FFmpeg normalization
  ↓
scene/round/exchange segmentation
  ↓
optional Whisper transcript
  ↓
SAM2 athlete masks
  ↓
MediaPipe / MMPose-RTMPose pose candidates
  ↓
Pose2Sim for controlled multiview captures
  ↓
MMAction2 / V-JEPA / InternVideo temporal evidence
  ↓
structured grappling observation
  ↓
expert BJJ + rules review
  ↓
DuckDB/Parquet + vector index
  ↓
calibration + key-pose reference
```

### What competition video is good for

- technique frequency;
- preferred chains;
- tactical score/time decisions;
- entry timing;
- common counters;
- match rhythm;
- broad phase duration;
- visual/camera reference.

### What single-view broadcast video is bad for

- exact hidden grips;
- exact occluded limb orientation;
- exact joint torque;
- submission safety thresholds;
- production-quality 3D reconstruction during heavy entanglement.

Never convert low-confidence inference into a fact.

## Own motion-capture studio

For final movement fidelity, prefer CRIA-owned recordings.

Recommended session:

- 4–8 synchronized camera/phone views;
- calibrated mat scale and camera intrinsics/extrinsics;
- two consenting trained athletes;
- unbranded high-contrast rashguards or approved GI;
- technique script derived from the authoritative graph;
- normal-speed repetition;
- controlled-speed repetition;
- common counter branch;
- common failure branch;
- explicit tap/safety protocol;
- athlete and footage releases.

Record clean key states for setup, entry, contact, establishment, defense and recovery.

For multi-view reconstruction use Pose2Sim/RTMPose or another audited stack as research tooling. Keep original video and calibration files immutable and hashed.

## Dataset policy

Research datasets can be very useful without being shippable.

Examples:

- ViCoS BJJ positions: benchmark/research only under its current noncommercial CC BY-NC-SA terms;
- Open FSW wrestling dataset: valuable close-contact action-recognition benchmark, but underlying media rights must be reviewed independently from repository code license;
- tiny/incomplete BJJ datasets: schema inspiration only, never evidence of model readiness.

Training rights, code license, checkpoint license and source-media rights are four separate fields.

## Visual production bridge

Combat Intelligence produces movement/reference metadata; Sprite Forge V2 produces the visual candidate.

For pixel art:

1. lock both character identities;
2. select accepted starting paired pose;
3. author/generate the whole phase strip or coherent blocks, not isolated frames;
4. normalize shared scale/pivot/contact space;
5. validate content bounds and contact continuity;
6. compare phase endpoints to combat state;
7. run paired preview;
8. integrate in Godot only after rights/human review.

The primary shipping renderer remains premium 2D pixel art. The simulation must not encode pixel-art assumptions so a future 3D/hybrid representation remains possible.

## Rules profiles

Support multiple rules profiles through adapters, not conditionals scattered through animation code.

At minimum:

- IBJJF GI;
- IBJJF NO-GI where relevant;
- ADCC World-style professional rules;
- ADCC Trials/Open variants;
- fictional CRIA clandestine rules only where canon explicitly defines them.

ADCC needs first-class concepts for:

- no-positive-points phase;
- positive/negative scoring phase;
- overtime;
- negative points;
- out-of-bounds restart while preserving established grips/position;
- tactical behavior changing with clock phase.

## Validation metrics

Combat quality cannot be measured only by win rate.

Track:

- illegal action rate = 0;
- impossible source-position transitions = 0;
- deterministic replay mismatch = 0;
- score/rules mismatch = 0;
- paired contact mismatch rate;
- animation endpoint/state mismatch rate;
- input-to-state latency;
- policy diversity by fighter;
- action entropy without random nonsense;
- calibration error for empirical probabilities;
- expert agreement/disagreement;
- video model confusion by position/technique;
- performance on high-occlusion holdout;
- CPU/frame budget on target Android.

## Fail-closed gates

Do not claim complete combat until:

- full 40/120/10 authoritative BJJ source is present;
- rule adapters are tested;
- paired animations exist for required transitions;
- F3 empirical calibration is complete;
- F4 balance is complete;
- expert biomechanical review is recorded;
- deterministic replays pass;
- visual runtime QA passes;
- physical Android evidence passes.

## Engine migration

Current project/CI versions are below the current supported Godot line. Do not upgrade `main` as part of unrelated combat work.

Follow `data/production/godot_migration_plan_v1.json` on a dedicated migration branch, maintaining a dual-version evidence window until runtime/import/export tests are green.

## Commands

```bash
python tools/combat/validate_combat_intelligence_v1.py
python -m unittest discover -s tests -p 'test_combat_intelligence_v1.py'
npm run quality
```

## Definition of success

The system is successful when a knowledgeable grappler can explain *why* a transition was available, *what contact/base/angle made it work*, *what counter window existed*, *why the rules scored or did not score it*, and the paired animation visibly tells the same story.
