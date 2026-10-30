# Deck Builder — responsive touch layout (2026-10-30)

**Status:** IMPLEMENTED IN DRAFT PR; CI and physical Android sign-off required.
**Base:** `main` at `f6330dfbb3c0ef1f0c1ba69119fbe67ddf5498ff`.

## Functional defect

The real `DeckBuilder.tscn` used a horizontal body with a 720 logical-pixel minimum Gi panel, five 132 px slots in one row, and four 190 px actions in one row. A 360 px portrait viewport could not access the full editor by touch. This blocked the existing skill-tree → unlocked technique → equip flow on compact Android screens, despite the underlying transactional `DeckManager` already working.

## Implementation

- The existing `DeckBuilder` scene now has a vertical `ScrollContainer` around the editor. Horizontal scrolling is disabled.
- The existing body switches between horizontal desktop and vertical compact arrangements, with a one-column collection, a 3-column active-slot grid, and a two-column action grid on widths below 1200 logical px.
- Five active and three passive slots remain in the same node hierarchy under the new scroll wrapper. All button signals and stable card IDs are retained.
- Mobile action buttons have minimum 136×52 logical px, equipped slots 96×100, and removal buttons 48 px high.
- Viewport size changes recompute layout. The 1280×720 desktop arrangement returns to two collection columns, five active columns, four actions, and the existing 720 px Gi minimum.
- A failed explicit save is shown as an error. Navigation back to Terreiro is blocked if saving fails, rather than silently discarding the unsaved deck.
- No manager, autoload, gameplay data, map route, save version, or asset is added or replaced.

## Regression and acceptance

```bash
npm run quality
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/skill_tree_deck_smoke.gd
godot --headless --path . --script res://tests/deck_builder_mobile_touch_smoke.gd
godot --headless --path . --script res://tests/first_run_flow_smoke.gd
```

The Skill Tree and Deck V1 workflow now runs Godot 4.2.2 and 4.3 matrix jobs. The new smoke checks portrait 360×800, compact landscape 640×360, 854×480, desktop 1280×720, all eight equip slots, action hit targets, scroll containment, and that layout checks do not mutate the deck. These are **headless logical-layout checks**, not physical touch evidence.

## Integration and risk

The source PRs #167/#168/#169 and the prior combat/HUD/save fixes are already reported as merged into `main` on 2026-10-30. Their historical review state must not be retroactively described as human-approved; outstanding #165/#168 review threads need human disposition. PR #187 (vehicle/ROTA 101) is a separate open draft and is intentionally outside this change.

Ituberá remains the hub. Salvador and Itacaré remain external context. Existing map paintings are concept references only; Sprite Forge promotion still requires rights, provenance, visual QA and human approval.

**Android physical QA PENDING:** test a real ARM64 phone with gesture navigation/cutout, 360-class portrait and 854-class landscape; scroll the collection and Gi to all slots, equip/remove by touch, rotate, save, restart, and reload. Record device, OS, commit, screenshot, frame rate and human approval. An exported APK is not certified without this evidence.

**Rollback:** revert the scene, script, smoke, workflow and this note; no persistent data migration is necessary.
