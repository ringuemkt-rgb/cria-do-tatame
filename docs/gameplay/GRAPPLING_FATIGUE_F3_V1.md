# CRIA Grappling Fatigue + F3 Calibration V1

## Status

`SHADOW_CALIBRATION_ONLY` / `shipping=false`.

This layer exists to make fatigue observable, deterministic and calibratable before it is allowed to influence gameplay probability or cost.

It does **not** replace reducer gas, scoring, legality, RNG or winner state.

## Why a second state exists beside gas

The current reducer already owns a simple global `gas` resource. That remains useful for immediate action affordability and deterministic gameplay.

However, grappling fatigue is not well represented by one number alone. Repeated BJJ competition research supports tracking at least broad systemic and local effects, including forearm/grip and lower-limb fatigue, with incomplete recovery between repeated matches.

V1 therefore tracks six normalized shadow dimensions per athlete:

- systemic;
- forearm/grip;
- upper-body isometric;
- trunk isometric;
- lower body;
- recovery debt.

These dimensions are not medical measurements and are not injury models.

## Evidence boundary

The contract records two research anchors:

- PMID `39467539`, DOI `10.1123/ijspp.2023-0546`;
- PMID `25559902`, DOI `10.1519/JSC.0000000000000819`.

They justify the **structure** of local/repeated-match fatigue. They do not provide direct gameplay coefficients.

All V1 coefficients are explicitly `UNCALIBRATED_AUTHORING_PRIOR` and remain non-authoritative.

## Runtime flow

```text
BJJGraphReducerV2
        ↓
authoritative combat result
        ├── position / score / gas / winner
        ├── physical state
        ├── motion request
        └── GrapplingFatigueModelV1
                  ↓
            SHADOW ONLY
```

The fatigue model observes:

- accepted attack attempts;
- successful counters;
- reducer-owned gas delta;
- stabilization duration;
- explicit between-match rest.

It never writes back to reducer state.

## Gold-slice load profiles

`data/combat/grappling_fatigue_profiles_slice_v1.json` contains qualitative authoring profiles for the seven techniques used by the Ruan × Davi golden chain.

Loads are expressed only as:

```text
UNKNOWN
LOW
MODERATE
HIGH
VERY_HIGH
```

The corresponding scalar map exists solely so the deterministic shadow state can be exercised in tests.

`opponent_load` remains `UNKNOWN` for every profile in V1. We do not infer the other athlete's local load from a technique name or animation.

## Between-match persistence

Fatigue may be carried into a subsequent match through the optional residual state argument of `CriaGrapplingRuntimeV1.new_match()`.

This deliberately does not carry:

- score;
- reducer gas;
- winner;
- position;
- RNG tick.

`rest_fatigue(seconds)` reduces each local dimension independently using authoring recovery priors, while preserving combat state byte-for-byte.

No automatic full reset is permitted by the V1 contract.

## F3 empirical calibration

`tools/combat/f3_calibrate_bjj_v1.py` is report-only.

Eligible rows must be:

- expert approved;
- rules approved;
- rights eligible for calibration;
- assigned to `train`, `validation` or `holdout`;
- attributable to a source event and athlete-pair group;
- hashed/provenanced;
- binary-success eligible (`SUCCESS`, `FAILURE` or `COUNTERED`).

`ABORTED` and `UNCERTAIN` are not silently converted into failures.

### Leakage protection

Rows sharing the same source event or athlete-pair group may not cross data splits.

This prevents nearly identical exchanges, repeated clips or the same pair from contaminating holdout estimates.

### Current statistical report

For each stratum:

```text
technique
× source position
× ruleset
× modality
× skill band
```

F3 reports:

- n;
- successes;
- failures/countered attempts;
- candidate empirical proportion;
- Wilson 95% interval;
- small-sample warning.

The current promotion minimum `n` is intentionally unset. It must be approved before any runtime effect activation.

## Current corpus truth

`data/research/f3_observation_ledger_v1.json` is intentionally empty.

Therefore the only valid current F3 result is:

```text
DATA_PENDING
eligible_observations = 0
runtime_effect_active = false
```

The command below must succeed as a report:

```bash
python tools/combat/f3_calibrate_bjj_v1.py
```

The stricter gate must fail today:

```bash
python tools/combat/f3_calibrate_bjj_v1.py --require-data
```

A green repository does not mean F3 is complete.

## Gameplay activation gate

`GrapplingFatigueModelV1.projected_effect()` returns:

```text
active = false
success_multiplier = 1.0
cost_multiplier = 1.0
reason = F3_NOT_APPROVED
```

A future calibrated effect requires a separate PR after:

1. a rights-cleared observation corpus exists;
2. holdout evidence exists;
3. sample policy is approved;
4. expert review is recorded;
5. modality/ruleset/skill strata are evaluated;
6. calibration and uncertainty reports pass;
7. deterministic replay and balance tests remain green.

## Relationship to F4

F3 estimates observations.

F4 tunes the game.

They are intentionally different:

```text
F3: what was observed?
F4: what produces a fair, expressive game?
```

An empirical rate is not automatically a good gameplay probability, and a gameplay-tuned value must never be relabeled as empirical evidence.

## Validation

```bash
python tools/combat/validate_grappling_fatigue_f3_v1.py
python tools/combat/f3_calibrate_bjj_v1.py
python -m unittest discover -s tests -p 'test_grappling_fatigue_f3_v1.py'
godot --headless --path . --script res://tests/grappling_fatigue_f3_smoke.gd
npm run quality
```

## Definition of success for V1

V1 is successful when:

- fatigue state is deterministic;
- local dimensions can accumulate and recover;
- residual state can cross matches;
- rejected actions do not create fatigue evidence;
- countered attempts can load both participants without altering reducer outcomes;
- uncalibrated profiles remain visibly uncalibrated;
- F3 data leakage is rejected;
- empty evidence remains `DATA_PENDING`;
- reducer state is identical with or without the shadow observer.
