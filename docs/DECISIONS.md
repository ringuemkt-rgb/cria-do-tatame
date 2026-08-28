# Decisões Arquiteturais e Canônicas

**Status:** CANONICAL  
**Atualizado:** 2026-08-27
**Escopo:** integração v4 incremental e calibração visual/narrativa do slice sobre a `main` estável.

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

O nome de exibição aprovado é exatamente **Os Aleluiado**.

- ID canônico futuro: `ALE`.
- ID legado preservado: `os_aleluia`.
- O ID legado deve funcionar como alias de migração, nunca como quarta facção.
- Alterações são restritas a `name`, `display_name` e lore inequivocamente referente à facção ficcional.
- A palavra “aleluia” em contexto religioso real não deve ser alterada automaticamente.
- Ocorrências ambíguas permanecem intactas e devem ser registradas para revisão humana.

Esta decisão substitui, para o nome de exibição, a forma plural “Os Aleluiados” encontrada na branch-fonte do PR #32.

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

## D12 — Finais canônicos e cálculo data-driven

Os cinco finais e seus IDs de runtime são:

- `CRIA → heroi_duas_aguas`;
- `IDOLO → estrela_vazia`;
- `SOMBRA → rei_dos_atalhos`;
- `DUPLA_FACE → traidor_silencioso`;
- `RAIZ → raiz_eterna`.

`EndingsCalculator` não codifica thresholds nem ordem de precedência. Ele consome exclusivamente `data/finais_adultos.json`; `WorldState` e `StorySceneDirector` são consumidores.

## D13 — Territórios e cores das três facções

- NTM: Manguezal + Ferro Velho, cor primária `#D93A2B`;
- LEM: Colônia Nishiuchi + Beco do Engenho, cor primária `#3FBF3F`;
- ALE: domínio atual preservado, cor primária `#2E8FE2`.

As três facções permanecem integralmente ficcionais. `data/factions.json`, o contrato v4.2 e o geo canon devem permanecer coerentes.

## D14 — Faixa de Ruan

Ruan inicia a campanha na faixa branca. No vertical slice ouro Ruan × Davi, a variante visual autorizada usa faixa azul com exatamente duas graduações. A variante de slice não reescreve a progressão da campanha.

## D15 — Faixa de Davi

Davi usa faixa azul em todas as vistas e animações do slice.

## D16 — Costas do gi de Ruan

Ruan não possui patch traseiro. Marcações frontais ou laterais continuam ficcionais, discretas e sujeitas ao gate de direitos.

## D17 — Desgaste visual

Desgaste, sujeira e speckle do uniforme de Ruan ficam limitados a 30% da área visual útil; devem comunicar uso sem destruir leitura de silhueta, faixa ou contatos.

## D18 — Arco de infiltração adulto

O arco de infiltração é canônico como trama adulta discreta e totalmente ficcional. Ele engloba D21–D28 e não transforma o jogo em tutorial de crime, investigação real ou violência operacional.

## D19 — Migração para Godot 4.7.2

A migração para Godot 4.7.2 exige ADR e lote separados, com import/parser, save, Android, Windows e Web. Nenhum lote visual ou narrativo pode trocar a engine por conveniência. ADR: `docs/architecture/ADR_GODOT_4_7_2_MIGRATION.md`.

## D20 — NFT e Directors

NFT, World Director e Faction Director deixam de orientar evolução do produto. Documentos e catálogo NFT são arquivados. Autoloads e dados ainda consumidos permanecem apenas como compatibilidade legada até ADR de remoção, para não quebrar boot/save/smokes silenciosamente. Nenhuma feature nova pode depender deles.

## D21 — Consórcio e Patrono

O Consórcio e o Patrono são entidades ficcionais do arco de infiltração. Não representam organização, pessoa, empresa, federação ou agente público real.

## D22 — Nado

Nado é personagem ficcional definido para o arco de infiltração, com estado `defined_not_produced`. Função, visual e cenas além do registro canônico dependem do lote narrativo.

## D23 — Helena Vaz e A Maré

Helena Vaz é jornalista da publicação ficcional `A Maré`. Ela não pertence nem fala em nome de polícia, Ministério Público, imprensa ou instituição real.

## D24 — CAPA

`CAPA` é um valor narrativo de exposição entre 0 e 100. O significado, thresholds e efeitos devem vir de dados; não descreve técnica de infiltração real.

## D25 — Fogo de 2019

O fogo de 2019 é evento ficcional pregresso do Terreiro, tratado por consequência humana e memória. Causa, autoria e revelações são dados de narrativa, sem reproduzir caso real.

## D26 — Clandestino

O circuito clandestino usa No-Gi sem pontos. Continua sendo grappling ficcional seguro: tatame, tap/escape/intervenção e hazards apenas cenográficos.

## D27 — Discrição institucional

Nenhuma pessoa, organização, órgão público, academia, federação, imprensa ou instituição real pode aparecer como parte da trama. Nomes, símbolos, uniformes e brasões devem ser originais e ficcionais.

## D28 — Limites de cena

A trama não ensina método criminoso, vigilância, evasão, sabotagem ou infiltração operacional. Menores ficam fora das cenas de risco e do circuito clandestino.

## D29 — VIDA segmentada

A barra VIDA usa valor contínuo com segmentos semânticos verde → âmbar → vermelho. Cor nunca é o único sinal: geometria, rótulo e estado acessível acompanham a mudança.

## D30 — Regras esportivas

Circuito oficial: Gi com pontos e No-Gi com pontos, inspirado abstratamente no ritmo de regras ADCC sem usar marca ou material protegido. Circuito clandestino: No-Gi sem pontos. Finalizações permanecem seguras.

## D31 — Legenda do mapa

Rotas: terrestre amarela, marítima ciano, perigosa vermelha e bloqueada cinza. Tipo de linha/ícone acompanha cor para acessibilidade.

## D32 — Montenegro e DIE

Montenegro integra a agência ficcional `DIE`. Nenhum brasão, uniforme, cargo, sigla expandida ou identidade visual de órgão real pode ser reproduzido.

## D33 — Inputs contextuais

O HUD mostra cinco pílulas de ação contextuais por vez, sem soco ou chute. Elas são selecionadas de um vocabulário maior de comandos de grappling definido na D43.

## D34 — Skins ARENA e RUA

ARENA e RUA são skins sobre um único contrato `data/visual/tokens.json`. Não existem dois HUDs de regra nem lógica duplicada.

## D35 — Personagens definidos e não produzidos

Os IDs `lucas_caveira`, `montenegro_die`, `nado`, `helena_vaz` e `patrono` existem em `data/characters.json` com `production_status=defined_not_produced`. Registro não significa asset, cena ou integração.

## D36 — Crowd

Crowd é baked por padrão, com no máximo quatro personagens animados simultaneamente por stage e variantes low-end.

## D37 — Sprite Forge como ferramenta

`0x0funky/agent-sprite-forge`, MIT, pinado no commit `64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2`, pode ser usado somente como ferramenta offline em `tools/sprite_forge/`.

## D38 — Limite do Sprite Forge

Sprite Forge serve para corte, transparência, layout de atlas, props, mapas e cleanup técnico. Não decide cânone, anatomia, contato, faixa, paleta aprovada ou promoção.

## D39 — Chroma e grappling pareado

Chroma padrão do forge: magenta. Fringe magenta é erro de QA. Animação BJJ pareada final nunca é produzida ou aprovada apenas por esse caminho.

## D40 — Q-REF

Q-REF 01–10 é a régua de comparação visual. Referência orienta composição e qualidade; não autoriza cópia de personagem, cenário, texto, marca ou asset.

## D41 — Bíblia v1 de stages

A Bíblia v1 usa nove pacotes de produção: `Terreiro Vivo` (Dia + Pôr do Sol), `Terreiro Noite-do-Fogo`, Dique, Nishiuchi, Ponte do Saci, Pratigi, Ferro Velho, Manguezal e Budokan. Assim, as dez variantes nomeadas não inventam um décimo local.

## D42 — Set dressing religioso

Altar inspirado em São Jorge/Iemanjá só pode aparecer de forma respeitosa, não interativa e após Gate 06. Na ausência de aprovação, usar fallback devocional totalmente ficcional, sem sincretismo caricato.

## D43 — HUD mobile de grappling

HUD: D-pad de footwork, chip POSIÇÃO, barra GUARDA, Dica de Mestre e cluster com o vocabulário `PEGADA`, `PASSAGEM`, `RASPAGEM`, `FINALIZAÇÃO`, `DEFESA`, `ESQUIVA-DE-QUEDA`, `ESPECIAL`. Somente cinco comandos elegíveis aparecem simultaneamente, conforme D33.

## D44 — Ruan sem tatuagens

Ruan não possui tatuagens em campanha, slice, retratos ou materiais promocionais.

## D45 — Árvore de progressão

A árvore possui quatro ramos por cinco tiers. Dados e UI permanecem paramétricos; nenhum mockup define habilidade nova.

## D46 — Hub Terreiro

O hub Terreiro apresenta seis ações contextuais, desafios, progresso, Cria Live e relógio. Ações concretas vêm dos dados ativos; imagem não vira controle.

## D47 — Pipeline e orçamento de stages

Cada stage nasce com low-end desde o primeiro commit. Orçamento por stage: no máximo dois atlas de 2048², 24 draw calls, 64 partículas simultâneas e crowd conforme D36.

## D86 — Nome canônico corrigido

Colônia Nishiuchi (não Nishimura). Todas as referências anteriores são erro.

## Resoluções operacionais do Lote 00

### R00-01 — `index.html` ativo

A `main` de 27/08/2026 contém um launcher Web/PWA real na raiz e não contém `index-1.html`. Pela hierarquia, o launcher permanece. O laboratório de auditoria é consolidado em `tools/audit/visual_lab.html`; ele não substitui o runtime Web.

### R00-02 — Arquivamento sem regressão

Os documentos de World/Faction Director e o catálogo NFT são movidos para `docs/archived/`. Managers/dados ainda consumidos não são removidos neste lote; isso exigiria ADR de autoload/save e é proibido pela D4 e Cláusula 26.

### R00-03 — “Nove cenários” e dez variantes

A lista explícita contém dez variantes, mas oito locais-base. A D41 resolve o conflito como nove pacotes: Dia/Pôr do Sol compartilham `Terreiro Vivo`; Noite-do-Fogo é pacote separado.

### R00-04 — Trama PF real

Nenhum arquivo versionado na `main` atual contém Polícia Federal/PF. Referências externas desse rascunho são pesquisa não canônica e ficam governadas por `docs/research/INSTITUTIONAL_REFERENCE_BOUNDARY.md`; a história ativa usa DIE e A Maré.
