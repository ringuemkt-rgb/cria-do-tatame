# Candidate Frame Prompt — template

Status: AUTHORING CANDIDATE. Always write `shipping=false`, `qa_status=pending`.
Authority: `data/techniques.json`, `data/transitions/<id>.json`,
`.agents/skills/cria-art-direction/SKILL.md`, `data/visual/sprite_forge_contract_v1.json`.

## Fill before use
- technique_id: <existing catalogue ID only>
- character_id: <canonical ID>
- actor_role: attacker | defender
- clothing: gi_white | gi_blue | nogi
- faction: ALE | LEM | NTM
- phase: anticipation | entry | establish | stabilize | response | recovery
- input_reference: <licensed/consented human evidence>
- frame_index: <zero-based integer, same timeline for both actors>

## Immutable locks
HD pixel art 2.5D regional premium. True square pixel grid. 128×128 RGBA; shared pivot (64,96), grounded feet, 12 fps, nearest; no smooth gradient, blur, photography, generic anime, 3D render, real logos, baked HUD or non-BJJ striking. 2–3 cel-shading tones, 1–2 px black outline; base palette from `config/art_direction.json` and optional faction token. Five fingers per visible hand. Side view for all combat phases. GI and NO-GI are separate variants, never mixed unless a documented narrative beat authorizes it. Ruan Macacão's gold silverback patch must stay consistent.

## Paired contract
Generate two **distinct** licensed references for attacker/defender. Contact edges and occluded grips remain UNKNOWN until checked by a human. Require a shared `sync_map.json` with exactly six phases, equal frame counts and matching pivot. Do not claim a scoring outcome from the picture; existing Godot combat resolver owns it.

## Output
Only **candidate frames** for review and sidecar documentation. Never set shipping=true or claim human approval.
