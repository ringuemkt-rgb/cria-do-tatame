# Decisões Arquiteturais e Canônicas

**Status:** CANONICAL  
**Atualizado:** 2026-08-02  
**Escopo:** integração v4 incremental sobre a `main` estável.

Este registro documenta decisões vinculantes para agentes, revisores e contribuições. Em conflito, prevalecem os contratos executáveis em `data/production/`, seguidos deste documento e das demais fontes conforme a hierarquia definida em `AGENTS.md`.

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
- Alterações são restritas a `name`, `display_name` e lore inequivocamente referente à facção ficcional.
- A palavra “aleluia” em contexto religioso real não deve ser alterada automaticamente.
- Ocorrências ambíguas permanecem intactas e devem ser registradas para revisão humana.

Esta decisão substitui as formas anteriores “Os Aleluia” e “Os Aleluiado” como nome de exibição da facção ficcional, sem alterar o ID `ALE`, o alias `os_aleluia`, relações, territórios, flags ou save v5.

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

## D14 — Mundo jogável: Baixo Sul da Bahia

O jogo ocorre exclusivamente no **Baixo Sul da Bahia**. O mapa canônico está em `data/world/baixo_sul_map_v2.json`.

- Ituberá é o hub principal.
- Município e arena são níveis distintos: o município é nó de viagem; arena e ponto de interesse são subnós.
- A Ponte do Saicí, a Praia de Pratigi, a Cachoeira da Pancada Grande, o Terreiro, o Dique e o Manguezal Profundo pertencem ao núcleo jogável de Ituberá.
- Zambiapunga é evento cultural situado em Nilo Peçanha, nunca município independente.
- Valença recebe o grande palco oficial da Copa do Baixo Sul.
- Camamu recebe o eixo portuário e o Ferro Velho do Cais.
- Igrapiúna recebe o treino avançado; Cairu, a travessia insular; Wenceslau Guimarães, o clímax de mata.
- Salvador, São Paulo e Itacaré não são nós jogáveis. Podem existir apenas como referência histórica, borda de mapa ou conteúdo arquivado.
- Nenhum asset, missão, arena ou rota nova pode promover local externo ao território jogável sem nova decisão canônica e migração coordenada.

As quinze arenas canônicas e seus municípios estão congelados no contrato de mapa. O runtime antigo pode permanecer temporariamente como legado durante a migração, mas não orienta produção nova.

## D15 — Vertical slice ouro Ruan × Davi

O contrato `data/production/vertical_slice_gold_v1.json` define o primeiro pacote de qualidade representativa do jogo.

- Ruan “Macacão” Silva enfrenta Davi Relâmpago na Arena do Dique de Ituberá.
- Terreiro da Luta é o hub de entrada e retorno.
- Gi e No-Gi são obrigatórios como rulesets reais, não troca cosmética.
- O HUD fixo usa Gás, Controle, Pegada e Fluxo; Vida, Guarda, Foco e Moral são contextuais.
- O deck equipa cinco cartas ativas, três fundamentos passivos e apresenta mão contextual de três.
- Oito técnicas pareadas são congeladas para o lote: `grip_de_ferro`, `baiana`, `sprawl`, `puxada_guarda`, `corte_joelho`, `montada_pesada`, `saida_montada` e `mata_leao`.
- Toda técnica pareada exige atacante, defensor, pivô compartilhado, contato, `sync_map`, metadata, preview e QA biomecânico humano.
- `instant_finish` permanece falso e o modificador de clash permanece limitado a `[-0.30, +0.35]`.
- O vertical slice só pode ser declarado concluído após integração real, gates automatizados e teste Android ARM64 físico com pelo menos 45 FPS sustentados.
