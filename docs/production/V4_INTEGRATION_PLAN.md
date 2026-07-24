# CRIA DO TATAME — Plano Único de Integração v4

Branch canônica de integração: `release/v4-integration`.

## Regra

Nenhum novo sistema substitui um autoload estável de forma destrutiva. Toda migração usa adapter/fachada, teste de regressão e save compatível.

## Ordem de integração

1. Hardening/CI do PR #27 — base desta branch.
2. Cânone documental do PR #29.
3. Facções v3 + migração de saves.
4. Combate por cartas do PR #30 por adapter.
5. Game feel do PR #25.
6. Audiovisual do PR #24.
7. Pipeline visual local do PR #26.
8. Godot 4.3, GUT, Android físico e performance.

## Contratos já adicionados nesta branch

- `data/factions/factions_v3.json`: exatamente LEM, NTM e ALE.
- `src/compat/FactionSaveMigrationV3.gd`: mapeamento de IDs legados sem perda silenciosa.
- `src/compat/PositionalCombatAdapter.gd`: ponte entre estados `PLAYER_TOP_*` e posição+lado.
- `tools/lint_canon_v4.py`: gate canônico independente.

## Gates antes de ativar runtime v4

- lint canônico verde;
- testes de migração de save;
- import Godot sem erro;
- smoke legado preservado;
- GUT do novo combate;
- cena vertical slice Ruan × Davi;
- Hub → deck → luta → resultado → Cria Live → save/load;
- Android físico ≥45 FPS.

## Proibições

- quarta facção;
- núcleo tratado como facção;
- segundo `CombatManager` ou segundo `DeckManager` concorrente;
- poder de luta comprado com Molho;
- promoção automática de asset gerado;
- declaração de jogo final sem device test.
