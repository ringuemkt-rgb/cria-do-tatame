# PixelLab MCP → CRIA Sprite Forge v1

**Status:** authoring-provider candidate  
**Runtime dependency:** no  
**Shipping default:** false  
**Provider id:** `pixellab_mcp`

## Purpose

PixelLab is registered as an **external authoring provider** for CRIA DO TATAME. It may generate or edit pixel-art candidates for characters, directional sprites, locomotion, vehicles, props, tilesets and UI. It is not canon authority, BJJ authority, combat authority, release authority or a runtime dependency.

The endpoint is:

```text
https://api.pixellab.ai/mcp
```

Authentication uses a bearer token supplied by the execution environment. Never commit a PixelLab token, paste it into tracked JSON/Markdown, or write it into asset sidecars.

Recommended secret name:

```text
PIXELLAB_API_TOKEN
```

## Integration boundary

```text
CRIA requirement
    ↓
canon + art direction + identity lock
    ↓
PixelLab MCP generation/editing
    ↓
RAW CANDIDATE (shipping=false)
    ↓
CRIA Sprite Forge v2
    ↓
normalize / crop / content bounds / pivot / alpha / palette
    ↓
BJJ semantic gate when applicable
    ↓
Godot preview
    ↓
human visual approval + provenance/rights review
    ↓
registry + runtime evidence
    ↓
shipping candidate
```

PixelLab never promotes its own outputs.

## Best uses in CRIA

### Characters

Use after an identity specification or approved master exists:

- turnaround candidates;
- front/back/side directional views;
- world locomotion;
- idle/walk/run;
- portraits and controlled expressions;
- clothing variants that preserve identity.

Reference conditioning should always start from the approved identity master. A fresh text-only generation is not allowed to silently redefine a canonical fighter.

### Kombi and vehicles

High-value use for the vehicle exploration system:

- Kombi rear view;
- rear 3/4 left/right;
- side views;
- lean/turn states;
- headlight and taillight variants;
- damage-state candidates;
- motorcycles and fictional regional traffic sprites;
- road props.

The vehicle gameplay contract remains authoritative. PixelLab only renders candidates.

### World and map

Good candidates:

- cacao, piaçava, fishing and plant icons;
- mangrove and tropical vegetation props;
- bridges, piers, stalls, fences and colonial facade pieces;
- tilesets;
- route markers and HUD icons;
- arena/environment props.

A generated flat environment is never accepted as navigation/collision truth. World collision, walkability, routes and node state remain data-driven in Godot.

### BJJ / combat

PixelLab may render **only after** Combat Intelligence / Motion Lab provides:

- technique id;
- source and target positions;
- attacker/defender roles;
- GI/NO-GI modality;
- six motion phases;
- pivots;
- contact points;
- sync map;
- legal/illegal semantics.

Do not prompt PixelLab with generic requests such as `make a cool grappling attack` and treat the result as a valid technique.

## Production policy

For production assets:

```text
1 requirement
→ 1 generated asset/file
→ QA
→ sidecar
→ registry
→ next asset
```

Default CRIA batch size for controlled production is **10 assets**, but each output remains an individual file. Collages/sheets are allowed only when the requirement itself is a presentation/reference sheet or authored sprite sheet.

Raw provider outputs stay outside final runtime paths until approved.

## Sprite Forge normalization

Gameplay character frames continue to use the CRIA contract:

- 128×128 RGBA normalized frame;
- pivot `[64,96]` for upright fighters;
- nearest-neighbor resampling;
- integer scaling;
- clean alpha;
- detached FX separate from body sprites;
- no text/watermark hallucination;
- identity-lock comparison before approval.

The high-resolution PixelLab output may be retained as source/provenance material, while the normalized runtime derivative is generated deterministically by CRIA tooling.

## Asset metadata

Every accepted candidate should record at minimum:

```json
{
  "provider_id": "pixellab_mcp",
  "generation_tool": "<tool returned by MCP>",
  "reference_asset_ids": [],
  "output_sha256": "<sha256>",
  "terms_audit_date": "2026-09-12",
  "qa_profile": "<profile>",
  "shipping": false
}
```

Do not record API tokens, authorization headers or private account identifiers.

## Legal / output policy snapshot

The PixelLab terms audited on 2026-09-12 state that generated creations may be used commercially and that users retain rights in their creations, subject to responsibility for third-party rights. The same terms prohibit using PixelLab-generated images to train new models without explicit written permission.

This is **not** automatic clearance for every output. CRIA still applies its own rights/provenance and human-review gates before shipping.

## Connection checklist for ChatGPT Work / Codex

When the execution environment supports adding a remote MCP server:

1. add the endpoint `https://api.pixellab.ai/mcp`;
2. provide the bearer token through the environment/secret store;
3. keep the token outside the repository;
4. confirm the MCP tool inventory before generating assets;
5. use `data/visual/pixellab_mcp_profile_v1.json` as the provider policy;
6. use `.agents/skills/cria-sprite-forge/SKILL.md` for manufacturing/QA;
7. use `.agents/skills/cria-art-direction/SKILL.md` for visual direction;
8. apply Combat Intelligence + Motion Lab before any BJJ animation generation.

## First recommended production slice

Do not start by generating the whole roster. Validate the adapter on a narrow set:

1. Kombi rear master;
2. Kombi rear 3/4 left;
3. Kombi rear 3/4 right;
4. cacao resource icon;
5. piaçava resource icon;
6. fishing resource icon;
7. Ruan world idle candidate from approved identity reference;
8. Davi world idle candidate from approved identity reference;
9. Terreiro modular prop;
10. road-side Baixo Sul vegetation prop.

If identity/style/alpha/scale QA passes consistently, expand to the next controlled batch.
