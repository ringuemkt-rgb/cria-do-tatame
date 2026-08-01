# AGENTS.md — Cria do Tatame

Este arquivo é vinculante para Codex, Manus, agentes locais e qualquer assistente automatizado que trabalhe neste repositório.

## 0. Inicialização obrigatória

Antes de criar, editar, apagar, mover ou integrar qualquer arquivo:

1. leia `README.md`;
2. leia `docs/REPOSITORY_GOVERNANCE.md`;
3. leia `docs/DECISIONS.md`;
4. leia `docs/ROADMAP.md`;
5. leia `docs/INDEX.md` e a fonte canônica da área;
6. consulte `data/production/canon_contract_v4_1.json`;
7. consulte `data/production/faction_migration_v4_2.json` quando tocar facções ou save;
8. consulte `data/production/combat_master_contract_v2.json` quando tocar combate, progressão, arenas ou pipeline visual;
9. consulte `data/production/ruleset_contract_v4_3.json`, `data/combat/rulesets_v01.json` e `data/combat/technique_rulesets_v01.json` quando tocar GI, No-Gi, técnicas, cartas, uniformes ou animações;
10. consulte `data/production/supreme_build_contract_v01.json`;
11. procure implementação, issue ou PR equivalente;
12. defina um lote vertical pequeno, testável e reversível.

Não comece implementando apenas porque a solicitação parece clara. Primeiro confirme a posição da tarefa na arquitetura e no roadmap.

## Missão

Construir **Cria do Tatame – Pressão**, jogo Godot para Android e Windows com combate tático de Jiu-Jitsu Brasileiro, carreira, reputação, mundo vivo do Baixo Sul da Bahia e identidade visual regional premium.

## Fonte única de verdade

```text
ringuemkt-rgb/cria-do-tatame
```

- Não criar outro repositório do jogo.
- Protótipos vivem em branches e precisam de condição de encerramento.
- Não criar segunda árvore de runtime, outro `project.godot`, frontend concorrente ou backend obrigatório.
- Antes de criar sistema novo, procure implementação equivalente.
- Trabalho existente fora de `main` só conta como produto depois de integrado e validado.

## Regra de ouro

Primeiro abrir, rodar, salvar, lutar, concluir, avançar a semana e exportar. Depois expandir e polir.

O repositório não é galeria de prompts, depósito de concept art ou cemitério de branches.

## Cânone inviolável

- Protagonista: Ruan “Macacão” Silva;
- símbolo: Gorila Silverback;
- origem: Ituberá, Baixo Sul da Bahia;
- estilo: pressão, grip de ferro e top game dominante;
- poder: Silverback Grip;
- frase eixo: Ser forte é ser gentil;
- facções ativas do cânone v4: LEM, NTM e ALE;
- nome de exibição de ALE: **Os Aleluiado**;
- ID legado `os_aleluia` é alias de migração e não deve ser renomeado em lugar;
- rulesets canônicos: `GI` e `NO_GI`;
- `GI` permanece padrão para compatibilidade enquanto a seleção completa não estiver integrada;
- No-Gi não pode ser apenas troca cosmética de uniforme.

Caio Ravel, Ruan “Cria”, uma quarta facção ativa, `instant_finish=true` e técnica fora de `data/techniques.json` são bloqueados em shipping.

## Hierarquia de autoridade

Quando houver conflito:

1. contratos executáveis em `data/production/` e contratos canônicos mais recentes;
2. `docs/DECISIONS.md`, `docs/canon/` e decisões aprovadas;
3. runtime, cenas e dados realmente consumidos;
4. `docs/REPOSITORY_GOVERNANCE.md` e este arquivo;
5. documentação técnica ativa;
6. issues/PRs;
7. prompts, concept art, relatórios antigos e branches legadas.

Nunca escolha a versão “mais bonita” ou “mais completa” sem verificar integração, data, testes e precedência.

## Arquitetura obrigatória

- Godot é o único runtime.
- `main` deve permanecer bootável.
- Gameplay crítico é determinístico e offline.
- `CombatManager`, `DeckManager`, `DataRegistry`, `TechniqueClashResolver`, `SaveManager`, `AudioManager` e managers de mundo existentes não podem ser duplicados.
- Migrações usam adapter/fachada e testes de compatibilidade.
- Alteração de autoload exige auditoria de boot.
- Dados persistíveis exigem versão e migração de save.
- IDs de dados são estáveis; renome só com mapper.
- Técnicas vêm exclusivamente de `data/techniques.json`; catálogos auxiliares são projeções e contratos, não segunda fonte.
- O modificador final de clash deve permanecer entre `-0.30` e `+0.35`.
- `instant_finish` é sempre falso.
- Finalizações terminam em tap, escape ou intervenção técnica.
- Controle posicional e fluxo são recursos distintos.
- Uma classe, JSON ou asset sem consumidor real não conta como feature integrada.

## GrappleMap

`Eelis/GrappleMap` pode ser usado como referência de domínio público para:

- grafo dirigido de posições;
- taxonomia e tags;
- poses e entanglements;
- sequência esquemática de transições.

Não pode ser tratado como fonte autoritativa de timing real, cobertura específica de Gi, validação biomecânica ou arte final. Técnicas de tecido exigem referência separada e revisão humana.

## Fluxo que não pode regredir

```text
Main Menu
→ Terreiro
→ treino/deck
→ combate
→ resultado
→ Cria Live
→ avanço da semana
→ save
→ retorno ao Terreiro
```

## Processo de trabalho

1. **Inventário:** arquivos, sistemas, PRs, testes e dependências.
2. **Diagnóstico:** fato, conflito, lacuna, risco e dívida.
3. **Plano vertical:** objetivo observável, escopo, fora do escopo, testes e rollback.
4. **Implementação:** reutilizar arquitetura existente.
5. **Integração:** cena, fluxo, sinais, save, dados e UI.
6. **Validação:** `npm run quality`, Godot, smokes e gates específicos.
7. **Documentação:** decisões, migrações, limitações e evidências.
8. **GitHub:** commit focado, issue e PR atualizados.

## Branches e commits

Use somente prefixos aprovados:

- `fix/`, `feat/`, `content/`, `visual/`, `build/`, `docs/`, `chore/`, `release/`.

Use Conventional Commits. Não trabalhe diretamente em `main` sem autorização explícita e checks verdes.

PR empilhado deve declarar dependência, ordem de merge e base ativa. Se a base for abandonada, porte ou encerre o PR.

## Arte, animação e áudio

- Concept art, mockup, geração bruta e fila de produção são candidatos.
- Asset final exige origem/licença, metadata, preview, QA, aprovação humana e integração Godot.
- Técnica pareada exige atacante, defensor, pivô compartilhado, timing validado, `sync_map` e correspondência entre estado lógico e visual.
- GI e No-Gi exigem variantes quando pegadas, roupa, contato ou áudio divergem.
- Nenhum tecido de kimono pode aparecer em animação No-Gi.
- Não copiar pessoa, marca, frame, aula, logo ou áudio de terceiro sem licença.
- Não promover automaticamente saída de IA para caminhos de shipping.
- Sem teleporte, clipping, pegada invisível antes de projeção ou defensor dessincronizado.

## Segurança

- Não versionar tokens, chaves, `.env`, keystore, senha, credenciais ou dados pessoais.
- Serviços externos são opcionais e tratados como não confiáveis.
- Nenhuma LLM controla o loop de combate.
- Conteúdo cosmético opcional não concede poder jogável.
- Sem animação de lesão como prêmio.
- Sem referência a liga comercial real.

## Gates mínimos

Sempre execute:

```bash
npm run quality
```

Quando aplicável:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/runtime_smoke.gd
godot --headless --path . --script res://tests/ruleset_smoke.gd
```

Mudanças de release Android exigem instalação e teste em aparelho físico. Desempenho estimado não é evidência.

## Saída obrigatória de cada agente

1. Entregue — resultado funcional;
2. Arquivos — criados, modificados e removidos;
3. Integração — consumidor real e fluxo afetado;
4. Validação — comandos e resultados;
5. GitHub — branch, commits, issue e PR;
6. Riscos — falhas, incertezas e dívida;
7. Próximo lote — menor passo vertical de maior valor.

## Condições de parada

Pare e registre bloqueio quando houver:

- conflito de cânone ou precedência;
- risco de apagar trabalho útil;
- branch-base abandonada sem estratégia de port;
- licença ou origem incerta;
- biomecânica insegura;
- credencial ausente;
- ação irreversível não autorizada;
- teste obrigatório impossível no ambiente.

Nunca invente sucesso. Entregue a parte segura e registre a evidência faltante.
