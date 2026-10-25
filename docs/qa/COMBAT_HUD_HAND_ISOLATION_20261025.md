# HUD combat hand isolation — 2026-10-25

**Status:** DRAFT / not integrated into `main`.

## Reproduced code path and impact

`CombatDeckHUD` subscribes to both `SignalBus.combat_deck_hand_changed` (legacy DeckManager cards) and `SignalBus.combat_v2_hand_changed` (CombatManager technique IDs). After entering V2, a late legacy hand refresh previously overwrote the V2 button labels and `card_id` metadata. In the legacy path, refreshing a hand while `_actions_enabled=false` could also paint a compatible button as enabled, even though the press handler rejected the action.

## Minimal runtime change

In the existing `scenes/ui/CombatDeckHUD.gd`:
- ignore legacy hand refresh while `v2_mode` or `defense_mode` is active;
- keep legacy card buttons disabled while `_actions_enabled` is false;
- leave CombatManager, DeckManager, defense signal, card IDs, saves and rules untouched.

The initial legacy hand is still rendered before V2 mode starts. Once V2 is active, `_on_v2_hand_changed` and `close_defense_window` restore the authoritative technique hand.

## Regression and gates

Extended `tests/combat_defense_touch_window_smoke.gd` to check:
1. legacy card available on an unlocked turn;
2. legacy refresh cannot visually re-enable cards during AI lock;
3. unlock restores legacy card state;
4. switching to V2 binds technique ID;
5. late legacy refresh cannot replace that V2 ID or stored V2 hand;
6. existing timed defense, single-submit, malformed option and re-open tests remain active.

Existing workflow `Combat defense touch window` runs `npm run quality` and imports/executes this smoke on Godot 4.2.2 and 4.3.0. CI must be green **on this branch head** before promotion. Also require a human review and Android physical-device touch playtest: enter Ruan × Davi, receive a V2 hand, trigger a legacy DeckManager update, verify the hand stays V2, test Davi defense, and check buttons remain locked during the AI turn. No physical test is claimed here.

## Dependency and rollback

Stack: **#175 → #177 → #180 → this PR**. PRs #176 (regional save), #178 (first session) and #179 (atlas native touch) are sibling changes requiring reconciliation and joint regression before merging to `main`. Existing #157/#164/#165/#166/#167/#168/#169 are absorbed only through the reviewed integration path. No new manager, runtime, asset, coordinate, migration or APK.

Rollback: revert this PR's HUD and test commits. The legacy/V2 hand fix has no save or data migration. Keep art candidates under Sprite Forge review; no `shipping=true` promotion.
