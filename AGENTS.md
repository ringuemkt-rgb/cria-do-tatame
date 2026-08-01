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
7. consulte `data/production/faction_migration_v4_2.json`;
8. para qualquer tarefa visual, leia `.agents/skills/cria-visual-production-director/SKILL.md` e `data/visual/visual_production_director_v1.json`;
9. consulte `data/production/supreme_build_contract_v01.json`;
10. procure implementação, issue ou PR equivalente;
11. defina um lote vertical pequeno, testável e reversível.

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
- nome de exibição de ALE: **Os Aleluiados**;
- ID legado `os_aleluia` é alias de migração e não deve ser renomeado em lugar.

Caio Ravel, Ruan “Cria”, `Os Aleluia`, `Os Aleluiado` e uma quarta facção ativa são bloqueados em material novo e shipping.

## Hierarquia de autoridade

Quando houver conflito:

1. contratos executáveis em `data/production/` e `data/visual/` e contratos canônicos mais recentes;
2. `docs/DECISIONS.md`, `docs/canon/` e decisões aprovadas;
3. runtime, cenas e dados realmente consumidos;
4. `docs/REPOSITORY_GOVERNANCE.md` e este arquivo;
5. documentação técnica e art bible ativas;
6. issues/PRs;
7. prompts, concept art, relatórios antigos e branches legadas.

Nunca escolha a versão “mais bonita” ou “mais completa” sem verificar integração, data, testes e precedência.

## Arquitetura obrigatória

- Godot é o único runtime.
- `main` deve permanecer bootável.
- Gameplay crítico é determinístico e offline.
- `CombatManager`, `DeckManager`, `AudioManager` e managers de mundo existentes não podem ser duplicados.
- Migrações usam adapter/fachada e testes de compatibilidade.
- Alteração de autoload exige auditoria de boot.
- Dados persistíveis exigem versão e migração de save.
- IDs de dados são estáveis; renome só com mapper.
- Uma classe, JSON ou asset sem consumidor real não conta como feature integrada.

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

- Toda tarefa visual ativa obrigatoriamente a skill `.agents/skills/cria-visual-production-director/SKILL.md`.
- O contrato executável é `data/visual/visual_production_director_v1.json`.
- O padrão humano é `docs/art_bible/VISUAL_RECONCILIATION_AND_PRODUCTION_STANDARD_V2.md`.
- Concept art, mockup, ficha densa, geração bruta e fila de produção são candidatos.
- Prancha 1536×1536 não é HUD de runtime, sprite ou prova de integração.
- Asset final exige origem/licença, metadata, preview, QA, aprovação humana e integração Godot.
- Técnica pareada exige atacante, defensor, pivô compartilhado, mesmo frame count, timing e `sync_map`.
- Personagens são produzidos a partir de seed aprovado e strip completa; frame independente é proibido por padrão.
- GI e No-Gi exigem variantes técnicas reais, não apenas troca de roupa.
- Não copiar pessoa, marca, frame, aula, logo ou áudio de terceiro sem licença.
- Não promover automaticamente saída de IA para caminhos de shipping.
- Pixel art final deve usar filtro nearest, grade legível, escala estável e leitura em Android.
- HUD runtime protege o playfield; lore e estatística extensa ficam em tutorial, codex, pausa ou art bible.

## Segurança

- Não versionar tokens, chaves, `.env`, keystore, senha, credenciais ou dados pessoais.
- Serviços externos são opcionais e tratados como não confiáveis.
- Nenhuma LLM controla o loop de combate.
- Conteúdo cosmético opcional não concede poder jogável.
- Marcas, brasões, ligas, academias, polícias, prefeituras e patrocinadores reais exigem licença ou substituição ficcional.

## Gates mínimos

Sempre execute:

```bash
npm run quality
```

Quando aplicável:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/runtime_smoke.gd
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

Para tarefas visuais, acrescente:

8. classificação da referência;
9. correções canônicas aplicadas;
10. seed/âncora/escala e regras GI/No-Gi;
11. score visual e blockers;
12. aprovação humana e teste de aparelho.

## Condições de parada

Pare e registre bloqueio quando houver:

- conflito de cânone ou precedência;
- risco de apagar trabalho útil;
- branch-base abandonada sem estratégia de port;
- licença ou origem incerta;
- biomecânica insegura;
- técnica ausente de `data/techniques.json`;
- personagem, facção, ruleset ou localização não confirmados;
- animação pareada sem defensor ou sincronização;
- credencial ausente;
- ação irreversível não autorizada;
- teste obrigatório impossível no ambiente.

Nunca invente sucesso. Entregue a parte segura e registre a evidência faltante.
