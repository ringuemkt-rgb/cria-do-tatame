# CRIA Sprite Forge — Phase 1A–1C

**Status:** ACTIVE TOOLING CONTRACT  
**Runtime impact:** none  
**Shipping authority:** none

## Scope

This phase extends the Sprite Forge foundation already merged into `main` with three authoring/QA layers:

- **1A — Gate taxonomy and action profiles**: 14 automatic technical gates + 2 authority gates, with thresholds selected by motion family instead of one universal tolerance.
- **1B — Canon Adapter**: compiles canonical character data, visual language, action sets, QA profile and upstream pin into a deterministic job spec.
- **1C — Identity Lock**: protects an approved master reference using SHA-256 plus human-authored identity regions. It does not claim identity similarity by itself.

No PNG is generated, migrated or promoted in this phase.

## Gate model

The 16 promotion gates are split into:

```text
14 automatic technical gates
+ human_approval
+ rights_status
= 16 promotion gates
```

Automation may validate that human/rights evidence exists, but it cannot originate either approval.

## Action profiles

Universal `body_height_drift` or silhouette thresholds are invalid for grappling transitions. The contract therefore defines:

- `upright_grounded` — idle, walk, guard, stable grip;
- `dynamic_upright` — grip exchanges, hurt, standing celebration and striking-capability candidates;
- `evasive` — slip/dodge tooling candidates;
- `ground_transition` — knockdown, baiana entry, side-control transitions, tap/reset;
- `signature_custom` — explicit per-action overrides, including Silverback Grip.

Striking entries are **tooling capability only** while the executable gameplay contract remains a BJJ positional grappling core.

## Canon Adapter

Example:

```bash
python tools/art/cria_canon_adapter.py \
  --character ruan_macacao \
  --actions idle,baiana_entry,jab
```

The result explicitly marks `jab` as `gameplay_authority=false`; it cannot silently expand the combat canon.

## Identity Lock

Status only:

```bash
python tools/art/identity_lock.py --character ruan_macacao --plan
```

A lock can be written only after all of the following are true:

1. the master reference exists under `assets/chars/ref/`;
2. `master_reference_status=approved` was authored after human review;
3. required identity regions have explicit pixel bounding boxes;
4. the reference can be decoded as an image.

Then:

```bash
python tools/art/identity_lock.py --character ruan_macacao --write
```

The lock contains:

- SHA-256 of the exact reference file;
- reference dimensions;
- human-authored region coordinates;
- SHA-256 over decoded RGBA bytes for each region.

This protects reference integrity. A future `identity_match` comparator must consume the lock as supporting evidence and produce separate comparison evidence. SSIM is not accepted as the sole authority.

## Ruan status

`data/chars/canon/ruan_macacao.json` is the first visual-canon record. Its master turnaround is deliberately marked:

```text
pending_ingestion_and_human_approval
```

Therefore Identity Lock must report `lock_ready=false` today. That is the expected fail-closed state until approved source art is ingested.

## Legacy sprite packages

Historical packages under `assets/sprites/ruan_macacao/` are not automatically treated as Sprite Forge v1 packages. Migration into `assets/chars/frames/` requires explicit provenance, M3 validation and the new consistency gates.

## Validation

```bash
npm run validate:sprite-forge-phase1
npm run test:sprite-forge-phase1
npm run quality
```
