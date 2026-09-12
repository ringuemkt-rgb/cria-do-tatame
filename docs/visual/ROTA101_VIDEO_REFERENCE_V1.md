# ROTA 101 — Video Reference Target v1

**Status:** visual-direction reference only  
**Runtime authority:** none  
**Shipping asset:** no  
**Purpose:** convert the supplied concept video into an auditable visual target for the Godot implementation without treating a rendered concept as proof of implemented gameplay.

## Target read

The reference establishes a clear visual identity for ROTA 101:

- 16-bit / high-detail pixel-art presentation rather than flat vector debug shapes;
- Bahia coastal-road golden-hour atmosphere;
- road descending toward water, town and mountain silhouettes;
- strong sunset reflection on the sea;
- tropical vegetation and palms framing the highway;
- guardrails and road furniture that make the route feel regional rather than generic;
- rear-view Kombi as the dominant focal point;
- occupants visible through the rear glass to communicate crew travel;
- large CRIA identity mark on the vehicle;
- road signage and route information integrated into the scene;
- title treatment built around `ROTA 101` / `A ESTRADA DO CRIA`;
- dark utilitarian menu/control panels laid over the scene without obscuring the road;
- camera language that moves between establishing view and a tighter rear-vehicle framing.

The concept is a **visual benchmark**, not a runtime screenshot. Nothing in this document promotes the reference itself into game assets or evidence of completed implementation.

## Composition contract

### Camera

- Primary camera: rear chase view, vehicle centered near the lower-middle third.
- Horizon: approximately upper third of the frame.
- Road vanishing point: near the vertical center axis.
- Vehicle should occupy roughly 18–28% of frame height in normal driving.
- Camera may tighten temporarily for dialogue/event emphasis, but gameplay readability wins over cinematic zoom.

### Environment hierarchy

1. sky / sunset;
2. distant mountains;
3. sea / bay;
4. coastal town silhouette and selected landmark shapes;
5. vegetation / palms;
6. guardrails, signs and shoulder detail;
7. road surface and lane markings;
8. Kombi / traffic / hazards;
9. HUD and accessibility controls.

The first seven layers must remain visually subordinate to route readability.

### Palette target

Use a warm Bahia sunset against cool water and blue-green vegetation:

- sky highlights: peach / amber / coral;
- water: blue-teal with warm reflected sun;
- mountains: desaturated blue-violet / green;
- vegetation: deep tropical green;
- asphalt: warm charcoal;
- lane marks: aged cream/yellow;
- guardrails/signs: muted cool gray/green;
- Kombi: off-white upper body + deep blue lower body;
- UI: charcoal/black panels with aged cream, warm yellow and restrained red accents.

Exact values belong in the approved art asset/Theme contract, not in this prose spec.

## Kombi identity lock

The rear vehicle view is the key signature asset and should be manufactured before broad scenery production.

Required states:

1. rear master;
2. rear 3/4 left;
3. rear 3/4 right;
4. subtle lean/steer variants;
5. brake-light state;
6. head/tail-light night state;
7. light wear state;
8. heavy-damage state kept visually readable but non-gory/non-weaponized.

The Kombi remains transport/gameplay identity, never a combat weapon. Pedestrians and cyclists remain excluded as score targets by the gameplay contract.

## UI target

The reference suggests a stronger diegetic/travel identity than the current debug HUD.

Production UI should converge on:

- `ROTA 101` title card / loading treatment;
- route/distance sign language inspired by Brazilian highway signage without copying real police or protected branding;
- speed, vehicle condition and clean-driving score compactly grouped;
- progress represented as route progress, not arcade lap count;
- accessibility controls available but not visually dominant during normal play;
- mobile controls large enough for touch QA but visually integrated near screen edges;
- event/POI callouts appearing in the road world rather than as large modal overlays whenever possible.

## Runtime architecture

The target must be implemented with layered assets and the existing deterministic simulation, not by playing a prerendered video.

Preferred separation:

```text
Rota101Simulation.gd
    -> deterministic speed / lateral / hazards / outcome

Rota101Travel.gd
    -> input / orchestration / HUD / commit

visual layers
    -> backdrop / road / vegetation / signage / Kombi / FX

WorldMapManager
    -> TravelPlan + two-phase commit authority
```

No visual layer may become a second travel authority.

## Asset manufacturing order

P0 visual slice:

1. Kombi rear master;
2. Kombi rear 3/4 left;
3. Kombi rear 3/4 right;
4. coastal Bahia highway backdrop master;
5. road/guardrail foreground layer;
6. palm/vegetation side layers;
7. route sign kit;
8. hazard/POI icon kit;
9. title/logo treatment;
10. mobile control skin.

Each output remains an individual candidate asset with provenance, sidecar, visual QA and Godot preview before promotion.

## Acceptance gates

A visual candidate is not considered matched merely because it contains a road and a Kombi. The slice should satisfy all of the following:

- recognizable Bahia/coastal identity at first glance;
- Kombi is the dominant focal object;
- road remains readable under HUD and effects;
- background has visible depth through at least four parallax bands;
- nearest-neighbor / pixel-art presentation remains coherent at 1280×720 and mobile aspect ratios;
- no generated text artifacts on signs or vehicle;
- UI does not cover the lane decision area;
- motion does not depend on remote generation;
- Android target remains performant;
- visual QA evidence is captured from the real Godot runtime.

## Evidence rule

The supplied video is treated as an **art-direction reference**. Release evidence must come from captured frames of the actual Godot scene on the current branch/build, followed by Android physical-device evidence for the shipping gate.
