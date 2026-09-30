# Codex Game Assembly V1

**Status:** ACTIVE EXECUTION PLAN  
**Scope:** turn the audited repository + 2026-09-29 visual intake into a playable, testable Godot game without bypassing canon, rights, QA or human approval.  
**Machine contract:** `data/production/codex_game_assembly_v1.json`.

## Purpose

This is the long-running execution plan for Codex and other coding agents working on **Cria do Tatame – Pressão**. It does not create a second product plan. It translates the current canon, runtime, Production OS and audited visual session into a safe execution sequence.

Codex must still obey `AGENTS.md`, repository governance, the active canon/build contracts and every narrower skill loaded for the task.

## External visual material

The audited session references 43 unique constructed assets. Their machine-readable status is:

`data/visual/session_visual_intake_2026_09_29.json`

The private binary archive is:

`cria_visual_master_pack_2026-09-29.zip`

Expected SHA-256:

`2de0f1cd6b5ea2756a57b4a561d185e98df62b500b6373d284938edad3431e05`

When the archive is available in the Codex workspace, verify the hash before reading any binary. If it is absent, continue only with metadata/code/data work. Never fabricate the missing images and never silently substitute unrelated art.

## Execution rule

Every Codex task must be a small vertical batch with:

1. observable goal;
2. exact source authorities;
3. consumer in the existing Godot runtime;
4. validation commands;
5. rollback path;
6. explicit distinction between candidate, approved, integrated and shipping.

Do not treat prompts, boards, concept art or a generated PNG as a completed feature.

## C0 — Bootstrap and repository truth

Before editing:

- read the mandatory files listed in `AGENTS.md`;
- inspect current open PRs/issues touching the same subsystem;
- run or confirm the current baseline;
- do not revive old PRs by bulk merge;
- port only still-useful work into a current branch.

Required baseline:

`npm run quality`

When runtime files are touched:

`godot --headless --editor --path . --quit`

and relevant Godot smoke tests.

## C1 — Ruan × Davi identity lock

Primary audited candidates:

- `ruan_turnaround_v2_beard_pixel`
- `davi_identity_action_sheet_v1`

The session images are references/candidates only. Produce approved identity masters only after:

- canon match;
- face/hair/body consistency;
- no real-person likeness;
- rights/provenance record;
- human approval;
- Sprite Forge normalization;
- 128×128 gameplay frame requirements where applicable;
- pivot `[64,96]` and grounded feet.

Do not use `ruan_combat_pose_alt_hair_v1` as identity authority because the intake marks it as identity drift.

## C2 — Gold combat slice

Use the current slice fixture:

`data/bjj/bjj_kg_slice_ruan_davi_v1.json`

Visuals must follow attacker/defender paired animation semantics. Codex may implement and integrate only graph-authorized transitions. `CombatManager` remains the scene authority.

Priority technique chain begins with the existing slice transitions and their verified counters. Do not infer missing full-graph techniques from the truncated historical F1 payload.

For paired visuals, load:

- `.agents/skills/cria-art-direction/SKILL.md`
- `.agents/skills/cria-sprite-forge/SKILL.md`
- `.agents/skills/cria-combat-intelligence/SKILL.md`
- motion-lab skill when video/mocap evidence is involved.

## C3 — Terreiro + Arena do Dique + fight UI

Build the first complete visual loop before expanding the world:

- Terreiro environment layers;
- Arena do Dique environment layers;
- combat HUD;
- position ladder;
- counter telegraph;
- submission HUD;
- mobile touch controls;
- Ruan/Davi runtime sprites.

All UI must remain data-driven and mobile-readable.

## C4 — Map system from all map references

The 10 core map pages are **style anchors**, not flat runtime screens.

Rebuild them as layered content:

`base art -> terrain/water -> structures -> routes -> nodes -> faction control -> collectables -> locks/secrets -> weather/tide -> Godot labels/UI`

Use all five overlay references to derive systems for:

- regional resources;
- Teruko memory fragments;
- PF evidence dossiers;
- CriaCoin caches;
- faction control;
- route state;
- tide/climate effects.

Mutable state must not be baked into base map textures.

The four `Costa das Marés` assets remain expansion references until a separate canon decision promotes the region.

## C5 — Faction banners and technique cards

Faction visual references:

- LEM and NTM light/dark variants may guide ceremonial/UI styling;
- ALE variants must not ship with the incorrect text `Os Aleluiados`;
- runtime display name remains **Os Aleluiado**.

Prefer image-only emblems/frames plus Godot-rendered localized text.

Technique card references define visual grammar, not authoritative stats. Runtime card data comes from game data.

Current direct mapping from the audited session:

- `card_chave_de_braco_t057_v1` -> `t057` visual reference.

The Tesoura, Joelho na Barriga, Mata-leão and Kimura boards remain layout references until their runtime technique IDs/data are resolved.

## C6 — Campaign assembly

Connect existing systems into the mandatory flow:

`Main Menu -> Terreiro -> treino/deck -> combate -> resultado -> Cria Live -> avanço da semana -> save -> Terreiro`

Then extend through the approved acts, missions, factions, economy, map, fragments and endings without creating parallel managers.

## C7 — Release hardening

A green CI export is not physical-device evidence.

Before any Android release-ready claim:

- automatic repository/data/runtime checks green;
- Android export succeeds;
- install and run on physical Android hardware;
- input, save/load, combat, UI scale and performance are recorded;
- release ledger is updated with evidence.

## Material consumption policy

All 43 audited assets must have a disposition, but **not all must become runtime binaries**.

- core maps: consume as style/system references;
- expansion maps: retain as hold/reference;
- map overlays: convert into data-driven mechanics;
- faction banners: convert into canonical emblem/frame language;
- character candidates: promote only through identity lock;
- character concept boards: keep reference-only unless canon/roster promotes them;
- private likeness material: keep blocked/private unless explicit clearance and policy change exist;
- technique cards: extract art/layout language, render gameplay values from data.

This is what “use all material” means under repository governance: no useful information is lost, and no blocked material is smuggled into shipping.

## Codex task prompt

Use this as the default start prompt in Codex:

> Work on `ringuemkt-rgb/cria-do-tatame`. Read `AGENTS.md` first, then `docs/production/CODEX_GAME_ASSEMBLY_V1.md` and `data/production/codex_game_assembly_v1.json`. Inspect current main and open PRs before editing. Execute only the next smallest vertical batch that moves the mandatory Godot flow toward a playable Ruan × Davi gold slice. Reuse existing managers and data. Run required tests, commit focused changes, report exact evidence and never claim candidate art is shipping.

## Progress log

Codex should append a short dated entry here only when a milestone materially advances. Each entry should state commit/PR, tests and remaining blocker. Do not use this file as a substitute for issue/PR history.

### 2026-09-30 — C0 bootstrap quality repair

Batch: `fix/codex-assembly-bootstrap-quality`, based on PR #159 at
`4cc6aad1df3590fe832540148e06e073f1d15dc2`. Related to #103.

- Reproduced the mandatory baseline failure: Davi's `counter_entry` had no QA
  profile. `sprawl_response`, `scramble` and `counter_whiff` were also unmapped.
- Ported only the profile mappings and all-character adapter regression from
  commit `513822211917acbaf48171e45c608ab43939d8c4` (#138, also reused in #157).
  Existing thresholds, custom signature overrides and approval gates remain.
- Repository Quality now runs `npm run quality` and triggers for PRs against
  any base, including stacked PRs. Nine green workflows on #159 had not run
  this full gate because Repository Quality only targeted `main`.
- Validation: full `npm run quality` PASS; workflow YAML parse and checks for
  stacked-PR trigger/full gate PASS. Runtime and scene files were not changed.
- External master pack is absent; its expected SHA-256 was not verified.
  The four accessible JPEG attachments visually correspond to the existing
  Salvador, Interior Norte, Cairu and Interior Sul style references. They do
  not supply Ruan/Davi identity masters or separated runtime map layers.
- C1 remains blocked on the verified master pack and recorded identity,
  human/rights approval. No visual material was promoted. Next batch is C1
  when its prerequisites are available; Android/device and release gates
  remain pending. Rollback: revert this focused bootstrap batch.
