# CRIA Sprite Forge v1

**Status:** ACTIVE TOOLING CONTRACT  
**Version:** 1.0.0  
**Runtime impact:** none  
**Shipping authority:** none

## Purpose

CRIA Sprite Forge v1 adds deterministic sprite-consistency measurement and QA to the existing Asset Pipeline v2. It solves a narrow production problem: keeping one character visually stable across idle, locomotion, guard, attack, hurt and other animation families before those frames are assembled into Godot `SpriteFrames`.

It does **not** replace `assets/manifest_v2.json`, M3 QA, sidecars, the art bible, the production manifest, Godot, or human review.

## Research provenance

The design was informed by the MIT-licensed project:

- repository: `https://github.com/0x0funky/agent-sprite-forge`;
- audited pin: `64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2`;
- adopted ideas: per-action generation before atlas assembly, grounded feet anchors, master scale profiles, body/FX separation and quantitative anchor/scale QC.

No upstream runtime code is vendored into the game. The integration here is project-native Python tooling and machine-readable contracts.

## Existing pipeline preserved

```text
reference_candidate
  -> provenance
  -> normalize
  -> 128x128 frame package
  -> Asset Protocol M3
  -> Sprite Forge consistency profile
  -> cached Godot SpriteFrames
  -> candidate_integrated
  -> human + rights + device gates
```

`shipping=false` remains mandatory through this tooling layer.

## Frame contract

| Rule | Value |
|---|---|
| Frame | 128x128 RGBA |
| Pivot | 64,96 |
| Grounded anchor | feet |
| Resampling | nearest |
| Runtime scaling | integer |
| Default FPS | 12 |
| Palette / AA | existing Asset Protocol v2 |

## Master profile

A character chooses one accepted grounded action, normally `idle`, `walk` or `run`, as the scale reference.

For each action the builder measures the alpha silhouette of every normalized frame and records:

- mean body-height ratio (`body_scale_mean`);
- coefficient of variation (`body_scale_cv`);
- mean bottom-anchor ratio (`anchor_y_mean`);
- anchor standard deviation (`anchor_y_std`);
- relative mean scale drift against the master action;
- edge-touch and empty-frame counts.

Current technical thresholds:

```text
body_scale_cv <= 0.08
anchor_y_std <= 0.05
profile_body_scale_drift <= 0.08
edge_touch_frames == 0
empty_frames == 0
paste_clamped_frames == 0
```

The validator recomputes measurable values from the PNG frames. Stored metrics are not trusted as evidence by themselves.

## Files

```text
data/visual/sprite_forge_contract_v1.json
assets/schemas/sprite_forge.manifest.schema.json
.agents/skills/cria-sprite-forge/SKILL.md
tools/art/build_sprite_forge_profile.py
tools/art/validate_sprite_forge.py
tests/test_sprite_forge.py
```

A participating character receives:

```text
assets/chars/frames/<character_id>/
  idle/*.png
  walk/*.png
  ...
  sprite_forge_manifest.json
```

## Commands

Generate a profile without writing:

```bash
python tools/art/build_sprite_forge_profile.py --character ruan_macacao --master-action idle
```

Write it beside the character actions:

```bash
python tools/art/build_sprite_forge_profile.py --character ruan_macacao --master-action idle --write
```

Validate all production packages that currently exist:

```bash
npm run validate:sprite-forge
```

Require at least one production package (useful for a dedicated vertical-slice gate):

```bash
python tools/art/validate_sprite_forge.py --require-package
```

Run regression tests:

```bash
npm run test:sprite-forge
```

## Honest zero-package behavior

The general repository quality gate may run before any character has been migrated to Sprite Forge. In that state the validator verifies the contract and reports:

```text
production_packages=0; readiness=TOOLING_ONLY
```

This is not asset readiness and must never be reported as a visual PASS for the game. A character-specific migration gate should use `--require-package`.

## Relationship to older work

- PR #26 (`Open Pixel Forge`) is historical generation-tool research; not a dependency.
- PR #38 (`CRIA Visual Forge`) is historical queue/registry work; not a dependency.
- PR #52 (`ART_PROTOCOL`) is historical/staged visual-governance work; not a dependency of this branch.

This implementation starts from the current `main` Asset Pipeline v2 to avoid reviving stale branch bases or creating a second visual pipeline.

## Out of scope for v1.0.0 contract batch

- generating new binary art;
- importing upstream executables/scripts wholesale;
- changing `project.godot`;
- replacing `SpriteLoader` or `build_spriteframes.py`;
- changing combat, save, deck, world or narrative runtime;
- authorizing final art or shipping;
- claiming Android/device validation.

## Next vertical migration

The first production package should be the gold-slice protagonist, using approved Ruan reference art and one accepted grounded master action. It must pass existing M3, Sprite Forge metrics, human identity/anatomy review, Godot integration and the normal rights gates before any shipping discussion.
