# Combat Core V2 — Gold Slice

## Status

Combat Core V2 is an opt-in combat layer stacked on the Davi gold slice. It does not flip the canonical reducer authority yet.

## Authority

- CombatManager remains the only scene-level combat judge.
- BJJGraphReducerV2 is the target canonical reducer after a real parity harness exists.
- Factions may bias scouting/deck/style only.
- CriaLive may consume clip quality after a fight; it cannot change the result.
- New systems are RefCounted, not autoloads.

## Deck reconciliation

The repository already has an autoload DeckManager used by save/progression/UI. Removing it in one PR would break existing consumers.

Therefore:
- DeckManager remains a compatibility facade and persistent collection/preset store.
- CombatDeckRuntimeV2 is the per-fight deterministic RefCounted deck runtime.
- V2 is opt-in through CombatManager.prepare_combat_v2().
- Without a V2 pre-fight plan, legacy fights behave as before.

## Pre-fight flow

Terreiro -> PreFightHub -> CombatArenaBase.

PreFightHub provides:
- opponent scouting;
- deck selection 6–8;
- offensive/defensive/adaptive preset storage;
- campaign ruleset timer profile;
- GI/NO-GI toggle;
- Tinker plan preview.

## Combat flow

When V2 is prepared:
1. the selected deck is seeded;
2. six techniques are drawn;
3. only techniques in the current hand and current position are exposed as actions;
4. using a technique discards it and refills the hand;
5. opponent repetition feeds runtime scouting;
6. Tinker can surface a counter suggestion after repeated observation;
7. Virada do Cria can recover resources once per fight when the player is behind or depleted;
8. CombatManager builds deterministic clip-quality candidates on finish.

## Timers

data/combat/ruleset_timers_v1.json defines campaign gameplay profiles. They are not universal official-duration claims.

The verified scoring/legal rules remain in data/combat/bjj_rulesets_verified_v1.json.

If a timer expires before the canonical reducer flip, CombatManager emits a timer-expired event requiring authoritative resolution rather than inventing a winner.

## Parity

This PR does not claim v1≈v2 parity.

There is no reducer-v1 implementation with the same canonical state/action contract in the repository. Faking a 100% parity number would be meaningless.

What is gated now:
- V2 deterministic replay: 50 seeded cases;
- legacy compatibility through opt-in migration;
- timing accessibility floor;
- deck invariants;
- one-use comeback;
- no new combat autoloads.

Reducer authority remains blocked until an explicit comparator/harness is implemented.

## UX remaining

Tap-to-play is wired for the six-card V2 hand. Drag-to-play remains a later mobile UX enhancement and is not claimed by this slice.


## Save v6

The existing SaveManager persists DeckManager, including V2 presets introduced by this slice.

This PR does **not** claim mid-fight resume. The prepared plan and live fight state are currently runtime-only. Mid-fight serialization/restoration remains a release gate before Combat Core V2 can be called release-complete.
