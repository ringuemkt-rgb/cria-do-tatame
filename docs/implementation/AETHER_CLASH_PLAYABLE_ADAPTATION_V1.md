# Aether Clash → Cria do Tatame — Playable Combat Adaptation V1

Status: implementation batch on `feat/aether-playable-combat-v1`, stacked on `fix/positional-combat-audit-20260929`.

## Reference

External reference repository:

- `bangtutorial/aether-clash`
- Snapshot reviewed: `1ac9751f86569b6b8c177994d5074a0d85faf94d` (Initial release, 2026-09-30)
- Source code license: MIT
- Art/audio/character assets: CC BY-NC 4.0

This adaptation uses Aether Clash as an engineering reference. No Aether character art, sprites, arenas, voices, music, logos or other CC BY-NC assets are imported into Cria do Tatame.

## What was adopted

### 1. One input path for touch and keyboard

Aether routes touch controls through the same gameplay input path used by desktop controls. Cria now follows the same principle for combat cards:

- touch/click still calls the existing card handler;
- keyboard keys `1` through `6` call that same handler;
- the same path is used during reactive defense windows;
- card labels expose the corresponding number for desktop play.

This avoids a second desktop-only combat implementation.

### 2. CPU difficulty through behavior, not stat cheating

Aether changes CPU reaction, mistakes and decision quality while preserving combat stats. Cria adapts that idea to positional grappling:

| Difficulty | Reaction delay | Mistake chance | Pattern-read strength | Candidate pool |
| --- | ---: | ---: | ---: | ---: |
| Fácil | 0.55 s | 28% | 0.35 | top 4 |
| Normal | 0.35 s | 12% | 0.65 | top 3 |
| Difícil | 0.22 s | 5% | 0.85 | top 2 |
| Pesadelo | 0.14 s | 1% | 1.00 | best |

Difficulty does **not** modify points, legal techniques, damage/HP, gas capacity or BJJ rules. It changes how quickly and how accurately Davi reads and chooses among legal actions.

### 3. Deterministic decision making

Cria already seeds combat/runtime decisions. The new difficulty behavior remains inside the existing seeded Davi AI RNG rather than introducing wall-clock randomness.

### 4. Explicit pacing and real difficulty selection

The pre-fight hub now exposes Fácil / Normal / Difícil / Pesadelo. The selected value is persisted in the pre-fight plan, threaded through CombatManager and read by the arena. Davi's actual turn reaction delay then comes from the selected AI profile instead of one fixed delay for every match.

## What was deliberately not adopted

- Aether's HP/KO victory model;
- strike hitboxes, projectile rules, anti-air, juggle or combo-stun rules;
- its Canvas/JavaScript runtime;
- its 1/120 browser simulation loop as a replacement for Godot;
- Aether match assets, sprites, audio or character kits;
- any second combat manager or parallel frontend.

Cria remains a positional BJJ game. Match authority continues to live in the existing Godot systems.

## Authority preserved

The adaptation does not replace:

- `CombatManager` — runtime orchestration;
- `BJJGraphReducerV2` / BJJ rules — legal positional transitions;
- `ScoringSystem` — stabilization, points, advantages and penalties;
- existing timer/time-decision logic;
- submission/tap termination;
- save/career/post-fight flow.

The branch inherits the #157 corrections that remove HP/gas exhaustion as grappling win conditions and resolve regulation by authoritative score.

## Files changed by this batch

- `src/combat/DaviAIController.gd`
- `src/combat/CombatCoreV2Coordinator.gd`
- `src/autoloads/CombatManager.gd`
- `scenes/combat/PreFightHub.gd`
- `scenes/combat/PreFightHub.tscn`
- `scenes/combat/CombatArenaBase.gd`
- `scenes/ui/CombatDeckHUD.gd`
- `tests/combat_action_safety_smoke.gd`
- this document

## Validation target

The combat action safety smoke now checks:

- reaction delay gets progressively shorter from Fácil → Pesadelo;
- pattern-read strength rises with difficulty;
- invalid difficulty falls back to Normal;
- selected difficulty survives pre-fight planning and reaches the fight plan;
- keyboard 1 maps to card 1;
- keyboard 6 maps to card 6;
- unrelated key 7 does not fire a combat card.

Full repository gate remains `npm run quality`; Godot smoke tests and device testing remain authoritative release gates.

## Rollback

Revert the commits on `feat/aether-playable-combat-v1`. No schema migration, save migration or imported third-party asset is required.
