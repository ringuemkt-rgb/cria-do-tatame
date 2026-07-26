# DECISIONS — Master Plan do Cria do Tatame

**Status:** decisões arquiteturais e de produto congeladas.  
**Atualizado em:** 2026-07-25  
**Escopo:** governa a migração incremental do runtime; não substitui o contrato SUPREME nem a ordem de precedência em `docs/DOC_PRECEDENCE.md`.

## D1 — Repositório único

`ringuemkt-rgb/cria-do-tatame` é a fonte única de código, dados, documentação e releases. `Tatamecria` é somente espelho de build e não recebe desenvolvimento.

## D2 — Combate via fachada progressiva

`TransitionManager` é o destino canônico da resolução de transições. `CombatManager` preserva todas as assinaturas públicas legadas e delega ao destino canônico por adapter (Strangler Fig). Não é permitido reescrever autoloads inteiros durante a migração.

## D3 — Um mixer de áudio

`AudioManager` é o único mixer de runtime. `CombatAudio` permanece apenas como módulo ou ponte compatível; não pode criar buses, mixer ou pipeline paralelo.

## D4 — Responsabilidades de mundo separadas

`WorldState` guarda dados; `WorldDirectorManager` gere eventos; `NavigationManager` trata transporte; `WorldMapManager` renderiza o mapa. Esses papéis não devem ser fundidos.

## D5 — Deck canônico

`DeckManager` é a única autoridade do deck. HUD, testes e dados de teste são consumidores; não podem manter um deck paralelo.

## D6 — Schemas em camadas

`technique_catalog_v05` é o catálogo-mestre de técnicas. `combat_deck_schema` é projeção por `technique_id`. Cartas sem referência válida não entram no deck de runtime.

## D7 — Acessibilidade neurodivergente é pilar

Sem-timer, foco, perfil sensorial e narração são requisitos de design. Efeitos de flash, shake e slow-motion devem respeitar o perfil persistido do jogador.

## D8 — Colecionáveis e patches; sem blockchain

Colecionáveis são patches cosméticos sem pay-to-win. Blockchain, NFT, carteira, transação, token de poder e dependência de rede são proibidos no runtime e nos dados novos.

O checkout legado ainda contém nomes incompatíveis (`NFTManager` e `assets/cosmetics/nft/`). Esta decisão não afirma que há integração de blockchain ativa: ela bloqueia qualquer expansão e exige inventário, adapter de compatibilidade, migração de save e remoção segura em lote próprio antes de apagar referências.

## D9 — Escopo do núcleo protegido

O loop de 30 segundos — escolher carta, ameaçar, ler/defender/fintar e sentir o impacto — é prioritário. Facções, clima e expansão de mundo ficam fora do core atual; não devem crescer antes do vertical slice jogável.

## Regra de migração

Toda mudança atravessa adapter/fachada, preserva APIs públicas até os consumidores migrarem, atualiza teste e passa por `tools/audit/audit_boot.py`. Qualquer conflito com a precedência documental deve ser registrado antes da implementação.
