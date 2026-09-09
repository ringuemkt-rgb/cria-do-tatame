# CRIA ART DIRECTION — Anchor Registry v1

**Status:** ACTIVE AUTHORING REFERENCE  
**Rule:** an anchor is authoritative only to the extent allowed by the repository hierarchy. Concept art never overrides executable canon.

## A. Repository-authoritative anchors

### Canon / product

- `data/production/canon_contract_v4_1.json`
- `data/production/supreme_build_contract_v01.json`
- `docs/DECISIONS.md`
- `AGENTS.md`

### Visual / UI

- `data/visual/production_manifest_v02.json`
- `data/visual/production_manifest_v03.json`
- `data/visual/ui_theme_v2.json`
- `docs/05_ART_DIRECTION.md`
- `docs/08_ASSET_PIPELINE.md`

### Sprite consistency and production

- `data/visual/sprite_forge_contract_v1.json` — legacy quantitative package compatibility;
- `data/visual/sprite_forge_contract_v2.json` — active production-grade authoring/QA contract;
- `data/visual/sprite_forge_requirements_v2.json` — derived character/world/BJJ manufacturing policy;
- `data/visual/sprite_qa_profiles_v1.json` — technical action profiles;
- `assets/schemas/character_identity_master_v2.schema.json`;
- `assets/schemas/paired_bjj_animation_v2.schema.json`;
- `assets/schemas/world_art_package_v2.schema.json`;
- `assets/schemas/sprite_forge_v2.provenance.schema.json`;
- `.agents/skills/cria-sprite-forge/SKILL.md`;
- `tools/art/validate_asset_protocol.py`;
- `tools/art/validate_sprite_forge.py`;
- `tools/art/validate_sprite_forge_v2.py`.

### BJJ vertical slice

- `data/bjj/bjj_kg_slice_ruan_davi_v1.json`
- `data/combat/bjj_rulesets_verified_v1.json`
- `data/combat/bjj_position_values_v1.json`
- `data/combat/bjj_timing_windows_v1.json`
- `data/combat/bjj_completion_gate_v1.json`

## B. Visual anchors from creator review — session references

The creator has approved a recurring direction across the current visual review set:

- Ruan model/turnaround sheets with strong Black Brazilian identity, white/off-white GI, black belt and Silverback identity;
- Ruan combat-pose pixel-art studies;
- Davi blue-GI turnaround/action studies;
- character board covering Ruan, Dendê, Tinker, Davi, Leoa, Jacaré, Oni da Lapa, Cássio, Irmão Caleb and Kenzo;
- faction banner concepts for ALE, LEM and NTM;
- dense regional map pages for Baixo Sul, Ituberá, Nilo Peçanha, Valença, Camamu, Cairu, Itacaré/Maraú, Interior Norte, Interior Sul and Salvador;
- resource/collectible map overlay concept;
- `Costa das Marés` as expansion candidate, not current campaign-map authority.

These images are **visual reference candidates** until imported through the asset pipeline with repository path, provenance/rights metadata, QA and human approval. Do not invent a repository path for a chat-uploaded image.

## C. Canon corrections that always override visual text

1. Protagonist: `Ruan “Macacão” Silva`.
2. ALE display name: **Os Aleluiado**.
3. LEM: `Lá Ele Mil Vezes`.
4. NTM: `Nós Tem Um Molho`.
5. `Costa das Marés` is not one of the current ten canonical campaign pages unless a later approved migration says otherwise.
6. A generated map label, faction color, municipality, institution, technique or mission cannot become canon by appearing in an image.
7. Real police/federation/academy/brand marks are not shipping anchors without explicit rights.

## D. Character anchor policy

A character identity master must resolve to:

- canonical character ID;
- canonical/reference facial features;
- fixed hair silhouette;
- body/scale profile;
- GI/NO-GI outfit variant;
- team/faction patch rules;
- stable identity anchors;
- front/back/side reference chain;
- palette and silhouette signature;
- asymmetry/mirroring contract;
- human approval status;
- provenance/rights status.

Do not select an image as identity master solely because it is aesthetically strongest.

## E. Map anchor policy

Use the approved map direction as composition/style reference:

- dense coastal topography;
- ocean/river/mangrove readability;
- high-value hub focal point;
- faction badges/locks/secret treatment;
- strong black/gold UI framing;
- world routes visible at a glance;
- region-specific economy/culture/landmarks;
- base art separated from mutable overlays.

A single generated flat map is never a shipping map. Production locations must separate terrain/base, structures, props, foreground occlusion, collision/navigation metadata, lighting, weather and ambient FX.

Geography, POI IDs, faction control, locks, navigation, collision and resource data must come from authoritative `data/`/runtime contracts before integration.

## F. Escalation

If two references disagree:

1. use executable canon/data;
2. then use the most recently approved repository visual contract;
3. then use an approved identity/style anchor;
4. if still ambiguous, mark `REVIEW_REQUIRED` and stop.
