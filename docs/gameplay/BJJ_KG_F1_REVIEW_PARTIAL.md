# BJJ Knowledge Graph F1 — Partial Technical Review

**Status:** PARTIAL INPUT REVIEW  
**Input received:** positions + techniques `t001` through the beginning of `t093`; the message was truncated before the full 120-technique payload and chains were received.  
**Runtime authority:** none.

## Source/rules verification

Rules were re-checked against current official sources on 2026-09-07:

- IBJJF Rule Book v6.0 index: https://ibjjf.com/books-videos
- ADCC Championship Rules & Regulations: https://adcombat.com/adcc-rules-regulations/

The graph must reference `data/combat/bjj_rulesets_verified_v1.json`; rules are not owned by static `pts:[ibjjf,adcc]` tuples.

## Critical corrections before graph promotion

### 1. ADCC scoring in the supplied draft is incorrect

The draft states ADCC mount=4 and back=4. Current ADCC championship rules state:

- mount = 2;
- back mount with hooks/body triangle = 3;
- pass = 3;
- knee on stomach = 2;
- takedown to guard/half = 2;
- clean takedown past guard = 4;
- sweep to guard/half = 2;
- clean sweep past guard = 4;
- scoring positions require at least 3 seconds of stabilization and no active submission danger.

Therefore `mount_low`, `mount_high`, `smount`, `back_mount_hooks`, `back_mount_seatbelt`, and `back_no_hooks` cannot carry `[4,4]` as universal position metadata.

### 2. Seatbelt/no-hooks are control states, not automatic scoring states

`back_mount_seatbelt` and `back_no_hooks` must not grant automatic four-point IBJJF or three-point ADCC back scores. Scoring requires the ruleset-defined configuration and stabilization.

### 3. Perspective/top-bottom model is under-specified

The 40-position draft contains bottom guard nodes but almost no equivalent top-guard nodes. As a result, many sweeps are authored as:

`bottom guard -> mount_low`

Examples in the received fragment include `t033`, `t034`, `t035`, `t036`, `t037`, `t038`, `t040`, `t041`, `t042`, `t043`, `t044`, `t045`, `t046`, `t047`, `t048`.

This creates artificial positional teleportation. A realistic graph needs either:

1. actor-relative role metadata and target states such as `top_closed_guard`, `top_open_guard`, `top_half_guard`; or
2. joint-state nodes representing both athletes' roles.

F1 contract chooses **actor-relative** and requires `actor_role_from` / `actor_role_to`.

### 4. Closed guard cannot be treated as a direct knee-cut state

`t021` currently maps `closed_guard -> side_control` as Knee-Cut. A knee-cut requires the guard to have opened and normally proceeds through an open/half/headquarters-like state. The graph should expose the opening/transition rather than hide it inside the pass if fidelity is the goal.

### 5. Several gi/no-gi flags are too restrictive or inverted

Received examples requiring review:

- `t003 Osoto-Gari`: marked no-gi false, although osoto variants are viable without gi grips;
- `t006 Sumi-Gaeshi`: marked no-gi false, although no-gi sumi/overhook variants exist;
- `t008 Body-Lock Takedown`: marked gi false, although body-lock takedowns are possible in gi as well;
- `t009 Ankle Pick`: marked gi false, although ankle picks are used in gi;
- `t039 Berimbolo`: marked gi false / no-gi true; classic berimbolo is strongly associated with gi but no-gi variants also exist. It should not be represented as no-gi-only.

These should become availability/profile tags, not simplistic exclusivity where unnecessary.

### 6. Leg-lock legality needs more than gi/no-gi booleans

`t075`–`t079` and related entries cannot be made legal/illegal from `gi` and `nogi` alone. Legality depends on organization, age, belt/skill division and event rules. Use a legality matrix.

### 7. `half_guard_top -> clinch_bodylock` conflates ground and standing semantics

`t052 Underhook da Meia` currently exits to `clinch_bodylock`, defined as a standing clinch state. A half-guard underhook commonly leads to dogfight, coming-up, back exposure or a ground body-lock passing/control state. Introduce the missing intermediate state or rename the target semantics.

### 8. Back-take points must be scored after control is established

`t083` and `t084` attach points directly to turtle-to-back transitions. The transition can create a scoring opportunity, but points should be emitted only after the rules engine sees the required back-control configuration and stabilization.

### 9. Counter IDs need outcomes, not only references

A field such as `counters:["t111","t080"]` is useful for discovery but insufficient for execution. Each counter relationship needs an outcome such as:

- `deny_to_same_state`;
- `redirect_to_scramble`;
- `reverse_to_top`;
- `submission_threat`;
- `reset_to_neutral`.

### 10. Authoring success values are allowed only as priors

The supplied numeric `base` values may be retained as **authoring priors**, but they must be renamed/represented as:

```json
{
  "authoring_prior": 0.55,
  "prior_status": "UNCALIBRATED_EXPERT_HEURISTIC",
  "empirical_success": null
}
```

They are not measured success rates. F3 may add empirical values with dataset/sample provenance. F4 RL output is gameplay tuning and must not masquerade as real-world frequency.

## Accepted concepts from the partial payload

The following concepts are directionally sound and should remain in the F1 design:

- standing / clinch / guard / half / dominant / defensive / leg-entanglement categories;
- explicit grip/tie states;
- technique edges with costs and counter relations;
- chains as paths through the graph;
- rule-set-specific legality;
- separation of authoring prior, empirical calibration and RL balance.

## Gate for the full payload

Do **not** create or promote final `data/bjj_knowledge_graph.json` from the truncated message. The complete payload must be parsed and validated as a whole so that:

- all 120 technique IDs exist exactly once;
- all counters resolve;
- all 10 chains are continuous;
- every position is reachable or intentionally terminal;
- all gi/no-gi/legality declarations are reviewed;
- scoring references the versioned ruleset authority;
- authoring priors are marked uncalibrated;
- no F1 file claims runtime or empirical authority.
