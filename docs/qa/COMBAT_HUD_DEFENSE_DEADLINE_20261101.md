# Combat HUD — reaction deadline guard (2026-11-01)

**Status:** review candidate; not merged, not Android-certified.  
**Base:** `main` at `f6330dfbb3c0ef1f0c1ba69119fbe67ddf5498ff`.  
**Scope:** `CombatDeckHUD.gd`, its existing Godot smoke, and this QA note.

## Functional defect

The arena already rejects late `combat_v2_defense_selected` signals using its authoritative elapsed time and permitted IDs. However, the HUD left defense buttons enabled when the countdown reached zero, creating a misleading touch target and allowing late input to emit a signal that the arena discarded.

## Fix and integration

The existing HUD now disables all six card buttons when a defense window is opened with nonpositive remaining time or when `set_defense_window_remaining()` reaches zero. The state is latched for that window: a later positive countdown update cannot re-enable input. A new `open_defense_window()` resets the latch. Previously submitted feedback (`DEFESA ENVIADA`) is preserved. The arena, `CombatManager`, and `SignalBus` retain authority; this change does not alter the legal reaction window, technique rules, card IDs, deck limits, animations, autoloads, or save schema.

## Regression and required gates

```bash
npm run quality
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/combat_defense_touch_window_smoke.gd
```

The existing **Combat defense touch window** workflow tests Godot 4.2.2 and 4.3.0. Added assertions cover zero-duration open, timeout after an initially valid window, synthetic touch/keyboard after timeout, stale positive countdown updates, rearming on the next AI attack, and preserving submitted feedback. No tests modify persistent saves.

## Dependencies, review, rollback

- #157 (combat action guard) is already merged; #166 (paired preview) remains a separate draft and is not pulled into this PR.
- #167/#168/#169 are already in `main`; #188 (deck editor) and #189 (skill tree mobile) remain independent drafts.
- Human review is mandatory before merge; Android physical-device reaction timing, touch targets, screen orientation and FPS remain **PENDING**.
- Rollback: revert the HUD guard commit and its smoke/doc commits; no migration required.
- Sprite Forge: no candidate asset was promoted. Provenance, licensing, actual-frame QA, and human art approval are still required for shipping.

**Canonical regional scope unchanged:** Ituberá hub; Salvador and Itacaré remain nonplayable external context. No coordinates, roads or map imagery are introduced.
