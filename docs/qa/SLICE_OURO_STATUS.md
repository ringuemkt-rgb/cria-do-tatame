# Fatia ouro — auditoria 2026-09-17

Repo `ringuemkt-rgb/cria-do-tatame` branch `feat/slice-ouro-transition-v1`.

## Correções neste commit

- `TechniqueResolver.gd` — deny na janela (`frame <= commit_frame * defense_window`), fake antes do commit (custo 50%), `chain_id` +0.08, overlay merge.
- `SliceStateMapper.gd` — catálogo → `PLAYER_*` + espelho TOP↔BOTTOM.
- `DataRegistry.gd` — aplica `technique_slice_ouro_v1.json` em `get_technique` (aliases `knee_cut`/`clinch_entry`/`kimura`).
- `DaviAIController.gd` — lê `davi_policy_slice_v1.json` e enviesa `preferred_ids` do estado atual. CombatManager continua juiz.
- Validador `tools/combat/validate_slice_ouro_v1.py` + teste `tests/test_slice_ouro_v1.py`.
- Smoke contratual: baiana vs sprawl na janela → `denied=true`, `state_to=PLAYER_TOP_CLINCH`.

## Ainda NÃO é jogo completo

- Sprites pareados 6 fases + `sync_map` das 7 arestas
- Identity pixel shipping
- Playtest Android físico / smoke Windows
- Áudio mixado
- Merge dos PRs draft de mundo/NFT/IA remota

`shipping=false`. Sem segundo CombatManager. Sem LimboAI no tick.
