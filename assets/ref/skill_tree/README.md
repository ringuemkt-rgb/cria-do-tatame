# Skill Tree Reference Assets

This directory is the repository-side index for the approved ten-page CRIA DO TATAME skill-tree visual bible.

The original PNG boards are archived persistently in ChatGPT Library at:

`/CRIA DO TATAME/Visual Bible/Skill Tree v1/`

They are **not yet repository binaries**. Phase 2 asset ingestion must copy the exact archived images into this directory (or its final canonical replacement), generate per-binary provenance/license/QA sidecars, register them in `assets/manifest_v2.json`, and keep `shipping=false` until human QA.

Expected canonical filenames:

1. `01_skill_tree_overview.png`
2. `02_pressure_silverback.png`
3. `03_technique_zanshin.png`
4. `04_mobility_scramble.png`
5. `05_finalization.png`
6. `06_resilience.png`
7. `07_arena_perks.png`
8. `08_factions_reputation.png`
9. `09_meta_progression.png`
10. `10_jiujitsu_skill_tree.png`

Exact hashes and Library IDs live in `data/visual/skill_tree_visual_manifest_v1.json`.

## Non-negotiable rule

The boards are art/layout authority only. Baked text and numbers are never imported as gameplay authority. Runtime UI must recreate the design with Godot controls populated from canonical data.
