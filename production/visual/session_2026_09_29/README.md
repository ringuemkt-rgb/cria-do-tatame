# Session Visual Intake — 2026-09-29

This directory documents the handoff from session-generated visual material into the governed CRIA production system.

## What is stored in Git

Only metadata and review decisions are stored in the public repository:

- `data/visual/session_visual_intake_2026_09_29.json`;
- `docs/qa/VISUAL_MATERIAL_REVIEW_2026_09_29.md`.

The large visual archive itself is intentionally **not committed** because:

1. reference/candidate art is not runtime art;
2. some items contain real-person likeness and must remain private;
3. many images have baked mutable UI and require reconstruction;
4. promotion requires exact provenance, rights, QA and human approval;
5. the repository must not become a concept-art dump.

## Private master archive

Expected external/private artifact:

`cria_visual_master_pack_2026-09-29.zip`

SHA-256:

`2de0f1cd6b5ea2756a57b4a561d185e98df62b500b6373d284938edad3431e05`

Contents:

- 43 unique constructed visuals;
- full machine-readable visual catalog;
- review report;
- contact sheet;
- organized reference directories.

Excluded:

- two raw real-person photos;
- one exact duplicate.

## How production should consume the intake

Do **not** copy an archived image directly into a shipping path.

Use the asset IDs from the intake as references in a work order, then satisfy the active contracts:

### Characters

`reference -> human identity selection -> identity master -> normalized frames -> Sprite Forge -> Godot`

Preferred current references:

- `ruan_turnaround_v2_beard_pixel`;
- `davi_identity_action_sheet_v1`.

### Maps

`reference screenshot -> layered map specification -> base art + data-driven nodes/routes/overlays -> MapAtlasPresenter`

Priority reference:

- `map_core_02_itubera`.

### Cards

`layout reference -> authoritative technique/card data -> central art -> dynamic Godot shell`

Closest current card candidate:

- `card_chave_de_braco_t057_v1`.

### Factions

LEM/NTM are style anchors. ALE must be regenerated with the canonical display name **Os Aleluiado**.

## Existing execution tracks

This intake must feed, not duplicate:

- PR #147 — visual production queue;
- PR #144 — P1 fight graphics execution;
- issue #103 — Premium Pixel Art P1.

Every resulting binary still starts with `shipping=false`.
