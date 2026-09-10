# CRIA Grappling Runtime V1

## Status

Golden-chain implementation over the noncanonical Ruan x Davi slice. `shipping=false`.

This runtime proves the architecture required for the complete game without pretending that the incomplete `40 positions / 120 techniques / 10 chains` source is finished.

## Authority flow

```text
player / AI intent
        ↓
BJJGraphReducerV2
        ↓
canonical deterministic state
        ├── score / gas / winner / position
        ├── GrapplingPhysicalStateV1
        └── BJJMotionBindingV1
                 ↓
          visual-only request
                 ↓
          Sprite Forge / Godot
```

Only `BJJGraphReducerV2` owns the combat result. Animation, VFX, audio, camera, NPC dialogue, LLM output and video analysis are consumers of the result.

## Golden chain

```text
standing_neutral
  → t001 double-leg
half_guard_top
  → t025 body-lock pass
side_control
  → slice_side_to_mount
mount_high
  → t057 armbar
submission
```

Representative branches:

```text
t001 + slice_sprawl → front_headlock
t025 + t049         → knee_shield_half
t005                 → closed_guard
```

The chain is cross-checked against `data/bjj/bjj_kg_slice_ruan_davi_v1.json`; an unknown technique or contradictory transition fails validation.

## Two-body physical state

`GrapplingPhysicalStateV1` exposes the dimensions defined by Combat Intelligence OS: posture, supports, base, center of mass, hips, shoulders, head, inside position, grips, frames, hooks, wedges, leg topology, knee line, heel exposure, pressure, mobility, pinned segments, submission danger and fatigue.

However, only reducer-owned values are populated automatically today:

- canonical position;
- top player;
- gas;
- score.

Everything not established by an approved observation remains `UNKNOWN`.

This is deliberate. A plausible-looking invented grip is still false data.

## Connection Graph

`GrapplingConnectionGraphV1` validates edges of these kinds:

- grip;
- frame;
- hook;
- pin;
- post;
- wedge;
- head control;
- chest contact;
- hip contact;
- leg entanglement;
- foot contact;
- mat support.

Pending physical bindings cannot enter runtime. Promotion to `APPROVED` requires reviewer identity, evidence references and phase edges.

## Motion binding

A successful or countered reducer action generates a visual-only request containing:

- technique id;
- source and destination positions;
- six synchronized phases;
- paired-animation requirement;
- asset approval status.

Current final paired assets remain intentionally `MISSING_APPROVED_FINAL`.

A missing asset never changes the combat result and never becomes shipping evidence.

## Six phases

1. anticipation;
2. entry;
3. establish;
4. stabilize;
5. response;
6. recovery.

These phases align with the existing `paired_bjj_animation_v2` contract and Sprite Forge V2.

## Scoring rule

The sprite reaching a pose does not award points.

Example:

```text
t001 success
  ↓
half_guard_top
  ↓
pending takedown event
  ↓
3 s reducer stabilization
  ↓
IBJJF +2
```

The same pattern is proven for pass and mount in the golden-chain smoke.

## Evidence

Dedicated CI runs:

```bash
python tools/combat/validate_grappling_golden_chain_v1.py
python -m unittest discover -s tests -p 'test_grappling_golden_chain_v1.py'
Godot 4.2.2 import
grappling_golden_chain_smoke.gd
```

The first successful dedicated run produced `GRAPPLING_GOLDEN_CHAIN_SMOKE PASS 33/33`.

## Promotion gates

This runtime may not replace the legacy combat authority until, at minimum:

1. full BJJ source is restored and passes 40/120/10;
2. shadow coverage has no critical `UNMAPPED`/`AMBIGUOUS` states;
3. physical bindings for production techniques pass expert review;
4. paired animation packages pass identity/contact/provenance QA;
5. HUD and input adapters consume the canonical graph state;
6. deterministic replay remains green;
7. full game/runtime/Android gates remain green;
8. rollback and save migration are proven.

Until then, this is a production architecture and vertical-slice runtime proof, not a shipping claim.
