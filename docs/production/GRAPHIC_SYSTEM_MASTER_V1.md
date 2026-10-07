# CRIA DO TATAME — GRAPHIC SYSTEM MASTER v1

**Status:** AUTHORING / `shipping=false`  
**Runtime:** Godot 4.3+ only  
**Auxiliary authoring lab:** Unity Essentials allowed only for preview, blocking, composition and neutral export  
**Visual authority:** `.agents/skills/cria-art-direction/SKILL.md` + `.agents/skills/cria-sprite-forge/SKILL.md`  
**Canon authority:** `data/production/canon_contract_v4_1.json`

## 1. Mission

Turn the current CRIA DO TATAME visual direction into a complete, production-grade, mobile-first graphic system. This document is not a second canon source and does not promote generated material automatically.

The final visual language is **HD Pixel Art 2.5D Regional Premium**: Brazilian, Bahian, coastal, tactile and readable on small screens. It must never drift into generic anime, generic medieval fantasy, smooth-vector mobile art or photorealistic 3D.

## 2. Visual DNA

Core regional anchors:

- Ituberá and Baixo Sul da Bahia;
- river, mangrove, sea, docks, boats, bridges and tidal landscape;
- tropical vegetation, cacao, piaçava, clay, wood and tiled roofs;
- market, gym, warehouse, waterfall, road, island and coast;
- Brazilian Jiu-Jitsu positional combat;
- strength as care, discipline, belonging and honor.

### Palette

| Token | Hex | Use |
|---|---|---|
| ink | `#0B0B0D` | deep panels/background |
| gold | `#C9971C` | ornament/important borders |
| off_white | `#EDE6D6` | text/gi/highlights |
| river_blue | `#1E3A5F` | water/cool shadows |
| mangrove_green | `#2D5016` | vegetation |
| terracotta | `#B85C38` | earth/roof/accent |
| sand_wood | `#D4A574` | sand/wood |
| danger | `#8B0000` | danger only |
| avesso | `#4B0082` | secrets/Avesso |

Gameplay faction accents remain data-driven:
- ALE `#FF9408`;
- LEM `#4A6741`;
- NTM `#3FE3F5`;
- institutional `#1E3A5F`.

Ceremonial variants:
- ALE: royal blue + gold + white;
- LEM: purple/wine + gold;
- NTM: red/orange + gold.

## 3. Pixel contract

All gameplay character frames:

- `128x128 RGBA`;
- upright pivot `[64,96]`;
- nearest-neighbor only;
- integer scaling only;
- smoothing disabled;
- clean alpha;
- 1–2 px outline target;
- stable content bounds;
- clear mobile silhouette;
- detached FX by default;
- approximately 72 px useful character height in combat.

Generated images are never runtime-ready by default.

## 4. Character identity package

Every recurrent fighter requires an identity lock **before** dense animation production.

Minimum identity package:

```
identity_master.png
turnaround_front.png
turnaround_3q.png
turnaround_side.png
turnaround_back.png
combat_pose_front.png
combat_pose_side.png
silhouette.png
palette.json
identity_anchors.json
portrait_neutral.png
portrait_focus.png
portrait_victory.png
portrait_defeat.png
provenance.json
qa_report.md
```

The identity package must keep face, hair, body proportion, clothing identity, belt/variant, accessories and asymmetry stable.

### Gold-slice identity priority

1. Ruan `ruan_macacao`;
2. Davi `davi_relampago`;
3. Mestre Dendê;
4. Tinker Bell.

Preferred audited references remain:
- `ruan_turnaround_v2_beard_pixel`;
- `davi_identity_action_sheet_v1`.

They remain candidates until human approval and normalization.

## 5. Character gameplay packages

For each playable/recurrent fighter:

```
world/
  idle/
  walk_front/
  walk_back/
  walk_side/
combat/
  idle/
  stance/
  grip/
  defense/
  reaction/
  clinch/
  scramble/
  ground_top/
  ground_bottom/
  win/
  loss/
portraits/
  neutral/
  focus/
  concern_or_anger/
  victory/
  defeat/
```

Each animation folder should contain, when applicable:

```
raw_sheet.png
clean_sheet.png
spritesheet.png
frames/
preview.gif
contact_sheet.png
metadata.json
hitbox.json
import_notes.md
provenance.json
license.json
qa_report.md
```

## 6. Paired BJJ package

BJJ techniques are **paired visual products**, never independent attacker clips.

Each technique requires:

- attacker animation;
- defender animation;
- shared world/contact anchors;
- deterministic `sync_map.json`;
- `contact_map.json`;
- entry/exit state;
- interruption/response windows;
- camera recommendation;
- frame target;
- technical review;
- contact sheet;
- preview;
- Godot runtime evidence.

Gold slice:

| ID | Transition |
|---|---|
| t001 | standing_neutral → half_guard_top |
| slice_sprawl | standing_neutral → front_headlock |
| t005 | standing_neutral → closed_guard |
| t025 | half_guard_top → side_control |
| t049 | half_guard_top → knee_shield_half |
| slice_side_to_mount | side_control → mount_high |
| t057 | mount_high → submission |

## 7. Arena package

Arena is a playable layered system, not a poster.

Required baseline layers:

```
bg_far
bg_mid
crowd_back
play_area
foreground
particles
props/
water_or_weather_masks/
light_masks/
collision_metadata.json
camera_bounds.json
spawn_points.json
preview.png
qa_report.md
```

Priority arenas:
1. Terreiro da Luta;
2. Arena do Dique.

### Terreiro direction

River + mangrove + wood + tropical vegetation + open dojo + living water. Quiet strength, discipline and truth.

### Arena do Dique direction

Urban dike + water + official circuit + bright competitive lighting + crowd + stalls + banners + reflective surfaces.

## 8. World map system

Never ship flattened mutable UI inside map art.

Every core map page is split into:

```
map_base_art/
world_overlay/
ui_overlay/
narrative_overlay/
```

### Map base art

- terrain;
- water;
- vegetation;
- towns;
- landmarks;
- coastline;
- islands;
- bridges/docks.

### World overlay

- nodes;
- terrestrial routes;
- sea routes;
- blocked routes;
- locks;
- faction markers;
- secret markers;
- resources;
- collectables.

### UI overlay

- region header;
- legend;
- top navigation;
- selection;
- prompt;
- travel information.

### Narrative overlay

- plaques;
- event marks;
- contextual quote;
- secret event treatment.

Core pages:
1. Baixo Sul overview;
2. Ituberá;
3. Nilo Peçanha;
4. Valença;
5. Camamu;
6. Cairu;
7. Itacaré & Maraú;
8. Interior Norte;
9. Interior Sul;
10. Salvador.

`Costa das Marés` stays expansion/candidate until promoted by canon.

## 9. UI graphic system

Canonical base:
- background/panel: `#0B0B0D`;
- border/ornament: `#C9971C`;
- text: `#EDE6D6`;
- minimum touch target: 48 dp;
- primary touch target target: 72–96 dp;
- mutable text/stats rendered by Godot.

Core graphic atoms:

```
panels/
frames/
nine_slice/
buttons/
button_states/
toggles/
tabs/
badges/
meters/
icons/
portraits/
tooltips/
map_markers/
touch/
hud/
cards/
dialogue/
```

P1 UI:
- combat HUD mobile;
- position ladder;
- counter telegraph;
- submission HUD;
- touch controls.

## 10. Technique cards

Never bake gameplay stats into the permanent bitmap.

Card composition:

```
card_shell.png
central_art.png
type_icon.png
rarity_frame.png
data_binding.json
preview.png
qa_report.md
```

Godot owns title, description, stats, legality, stamina, difficulty, rarity and other mutable fields.

The audited `t057` armbar card is the current strongest data-link candidate.

## 11. Faction graphic kits

Each faction must ship as a coherent iconography family.

Per faction:

```
emblem_master.png
icon_48.png
icon_24.png
banner_light.png
banner_dark.png
badge_round.png
background_pattern.png
map_marker.png
ui_header.png
```

LEM:
- eye, roots, moon, water, mist;
- ceremonial purple/wine + gold.

NTM:
- chili/flame, mortar, stage, flags, stars;
- ceremonial red/orange + gold.

ALE:
- order, protection, discipline;
- dove/halo/laurel/stars;
- ceremonial royal blue + gold + white;
- display name must be **Os Aleluiado**.

## 12. VFX library

Engine-neutral transparent flipbooks:

1. grip confirmation;
2. cloth snap;
3. mat impact;
4. dust;
5. sweat;
6. focus glow;
7. counter flash;
8. submission danger;
9. crowd camera flash;
10. rain splash;
11. mangrove mist;
12. secret violet mist;
13. water shimmer;
14. leaf particles.

No Unity VFX Graph or engine-specific dependency may become the shipping artifact.

## 13. Portrait system

Initial portrait coverage:

- Ruan;
- Davi;
- Mestre Dendê;
- Tinker Bell;
- Cássio Molho;
- Kenzo Kuroi;
- Leoa Quilombola;
- Oni da Lapa.

Minimum states:
- neutral;
- focused;
- victory;
- defeat;
- concern/anger where narratively relevant.

Portrait identity must match sprite identity.

## 14. Marketing kit

Required families:

- `key_art_16x9`;
- `cover_vertical_4x5`;
- `store_banner_1920x1080`;
- `app_icon_1024`;
- `poster_character_ruan`;
- `move_list_infographic`;
- `social_carousel_techniques`;
- `trailer_storyboard_frames`;
- `thumbnail_pack`;
- `press_kit_character_sheets`;
- `press_kit_arena_sheets`.

Marketing art may be higher-detail than gameplay sprites but must preserve identity, palette and regional art direction.

## 15. Unity Essentials authoring lab

Unity is an **auxiliary lab only**.

Allowed:
- sprite import/slicing;
- pivot preview;
- paired animation blocking;
- 3D pose/contact preview;
- orthographic render checks;
- parallax staging;
- mobile UI safe-area prototype;
- VFX prototyping/baking;
- cutscene camera blocking.

Neutral exports only:
- PNG;
- WEBP;
- GLB;
- FBX;
- JSON;
- transparent flipbooks.

Forbidden as runtime dependency:
- `.unity` scenes;
- Prefabs;
- Animator Controllers;
- URP Materials;
- Shader Graph;
- VFX Graph;
- Addressables;
- Unity-specific UI prefabs.

## 16. Production folders

Candidate outputs:

```
production/candidates/
├── characters/
├── techniques/
├── arenas/
├── world_maps/
├── ui/
├── cards/
├── factions/
├── icons/
├── vfx/
├── portraits/
└── marketing/
```

Production source/intermediate material may live outside runtime paths. Final approved assets must be normalized into the existing CRIA asset system and registered through the current manifest/coverage contracts.

## 17. P1 execution order

1. Ruan identity master;
2. Davi identity master;
3. directional locomotion;
4. Terreiro layered world package;
5. Arena do Dique layered world package;
6. ground-position bases;
7. seven paired BJJ techniques;
8. combat UI;
9. Godot integration;
10. runtime visual capture;
11. physical Android visual review.

Do not expand horizontally before this slice reads as a finished game.

## 18. Full-campaign visual target

Derived from the active roadmap:

- 18 character identity packages;
- 18 portrait systems;
- 50 paired BJJ technique packages;
- 15 arena packages;
- 10 canonical core map pages;
- 3 faction graphic kits;
- 18 primary UI screens;
- 50 data-driven technique card shells/art packages;
- 14 core VFX families;
- complete marketing/store/press kit.

These are production targets, not evidence of current completion.

## 19. Promotion gates

A visual asset can move toward shipping only if all applicable gates pass:

1. canon/ID/name;
2. provenance;
3. rights/license;
4. human visual approval;
5. identity lock;
6. cultural review where relevant;
7. GI/NO-GI consistency;
8. biomechanical review for BJJ;
9. scale/pivot/anchor;
10. alpha/edge/frame QA;
11. paired sync;
12. mobile readability;
13. safe-area/touch QA;
14. integration in a real Godot scene;
15. runtime capture;
16. Android physical-device evidence.

Default remains `shipping=false`.

## 20. Definition of visual gold slice

The gold slice is visually ready only when:

- Ruan and Davi identity masters are human-approved;
- required Ruan/Davi locomotion and combat bases contain no placeholders;
- all seven paired BJJ packages pass sync/technical review;
- Terreiro and Dique are final layered packages;
- combat HUD, touch controls, position ladder, telegraph and submission HUD are readable on mobile;
- assets are provenance/rights cleared;
- Godot runtime evidence exists;
- Android physical-device visual QA passes.

