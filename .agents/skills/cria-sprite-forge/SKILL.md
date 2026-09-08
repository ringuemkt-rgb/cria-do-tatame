---
name: cria-sprite-forge
description: Use for production-oriented 2D character sprite consistency, animation package QA, and deterministic handoff into the existing Cria do Tatame Asset Pipeline v2. Never promotes generated art automatically.
---

# CRIA Sprite Forge v1

## Authority

This skill is an offline authoring/QA adapter for the existing repository. It is not a second runtime, asset registry, canon source, or image generator.

Authority order:

1. `data/production/` executable contracts;
2. active canon and visual bible sources;
3. `assets/manifest_v2.json` + Asset Pipeline v2 sidecars;
4. `data/visual/sprite_forge_contract_v1.json` for sprite-consistency rules;
5. this operational skill.

Godot remains the only runtime. `shipping=false` is the default and this skill has no authority to change it.

## Upstream provenance

Research basis: `0x0funky/agent-sprite-forge`, pinned at:

`64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2`

License: MIT.

This repository adapts concepts and contracts. It does not vendor or execute the upstream runtime/tooling in the game.

## Non-negotiable frame contract

- normalized gameplay frame: `128x128` RGBA;
- pivot: `[64, 96]`;
- grounded anchor: feet;
- nearest-neighbor resampling only;
- integer scale only;
- binary alpha after normalization;
- canonical palette and no-AA rules remain owned by `validate_asset_protocol.py`;
- raw/generated images are candidates, never runtime assets;
- main-character actions are produced/reviewed per action family before any atlas assembly;
- detached FX stay separate from body sheets by default;
- paired BJJ techniques require attacker + defender + shared pivot/timing + `sync_map`.

## Quantitative gates

For high-value grounded character actions:

- `body_scale_cv <= 0.08`;
- `anchor_y_std <= 0.05`;
- `profile_body_scale_drift <= 0.08` against the approved master action;
- edge-touch frames: `0`;
- empty frames: `0`;
- paste-clamped frames: `0`.

These are technical gates, not artistic approval. Human visual/cultural/biomechanical review remains mandatory.

## Workflow

1. Inspect the canonical character model/reference and active art protocol.
2. Select an accepted grounded master action, normally `idle`, `walk`, or `run`.
3. Produce or ingest candidate action frames outside shipping paths.
4. Normalize candidates into `assets/chars/frames/<character>/<action>/` only after provenance is known.
5. Run the existing M3 asset protocol gate.
6. Build consistency metadata:

```bash
python tools/art/build_sprite_forge_profile.py \
  --character <character_id> \
  --master-action idle \
  --write
```

7. Validate the generated package:

```bash
python tools/art/validate_sprite_forge.py --require-package
```

8. Build cached Godot SpriteFrames with the existing tool only after both gates pass:

```bash
npm run assets:spriteframes
```

9. Integrate into a real scene and keep all release/human gates unchanged.

## Package output

Each character using this protocol receives:

`assets/chars/frames/<character_id>/sprite_forge_manifest.json`

The manifest records:

- master action and scale profile;
- action frame directories and frame counts;
- loop intent;
- measured body-scale and anchor metrics;
- drift against the master profile;
- human, rights and M3 gate states;
- `shipping=false`.

## Stop conditions

Stop instead of promoting when any of these is true:

- identity drift across actions;
- scale/anchor thresholds fail;
- frame touches an edge or is empty;
- provenance/license is unknown;
- paired technique lacks synchronization data;
- visual canon conflict exists;
- generated output contains third-party person/brand/IP without cleared rights;
- Android/device evidence is being inferred rather than measured.

## Validation

Always run:

```bash
npm run validate:asset-protocol
npm run validate:sprite-forge
npm run test:sprite-forge
npm run quality
```
