# Repo Update v1 — Registro de Port Canônico

**Status:** ACTIVE  
**Data:** 2026-09-12  
**Branch:** `feat/repo-update-v1-20260912`  
**Base:** `main` @ `bf49d488f82f316773a42364e171de99365fe069`

## Objetivo

Portar o pacote Repo Update v1 para a arquitetura atual de **Cria do Tatame – Pressão** sem criar autoridades concorrentes, segundo `AGENTS.md`, `docs/REPOSITORY_GOVERNANCE.md`, `docs/DECISIONS.md` e os contratos executáveis ativos.

## Decisões anti-drift

1. `data/narrative/acts_v3.json` recebe a narrativa aprovada pelo proprietário como fonte de beats do pacote.
2. `data/narrative/missions_v1.json` passa a registrar vínculo missão→beat; definições ausentes permanecem explicitamente `LINK_ONLY`, nunca inventadas.
3. O canon lock existente continua em `data/brand/canon_lock.json`; não será criado um segundo `data/narrative/canon_lock.json` concorrente.
4. O nome canônico de ALE segue D10: **Os Aleluiado**. A grafia de NTM segue o contrato executável: **Nós Tem Um Molho**.
5. Arena do Dique permanece em Ituberá; `galpao_piacava` permanece associado a ALE.
6. Ruan inicia P1/faixa de entrada como branca conforme o patch aprovado.
7. NFT permanece proibido como dependência/produto; identificadores legados só podem existir durante migração segura.
8. Não criar `systems/combat/combat_reducer_v2.gd` ou `systems/ai/utility_ai_v2.gd`: as autoridades já existem em `src/combat/BJJGraphReducerV2.gd` e `src/ai/BJJUtilityScorerV2.gd`.
9. Não criar `asset_registry.json` ou `docs/MESTRE.md` como autoridades concorrentes; o inventário e a governança permanecem nos contratos/índices atuais.
10. C5/C6 só avançam com conteúdo concreto ou implementação já existente e validável; ausência de payload não será mascarada por placeholders de shipping.
11. A PR #124 (`feat(narrative): canonize five narrative fixes`) já foi incorporada à `main`; este pacote a estende com Parte Zero, linkage completo e a forma final de `acts_v3`, sem restaurar o cânone anterior.

## Ordem de commits deste port

- C1 — este registro de governança;
- C2 — narrativa canônica + missão↔beat + patch de cânone;
- C3 — validator com `structure_ok`, `linkage_ok` e `release_ready` separados;
- C4+ — somente ports compatíveis com a arquitetura vigente, sem segundo reducer/manager/runtime.

## Rollback

Cada commit deve ser reversível isoladamente. Nenhum lote posterior pode depender de estado não validado sem declarar o bloqueio no PR.
