# GOLD SLICE PROFESSIONAL V1

**Status:** ACTIVE EXECUTION PLAN  
**Scope:** Ruan × Davi + Terreiro da Luta + Arena do Dique + Android físico.  
**Machine contract:** `data/production/gold_slice_professional_v1.json`.

## Product thesis

The immediate production target is deliberately narrow:

> One exceptional fight > 120 incomplete techniques.  
> One living Terreiro > 24 concept arenas.  
> One excellent physical APK > dozens of technically interesting branches.

This plan converts that priority into measurable engineering work. It does not change canon and does not create a second runtime.

## 1. Success definition

The gold slice is complete only when the following loop works on a real ARM64 Android device:

```text
Main Menu
→ Terreiro da Luta
→ training / deck
→ pre-fight gameplan
→ Ruan × Davi
→ result
→ Cria Live
→ week advance
→ save
→ application restart
→ Terreiro with persisted state
```

Automatic CI, a generated APK, concept art or a desktop PCK are not substitutes for the physical-device gate.

## 2. Fight: Ruan × Davi

### 2.1 Runtime authority

- `CombatManager` remains scene authority.
- `BJJGraphReducerV2` remains shadow/state-migration authority until parity is proven.
- The rules engine owns legality and scoring.
- Animation, camera, VFX and audio never decide winner, score or legal state.
- No LLM is allowed in the frame-by-frame combat loop.

### 2.2 Gold technique set

Only these seven executable slice techniques are required for the first polished fight:

1. `t001`
2. `slice_sprawl`
3. `t005`
4. `t025`
5. `t049`
6. `slice_side_to_mount`
7. `t057`

Every technique must eventually have:

- authoritative from/to states;
- paired attacker/defender animation;
- six motion phases;
- contact/sync map;
- sound event;
- feedback profile;
- readable telegraph when counterable;
- fallback presentation;
- rights/provenance;
- human BJJ review;
- Godot runtime evidence.

### 2.3 Input

All player action paths resolve through the same action handler:

- touch;
- mouse;
- keyboard 1–6.

Touch counter windows cannot fall below 250 ms.

The CPU difficulty model may change:

- reaction delay;
- pattern-reading strength;
- decision pool;
- error margin.

It may not silently buff health, gas, scoring, legality or technique power.

### 2.4 Feedback budget

The game should visually acknowledge a valid input immediately, before the long-form technique animation resolves.

Feedback layers, in order:

1. card/button response;
2. telegraph/counter state;
3. animation anticipation;
4. contact;
5. sound;
6. small camera response;
7. positional/HUD update;
8. result message.

Hit-stop and shake are presentation-only and must obey reduced-motion settings.

### 2.5 Camera

Do not add a camera plugin until the Godot-version gate allows it.

For Godot 4.3, use the built-in camera path and the existing `GameFeelManager`.

Required shots:

- stable two-fighter neutral framing;
- modest takedown emphasis;
- ground framing that keeps both bodies visible;
- submission tension framing;
- finish/winner hold.

No camera behavior may make the touch UI move unpredictably.

## 3. Terreiro da Luta

The Terreiro must become a place rather than a menu.

### 3.1 Minimum living-world behavior

The scene must react to:

- time block;
- weather;
- active world events;
- present NPCs;
- current recommendation;
- energy;
- week/day;
- story progress.

The deterministic world director remains the source.

### 3.2 Presentation layers

The P1 Terreiro package should eventually contain:

```text
L0 far environment
L1 architecture
L2 tatame/training floor
L3 interactable props
L4 NPCs
L5 ambient life
L6 foreground
L7 weather
L8 UI
```

The first runtime upgrade may use placeholders, but final approval requires the layered world package defined by the P1 visual contract.

### 3.3 NPC behavior

At minimum:

- Mestre Dendê follows his existing routine;
- Tinker appears only when his schedule/weather state places him in the Terreiro;
- interaction copy changes with current activity;
- unavailable NPCs must not be presented as physically present.

No remote AI is required for this behavior.

### 3.4 Environmental identity

Priority ambience for P1:

- cloth/gi movement;
- mat foot movement;
- distant street/river life;
- birds/insects appropriate to weather/time;
- rain on roof when applicable;
- low crowd/training murmur;
- subtle regional music bed.

Audio must be original or licensed and pass the existing rights gate.

## 4. Visual production

### 4.1 Character order

1. Ruan identity master
2. Davi identity master
3. idle/guard/locomotion
4. ground bases
5. paired technique packages
6. portraits/emotes

Do not start full-roster action-sheet production before the two identity masters pass.

### 4.2 Pixel workflow

Preferred authoring chain:

```text
reference / generated candidate
→ Pixelorama
→ anatomical cleanup
→ palette cleanup
→ frame/pivot alignment
→ Sprite Forge QA
→ human approval
→ Godot import
→ runtime capture
```

LibreSprite may be used as an optional pixel editor, not as a runtime dependency.

### 4.3 Generative workflow

ComfyUI + Qwen Image / Pixel-Art LoRA remain external candidate generators only.

Generation does not equal:

- rights approval;
- identity approval;
- BJJ correctness;
- runtime readiness;
- shipping.

## 5. Audio

The current synthetic tone fallback is useful for tests but is not final production audio.

P1 audio target:

- button confirm/cancel;
- grip;
- gi/rash friction;
- foot shuffle;
- mat impact;
- sprawl impact;
- pass pressure;
- mount settle;
- submission tension;
- breathing tiers;
- Dique ambience;
- Terreiro ambience;
- crowd low/medium reaction;
- win/lose cues;
- one Terreiro music bed;
- one fight music bed.

Master/edit in Audacity; music authoring may use LMMS. Runtime is still Godot AudioServer/AudioManager.

## 6. Testing

### 6.1 Existing suite

Keep all current repository smokes.

### 6.2 Unit-test pilot

GUT 9.4.0 is the compatible pilot target for Godot 4.3–4.4.

Pilot only on pure components first:

- utility selection;
- game-feel profile lookup;
- Terreiro presentation composer;
- rules helper;
- route helper.

Do not rewrite the existing smoke suite around GUT.

### 6.3 Visual regression

Gold-slice screenshot checkpoints:

1. Terreiro morning
2. Terreiro rain
3. pre-fight
4. standing neutral
5. takedown
6. half guard
7. side control
8. mount
9. submission
10. result
11. Cria Live
12. post-restart Terreiro

Each capture must record viewport, device/class and build SHA.

## 7. Android physical certification

Package:

`com.criadotatame.pressao`

ABI:

`arm64-v8a`

Target:

- 60 FPS;
- sustained minimum 45 FPS on the accepted low-end test class;
- no severe thermal state;
- no fatal logcat;
- touch remains usable;
- save survives process death/restart.

The repository probe collects machine evidence, but a human still certifies:

- touch comfort;
- text readability;
- safe area;
- fight readability;
- no impossible actions;
- no UI overlap;
- perceived stutter;
- audio balance.

## 8. Performance workflow

Use tools in this order:

1. Godot profiler and monitor;
2. Android `dumpsys gfxinfo` / memory / battery;
3. Android GPU Inspector if GPU diagnosis is needed;
4. RenderDoc for a specific render-frame defect;
5. only then optimize shaders/assets.

Optimization must target measured bottlenecks.

## 9. Tool adoption policy

### Adopt now

- Pixelorama 1.2.3 — primary manual pixel authoring/cleanup.
- Android GPU Inspector — physical Android GPU investigation.
- RenderDoc — targeted frame debugging.
- Audacity — SFX/foley editing.
- LMMS — music authoring.

### Pilot

- GUT 9.4.0 — unit tests for selected pure Godot components.
- Keychain — only after the current touch/keyboard baseline is locked.

### Defer

- Phantom Camera — current published plugin baseline requires a newer Godot line than the production 4.3 baseline; reconsider in the engine-upgrade branch.
- Godot RL Agents — F4 only, after deterministic parity.
- MMPose/MMAction2 — F3 research/calibration only.

## 10. Merge order

The safe integration order from the current Build-All base is:

1. resolve Full Game Hardening blockers;
2. port the proven Aether-inspired input/pacing changes;
3. integrate Graphic System Master as production authority;
4. make Terreiro presentation state-driven;
5. make game feel data-driven and accessibility-aware;
6. add physical Android evidence tooling;
7. run complete CI;
8. produce P1 identity/art/audio;
9. run physical-device certification.

## 11. Non-goals

This slice does not need:

- 120 final technique packages;
- 24 finished arenas;
- full roster;
- remote AI;
- multiplayer;
- Godot version migration;
- F3/F4;
- expansion regions.

Those are blocked behind a successful gold slice.

## 12. Exit gate

This plan may be marked complete only when:

- CI is fully green;
- the Ruan × Davi loop is playable end-to-end;
- Terreiro visibly reacts to world state;
- P1 visual/audio package is approved;
- physical Android evidence exists;
- save/restart passes;
- release claims remain calibrated to actual evidence.
