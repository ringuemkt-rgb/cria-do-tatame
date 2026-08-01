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
7. consulte `data/production/faction_migration_v4_2.json` quando tocar facções, aliases ou save;
8. consulte `data/visual/brand_identity_v01.json` quando tocar logo ou marca;
9. para qualquer tarefa visual, leia `.agents/skills/cria-visual-canon-director/SKILL.md` e `data/visual/visual_canon_contract_v2.json`;
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
- nome de exibição de ALE: **Os Aleluiados**;
- ID legado `os_aleluia` é alias de migração e não deve ser renomeado em lugar;
- logo oficial: `assets/branding/logo_oficial_cria_do_tatame.svg`;
- contrato visual oficial: `data/visual/brand_identity_v01.json`;
- sistema visual canônico: `data/visual/visual_canon_contract_v2.json`;
- skill visual obrigatória: `.agents/skills/cria-visual-canon-director/SKILL.md`;
- composição protegida do logo: Silverback frontal, coroa dourada, kimono preto, emblema circular e wordmark `CRIA DO TATAME`;
- paleta principal do logo: preto, branco e dourado;
- `Cria` é o título da marca e não substitui o apelido canônico `Macacão`;
- arte final: pixel art 2D;
- apresentação 2.5D: somente por camadas, parallax, oclusão, luz, partículas e câmera.

Caio Ravel, Ruan “Cria”, uma quarta facção ativa, arte final 3D realista e qualquer substituição não aprovada do logo oficial são bloqueados em shipping.

O arquivo visual do logo é a fonte canônica aprovada pelo criador, mas contém uma marca de terceiro observada nos óculos. Nenhum build comercial pode usar essa versão antes da limpeza jurídica registrada no contrato visual.

## Hierarquia de autoridade

Quando houver conflito:

1. contratos executáveis em `data/production/` e `data/visual/` e contratos canônicos mais recentes;
2. `docs/DECISIONS.md`, `docs/canon/` e decisões aprovadas;
3. runtime, cenas e dados realmente consumidos;
4. `docs/REPOSITORY_GOVERNANCE.md` e este arquivo;
5. skills e documentação técnica ativa;
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

1. **Inventário:** arquivos, sistemas, referências, testes e dependências.
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

- Toda tarefa visual ativa `.agents/skills/cria-visual-canon-director/SKILL.md`.
- Concept art, mockup, geração bruta e fila de produção são referências ou candidatos.
- Estados de asset devem avançar sequencialmente de `reference_only` até `release_ready`.
- Asset final exige origem/licença, metadata, preview, QA, aprovação humana e integração Godot.
- Técnica pareada exige atacante, defensor, pivô compartilhado, timing e `sync_map`.
- Técnicas vêm exclusivamente de `data/techniques.json`.
- Não copiar pessoa, marca, frame, aula, logo ou áudio de terceiro sem licença.
- Não promover automaticamente saída de IA para caminhos de shipping.
- Não redesenhar, simplificar, recolorir ou remover Silverback/coroa do logo oficial sem aprovação explícita do criador.
- Derivados do logo devem preservar proporção, hierarquia, contraste e identidade de Jiu-Jitsu.
- Produção visual ocorre em lotes de até dez itens do mesmo tipo, uma âncora e um commit; QA antes do lote seguinte.
- Finalização visual termina em tap, escape ou intervenção técnica; lesão não é prêmio.
- Mapas conceituais não são autoridade geográfica.
- Prancha editorial não é HUD runtime.

## Segurança

- Não versionar tokens, chaves, `.env`, keystore, senha, credenciais ou dados pessoais.
- Serviços externos são opcionais e tratados como não confiáveis.
- Nenhuma LLM controla o loop de combate.
- Conteúdo cosmético opcional não concede poder jogável.
- Marcas, brasões, academias, ligas, eventos e patrocinadores reais exigem autorização escrita ou substituição ficcional antes de shipping.
- Zambiapunga, referências quilombolas, japonesas, afro-baianas e religiosas exigem contexto e revisão humana.

## Gates mínimos

Sempre execute:

```bash
npm run quality
```

Para trabalho visual:

```bash
python .agents/skills/cria-visual-canon-director/scripts/validate_skill.py
python tools/audit/validate_visual_canon_v2.py
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

Em tarefas visuais, adicionar classificação do asset, cânone aplicado, aprovação humana, licença/cultura e estado Android.

## Condições de parada

Pare e registre bloqueio quando houver:

- conflito de cânone ou precedência;
- risco de apagar trabalho útil;
- branch-base abandonada sem estratégia de port;
- licença ou origem incerta;
- biomecânica insegura;
- símbolo cultural sem contexto suficiente;
- asset sem consumidor definido;
- credencial ausente;
- ação irreversível não autorizada;
- teste obrigatório impossível no ambiente.

Nunca invente sucesso. Entregue a parte segura e registre a evidência faltante.
