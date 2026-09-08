# CRIA ART DIRECTION — QA Reference v1

**Status:** ACTIVE AUTHORING REFERENCE

This file collects operational thresholds. Executable validators remain the final machine authority.

## Absolute blockers

Any one of these prevents approval/promotion:

- unknown provenance or rights;
- missing human approval for shipping art;
- wrong canonical character/faction/ID;
- real third-party brand/person/IP without clearance;
- identity drift across character assets;
- GI/NO-GI contradiction;
- unsafe or implausible BJJ contact in paired technique;
- paired technique without attacker + defender + sync data;
- generated output promoted directly to shipping;
- mutable gameplay text/lock/state baked into map base without an explicit reason;
- map or environment claiming invented geography as canon;
- unreadable mobile UI or blocked playfield.

## Sprite technical targets

From the active Sprite Forge protocol:

- normalized frame: `128x128` RGBA;
- pivot: `[64,96]`;
- anchor: feet/contact line;
- `body_scale_cv <= 0.08`;
- `anchor_y_std <= 0.05`;
- `profile_body_scale_drift <= 0.08` against approved master action;
- edge-touch frames: `0`;
- empty frames: `0`;
- paste-clamped frames: `0`;
- nearest-neighbor resampling;
- integer scale in runtime;
- detached FX separated by default.

`data/visual/production_manifest_v02.json` currently targets approximately `72 px` combat body height within the normalized gameplay frame. Canvas size and rendered body height are distinct concepts.

## Paired technique QA

Required visual/technical checks:

- attacker ID and defender ID explicit;
- entry and exit positions match the source technique/fixture;
- shared pivot/contact system;
- phase order compatible with: anticipation → entry → establish → stabilize → response → recovery;
- equal/synchronized timing contract or explicit sync map;
- defender response visible;
- no teleport between positions;
- no hidden striking core;
- contact points plausible;
- submission pressure represented technically, not as gore/damage spectacle;
- ruleset/legality does not get invented by the image.

## Arena QA

- playfield remains readable at gameplay zoom;
- parallax/occlusion layers are separable;
- foreground props do not cover mandatory combat silhouettes;
- collision and camera bounds are data/runtime artifacts, not painted assumptions;
- lighting has one dominant source;
- environmental motion layers declared;
- no real brand/institution mark;
- safe margins for combat HUD.

## Map QA

- regional base art is separated from world/UI/narrative overlays;
- route categories visually distinct;
- secret areas use a consistent violet/mystery treatment;
- faction badge semantics are correct even if ceremonial colors vary;
- locks and objective state live in overlay/UI when mutable;
- resource/collectible icons are shown only when backed by data for integration;
- topography and POIs pass world/canon review;
- dense composition still preserves route/node readability;
- text is not required to decode the core route graph;
- any handwritten regional phrase is reviewed for spelling, tone and placement.

## UI QA

- dark panel + gold border + off-white text baseline;
- readable at target Android density;
- safe area respected;
- touch targets must meet the runtime accessibility/mobile contract when implemented;
- selection, lock, danger and faction states differ by shape/icon as well as color where possible;
- no long text baked into background;
- stats come from data.

## Human review rubric

Reviewers should score at least these dimensions:

1. canonical identity;
2. silhouette/readability;
3. anatomy/biomechanics;
4. regional/cultural specificity;
5. style consistency;
6. color/light consistency;
7. gameplay clarity;
8. technical export readiness;
9. provenance/rights;
10. emotional fit with `Ser forte é ser gentil`.

A high aesthetic score cannot compensate for an absolute blocker.

## Required commands before integration

```bash
npm run validate:asset-protocol
npm run validate:sprite-forge
npm run validate:sprite-forge-phase1
npm run test:sprite-forge
npm run test:sprite-forge-phase1
npm run validate:art-direction
npm run test:art-direction
npm run quality
```

Godot import/smokes and Android physical-device evidence remain separate gates when the asset is integrated into runtime.
