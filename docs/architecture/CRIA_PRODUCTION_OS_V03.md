# CRIA Production OS v03

## Purpose

CRIA Production OS v03 is the fail-closed production backbone for the whole game. It separates five different facts that must never be conflated:

1. a requirement exists;
2. a candidate was generated;
3. QA passed;
4. a human approved it and rights are clear;
5. the asset is integrated and shipping.

The only valid promotion path is:

`canon/data -> derived requirement -> generated candidate -> QA -> human approval + rights -> Godot integration -> runtime evidence -> shipping`.

Concept art, chat output and reference images never jump directly to product status.

## Authorities

- Runtime: Godot only.
- Canon: active executable canon/contracts outrank visual references.
- Visual direction: `.agents/skills/cria-art-direction/SKILL.md`.
- Sprite consistency: Sprite Forge contracts and QA profiles.
- Binary registry: `assets/manifest_v2.json`.
- Requirement derivation: `data/visual/production_manifest_v03.json`.
- Whole-game completion: `data/production/game_build_matrix_v1.json`.
- Exact requirement-to-binary linkage: `production/coverage/asset_links_v1.json`.

`data/visual/production_manifest_v02.json` remains historical/compatibility input; v03 derives current requirements from consumed data instead of treating v02 counts as truth.

## Derivation

Run:

```bash
python tools/ci/derive_production_manifest_v03.py
```

The materialized manifest is written to:

`production/generated/production_manifest_v03.materialized.json`

The derivator currently reads:

- roster v3;
- arena info v1;
- narrative acts v3;
- icon manifest v1;
- legacy visual package definitions;
- the locked P1 queue;
- the Ruan x Davi KG fixture only while the full graph remains unavailable.

Missing full sources are emitted as `source_blockers`, never interpreted as empty content.

## BJJ scale rule

The fixture `data/bjj/bjj_kg_slice_ruan_davi_v1.json` is valid for the gold slice only. It cannot authorize a full-game 40/120/10 claim.

Scale unlock requires a complete full graph with at least:

- 40 positions;
- 120 techniques;
- 10 chains.

Until then, full BJJ production remains source-blocked and `slice_heel_hook` stays excluded from P1 visual production because it is a legality-test edge.

## Coverage ledger

`production/coverage/asset_links_v1.json` links a derived `requirement_id` to exact paths already present in `assets/manifest_v2.json`.

Path substring guessing is forbidden. A link may progress only when its explicit gates are present:

- `qa_passed`;
- `human_approved`;
- `rights_cleared`;
- `godot_integrated`;
- `shipping`.

Normal validation:

```bash
python tools/ci/validate_production_coverage_v03.py
```

This reports real coverage and fails only false/invalid claims.

Shipping validation:

```bash
python tools/ci/validate_production_coverage_v03.py --shipping
```

This is intentionally red until every derived requirement is shipping, every linked binary is shipping in `assets/manifest_v2.json`, and all source blockers are gone.

## Game Build Matrix

`data/production/game_build_matrix_v1.json` tracks the complete game in nine domains:

- G0 Production OS/governance;
- G1 Gold Ruan x Davi slice;
- G2 Characters/animation;
- G3 BJJ content/calibration/balance;
- G4 World/maps/hubs/arenas;
- G5 Narrative/missions/endings;
- G6 Progression/factions/economy;
- G7 Audio;
- G8 QA/accessibility/release.

A green CI run does not by itself mark a domain complete. Each domain must have the runtime/content/asset evidence named in the matrix.

## Pixel-art quality contract

All visual production is candidate-only until it passes the project art-direction and Sprite Forge gates. The production standard is the current Regional Premium 2D pixel-art direction, with nearest filtering, fixed sprite frame/pivot conventions, identity locking, paired attacker/defender synchronization for BJJ, and explicit body/FX separation.

AI generation is an offline authoring aid. It is never a runtime dependency and never grants approval.

## P1 isolation

P1 is deliberately small:

- Ruan Macacão;
- Davi Relâmpago;
- the executable slice techniques except the legality-only heel hook;
- Terreiro;
- Arena do Dique;
- fight UI needed by the slice.

A future complete KG must not silently expand P1. Full-scale technique production is a later priority batch after source promotion.

## Release policy

A full shipping claim requires:

- 100% derived requirement coverage;
- zero source blockers;
- zero invalid ledger links;
- QA, human approval and rights clearance;
- Godot integration evidence;
- platform export evidence;
- separate physical Android evidence for Android release certification.

No generator, model, plugin or CI script may bypass these gates.
