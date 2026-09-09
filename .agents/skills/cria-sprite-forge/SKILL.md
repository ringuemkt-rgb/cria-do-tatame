---
name: cria-sprite-forge
description: Use for production-grade CRIA DO TATAME 2D pixel-art manufacturing, character identity consistency, directional locomotion, paired BJJ animation, world-layer authoring, preview QA, provenance and deterministic handoff into Godot. Never promotes generated art automatically.
---

# CRIA Sprite Forge v2

## Mission

Build the visual content of CRIA DO TATAME as a reproducible production system rather than a pile of generated images.

The Forge receives requirements from Production OS v03 and turns them into candidate art packages that are identity-locked, measurable, reviewable, rights-traceable and ready for Godot only after every applicable gate passes.

The Forge is **not**:

- a second runtime;
- a gameplay authority;
- a BJJ rules authority;
- a canon source;
- a legal-clearance authority;
- an automatic shipping promoter.

Godot remains the only runtime. `shipping=false` is the default.

## Authority order

1. `data/production/` executable contracts and completion matrix;
2. active canon and narrative authorities;
3. `.agents/skills/cria-art-direction/SKILL.md` and canonical visual data;
4. BJJ graph/rules/reducer authorities for combat semantics;
5. `assets/manifest_v2.json` + Asset Pipeline v2 sidecars;
6. `data/visual/sprite_qa_profiles_v1.json`;
7. `data/visual/sprite_forge_contract_v2.json`;
8. `data/visual/sprite_forge_requirements_v2.json`;
9. this operational skill.

If two authorities disagree, stop and resolve the upstream conflict. Do not blend contradictory data into an image prompt.

## Production coverage

Never create the visual TODO list by memory.

Run:

```bash
python tools/art/derive_sprite_forge_v2_requirements.py
python tools/art/validate_sprite_forge_v2.py
```

The derivator reads the roster, world locations and BJJ sources and materializes every required authoring unit. Missing authoritative BJJ data remains a blocker rather than being replaced by invented techniques.

The materialized requirements are authoring obligations, not release evidence.

## Non-negotiable pixel contract

Normalized gameplay frame:

- `128x128` RGBA;
- upright pivot `[64,96]`;
- nearest-neighbor resampling only;
- integer scaling only;
- smoothing disabled;
- binary alpha after normalization;
- candidate generation may happen at higher resolution;
- raw generated images never enter runtime paths;
- detached FX stay separate from body sprites by default.

Preserve the existing quantitative v1 gates and action-specific profiles.

## Character identity lock

Every playable fighter requires an identity reference chain before production animation.

Minimum master artifacts:

- identity master;
- turnaround;
- front combat pose;
- back view;
- side view;
- palette signature;
- silhouette signature.

The same character must remain recognizably the same across:

- GI and NO-GI variants;
- world locomotion;
- upright combat;
- clinch;
- ground control;
- transitions;
- portraits and emotes.

Never allow a generator to silently change:

- face;
- body proportions;
- skin/hair characteristics;
- clothing identity;
- patches/logos;
- belt/variant;
- equipment;
- left/right asymmetry.

Generated identity cannot approve itself. Human visual review remains mandatory.

## Directional authoring

Canonical authored directions:

- down/front;
- up/back;
- side-right.

Left may be mirrored only when the character/action asymmetry contract permits it. If clothing, grips, scars, tattoos, patches, stance or equipment make mirroring semantically wrong, author a separate left-facing asset.

Reference-conditioning order:

1. approved identity master;
2. same-action reference when available;
3. target direction.

Changing direction must never change attack type, equipment, GI/NO-GI semantics or character identity.

## Frame extraction and content bounds

Do not assume generated 2x2 cells are already normalized.

For every frame:

1. extract candidate cell;
2. detect nontransparent `contentBounds`;
3. record `x,y,width,height`;
4. measure body height/body span;
5. determine feet/contact anchor;
6. normalize scale against approved identity/action profile;
7. place on canonical frame/pivot;
8. verify no edge touch or clipping;
9. run palette/alpha cleanup.

Use `tools/art/sprite_preview_harness.html` for offline inspection before Godot promotion.

The preview harness is not gameplay authority and does not replace Godot runtime evidence.

## Model adapters

Generation providers are interchangeable authoring adapters, never runtime dependencies.

Each adapter must record:

- provider/model or tool id;
- endpoint/revision when available;
- known failure modes;
- prompt patches/negative constraints;
- reference images used;
- output terms/license review status.

A model adapter may compensate for predictable problems such as:

- wrong facing direction;
- text or watermark hallucination;
- fake grid/divider lines;
- inconsistent background;
- scale drift;
- identity drift.

A model adapter may **not**:

- define canon;
- define BJJ legality;
- invent scoring;
- choose shipping status;
- bypass human/rights review.

## External research policy

`data/production/external_tool_registry_v1.json` is the only external-tool authority.

Current high-value references include:

- `0x0funky/agent-sprite-forge` — permissive upstream concepts already adapted in v1;
- `poirotw66/Sprite-Animator` — processing/QA concepts only because current license is noncommercial;
- `blendi-remade/sprite-sheet-creator` — direction/reference/content-bounds/preview concepts only because no license is published at the pinned revision;
- Qwen Pixel-Art LoRA — candidate generation only, never automatic shipping;
- PixelSRPG-Forge — taxonomy/reference only; collected asset rights are not trusted.

Never copy source code or assets from a no-license/noncommercial/unknown-rights source into CRIA commercial shipping.

## World art manufacturing

A generated flat map is a concept, not a shippable game map.

Every production world location is decomposed into runtime-addressable layers:

1. background;
2. terrain/base;
3. structures;
4. props;
5. decals;
6. collision/navigation metadata;
7. characters;
8. foreground occlusion;
9. weather FX;
10. lighting FX;
11. HUD outside the world renderer.

Walkability, collision and navigation come from game/runtime data, never from image-model guessing.

Regional fidelity review must verify the visual identity of the Baixo Sul without turning real places or cultures into random generic tropical scenery.

At minimum review:

- vegetation/ecosystem;
- coastline/river/mangrove logic;
- urban/rural material language;
- tatame/academy logic;
- lighting/time/weather;
- readable paths and playable silhouettes;
- foreground occlusion that never hides critical combat/navigation information.

## Paired BJJ animation

Never generate BJJ through a generic `attack` prompt.

A technique package exists only if the graph-valid transition exists upstream.

Required synchronized phases:

1. anticipation;
2. entry;
3. establish;
4. stabilize;
5. response;
6. recovery.

Each paired package records:

- technique id;
- from/to positions;
- attacker/defender roles;
- GI/NO-GI modality;
- pivot policy;
- sync points;
- contact points;
- attacker frames;
- defender frames.

Contact validation includes:

- limb continuity;
- grip target;
- body contact;
- head/hip orientation where relevant;
- no GI-only grip in NO-GI;
- no frame teleportation;
- no unexplained side swap;
- no impossible body intersection outside the technique contract.

Expert biomechanical review is mandatory before human approval.

## Preview gate

Before Godot handoff, preview each package with actual frames.

Required checks:

- idle loop;
- directional locomotion;
- scale consistency;
- anchor stability;
- mirror/asymmetry correctness;
- one-shot transition/action playback;
- alpha/background cleanliness;
- content-bounds overlay.

Paired BJJ additionally requires:

- shared pivot;
- phase order;
- contact continuity;
- synchronization;
- attacker/defender spacing.

`frames_checked == 0` can never become PASS.

## Provenance

Every candidate/promotion package must preserve a sidecar containing:

- `asset_id`;
- originating production requirement id;
- authoring method;
- model/tool;
- model/tool revision;
- source references;
- license/terms status;
- human editor;
- QA evidence;
- human approval;
- rights status;
- `shipping`.

Unknown source or rights status blocks promotion.

## Manufacturing workflow

### A. Refresh obligations

```bash
python tools/art/derive_sprite_forge_v2_requirements.py
python tools/art/validate_sprite_forge_v2.py
```

### B. Select next requirement

Order:

1. P1 Ruan/Davi identity + locomotion;
2. Terreiro + Arena do Dique layered world package;
3. P1 combat/BJJ paired packages;
4. full roster identity masters;
5. full world locations;
6. full BJJ after authoritative 40/120/10 graph exists;
7. polish/FX.

### C. Produce candidate

Use generation or manual art outside runtime paths. Preserve prompt/tool/model/reference metadata.

### D. Normalize

Run Asset Pipeline/Sprite Forge normalization and measurement. Candidate art does not bypass the v1 quantitative gates.

### E. Preview

Open:

```text
tools/art/sprite_preview_harness.html
```

Load actual PNG frames and inspect bounds, pivot, scale and loop.

### F. Technical gates

```bash
npm run validate:asset-protocol
npm run validate:sprite-forge
npm run validate:sprite-forge-phase1
npm run validate:sprite-forge-v2
npm run test:sprite-forge
npm run test:sprite-forge-phase1
npm run test:sprite-forge-v2
```

### G. Human/rights gates

Do not infer these from technical success.

### H. Godot handoff

Only after technical + human + rights gates:

```bash
npm run assets:spriteframes
```

Then integrate into a real scene and gather runtime visual evidence.

## Stop conditions

Stop instead of promoting when any of these is true:

- identity drift;
- canon conflict;
- unknown provenance/license;
- no approved identity master;
- scale/anchor threshold failure;
- edge-touch or empty frame;
- flat generated map being treated as final map;
- collision/navigation inferred from pixels rather than authored metadata;
- generic attack generation used as BJJ authority;
- paired technique missing sync/contact map;
- technique not present in authoritative graph;
- GI/NO-GI mismatch;
- human or rights approval inferred automatically;
- Android/device evidence inferred instead of measured.

## Definition of done — visual unit

A visual unit is done only when:

```text
requirement exists
+ authority resolves
+ candidate provenance exists
+ identity/style contract passes
+ normalization passes
+ preview contains real frames
+ applicable paired/world contract passes
+ human review passes
+ rights review passes
+ asset registry handoff passes
+ Godot runtime evidence exists
```

Anything less is work-in-progress, even if the PNG looks excellent.

## Validation

Always finish Forge changes with:

```bash
npm run validate:external-tools
npm run test:external-tools
npm run validate:sprite-forge-v2
npm run test:sprite-forge-v2
npm run quality
```
