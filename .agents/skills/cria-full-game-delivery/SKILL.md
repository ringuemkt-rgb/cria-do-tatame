---
name: cria-full-game-delivery
description: Orquestra entregas verticais verificáveis do jogo CRIA DO TATAME em Godot, do inventário ao PR, sem substituir skills especialistas, contratos, revisão humana ou homologação física.
version: 1.0.0
status: ACTIVE_ORCHESTRATION_SKILL
---

# CRIA FULL GAME DELIVERY — Skill mestra de produção

## Missão e limites
Concluir progressivamente o jogo no repositório **ringuemkt-rgb/cria-do-tatame**, usando exclusivamente o runtime Godot existente, preservando o funcionamento de `main` e entregando funcionalidades reais, integradas, testadas e reversíveis. Esta é uma **skill orquestradora**, não uma nova autoridade, manager, engine, fonte de cânone ou autorização para merge/release. Nunca declarar autonomia irrestrita: direitos, direção artística, revisão técnica de BJJ, revisão humana de PR e Android físico dependem de evidência externa.

## Inicialização obrigatória — em toda sessão
1. Ler integralmente `README.md`, `AGENTS.md`, `docs/REPOSITORY_GOVERNANCE.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md`, `docs/INDEX.md`.
2. Consultar `data/production/canon_contract_v4_1.json`, `data/production/supreme_build_contract_v01.json`, `data/production/game_build_matrix_v1.json`, `data/production/release_gate_status_v01.json` e contratos específicos da tarefa. Não usar matriz ou status desatualizados como verdade de runtime sem confrontar `main`.
3. Inspecionar `project.godot`, cenas e consumidores reais, testes, workflows, branch-base, PRs equivalentes, diffs, reviews, threads, checks, conflitos e histórico recente.
4. Classificar cada item: especificado / implementado / integrado / CI validado / humano ou aparelho validado / release. Não confundir essas categorias.
5. Selecionar o menor lote **funcional**, com critérios de aceitação observáveis, dependências, riscos e rollback. Se não houver acesso de escrita ou testes, entregar patch verificável e declarar a limitação; não inventar commits.

## Especialistas obrigatórios (carregar sob demanda, não duplicar)
- **Combate, regras, cartas, IA e animações BJJ:** `.agents/skills/cria-combat-intelligence/SKILL.md`.
- **Captura, vídeo, biomecânica e contato:** `.agents/skills/cria-grappling-motion-lab/SKILL.md` mais skill de combate.
- **Qualquer arte visual:** `.agents/skills/cria-art-direction/SKILL.md`.
- **Sprites, personagens, animações e mapas por camadas:** `.agents/skills/cria-sprite-forge/SKILL.md` mais direção de arte; animação BJJ exige também combate e, quando derivada de vídeo, Motion Lab.
- **QA, build, mundo, narrativa, economia, áudio, segurança:** consultar primeiro os contratos, scripts, testes, skills e decisões já existentes da área; criar nova skill especializada apenas com lacuna demonstrada.
Esta skill **não reescreve** os procedimentos técnicos dessas skills. Executar seus gates específicos.

## Ordem de produção por dependências
**P0 — Vertical slice ouro:** Main Menu → Terreiro → treino/árvore/deck → Arena do Dique/Ruan × Davi → resultado → Cria Live → avanço da semana → save/reload → Terreiro. Fechar comandos e cartas no HUD, controles touch e teclado, navegação segura, falha de save, ciclo de combate e exportação debug.
**P1 — Conteúdo visual mínimo aprovado:** identidade Ruan/Davi, locomoção, animações pareadas essenciais, Terreiro e arena por camadas, UI e áudio mínimo; sem assets ficticiamente 'finais'.
**P2 — Mundo e carreira:** atlas regional de 10 páginas/40 nós quando contrato permitir, destinos jogáveis autorizados, NPCs, missões, facções, recompensas, economia e progressão persistente.
**P3 — Amplitude de conteúdo:** roster, técnicas, arenas, atos, finais e audiovisual conforme metas do contrato supremo; só marcar completo com consumidores e cobertura reais.
**P4 — Estabilização/release:** QA visual, desempenho, acessibilidade, Android ARM64 e Windows, testes físicos, direitos, aprovação e release gates.
Se um P2/P3 desbloquear P0, executar somente o recorte necessário. Evitar expansão horizontal sem fluxo jogável.

## Regras arquiteturais e de mundo
- Reutilizar `CombatManager`, `DeckManager`, `SaveManager`, `WorldState`, `WorldMapManager`, `AudioManager` e autoridades existentes. Não criar manager concorrente, segundo `project.godot`, segundo runtime ou dependência online obrigatória.
- Estado e pontuação do BJJ vêm do reducer/contratos de regras; animação, LLM, vídeo e UI não decidem legalidade, score ou vencedor. Jogo determinístico e funcional offline.
- IDs persistentes imutáveis; migrações com mapper, versão e regressão de save, incluindo legado Salvador. `os_aleluia` é alias de migração, ALE exibe 'Os Aleluiado'.
- Ruan “Macacão” Silva, Ituberá como hub, Baixo Sul como domínio jogável autorizado. Salvador e Itacaré apenas contexto externo. Mapas enviados são referência artística; nunca inferir geocoordenadas, estradas, distâncias ou colisão a partir de imagem.
- Cada recurso deve ter consumidor real em cena. JSON isolado, prompt, mockup e branch aberta não são entrega integrada.

## Pipeline de código — ciclo obrigatório
1. **Inventariar** `main`, PRs e implementação equivalente. PRs #167/#168/#169 e #157/#164/#165/#166 são referências de integração, não autorização de merge; verificar estado atual, inclusive #188–#194, antes de portar.
2. **Planejar** feature pequena com teste negativo, teste positivo, caminho de usuário, save/reload e rollback. Evitar PRs empilhados sem necessidade; se empilhar, documentar base, ordem e CI ausente.
3. **Implementar** em branch temporária aprovada, commits Conventional Commits, alterações mínimas; preservar boot, APIs e sinais.
4. **Testar** `npm run quality`, importação Godot headless, `tests/runtime_smoke.gd`, smokes específicos, contratos de dados, regressões de touch/rotação, save legado e combate determinístico. Executar nas versões disponíveis (produção 4.3+, compatibilidade 4.2.2 quando exigida). Registrar comandos, ambiente e saída; CI verde em outro commit não prova head atual.
5. **Revisar integração**: diff contra base, arquivos afetados, regressões, conflitos, check suites, revisão humana, comentários não resolvidos e artefatos de build. Nunca mesclar sem todos os gates exigidos e aprovação.
6. **Entregar PR Draft** com objetivo, antes/depois, consumidor, testes reais, pendências, riscos e rollback. Sem merge automático, push direto em `main` ou declaração de APK certificado.

## Pipeline Sprite Forge e audiovisual
- Fonte de requisitos: manifesto de produção ativo, contrato Sprite Forge, identidade e fila derivada; `shipping=false` até aprovação.
- Produzir candidatos com origem, licença, ferramenta/modelo, revisão, referências, hash/metadata, preview e QA; nunca reutilizar mídia de terceiros sem direitos.
- Sprites de gameplay normalizados a 128×128 RGBA, pivot [64,96], nearest-neighbor, escala inteira e alpha conforme contrato vigente; confirmar perfis por ação.
- BJJ exige duas pessoas sincronizadas, fases anticipation/entry/establish/stabilize/response/recovery, pivô, contato e sync map, revisão biomecânica humana.
- Mapas são camadas independentes com colisão/navegação autoradas, não imagens planas promovidas automaticamente.
- Rodar validadores e testes Sprite Forge, visualizar frames reais e integrar na cena somente após revisão de direitos e aprovação humana.

## Matriz de evidência / Definition of Done
Para cada funcionalidade: requisito canônico → implementação → consumidor de runtime → regressão positiva/negativa → save/reload quando aplicável → CI head → revisão humana quando obrigatória → dispositivo físico quando necessário. Estado 'PASS' exige evidências de cada gate aplicável.
Android: export debug ≠ APK certificado; exigir instalação em aparelho, toque, rotação, desempenho medido, ciclo completo, reinício e recuperação de save. Windows: smoke de export e execução. Não estimar FPS como medição.
Bloqueadores: fontes BJJ incompletas, rights, master de identidade ausente, aprovação humana, testes indisponíveis ou divergência de cânone; parar a promoção da parte bloqueada, mas continuar em trabalho seguro independente.

## Política de execução autônoma
Pode pesquisar, auditar, escrever código, criar testes, atualizar documentação e abrir PRs quando ferramentas e permissões permitirem. Não executar merge, release, alteração irreversível, promoção de arte ou aprovação em nome de humano. Não prometer atividade contínua sem automação configurada; cada execução é delimitada e auditável.
Priorizar consertar falhas detectadas por CI e fechar PRs existentes sobre abrir uma cadeia infinita de patches triviais.

## Relatório final obrigatório (sem marketing)
- **Entregue:** comportamento observável e consumidor.
- **Arquivos/commits:** caminhos, branch, SHAs e URL do PR; se não criados, dizer explicitamente.
- **Validação:** comando, versão, resultado PASS/FAIL/NOT RUN, links de CI do head.
- **Integração:** PRs dependentes, revisão, conflitos, estado de `main`, rollback.
- **Bloqueios:** humano, direitos, fontes, Android físico, testes e qualquer incerteza.
- **Próximo lote:** uma entrega funcional pequena com critérios de aceite.
Nunca confundir plano com código publicado nem 'mergeable' com autorização de merge.
