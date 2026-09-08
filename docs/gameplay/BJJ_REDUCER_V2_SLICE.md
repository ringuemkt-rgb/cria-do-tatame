# BJJ Reducer V2 — Vertical Slice Contract

**Status:** DRAFT  
**Branch:** `feat/bjj-reducer-v2-slice`  
**Runtime authority:** **NO**  
**Target:** prove the Ruan × Davi graph-driven combat path without replacing the canonical `CombatManager`.

## Scope

This batch stages the first executable Knowledge Graph reducer behind a noncanonical slice fixture.

It deliberately does **not** claim that the complete F1 Knowledge Graph exists in the repository. The chat payload received so far is complete only through `t092`; the next message fragments at `t093`, and the final chains were not received intact. The canonical `data/bjj/bjj_knowledge_graph_v1.json` therefore remains absent until it can pass the full `40 positions / 120 techniques / 10 chains` promotion gate.

## Artifacts

- `data/bjj/bjj_kg_slice_ruan_davi_v1.json` — executable, noncanonical Ruan × Davi fixture;
- `src/combat/BJJGraphLoader.gd` — fail-closed loader and graph validation;
- `src/combat/BJJRulesEngineV1.gd` — versioned scoring and legality queries;
- `src/combat/BJJGraphReducerV2.gd` — pure seeded reducer;
- `src/ai/BJJUtilityScorerV2.gd` — deterministic utility ranking with stable tie-break;
- `tools/data/validate_bjj_reducer_v2_slice.py` — repository-level gate;
- `tests/test_bjj_reducer_v2_contract.py` — contract regression tests;
- `tests/bjj_reducer_v2_smoke.gd` — Godot deterministic smoke.

## Contract corrections relative to the original chat sketch

1. `base` is not treated as measured probability. Runtime authoring uses `authoring_prior`, with `empirical_success=null` until F3.
2. Static `pts:[IBJJF,ADCC]` tuples are forbidden as scoring authority. Scoring is emitted as an event and awarded only after the configured stabilization period.
3. Legality is not a `gi/nogi` boolean alone. The slice checks ruleset, modality, skill/belt division and age division.
4. Counter references are semantic objects with an explicit outcome.
5. Both attacker and defender pay resource cost when a counter is attempted.
6. Invalid or unaffordable actions do not advance the deterministic replay tick.
7. Candidate IDs are sorted and the Utility AI tie-breaks by ID to remove dictionary-order nondeterminism.
8. The reducer uses a seed/tick/action salt; it never calls `randomize()` or `randf()`.
9. The current `CombatManager`, `DeckManager`, signals and state machine remain canonical until the vertical slice adapter is proven.

## Promotion gates

The reducer may be integrated into the Ruan × Davi slice only after:

- `npm run quality` passes;
- the dedicated reducer-v2 contract workflow passes;
- Godot imports/parses the new scripts;
- identical seed + action sequence yields identical state/log;
- IBJJF and ADCC scoring tests pass with stabilization;
- legality and counter tests pass;
- the existing runtime smokes remain green.

Replacing the legacy state machine is **not** part of this batch. The next batch is an adapter into the existing `CombatManager`, preserving public APIs and rollback.

## Repository truth reconciliation

Several items previously described as “chat-only” already exist in `main` under canonical or successor names. Examples include `world_map_v4.json`, `acts_v3.json`, `endings_v2.json`, `tekuro_fragments_v2.json`, `training_exercises_v2.json`, `validate_phase1_data.py`, and `skill_graph_v1.json` (successor to the earlier `skills_v1` draft name).

Top-level `asset_registry.json` and `docs/MESTRE.md` are intentionally not introduced as competing sources of truth. Asset authority remains the existing manifest/sidecar pipeline; repository authority remains the executable production contracts plus `docs/INDEX.md`, `docs/DECISIONS.md` and repository governance.
