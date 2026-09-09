# CRIA COMBAT INTELLIGENCE OS v1

**Status:** ACTIVE AUTHORING / RESEARCH ARCHITECTURE  
**Runtime authority:** Godot + deterministic BJJ reducer  
**Shipping:** false by design

## 1. Objective

CRIA DO TATAME needs a combat architecture that can represent real grappling logic while remaining playable on Android and visually expressible through premium 2D pixel art.

The target is not to reproduce a proprietary MMA game's code. The target is to adopt useful high-level design lessons from modern combat games — fighter-specific movement identity, contextual advantage, readable timing, responsive contact and style-driven momentum — and rebuild them around BJJ, wrestling and submission grappling.

The combat simulation must remain renderer-independent. A pixel-art client and a future 3D client should be able to consume the same authoritative fight state.

## 2. Current foundation

The current `BJJGraphReducerV2` already provides a strong deterministic spine:

- seeded resolution;
- position/role filtering;
- rules engine integration;
- timing-aware counters;
- gas cost;
- pending score and stabilization;
- deterministic log/replay semantics.

`BJJUtilityScorerV2` adds a first tactical layer using authoring prior, points, position value, counter count, gas and nemesis bias.

Combat Intelligence OS does not delete these systems. It defines the enriched state and evidence required to evolve them safely.

## 3. State architecture

### 3.1 Contest state

The match itself has state independent of body pose:

- ruleset;
- match phase;
- phase clock;
- scoring phase;
- score;
- penalties/negative points;
- mat zone;
- boundary/restart context;
- pending scoring event.

This is essential for ADCC. A technically identical guard pull or takedown attempt has different strategic meaning depending on whether positive points are active.

### 3.2 Athlete state

Each athlete has a grappling state beyond `gas` and `grip`:

- posture and base;
- support points;
- center-of-mass projection estimate;
- head, shoulder and hip orientation;
- inside position;
- frames/wedges;
- grips and ties;
- underhooks/overhooks;
- leg-entanglement topology;
- knee-line/heel exposure;
- off-balance;
- pressure direction;
- mobility freedom;
- pinned segments;
- submission danger;
- energy, isometric load and local fatigue;
- decision confidence.

These dimensions do not all need to be continuously simulated as rigid-body physics. They are structured game state that can be discrete, continuous or unknown.

### 3.3 Interaction/contact graph

Grappling is fundamentally relational. The important state is often the connection between bodies.

Represent contacts as graph edges:

```text
hand → wrist     = grip/tie
forearm → neck   = frame/head control
knee → torso     = wedge
foot → hip       = hook/frame
chest → torso    = pressure contact
leg → leg        = entanglement
hand/foot → mat  = post/support
```

Edges carry type, strength/quality, phase and confidence.

This graph gives us one language for simulation, video annotation and paired animation QA.

## 4. Technique as a causal graph transition

A technique is not `animation_name`.

Every technique should eventually contain:

1. source and destination positions;
2. attacker/defender role;
3. rules legality by context;
4. prerequisites;
5. setup/entry cues;
6. required contact graph;
7. body alignment;
8. weight shift;
9. force direction;
10. attacker objective;
11. likely defender branches;
12. counter links;
13. success topology;
14. failure topology;
15. score/stabilization semantics;
16. energy and isometric cost;
17. risk profile;
18. paired animation phases;
19. recovery state.

This lets the same `double_leg` behave differently when head position, inside tie, boundary and opponent reaction differ.

## 5. Six-phase animation binding

The canonical phases remain:

```text
anticipation
→ entry
→ establish
→ stabilize
→ response
→ recovery
```

Simulation resolves the branch. Animation visualizes it.

A pass does not score because a sprite reached a final frame. It scores only if the rules engine and stabilization state say it scored.

Conversely, the renderer may shorten/cancel a visual sequence when the reducer resolves a counter. It must not wait for a decorative animation to finish before acknowledging the state change.

## 6. Fighter identity: CRIA Rhythm

Modern combat games demonstrate that athlete identity is more convincing when expressed through movement and preferred decisions rather than ratings alone.

CRIA generalizes that principle for grappling.

A fighter profile should encode preferred:

- tie system;
- takedown family;
- guard family;
- pass family;
- pressure/scramble balance;
- submission family;
- pace;
- risk tolerance;
- counter tendency;
- late-match behavior.

`Cria Rhythm` is a style-coherence system. It can reward a player for executing the fighter's coherent game plan, but it cannot provide supernatural bonuses, invalidate a legitimate defense or make an illegal technique legal.

## 7. Tactical AI

Recommended runtime planning stack:

```text
rules filter
  ↓
macro statechart
  ↓
utility ranking
  ↓
short-horizon chain search
  ↓
fighter identity bias
  ↓
action proposal
  ↓
deterministic reducer
```

### Utility dimensions

Move beyond the current coarse score with:

- point value under current rules/time;
- destination positional value;
- finish probability;
- opponent escape/counter exposure;
- gas/isometric cost;
- boundary risk;
- score-clock urgency;
- opponent observed tendencies;
- style fit;
- continuation/chain value;
- emergency escape value.

### Offline learning

Self-play/RL can be useful to calibrate policies and discover degenerate loops. It must operate behind rules constraints and feed candidate tuning back into versioned data. The trained policy is not the rules engine.

## 8. ADCC first-class support

ADCC-style matches need more than a point table.

The engine must model:

- initial no-positive-points period;
- positive/negative point period;
- overtime;
- negative points and passivity/disengagement logic;
- boundary restart preserving established position/grips where applicable;
- 3-second establishment concepts where rules require them;
- strategy changes around the scoring-phase transition.

This means AI should legitimately behave differently at 4:50 than at 5:10 in a 10-minute qualifying match.

## 9. Evidence-first video system

### 9.1 Why video is useful

Large fight/instructional corpora can support:

- technique and chain frequency;
- phase timing;
- common counters;
- position transition statistics;
- athlete tactical tendencies;
- key-pose references;
- animation review;
- score-clock behavior.

### 9.2 Why video is not enough

Close-contact grappling is a difficult computer-vision domain:

- bodies overlap heavily;
- grips disappear behind torsos;
- limbs are occluded;
- jersey/rashguard textures change;
- camera angles vary;
- action classes can look visually similar.

Therefore a single broadcast camera cannot be the final authority for hidden grip state, joint torque or safe submission end range.

### 9.3 Processing stack

Recommended modular stack:

```text
source ledger
→ FFmpeg
→ PySceneDetect
→ Whisper when speech matters
→ SAM2 masks/tracks
→ MediaPipe or MMPose/RTMPose
→ Pose2Sim for controlled multiview
→ MMAction2 / V-JEPA2 / InternVideo3
→ structured observation JSON
→ BJJ expert review
→ rules review
→ DuckDB/Parquet + vector index
```

No individual model is required. They are interchangeable analysis adapters.

## 10. Current research findings

### High-value computer vision

- **SAM 2** — video segmentation/tracking, valuable for keeping athlete identity through partial occlusion.
- **MMPose / RTMPose** — flexible pose-estimation toolbox; checkpoint/dataset licensing must be audited separately.
- **MediaPipe** — lightweight local pose baseline.
- **Pose2Sim** — strong candidate for controlled multi-camera sports kinematics.
- **MMAction2** — action recognition and temporal localization.
- **V-JEPA 2/2.1** — self-supervised motion/video representation research.
- **InternVideo3** — long-video understanding and semantic indexing research.

### Grappling-specific evidence

- **ViCoS BJJ Positions Dataset** is directly relevant to BJJ position/keypoint detection but is noncommercial under CC BY-NC-SA 4.0. Treat as benchmark/research only.
- **Open FSW 2026** studies freestyle wrestling action recognition under mutual occlusion and provides seven action classes. Repository code/data packaging declares MIT, but underlying broadcast clip rights require separate review.
- Small Hugging Face BJJ datasets can inform annotation schema but are currently insufficient for serious calibration if sample counts remain tiny.

### Simulation/calibration

- **MuJoCo** can test offline contact/kinematic hypotheses; not intended as CRIA runtime.
- **PettingZoo / Godot RL Agents** can support constrained self-play research.
- **LimboAI / StateCharts / Utility AI** are architecture candidates for macro AI, subject to engine/version and license pinning.

## 11. Own capture is the commercial gold standard

The best route to animation fidelity and clean rights is to record our own grappling reference corpus.

Suggested capture unit:

- 4–8 synchronized cameras;
- calibrated mat dimensions;
- two trained consenting athletes;
- clean high-contrast wardrobe;
- scripted technique/counter pairs;
- normal and controlled speed;
- failure branches;
- clear safety/tap protocol;
- signed rights/releases;
- immutable source hashes.

This creates data we are actually allowed to use for commercial training, animation reference and QA.

## 12. Visual renderer strategy

The game remains premium pixel art.

That does not mean combat simulation should be simplified to sprite logic.

Use the enriched state to drive:

- paired character sprites;
- contact-aware phase transitions;
- feet/knee/elbow posts;
- pressure and direction cues;
- sweat/impact as separate FX;
- camera framing;
- HUD feedback;
- audio/fabric/mat contact events.

Sprite Forge V2 remains the visual manufacturing authority.

## 13. Engine lifecycle

The audited current stable Godot line is newer than the project's current CI/runtime probe.

Migration to `4.7.2-stable` is planned separately in `data/production/godot_migration_plan_v1.json`.

Do not combine an engine migration with a major combat architecture change. First lock Combat Intelligence contracts and tests; then migrate the engine under its own regression evidence.

## 14. Quality gates

Minimum future combat gates:

- zero illegal actions;
- zero impossible source-position transitions;
- deterministic replay equality;
- score/rules parity;
- paired phase/contact continuity;
- visual endpoint matches resulting state;
- input-to-state latency budget;
- no single optimal universal fighter policy;
- fighter-specific policy diversity;
- calibration error report;
- high-occlusion video holdout report;
- expert disagreement ledger;
- Android frame/CPU budget;
- physical-device proof before release.

## 15. What is deliberately not claimed

This architecture does **not** claim:

- that thousands of videos have already been processed;
- that the full 40/120/10 BJJ graph exists;
- that ML can replace a BJJ expert;
- that any external dataset is automatically commercially usable;
- that motion inferred from a broadcast angle is production-grade mocap;
- that Godot 4.7.2 has already been migrated into the game.

It creates the system required to do those tasks transparently and reproducibly.
