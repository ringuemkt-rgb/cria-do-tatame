# Decisões Arquiteturais e Canônicas

**Status:** CANONICAL  
**Atualizado:** 2026-08-01  
**Escopo:** integração v4 incremental sobre a `main` estável.

Este registro documenta decisões vinculantes para agentes, revisores e contribuições. Em conflito, prevalecem os contratos executáveis em `data/production/` e `data/visual/`, seguidos deste documento e das demais fontes conforme a hierarquia definida em `AGENTS.md`.

## D1 — Fonte única

`ringuemkt-rgb/cria-do-tatame` é o único repositório oficial de código, dados, documentação e builds do jogo.

- Não criar segundo runtime, segundo `project.godot` ou frontend concorrente.
- Repositórios antigos não são espelhos de desenvolvimento nem de build.
- Trabalho fora da `main` só conta como produto depois de integrado e validado.

## D2 — Combate

O `CombatManager` atual permanece o runtime estável durante a migração v4.

- Não substituir seu corpo por uma fachada reduzida.
- Não quebrar assinaturas públicas existentes.
- Funcionalidades v4 entram por adapter e migração incremental de consumidores, com teste de regressão por lote.
- Um eventual `TransitionManager` não se torna canônico antes de port, integração real e validação.

## D3 — Áudio

`AudioManager` é o único manager de áudio.

Uma ponte de combate só pode ser adicionada depois de existir contrato explícito para eventos, buses, layers e volumes. Nenhum segundo mixer ou singleton de áudio pode competir com o manager canônico.

## D4 — Mundo

`WorldState`, `WorldDirectorManager`, `WorldMapManager` e os demais managers de mundo possuem responsabilidades distintas. Eles não devem ser fundidos sem ADR específica, migração e testes de compatibilidade.

## D5 — Deck

`DeckManager` permanece único. Cartas referenciam técnicas por `technique_id`; HUD, IA e cenas são consumidores, não fontes mestras.

## D6 — Dados

O catálogo de técnicas é a fonte mestre. Deck, HUD, animação e IA são projeções ou consumidores.

- IDs persistíveis são estáveis.
- Renome exige alias ou mapper.
- Schema novo não substitui dados ativos sem migração validada.

## D7 — Acessibilidade

Acessibilidade neurodivergente é requisito de produto: perfil sensorial, redução de flash e tremor, modo foco, modo sem timer e narração. A implementação de runtime deve ocorrer em lote próprio, integrada aos efeitos existentes e testada em dispositivo.

## D8 — Colecionáveis

Colecionáveis e patches são exclusivamente cosméticos.

- Sem blockchain.
- Sem NFT como dependência de produto.
- Sem pay-to-win.
- Identificadores legados podem permanecer apenas até migração segura de save e assets.

## D9 — Prioridade

O vertical slice ouro Ruan × Davi tem precedência sobre expansão massiva de mundo, elenco, facções, ferramentas ou serviços remotos.

## D10 — Nome canônico da facção ALE

O nome de exibição aprovado é exatamente **Os Aleluiados**.

- ID canônico: `ALE`.
- ID legado preservado: `os_aleluia`.
- O ID legado funciona como alias de migração, nunca como quarta facção.
- A alteração é exclusivamente de exibição e não modifica save, relações, territórios ou IDs persistíveis.
- Alterações automáticas são restritas a `name`, `display_name` e lore inequivocamente referente à facção ficcional.
- A palavra “aleluia” em contexto religioso real não deve ser alterada automaticamente.
- Ocorrências ambíguas permanecem intactas e devem ser registradas para revisão humana.

Esta decisão substitui as formas anteriores **Os Aleluia** e **Os Aleluiado** em material ativo. Documentos históricos podem registrar essas formas somente como estado anterior ou exemplo de migração.

## D11 — Integração v4

O PR #32 (`release/v4-integration`) é branch-fonte e não deve ser mesclado monoliticamente.

A ordem oficial de port é:

1. cânone e contratos executáveis;
2. migração das três facções e save;
3. cartas, posições e rulesets;
4. adapter de combate preservando o runtime estável;
5. Arena v4 e Submission HUD;
6. mundo, economia, informante e finais;
7. terreno e acessibilidade.

Cada lote deve partir da `main` mais recente, ter escopo vertical pequeno, rollback claro e checks verdes antes do próximo.
