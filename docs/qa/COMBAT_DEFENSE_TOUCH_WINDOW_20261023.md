# Combat defense touch window — 2026-10-23

**Status:** draft patch, awaiting CI and human/mobile QA. **Base:** integration PR #175; do not merge directly to main.

## Observable defect

`CombatArenaBase._execute_player_action()` locks ordinary player actions with `_set_actions_enabled(false)` while Davi's AI turn executes. `_await_player_defense()` opens the reaction window before re-enabling ordinary actions. Previously, `CombatDeckHUD._on_card_pressed()` rejected **all** presses while `_actions_enabled == false`, including valid timed defense buttons. The defender therefore timed out even after tapping a visible enabled option.

## Runtime change

- In `CombatDeckHUD`, reject ordinary attack/deck selections while actions are locked, but permit the visible enabled defense buttons when `defense_mode` is true.
- Keep the existing authoritative `CombatManager` and `SignalBus.combat_v2_defense_selected` path; do not alter technique legality, clock, scoring, animation, or save schema.
- Ignore regular hand-refresh signals during the defense window so a concurrent deck update cannot replace the defense choices.
- Closing the window restores the existing lock behavior, so a stale tap cannot issue an attack or defense.

## Automated evidence

`tests/combat_defense_touch_window_smoke.gd` instantiates the real `CombatDeckHUD.tscn`, simulates the existing AI-turn lock, opens a valid/invalid defense option, presses buttons, checks emitted signals, refreshes the hand during the window and checks stale taps after close. `.github/workflows/combat-defense-touch-window-smoke.yml` executes the smoke with Godot 4.2.2 and 4.3.

## Human Android gate (not yet passed)

On a physical Android device, enter the Ruan × Davi match, allow Davi to attack, press a visible defense card within the 1.15-second reaction window and confirm that the defense branch resolves in the match log. Repeat with a late tap and a disabled option; verify no ghost actions, overlap, clipped touch targets or unresponsive controls at 1280×720 and a narrower phone aspect ratio. Capture logs, FPS and device model.

## Dependency and rollback

This patch is stacked on integration PR #175 and independent of the regional-save PR #176. It must not be merged before its base and required review/gates are approved. Rollback: revert the single HUD code commit; the regression test and workflow may be retained for diagnosis. No asset is promoted to shipping by this patch.
