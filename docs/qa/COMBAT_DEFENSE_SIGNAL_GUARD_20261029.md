# Timed defense signal guard — 2026-10-29

**Status:** IMPLEMENTED IN STACKED DRAFT PR; CI and Android physical evidence must be checked before promotion.

## Defect and observable change

`CombatArenaBase._on_v2_defense_selected` previously accepted any nonempty shared `SignalBus.combat_v2_defense_selected` payload while a reaction was open, without checking that the ID was actually offered for Davi's current attack. A stale/synthetic signal could therefore close the reaction with an invalid choice. The arena also did not reject an event when its elapsed timer had already reached the deadline.

The existing arena now snapshots only nonempty IDs from the current `options` array (ignoring malformed rows), retains the reaction duration, and commits a defense only when:

1. `CombatManager.is_running` and the reaction is open;
2. no prior choice was committed;
3. the selected ID belongs to the current offered set;
4. elapsed reaction time is strictly below the current deadline.

The allowed set is cleared when the reaction closes or combat finishes. The existing `CombatDeckHUD` still handles native touch and keyboard slots 1–6 and locks buttons on first submission; the arena is now the final fail-closed authority for this signal. No new manager, autoload, save field, technique, scoring rule, animation or asset was introduced.

## Executable regression

The existing `tests/combat_defense_touch_window_smoke.gd` now instantiates the actual arena script without entering the scene tree (avoiding combat start and save writes). It verifies that malformed/empty offered options are excluded; forged and empty IDs cannot commit; expired inputs are ignored; a valid offered ID commits once; late duplicate signals cannot overwrite it; and stopped combat rejects further selections.

Run after checkout:

```bash
npm run quality
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/combat_defense_touch_window_smoke.gd
bash tools/ci/run_godot_smokes.sh godot reports/full_game_audit
```

The existing `Combat defense touch window` GitHub Actions workflow exercises this smoke on Godot 4.2.2 and 4.3.0. **Do not claim these commands passed until the run for the exact head SHA is inspected.**

## Dependencies, boundaries and rollback

Stack: **#175 → #177 → #180 → #181 → #182 → #184 → this PR**. #175 already consolidates the functional changes from #157/#164/#165/#166/#167/#168/#169; do not merge those original branches again. The regional-save #176, first-run #178, atlas-touch #179 and travel #183 branches still require separate reconciliation. No merge to `main` without current green required checks, review-thread reconciliation (notably #165 and #168) and independent human approval.

The Baixo Sul remains the playable scope, Ituberá is the hub, and Salvador/Itacaré remain external context. No roads or geocoordinates were added. Visual candidates remain `shipping=false` until Sprite Forge QA, rights and human review. Physical Android tests of real taps at the reaction deadline, device cutouts, six card slots, FPS and save/reload remain pending.

**Rollback:** revert the arena script, smoke test and this document from this PR. No data migration is required.
