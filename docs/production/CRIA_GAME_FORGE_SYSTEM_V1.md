# CRIA GAME FORGE v1 — Universal Agent Production OS

**Status:** ACTIVE  
**Version:** 1.0.0  
**Runtime:** Godot only  
**Shipping authority:** none  
**Primary machine contract:** `data/production/agent_production_contract_v1.json`

## 1. Mission

CRIA Game Forge v1 is the orchestration layer that lets **any sufficiently capable AI agent** contribute to *Cria do Tatame* without depending on one model vendor, one IDE, one MCP server or one image generator.

It does not try to make every agent equally capable. It does something safer:

1. discover what the current agent/environment can actually do;
2. choose the highest safe execution tier;
3. route the task to existing domain authorities and skills;
4. use the best available tool for each capability slot;
5. fall back to spec/code/queue work when a tool is missing;
6. require real evidence before claiming integration, runtime or release completion.

The game remains a **Godot project**. The Forge is a production operating system around the game, not a second engine.

---

## 2. Why v0.6 was insufficient

The old Game Forge v0.6 correctly described a flow from technique → data → sprite request → Godot → QA, but it assumed a generic studio without a machine-readable answer to:

- What can this agent actually execute?
- Does it have image generation or only code editing?
- Can it launch Godot?
- Is Blender installed?
- Is MCP present?
- Can it inspect video?
- Does it have an Android device?
- Which external tool is legally reusable, reference-only or blocked?
- What is the fallback if a capability is missing?

The repository has since gained mature systems that v0.6 did not coordinate:

- Production OS v03;
- executable canon/release contracts;
- Combat Intelligence;
- Grappling Motion Lab;
- Art Direction;
- Sprite Forge v1/v2;
- Visual Foundry v1 (3D → sprite);
- external tool and motion registries;
- coverage ledger;
- headless runtime and release gates.

v1 connects those systems instead of inventing replacements.

---

## 3. Authority hierarchy

An agent must resolve disagreements in this order:

1. **`AGENTS.md`** — repository-wide rules and immutable runtime boundaries;
2. **executable canon/contracts in `data/production/`**;
3. **Godot runtime implementation and tests**;
4. **Production OS / build matrix / release ledger**;
5. **domain-specific active skills**;
6. **active art bible / visual contracts**;
7. **external tools and research references**;
8. prompts, concept boards and historical documents.

External tools never outrank CRIA canon.

---

## 4. Universal capability handshake

The agent identity is irrelevant. Capabilities matter.

The machine-readable contract defines capabilities including:

### Repository / execution

- `repo_read`
- `repo_write`
- `git_cli`
- `github_remote`
- `shell_exec`
- `python_exec`
- `node_exec`
- `binary_file_io`

### Research / media

- `web_research`
- `vision`
- `image_generate`
- `image_edit`
- `video_read`
- `audio_read`

### Engine / DCC

- `godot_cli`
- `godot_mcp`
- `blender_cli`
- `blender_mcp`
- `ffmpeg_cli`
- `imagemagick_cli`
- `pixel_editor`
- `map_editor`
- `comfyui_external`
- `mocap_pose_stack`
- `annotation_stack`

### Release / human gates

- `adb`
- `physical_android_device`
- `human_review`
- `rights_review`

Detection command:

```bash
python tools/agents/detect_capabilities.py \
  --write reports/agent_bootstrap/capabilities.json
```

Platform-native tools that are invisible to PATH can be declared explicitly, for example:

```bash
python tools/agents/detect_capabilities.py \
  --declare github_remote,web_research,vision,image_generate,image_edit \
  --write reports/agent_bootstrap/capabilities.json
```

The detector never reads or prints secret values.

---

## 5. Execution tiers

### T0 — Observer

**Minimum:** repository read.

Can:

- inspect code/data/docs;
- audit architecture;
- produce plans/specs;
- identify missing evidence.

Cannot claim:

- file modifications;
- runtime PASS;
- asset integration;
- device testing.

### T1 — Author

**Minimum:** repo write + at least a useful execution/remote path.

Can:

- modify code/data/docs;
- add tests;
- create branches/PRs;
- run static validators when available.

If Godot is absent, runtime remains unverified.

### T2 — Asset Author

**Minimum:** T1-like repository access + binary IO + vision + a real visual authoring path.

Can produce:

- candidate character art;
- action grids;
- arenas;
- UI;
- masks;
- maps;
- deterministic sprite postprocessing.

Every generative output starts `shipping=false`.

### T3 — Runtime Integrator

**Minimum:** repo write + Godot CLI.

Can:

- import scenes/resources;
- execute headless tests;
- capture runtime evidence;
- build candidate exports.

Cannot substitute this for physical Android validation.

### T4 — Motion Producer

**Minimum:** video read + authoring tools such as FFmpeg / pose stack / Blender.

Can:

- inspect rights-cleared motion;
- derive contact/keyframe candidates;
- build paired grappling references;
- create `sync_map` / contact observations;
- perform offline biomechanics QA.

Motion tooling never becomes combat-rule authority.

### T5 — Release Operator

**Minimum:** Godot + ADB + real Android device + human gate.

Can produce actual device evidence. Release still depends on the existing release contract and ledger.

---

## 6. Studio roles without agent inflation

Roles are review lenses, **not a requirement for multiple LLM instances**.

One capable agent can act as producer, technical director and QA engineer in one run, as long as it observes the different authorities.

Canonical roles in `.criaforge/agents.yaml`:

- Producer / Orchestrator
- Canon Director
- Godot Technical Director
- BJJ Gameplay Lead
- Motion Lab Lead
- Art Director
- Sprite Forge Lead
- World Systems Lead
- AI Lead
- Audio Lead
- QA / Release Lead

This avoids the common failure mode where dozens of agents spend more effort talking to each other than finishing the game.

---

## 7. Complete toolchain

The following is a **toolbox**, not a mandatory installation list. The contract chooses a provider by capability and fallback.

### 7.1 Repository, CI and provenance

| Tool / class | Role | Policy |
|---|---|---|
| Git | local source control | preferred when available |
| GitHub | canonical remote, issues, PRs, Actions | preferred remote |
| GitHub Actions | reproducible CI/evidence | existing project infrastructure |
| Git LFS | optional large binary versioning | use only where repo policy calls for it |
| DVC | dataset/motion lineage | optional Motion Lab candidate |
| rclone / Drive adapter | private source transfer | existing cloud adapter rules |

### 7.2 Godot production

| Tool | Role | Policy |
|---|---|---|
| Godot CLI | import, tests, scenes, exports | primary runtime authoring path |
| `Sods2/godot-mcp` | optional agent→Godot bridge | MIT; external authoring bridge only |
| CRIA headless tests | deterministic gameplay/runtime verification | mandatory where applicable |
| ADB | Android install/log/performance | release/device path |

MCP is an interface convenience. It does not become a new manager or runtime service.

### 7.3 2D sprite production

| Tool | Role | Policy |
|---|---|---|
| CRIA Sprite Forge | normalization + consistency + QA | project authority |
| `0x0funky/agent-sprite-forge` | upstream patterns / selected MIT ports | pinned MIT upstream |
| Pillow + NumPy | deterministic image processing | preferred local processor |
| ImageMagick | optional conversion/inspection | external executable |
| Pixelorama | optional manual pixel cleanup | DCC only |
| Krita | optional paint/cleanup | DCC only |
| `poirotw66/Sprite-Animator` | alignment/slicing concepts | CC BY-NC-SA; concept-only |
| `blendi-remade/sprite-sheet-creator` | content-bounds/preview concepts | no license; concept-only |

#### Standard body workflow

```text
approved identity master
→ character anchor layout
→ one action family per generated grid
→ alpha/chroma cleanup
→ split
→ shared scale profile
→ feet/root alignment
→ 128×128 RGBA
→ pivot [64,96]
→ nearest
→ Sprite Forge metrics
→ contact sheet / preview
→ Godot atlas/SpriteFrames
```

Raw `1×N` generated body strips are not the default. Use compact grids first, then assemble delivery strips deterministically.

### 7.4 Candidate image generation

| Path | Role | Policy |
|---|---|---|
| agent-native image generation/edit | first-choice when available | candidate only |
| Qwen 2512 Pixel Art LoRA profile | cloud/local candidate generation | already audited/pinned profile |
| ComfyUI | repeatable node workflows | GPL external executable only |
| official Comfy MCP | optional agent bridge | AGPL/commercial dual license; explicit license gate |

The game must still be buildable without cloud image services.

### 7.5 Visual Foundry — 3D manufacturing

CRIA Visual Foundry v1 is the preferred route for recurrent fighters and difficult paired grappling where 2D-only generation drifts.

| Tool | Role | Status |
|---|---|---|
| Blender | DCC, rig cleanup, paired posing, orthographic render | preferred |
| `ahujasid/mcp-for-blender` | optional agent→Blender bridge | MIT external bridge |
| TripoSG | image→3D candidate | license/smoke-test gated candidate |
| TripoSR | fast image→3D candidate | gated candidate |
| TRELLIS.2 | image→3D/PBR candidate | gated candidate |
| UniRig | auto-rig candidate | gated candidate |
| Instant Meshes | retopology | candidate |
| QuadriFlow | retopology | candidate |

Canonical flow:

```text
visual canon
→ identity lock
→ 3D master
→ retopo / UV / materials
→ rig
→ animation / paired pose
→ locked orthographic RGBA render
→ pixel pass
→ Sprite Forge
→ Godot
```

3D is a manufacturing source, not the default gameplay shipping format.

### 7.6 Grappling Motion Lab

The motion registry already classifies high-value tools:

| Tool | Role |
|---|---|
| FFmpeg | frame/time normalization, proxies |
| Pose2Sim | multi-view calibration and 3D kinematics candidates |
| MMPose / RTMPose | body/hand keypoint candidates |
| SAM2 | segmentation and occlusion support |
| OpenSim | optional musculoskeletal/kinematic analysis |
| CVAT Community | video/track annotation and human review |
| Label Studio | annotation alternative |
| FiftyOne | dataset visual QA/error analysis |
| DVC | lineage/versioning |
| Blender | retarget/inspection/reference rendering |
| mixamo-llm-mocap adapter | pinned offline retarget/reference path; third-party license gates remain |
| MuJoCo / Brax / Genesis | offline research/control hypotheses only |

Restricted/noncommercial datasets/models remain benchmark/reference-only according to `motion_tool_registry_v1.json`.

#### Paired BJJ product

A grappling technique is one synchronized product:

```text
canonical combat edge
→ 6 motion phases
→ attacker + defender
→ shared origin
→ visible contacts / UNKNOWN occlusions
→ sync_map
→ contact_map
→ paired render streams
→ Sprite Forge
→ biomechanical review
→ Godot transition binding
→ runtime capture
```

Independent attacker/defender GIF generation is invalid as a production default.

### 7.7 Maps and world

Runtime authority stays with existing data/managers. Useful authoring paths include:

- CRIA world JSON and existing scene stack;
- Art Direction;
- Visual Foundry layered maps;
- generated base/prop layers;
- Blender blockout/reference render;
- Pixelorama/Krita cleanup;
- Tiled or LDtk as optional authoring utilities when they solve a concrete map job.

Do not create a second world manager. An LLM may suggest events/dialogue at authoring time but does not move NPCs per frame.

### 7.8 UI / HUD

Use project art direction and existing Godot Control scenes. Visual generation may produce candidate plates/icons, but interaction state and accessibility must remain native data/UI logic.

Required concerns:

- mobile legibility;
- touch targets;
- controller mapping;
- reduced motion;
- semantic state colors;
- no baked interactive text when native UI can render it;
- deterministic button/selection states.

### 7.9 Audio

The existing `AudioManager` remains authority. Useful authoring tools may include an external waveform editor such as Audacity or equivalent, FFmpeg for normalization and any rights-cleared/generated SFX path available to the active agent.

Audio rules:

- source/provenance recorded;
- no third-party music/SFX without rights;
- normalize assets offline;
- runtime remains offline and deterministic;
- no new parallel audio manager.

### 7.10 QA and release

Core QA:

```bash
npm run quality
```

Domain validators are used earlier for faster feedback.

Runtime evidence:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/runtime_smoke.gd
```

Android release evidence:

```text
export candidate
→ adb install
→ boot on physical device
→ play core loop
→ capture logs/performance/screens
→ bind evidence to commit/build
→ update release ledger
```

CI green is valuable but is not a substitute for the physical-device gate.

---

## 8. Provider-independent fallbacks

### No image generation

Do not stall the whole feature. Deliver:

- requirement/COMMAND;
- identity and motion spec;
- file/path contract;
- tests/validator;
- Godot placeholder linkage only where explicitly allowed;
- clear `BLOCKED_ON_ASSET_AUTHORING` state.

### No Godot

Implement code/data/tests that can be statically validated, then mark runtime as pending. Use GitHub CI if available; do not say the scene ran locally.

### No Blender

Use 2D action-grid production or motion specs. Do not claim 3D master evidence.

### No MCP

Use CLI/files. MCP is never required.

### No shell

Use repository connector/API actions, machine contracts and remote CI. The agent stays at the highest tier actually supported.

### No physical Android device

Stop at export/CI. `DEVICE_PASS` remains false.

---

## 9. Canonical workflows

### A. Technique → gameplay

`.criaforge/workflows/technique_to_gameplay.yaml`

Focus: reducer state, defense, cost/effects, tests, optional visual requirement.

### B. Visual asset → runtime

`.criaforge/workflows/visual_asset_to_runtime.yaml`

Focus: requirement ID → candidate → normalization → QA/rights → Godot → coverage.

### C. Paired BJJ → runtime

`.criaforge/workflows/paired_bjj_to_runtime.yaml`

Focus: canonical transition → paired motion → sync/contact → sprites → Godot.

### D. Map/world → runtime

`.criaforge/workflows/map_world_to_runtime.yaml`

Focus: one map page/hub/arena → layered presentation → existing world managers → smoke.

### E. Vertical slice → release evidence

`.criaforge/workflows/release_vertical_slice.yaml`

Focus: coverage → quality → Godot → build → physical Android → release ledger.

---

## 10. Production strategy for the current game

The system must resist horizontal expansion until the gold slice proves the factory.

Current preferred order:

1. stabilize main quality gates;
2. Ruan identity master;
3. Davi identity master;
4. shared scale/action foundations;
5. locomotion and combat stances;
6. first paired BJJ chain used by Ruan × Davi;
7. Arena do Dique + required HUD/SFX/VFX;
8. Godot runtime evidence;
9. Android physical evidence;
10. then expand roster/arenas/techniques.

The goal is not “many generated assets”. The goal is a repeatable vertical manufacturing line.

---

## 11. Shipping firewall

No system in this document may set an asset or feature to shipping merely because:

- a prompt completed;
- a PNG exists;
- a spritesheet exists;
- Blender rendered successfully;
- a model produced a GLB;
- a script parsed JSON;
- CI is green;
- a scene opens on desktop.

Promotion requires the existing CRIA chain:

```text
canonical requirement
→ actual binary/code
→ provenance
→ technical QA
→ human/domain QA
→ rights
→ real runtime consumer
→ runtime evidence
→ coverage link
→ platform/release gates
```

---

## 12. Machine contracts and validators

Primary files:

```text
data/production/agent_production_contract_v1.json
.criaforge/config.yaml
.criaforge/agents.yaml
.criaforge/quality_gates.yaml
.criaforge/workflows/*.yaml
.agents/skills/cria-universal-producer/SKILL.md
tools/agents/detect_capabilities.py
tools/ci/validate_agent_production_os_v1.py
tests/test_agent_production_os_v1.py
```

Validation:

```bash
npm run validate:agent-production-os
npm run test:agent-production-os
npm run validate:external-tools
npm run test:external-tools
```

Full repository:

```bash
npm run quality
```

---

## 13. Definition of done for an AI agent

Every production turn should be reportable in the same eight fields:

1. **Delivered** — what exists and works now;
2. **Files** — exact paths changed/generated;
3. **Integration** — which runtime/data consumer uses it;
4. **Validation** — commands actually executed and outcomes;
5. **GitHub** — branch, commits, issue/PR, CI state;
6. **Risks** — license, identity, biomechanics, performance, uncertainty;
7. **Missing capabilities/gates** — what the agent could not perform;
8. **Next vertical batch** — smallest step that increases playable completion.

This common handoff format is what makes work portable across ChatGPT/Codex-class agents, Claude/Cursor/Cline-class coding agents, local LLM agents, cloud agents and future systems without coupling the project to any one of them.
