# Authoring pipeline

1. Read `data/techniques.json` and `data/transitions/index.json`. All IDs and PLAYER states must match.
2. Obtain rights-cleared input video/PNG/BVH reference. BVH is timing evidence, **not** pixel geometry.
3. Extract 12 fps, 128×128 nearest; manually edit identity/outfit/contacts in Pixelorama.
4. Palette snap; build a separate candidate per actor, raw → clean → final.
5. Generate paired `sync_map.json` with six ordered phases, shared [64,96] pivot.
6. Run `python tools/cria-asset-factory/scripts/quality_gate.py --candidate <path>`.
7. Human rights/biomechanics/art QA, Godot scene import, npm run quality — no automatic promotion.
