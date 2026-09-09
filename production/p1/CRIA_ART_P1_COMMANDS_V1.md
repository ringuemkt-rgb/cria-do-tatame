# CRIA ART P1 COMMANDS v1

**Status:** AUTHORING_QUEUE  
**Skill:** `.agents/skills/cria-art-direction/SKILL.md`  
**Machine source:** `production/p1/cria_art_p1_commands_v1.json`  
**Default:** `shipping=false`

This is the first visual authoring queue for the gold **Ruan × Davi** slice. It does not claim that any image, spritesheet, arena layer or UI is approved, integrated or shipping.

## Global COMMAND contract

```text
STYLE: cria-art-direction@1.0.0
AUTH: source paths listed in the machine manifest
MOBILE: preserve small-screen readability, safe area and playfield
QA: canon + identity + rights + human approval + category gates
OUT: production/candidates/p1/... + sidecars · shipping=false
```

---

# BATCH P1-CHAR-01 — 10/10 CHARACTER COMMANDS

## #CMD P1-CHAR-001 | character | lote 1/10

```text
STYLE: cria-art-direction@1.0.0
AUTH: supreme_build_contract + production_manifest_v02 + ruan canon spec
SPEC: CHAR_TURNAROUND Ruan Macacão; GI identity master; front/3-4/back; Silverback; off-white GI; black belt; fixed face/hair/body anchors; grounded feet.
MOTION: n/a technical identity sheet
MOBILE: face and silhouette survive downscale
QA: canon_match · identity_lock · anatomy · five_fingers · feet_grounded · rights · human_approval
OUT: production/candidates/p1/chars/ruan_macacao/turnaround_v1/ · shipping=false
```

## #CMD P1-CHAR-002 | character | lote 2/10

```text
SPEC: CHAR_COMBAT_POSE Ruan; side-view GI stance; pressure/top-game/grip identity; no generic striking-core silhouette.
MOTION: breathing + weight shift implied
OUT: production/candidates/p1/chars/ruan_macacao/combat_pose_gi_v1/ · shipping=false
```

## #CMD P1-CHAR-003 | character | lote 3/10

```text
SPEC: ACTION_SHEET_CORE Ruan from fighter_core profile; normalized 128x128; pivot (64,96); identity master locked; detached FX.
MOTION: idle/walk/dash/guard/hit/stagger/exhausted/technical-standup/victory/defeat
OUT: production/candidates/p1/chars/ruan_macacao/fighter_core_v1/ · shipping=false
```

## #CMD P1-CHAR-004 | character | lote 4/10

```text
SPEC: ACTION_SHEET_CLINCH Ruan; pummeling/head-position/posture-break/grip-break/defense/exit; GI contact coherent.
OUT: production/candidates/p1/chars/ruan_macacao/fighter_clinch_v1/ · shipping=false
```

## #CMD P1-CHAR-005 | character | lote 5/10

```text
SPEC: ACTION_SHEET_GROUND Ruan; guard/half/side/mount/back/turtle base poses required by the slice; stable contact line and overlap readability.
OUT: production/candidates/p1/chars/ruan_macacao/fighter_ground_v1/ · shipping=false
```

## #CMD P1-CHAR-006 | character | lote 6/10

```text
SPEC: CHAR_TURNAROUND Davi Relâmpago; unique technical-rival identity; lighter/faster silhouette; approved blue-GI direction only if human reference review confirms it; never a recolored Ruan.
OUT: production/candidates/p1/chars/davi_relampago/turnaround_v1/ · shipping=false
```

## #CMD P1-CHAR-007 | character | lote 7/10

```text
SPEC: CHAR_COMBAT_POSE Davi; side-view GI stance; reaction/scramble/counter readiness; compact athletic base.
OUT: production/candidates/p1/chars/davi_relampago/combat_pose_gi_v1/ · shipping=false
```

## #CMD P1-CHAR-008 | character | lote 8/10

```text
SPEC: ACTION_SHEET_CORE Davi from fighter_core profile; same technical frame contract, distinct reactive body language.
OUT: production/candidates/p1/chars/davi_relampago/fighter_core_v1/ · shipping=false
```

## #CMD P1-CHAR-009 | character | lote 9/10

```text
SPEC: ACTION_SHEET_CLINCH Davi; defensive pummeling, head position, grip breaks and exits readable against Ruan scale.
OUT: production/candidates/p1/chars/davi_relampago/fighter_clinch_v1/ · shipping=false
```

## #CMD P1-CHAR-010 | character | lote 10/10

```text
SPEC: ACTION_SHEET_GROUND Davi; guard/half/side/mount/back/turtle responses; frames/shrimp/scramble structure; stable identity/contact.
OUT: production/candidates/p1/chars/davi_relampago/fighter_ground_v1/ · shipping=false
```

---

# BATCH P1-TECH-01 — 7/10 PAIRED TECHNIQUES

All seven use the canonical paired phase order:

`anticipation → entry → establish → stabilize → response → recovery`

The current `slice_heel_hook` is **not** an art requirement: it exists only to exercise legality filtering in the GI fixture.

## #CMD P1-TECH-001 | paired_technique | lote 1/10

```text
AUTH: bjj_kg_slice_ruan_davi_v1:t001
SPEC: Baiana Double-Leg, Ruan attacker × Davi defender; standing_neutral → half_guard_top; six phases; shared pivot; no teleport.
MOTION: level change · entry · drive · response · landing · stabilization
QA: paired_sync · bjj_biomechanics · entry_exit_match · identity_lock_both · rights · human_approval
OUT: production/candidates/p1/techniques/t001_ruan_vs_davi_v1/ · shipping=false
```

## #CMD P1-TECH-002 | paired_technique | lote 2/10

```text
AUTH: slice_sprawl + bjj_timing_windows_v1
SPEC: Davi Sprawl + Front Headlock counter vs Ruan double-leg; hip pressure and redirect into front_headlock; no neck-twist exaggeration.
MOTION: timing telegraph · sprawl · redirect · control · stabilization
OUT: production/candidates/p1/techniques/slice_sprawl_davi_vs_ruan_v1/ · shipping=false
```

## #CMD P1-TECH-003 | paired_technique | lote 3/10

```text
AUTH: t005
SPEC: Guard Pull, Ruan × Davi; standing_neutral → closed_guard; controlled connection/descent; no slam or striking language.
OUT: production/candidates/p1/techniques/t005_ruan_vs_davi_v1/ · shipping=false
```

## #CMD P1-TECH-004 | paired_technique | lote 4/10

```text
AUTH: t025 + verified rules authority
SPEC: Body-Lock Pass, Ruan top × Davi bottom; half_guard_top → side_control; leg extraction and stabilization visible before scoring state.
OUT: production/candidates/p1/techniques/t025_ruan_vs_davi_v1/ · shipping=false
```

## #CMD P1-TECH-005 | paired_technique | lote 5/10

```text
AUTH: t049 + bjj_timing_windows_v1
SPEC: Knee-Shield Frame counter; Davi frames/recovers shield while Ruan pressure is denied; arm and shield leg readable.
OUT: production/candidates/p1/techniques/t049_davi_vs_ruan_v1/ · shipping=false
```

## #CMD P1-TECH-006 | paired_technique | lote 6/10

```text
AUTH: slice_side_to_mount + verified rules authority
SPEC: Ruan Side Control → High Mount; explicit knee/hip path, defender response and stable high-mount establishment.
OUT: production/candidates/p1/techniques/side_to_mount_ruan_vs_davi_v1/ · shipping=false
```

## #CMD P1-TECH-007 | paired_technique | lote 7/10

```text
AUTH: t057
SPEC: Armbar from High Mount; Ruan × Davi; technical setup/isolation/pivot/lock/response; no gore or injury spectacle.
OUT: production/candidates/p1/techniques/t057_ruan_vs_davi_v1/ · shipping=false
```

Slots 8–10 remain intentionally unfilled until the runtime slice proves another visual edge is actually required.

---

# BATCH P1-ARENA-01 — 10/10 ARENA LAYERS

## Arena do Dique — 5 layers

```text
#CMD P1-ARENA-001 | arena_layer | lote 1/10
SPEC: arena_do_dique.bg_far — official-event skyline/regional far layer; no HUD baked.
MOTION: distant flags · sky/water shimmer
OUT: production/candidates/p1/arenas/arena_do_dique/bg_far_v1/ · shipping=false
```

```text
#CMD P1-ARENA-002 | arena_layer | lote 2/10
SPEC: arena_do_dique.bg_mid — crowd/architecture layer; fictional event identity, no real federation/brand.
MOTION: crowd idle · banners · lights
OUT: production/candidates/p1/arenas/arena_do_dique/bg_mid_v1/ · shipping=false
```

```text
#CMD P1-ARENA-003 | arena_layer | lote 3/10
SPEC: arena_do_dique.play_area — clean central BJJ zone with strongest fighter contrast.
OUT: production/candidates/p1/arenas/arena_do_dique/play_area_v1/ · shipping=false
```

```text
#CMD P1-ARENA-004 | arena_layer | lote 4/10
SPEC: arena_do_dique.foreground — rails/edge spectators/props; cannot cover mandatory grappling silhouettes or UI.
OUT: production/candidates/p1/arenas/arena_do_dique/foreground_v1/ · shipping=false
```

```text
#CMD P1-ARENA-005 | arena_layer | lote 5/10
SPEC: arena_do_dique.particles — detachable event atmosphere; low-overdraw/reducible; no baked blur.
OUT: production/candidates/p1/arenas/arena_do_dique/particles_v1/ · shipping=false
```

## Terreiro da Luta — 5 layers

```text
#CMD P1-ARENA-006 | arena_layer | lote 6/10
SPEC: terreiro_da_luta.bg_far — Ituberá river/mangrove regional identity.
MOTION: water · boats · birds · foliage
OUT: production/candidates/p1/arenas/terreiro_da_luta/bg_far_v1/ · shipping=false
```

```text
#CMD P1-ARENA-007 | arena_layer | lote 7/10
SPEC: terreiro_da_luta.bg_mid — wood/training-community/pier context; mat remains primary read.
MOTION: students · cloth/flags · foliage
OUT: production/candidates/p1/arenas/terreiro_da_luta/bg_mid_v1/ · shipping=false
```

```text
#CMD P1-ARENA-008 | arena_layer | lote 8/10
SPEC: terreiro_da_luta.play_area — worn but cared-for training mat; uncluttered sparring zone.
OUT: production/candidates/p1/arenas/terreiro_da_luta/play_area_v1/ · shipping=false
```

```text
#CMD P1-ARENA-009 | arena_layer | lote 9/10
SPEC: terreiro_da_luta.foreground — wood/training/community objects framing playfield without blocking it.
OUT: production/candidates/p1/arenas/terreiro_da_luta/foreground_v1/ · shipping=false
```

```text
#CMD P1-ARENA-010 | arena_layer | lote 10/10
SPEC: terreiro_da_luta.particles — detachable warm dust/humidity/rain layers.
OUT: production/candidates/p1/arenas/terreiro_da_luta/particles_v1/ · shipping=false
```

---

# BATCH P1-UI-01 — 5/10 FIGHT UI COMMANDS

```text
#CMD P1-UI-001 | fight_ui | lote 1/10
AUTH: ui_theme_v2 + production_manifest_v02
SPEC: combat_hud_mobile chrome; dark/gold/off-white; gas/score/position hierarchy; no values baked.
MOBILE: safe area + playfield protected
OUT: production/candidates/p1/ui/combat_hud_mobile_v1/ · shipping=false
```

```text
#CMD P1-UI-002 | fight_ui | lote 2/10
AUTH: bjj_position_values_v1
SPEC: compact position ladder driven by runtime positional-value data; current position highlight.
OUT: production/candidates/p1/ui/position_ladder_v1/ · shipping=false
```

```text
#CMD P1-UI-003 | fight_ui | lote 3/10
AUTH: bjj_timing_windows_v1
SPEC: counter telegraph states tight/standard/generous; shape/icon + color; timing value remains runtime data.
OUT: production/candidates/p1/ui/counter_telegraph_v1/ · shipping=false
```

```text
#CMD P1-UI-004 | fight_ui | lote 4/10
AUTH: supreme_build_contract submission phases
SPEC: Submission HUD for setup/lock/technical-pressure/tap-or-escape/referee-or-recovery; no injury meter.
OUT: production/candidates/p1/ui/submission_hud_v1/ · shipping=false
```

```text
#CMD P1-UI-005 | fight_ui | lote 5/10
AUTH: ui_theme_v2 + ROADMAP touch requirement
SPEC: mobile touch-control visual kit for action/card selection and defense/counter states; runtime owns actual hit targets.
OUT: production/candidates/p1/ui/combat_touch_controls_v1/ · shipping=false
```

Slots 6–10 are intentionally reserved for assets demonstrated necessary by the integrated vertical slice rather than filled speculatively.

---

## P1 accounting

| Batch | Commands |
|---|---:|
| P1-CHAR-01 | 10 |
| P1-TECH-01 | 7 |
| P1-ARENA-01 | 10 |
| P1-UI-01 | 5 |
| **Total** | **32** |

### Explicit non-claims

- 32 commands ≠ 32 approved assets;
- generated candidate ≠ integrated asset;
- CI green ≠ human art approval;
- Android export ≠ Android physical-device visual QA;
- this P1 queue does not promote the incomplete full BJJ KG;
- this P1 queue does not promote Costa das Marés to campaign canon.
