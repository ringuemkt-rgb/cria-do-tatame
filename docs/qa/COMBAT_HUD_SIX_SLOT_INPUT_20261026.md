# Combat HUD — six-slot keyboard parity (2026-10-26)

**Status:** DRAFT — stacked PR; not merged into `main`.

## Reproduced defect

`CombatDeckHUD.tscn` renders six `Card1`–`Card6` buttons, but `CombatDeckHUD._unhandled_input` only routes `deck_card_1`–`deck_card_3`. `DeckManager._ensure_input_actions` likewise only registers keys 1–3. A player using a keyboard cannot select visible slots 4–6, including the timed defense choices that use those same buttons.

## Minimal implementation

- Extend the existing `DeckManager` input registration with physical keys **4**, **5**, **6**. Preserve the existing keys 1–3 and their three gamepad D-pad bindings. Do not assign gamepad buttons to 4–6 without an approved controller layout.
- Route all six `deck_card_N` actions through the existing guarded `CombatDeckHUD._on_card_pressed` method.
- Retain native touch via `Button.pressed`. No new manager, scene, autoload, combat rule, data schema, or save change.
- Do not promote concept art to shipping; Sprite Forge provenance, QA, rights and human approval remain required.

## Acceptance tests

`tests/combat_defense_touch_window_smoke.gd` checks keyboard registrations for 4–6, selecting the matching defense from a six-option window, double-input suppression, and unavailable slot rejection. It also retains legacy/V2 hand isolation, locked AI turn and defense window regressions.

Run:

```bash
npm run quality
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/combat_defense_touch_window_smoke.gd
bash tools/ci/run_godot_smokes.sh godot reports/full_game_audit
```

The existing Combat defense touch window CI covers Godot 4.2.2/4.3; Full Game Hardening also covers all smokes on integration to `main`. Results must be checked for **this PR head**, not inferred from parent branches.

## Android and manual QA (not yet passed)

On an Android ARM64 physical device: start Ruan × Davi, confirm six visible slots remain readable at native landscape sizes, tap slots 4–6 in a defense window, verify only one defense is emitted, then repeat after save/reload. On desktop, test keys 1–6 during the V2 fight. Measure safe-area overlap, touch hit targets, FPS and memory. Automated headless tests do not substitute for this gate.

## Dependencies and rollback

Stack: **#175 → #177 → #180 → #181 → this PR**. Regional save **#176**, first session **#178** and atlas touch **#179** remain sibling PRs to reconcile. Original **#167/#168/#169** and compatibility **#157/#164/#165/#166** must not be merged twice on top of #175.

Rollback: revert this PR's `DeckManager.gd`, `CombatDeckHUD.gd`, test and QA note. No persistent data or `main` mutation. Review unresolved threads in #165 and #168 before any integration.
