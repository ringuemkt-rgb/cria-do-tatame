# External Game Studio Intake v1

**Status:** ACTIVE research/governance layer  
**Runtime authority:** none  
**Shipping authority:** none

## Purpose

CRIA can learn aggressively from open repositories, model hubs and design benchmarks without turning the game into an uncontrolled dependency bundle or contaminating commercial shipping with unclear licenses.

Every external source enters through:

```text
source
  -> repository/model inspection
  -> immutable revision
  -> license + asset-rights classification
  -> role mapping
  -> ADOPT / PORT / REIMPLEMENT / REFERENCE / BLOCK
  -> CRIA-native tests and contracts
  -> only then implementation
```

The machine-readable authority for this intake is:

`data/production/external_tool_registry_v1.json`

## Triage classes

### ADOPTED_CANDIDATE_GENERATOR
External model/tool may generate offline candidates, but output remains subject to CRIA art direction, provenance, rights, QA, human approval and Godot integration.

Current example: pinned Qwen-Image-2512 Pixel Art LoRA.

### PORT_SELECTED_PATTERNS
License is clear enough for selected code/document patterns to be ported, with attribution where required. CRIA contracts and architecture still win on conflict.

Current example: `Donchitos/Claude-Code-Game-Studios` (MIT).

### REIMPLEMENT_CONCEPTS_ONLY / STUDY_AND_REIMPLEMENT_CONCEPTS_ONLY
Technical ideas may be studied and independently implemented, but source code is not copied. This is required for non-commercial, no-license or otherwise unsuitable sources.

### DESIGN_PATTERN_REFERENCE_ONLY / COMPARATIVE_DESIGN_REFERENCE_ONLY
Visual/interaction benchmark only. No HTML/CSS/JS or assets are copied.

### BLOCKED_DEACTIVATED
Source must not receive new implementation work.

## Highest-value transfers

### 1. Claude Code Game Studios -> CRIA Studio Orchestrator

The audited source provides a professional AI-studio structure with 49 agents, 73 skills, hooks, path-scoped rules, specialist roles and director gates. CRIA should not import the entire `.claude` tree blindly. The useful transfer is the **coordination model**:

```text
CRIA Producer/Orchestrator
  ├── Creative/Canon
  ├── Godot Technical Director
  │    ├── GDScript/runtime
  │    ├── tools/build
  │    └── performance
  ├── Combat/BJJ
  ├── Art Director
  │    ├── Sprite Forge
  │    ├── Maps/Arenas
  │    └── UI/technical art
  ├── World/Narrative
  ├── Audio
  └── QA/Accessibility/Release
```

Existing CRIA authorities remain above this layer:

`AGENTS.md -> canon/supreme contracts -> Production OS -> domain contracts -> orchestrator skill`.

Priority patterns to port/rewrite:

- project-stage detection;
- art-bible review;
- asset-spec and asset-audit workflows;
- vertical-slice gate;
- team-combat/team-ui/team-qa orchestration;
- Godot specialist review;
- performance/accessibility/release gates;
- session state + gap detection;
- path-scoped review rules.

## 2. Wolfcha -> living NPC cognition, reimplemented

Wolfcha demonstrates useful architecture for AI-controlled characters:

- stable personality;
- memory of observed events;
- role/faction goals;
- private vs public knowledge boundaries;
- fact-grounded decisions;
- suspicion/pressure state;
- history-aware actions and resume behavior.

CRIA should reimplement these ideas in a deterministic/offline-compatible **NPC Social Memory** layer. It must not allow NPC LLM context to become world truth.

Proposed invariant:

```text
WorldState facts
      ↓
NPC perception filter
      ↓
known facts + beliefs + memories
      ↓
intent/utility decision
      ↓
action/dialogue
      ↓
event log

belief ≠ fact
claim ≠ canon
private knowledge never leaks unless an explicit event reveals it
```

Wolfcha direct code remains disabled while its README/license-file metadata conflict is unresolved.

## 3. Sprite Animator -> independent Sprite Forge improvements

The project has excellent implementation ideas:

- integer grid slicing;
- padding/shift alignment;
- chroma cleanup;
- background color normalization;
- APNG/GIF/ZIP preview/export;
- worker-based processing;
- persistent batch jobs;
- CI including secret scanning and distribution budgets.

Its CC BY-NC-SA 4.0 license blocks commercial reuse without separate authorization. CRIA may independently implement equivalent algorithms/patterns but must not copy the code.

## 4. SNES engine -> engineering patterns only

The audited platformer demonstrates fixed timestep, camera bounds, tile collision, autotiling, sprite atlas baking, parallax, particle pooling, generated levels and headless regression tests. No license was found, and Mario-style content is not suitable for CRIA. Reimplement only generally applicable engineering ideas in Godot where they actually improve the existing runtime.

## 5. PixelSRPG Forge -> taxonomy only

The collection is useful for checking coverage categories, but its README explicitly says asset rights are uncertain and mentions internet downloads/commercial purchases. No binary from the collection may be linked in `asset_links_v1.json` without independent item-level provenance.

## 6. Mia HTML benchmark -> UI/microinteraction laboratory

The DeepSeek v4.1 Flash corpus is useful as a creative-interaction benchmark. No repository license was found, therefore code is reference-only.

CRIA-relevant experiments include:

- Pixel Art Studio: draw/erase/fill/pick, undo/redo, zoom, preview;
- Editorial Spread: visual hierarchy + reduced motion;
- Rain Alley: layered weather, reflection, shake, local light;
- Kinetic Clock: state-transition animation;
- Glitch Lab: controlled post-processing presets;
- Cursor Comet: velocity-driven particles;
- Vinyl Deck/Soft Synth: direct manipulation + procedural audio;
- Metamorphosis: swarm-state transitions.

These are idea sources for editor tooling, map/weather presentation, CriaLive transitions and UI polish. They are not new runtime frameworks.

## Low-priority/blocked sources

- Pixel Life Simulator: only simple joystick/four-direction/pixel-canvas reference; CRIA already has a stronger Godot foundation.
- old `ringuemkt-rgb/Cria-do-tatame-`: explicitly deactivated; never implement there.
- GPT-6 Astra HTML corpus: comparative design benchmark only.

## Validation

```bash
npm run validate:external-tools
npm run test:external-tools
```

The validator rejects direct reuse from ambiguous, non-commercial, no-license or deactivated sources. It also requires immutable SHAs for GitHub repositories that are used beyond pure comparative design reference.

## Shipping rule

This registry never makes an asset or implementation shipping-ready. Any imported or independently reimplemented capability must enter the normal CRIA path:

`proposal -> branch -> tests -> PR -> CI -> runtime evidence -> (asset: rights + human QA) -> shipping gate`.
