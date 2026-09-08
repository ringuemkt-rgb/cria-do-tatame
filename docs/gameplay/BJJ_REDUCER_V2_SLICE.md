# BJJ Reducer V2 — Vertical Slice Contract

**Status:** DRAFT  
**Foundation:** `main@4af5a62c`  
**P1 branch:** `feat/bjj-p1-positional-timing`  
**Runtime authority:** **NO**  
**Target:** prove the Ruan × Davi graph-driven combat path without replacing the canonical `CombatManager`.

## Scope

This line stages the executable Knowledge Graph reducer behind a noncanonical slice fixture and hardens two P1 concerns: positional legibility/utility and touch counter timing.

It deliberately does **not** claim that the complete F1 Knowledge Graph exists in the repository. The chat payload received so far is complete only through `t092`; the next message fragments at `t093`, and the final chains were not received intact. The canonical `data/bjj/bjj_knowledge_graph_v1.json` therefore remains absent until it can pass the full `40 positions / 120 techniques / 10 chains` promotion gate.

## Artifacts

- `data/bjj/bjj_kg_slice_ruan_davi_v1.json` — executable, noncanonical Ruan × Davi fixture;
- `data/combat/bjj_position_values_v1.json` — V.5 positional hierarchy tuning for Utility AI and future HUD ladder;
- `data/combat/bjj_timing_windows_v1.json` — V.9 touch counter timing and telegraph tiers;
- `src/combat/BJJGraphLoader.gd` — fail-closed loader and graph validation;
- `src/combat/BJJRulesEngineV1.gd` — versioned scoring and legality queries;
- `src/combat/BJJTimingPolicyV1.gd` — deterministic timing-window policy;
- `src/combat/BJJGraphReducerV2.gd` — pure seeded reducer with timing-aware counters;
- `src/ai/BJJUtilityScorerV2.gd` — deterministic utility ranking using versioned positional tuning;
- `tools/data/validate_bjj_reducer_v2_slice.py` — repository-level gate;
- `tests/test_bjj_reducer_v2_contract.py` — contract regression tests;
- `tests/bjj_reducer_v2_smoke.gd` — Godot deterministic smoke.

## Contract corrections relative to the original chat sketch

1. `base` is not treated as measured probability. Runtime authoring uses `authoring_prior`, with `empirical_success=null` until F3.
2. Static `pts:[IBJJF,ADCC]` tuples are forbidden as scoring authority. Scoring is emitted as an event and awarded only after the configured stabilization period.
3. Legality is not a `gi/nogi` boolean alone. The slice checks ruleset, modality, skill/belt division and age division.
4. Counter references are semantic objects with an explicit outcome.
5. Both attacker and defender pay resource cost when an in-window counter is attempted.
6. Invalid or unaffordable actions do not advance the deterministic replay tick.
7. Candidate IDs are sorted and the Utility AI tie-breaks by ID to remove dictionary-order nondeterminism.
8. The reducer uses a seed/tick/action salt; it never calls `randomize()` or `randf()`.
9. The current `CombatManager`, `DeckManager`, signals and state machine remain canonical until the vertical slice adapter is proven.

## P1 — V.5 positional values

The former hardcoded table in `BJJUtilityScorerV2` has been replaced by `data/combat/bjj_position_values_v1.json`.

Authoring bands:

```text
back mount      1.00
mount           0.90
side            0.75
knee-on-belly   0.70
pass progress   0.60  (transient HUD band, not a KG node)
half top        0.50
neutral         0.45
guards bottom   0.40
half bottom     0.35
turtle          0.25
```

These are **AUTHORING_INITIAL / UNCALIBRATED_AUTHORING** values. They are tuning inputs, not empirical claims. Front headlock, leg-entanglement positions, scramble and guard-jump remain explicitly unmapped and use the neutral fallback `0.45` until expert/playtest values are approved. The implementation intentionally does not invent values for them.

The Utility AI consumes the positional authority now. The same file exposes `hud_ladder`, but the production HUD does **not** consume it yet; that wiring belongs to the upcoming `CombatManager` adapter batch so D2 is preserved and no orphan UI authority is introduced.

## P1 — V.9 touch counter timing

`data/combat/bjj_timing_windows_v1.json` establishes an authoring floor of **250 ms** for touch counters and three playtest tiers:

```text
tight      250 ms · short telegraph
standard   350 ms · medium telegraph
generous   450 ms · long telegraph
```

The values are **AUTHORING_INITIAL / UNCALIBRATED_AUTHORING**. They require device playtest; they are not presented as universal reaction-time thresholds.

Counter relations now carry a `timing_tier`. `BJJGraphReducerV2` reads `defense_elapsed_ms` and:

- accepts a counter only inside the configured window;
- logs `counter_late` when the response is late;
- does not spend defender gas for a late input;
- continues resolving the attack after a late counter;
- exposes `counter_timing` metadata through `query()` so a future HUD can render the telegraph/window from the same authority.

This P1 batch covers **BJJ counter timing only**. It does not claim that a generic fighting-game parry system has been integrated.

## Promotion gates

The reducer line may advance into the Ruan × Davi runtime adapter only after:

- `npm run quality` passes;
- the dedicated reducer-v2 contract workflow passes;
- Godot imports/parses the new scripts;
- identical seed + action sequence yields identical state/log;
- IBJJF and ADCC scoring tests pass with stabilization;
- legality and semantic counter tests pass;
- touch timing floor/tier tests pass;
- in-window and late-counter Godot smokes pass;
- positional-value Utility ordering is exercised in Godot;
- the existing runtime smokes remain green.

Replacing the legacy state machine is **not** part of P1. The next batch is an adapter into the existing `CombatManager`, preserving public APIs and rollback, followed by real HUD ladder/telegraph wiring for Ruan × Davi.

## Repository truth reconciliation

Several items previously described as “chat-only” already exist in `main` under canonical or successor names. Examples include `world_map_v4.json`, `acts_v3.json`, `endings_v2.json`, `tekuro_fragments_v2.json`, `training_exercises_v2.json`, `validate_phase1_data.py`, and `skill_graph_v1.json` (successor to the earlier `skills_v1` draft name).

Top-level `asset_registry.json` and `docs/MESTRE.md` are intentionally not introduced as competing sources of truth. Asset authority remains the existing manifest/sidecar pipeline; repository authority remains the executable production contracts plus `docs/INDEX.md`, `docs/DECISIONS.md` and repository governance.
