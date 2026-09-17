# Cria Visual Foundry v1 — 3D → Sprite Production Layer

## Status

**Version:** 1.0  
**Scope:** offline production tooling  
**Runtime dependency:** none  
**Source of truth:** `data/visual/production_manifest_v02.json`

## Why this exists

The game ships primarily as **2D HD pixel art**, but recurrent fighters need dozens of poses and paired grappling animations. Generating every frame independently creates identity drift, unstable proportions and poor attacker/defender synchronization.

Visual Foundry v1 uses a reusable 3D master as a manufacturing intermediate:

```text
CANON
  ↓
reference lock
  ↓
3D master
  ↓
retopo / UV / material
  ↓
rig
  ↓
animation
  ↓
orthographic RGBA render
  ↓
pixel pass
  ↓
existing Sprite Forge
  ↓
Godot integration
```

The 3D source is not automatically a shipping runtime asset. For normal combat, the expected shipping target remains a 2D sprite.

## Architecture boundaries

### Canonical scope

`data/visual/production_manifest_v02.json` defines:

- characters;
- animation profiles;
- paired techniques;
- arenas;
- UI inventory;
- art constraints.

Visual Foundry is forbidden from silently changing that scope.

### Foundry profile

`data/visual/visual_foundry_profile_v1.json` defines manufacturing constraints such as:

- source render resolution;
- camera model;
- alpha policy;
- sprite scale/pivot;
- mesh soft budgets;
- provenance gates;
- tool status.

### Tool adapters

External tools are classified as `candidate`, `approved`, or `preferred`. A repository entry does not mean a model is installed, downloaded, licensed for every territory, or production-approved.

Current design intent:

| Tool | Role | Status |
|---|---|---|
| Blender | DCC, render, cleanup, export | preferred |
| TripoSG | image → 3D | candidate |
| TripoSR | fast image → 3D | candidate |
| TRELLIS.2 | image → 3D / PBR | candidate |
| UniRig | auto-rig | candidate |
| Instant Meshes | retopology | candidate |
| QuadriFlow | retopology | candidate |

Approval requires license review, reproducible smoke test, acceptable geometry, export compatibility and cost/hardware assessment.

## Character production contract

Every recurrent fighter should have a stable character identity package:

```text
production/visual_foundry/<character_id>/
├── refs/
├── master/
│   └── master.glb
├── rig/
│   └── rig_manifest.json
├── anim/
├── renders/
│   └── render_manifest.json
├── sprites/
│   ├── spritesheet.png
│   ├── metadata.json
│   ├── contact_sheet.png
│   └── preview.gif
├── provenance.json
└── qa_report.md
```

### Identity invariants

- silhouette;
- body proportions;
- face/hair read;
- canonical outfit;
- palette;
- accessories;
- fighting stance;
- scale relative to Ruan.

A regenerated master that breaks these invariants is a new candidate, not an automatic replacement.

## Grappling contract

Brazilian Jiu-Jitsu interactions are authored as **paired animation products**, not independent clips.

Each paired technique requires:

- attacker animation;
- defender animation;
- shared world/contact anchors;
- deterministic `sync_map.json`;
- hitbox/interaction metadata;
- entry state;
- exit state;
- frame target from the canonical manifest.

The 3D manufacturing stage is valuable here because the same skeletons can be positioned in one Blender scene before deriving the two sprite streams.

## Camera and render lock

Default character renders:

- orthographic camera;
- 1024 × 1024 source frame;
- transparent RGBA;
- fixed lighting rig;
- fixed object scale;
- documented floor contact line;
- no final pixel outline at this stage.

The existing art pipeline owns the final pixel treatment.

## Mobile-first constraints

The source can be high fidelity, but shipping sprites must continue to obey:

- combat read around 72 px character height;
- nearest filtering;
- 1 px outline;
- stable frame bounds;
- controlled atlas size;
- no accidental blur/AA;
- performance verification on Android hardware.

## Queue generation

```bash
python tools/visual_foundry/build_foundry_queue.py
```

This produces `production/visual_foundry/queue_v1.jsonl` with deterministic jobs for every canonical character and paired technique.

Preview without writing:

```bash
python tools/visual_foundry/build_foundry_queue.py --stdout
```

## Validation

```bash
python tools/visual_foundry/validate_visual_foundry_v1.py
python -m unittest discover -s tests -p 'test_visual_foundry_v1.py'
```

CI must reject drift between the Foundry profile and the canonical visual manifest.

## Production order

For the current vertical slice, use this order:

1. `ruan_macacao` master and identity lock;
2. `davi_relampago` master and identity lock;
3. common locomotion/combat poses;
4. Ruan × Davi paired grappling subset used by the playable slice;
5. render/pixel QA;
6. Godot integration;
7. Android device validation;
8. only then expand to the rest of the roster.

This keeps vertical completion ahead of horizontal asset inflation.

## Non-goals

Visual Foundry v1 does **not**:

- install or download external AI models automatically;
- commit model checkpoints;
- replace the Sprite Forge;
- modify combat logic;
- make cloud AI a runtime dependency;
- declare generated output shippable without human/game QA.
