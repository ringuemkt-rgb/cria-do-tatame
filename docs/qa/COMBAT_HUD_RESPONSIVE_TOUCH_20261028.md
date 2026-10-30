# Combat HUD — responsive six-slot touch layout (2026-10-28)

**Status:** IMPLEMENTED IN STACKED DRAFT PR — not merged, not physically certified.

## Functional defect and scope

The existing combat HUD uses six `Button` nodes inside a horizontal container and places its panel at 49%–98% of the viewport width. At compact Android viewport sizes, six side-by-side buttons can become too narrow to tap reliably, and the fixed 49%–65.5% vertical placement can clip their 68 px minimum height. The layout is a real consumer of the V2 combat hand and the timed-defense reaction choices.

This patch changes the **existing** `CombatDeckHUD` scene, not the combat/deck authorities:

- `Cards` becomes `GridContainer`; six columns remain the desktop/normal-landscape default.
- Narrow landscape (<720 logical px) and portrait use three columns, two rows.
- Compact layouts (<960 logical px wide or <600 high) move the panel to a bottom safe-inset area. The 1280×720 desktop layout is restored unchanged.
- Each of the six existing buttons has a 48×68 logical-pixel minimum touch target and clips overflow labels.
- The viewport resize signal recomputes layout. All six IDs, button signals, keyboard shortcuts, V2/legacy isolation, single-defense guard and saves remain unchanged.

This is a UI accessibility/geometry correction. It does not claim complete safe-area certification for every OEM Android cutout or guarantee that every long technique label is fully readable.

## Executable regressions

The existing `tests/combat_defense_touch_window_smoke.gd` now exercises portrait 360×800, compact landscape 640×360, landscape 854×480, and desktop 1280×720, plus minimum button sizes and clipping. Existing tests still cover locked AI turn, six keyboard actions, timed defense, double-submit prevention, invalid slots, and V2/legacy hand isolation.

```bash
npm run quality
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/combat_defense_touch_window_smoke.gd
bash tools/ci/run_godot_smokes.sh godot reports/full_game_audit
```

The `Combat defense touch window` workflow executes the smoke on Godot 4.2.2 and 4.3.0. **CI must be verified on this commit; a workflow declaration is not proof of success.**

## Dependencies and promotion gates

Stack: **#175 → #177 → #180 → #181 → #182 → this PR**. The atlas #168/#179/#183, regional travel #169/#176, skill tree #167, and compatibility PRs #157/#164/#165/#166 remain separate integration work. Do not merge the stack without human approval, resolved review threads, and green required gates. `main` and persistent save schemas are unchanged.

Physical Android QA remains **PENDING**: on a real ARM64 phone, test 360-class portrait and 854-class landscape logical viewports, six card touches, one defense per window, orientation/resizing, Android cutouts/gesture navigation, keyboard 1–6, long labels, performance, and save/reload. Record device/OS, build SHA, screen captures, FPS and human sign-off.

Sprite Forge assets are untouched; generated art remains candidate-only (`shipping=false`) until provenance, license, technical QA and human approval.

**Rollback:** revert this PR's HUD script, scene, test and this note. No manager, autoload, gameplay data or save migration is involved.
