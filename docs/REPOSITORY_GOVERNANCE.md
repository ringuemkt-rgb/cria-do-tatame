# Governança do Repositório — Cria do Tatame

## 1. Fonte única de verdade

O único repositório oficial é:

```text
ringuemkt-rgb/cria-do-tatame
```

Código, dados, cânone, arte, áudio, ferramentas, builds, documentação e planejamento do jogo devem apontar para este repositório. Outro repositório não pode ser usado como continuação, versão premium, protótipo oficial ou fonte concorrente.

## 2. Hierarquia de autoridade

Quando houver conflito, use esta ordem:

1. `data/production/supreme_build_contract_v01.json` e contratos canônicos executáveis mais recentes;
2. `docs/canon/` e decisões registradas no repositório;
3. `project.godot`, runtime em `src/`, cenas em `scenes/` e dados consumidos em `data/`;
4. `AGENTS.md` e este documento;
5. documentação técnica ativa;
6. issues e PRs abertos;
7. documentos históricos, prompts, concept art e branches antigas.

Documentação não integrada não substitui o runtime. Código legado também não pode contrariar um cânone aprovado sem uma migração explícita.

## 3. Branches oficiais

### Permanentes

- `main` — versão integrada, bootável e protegida;
- `release/<versao>` — estabilização temporária de uma release ou migração grande, quando declarada no roadmap.

### Temporárias

- `fix/`, `feat/`, `content/`, `visual/`, `build/`, `docs/`, `chore/`.

Uma branch temporária deve possuir issue/PR, responsável, base, objetivo e condição de encerramento. Depois do merge ou descarte documentado, deve ser removida para reduzir ruído.

## 4. Política para PRs empilhados

PR empilhado é permitido apenas quando:

- a dependência está declarada;
- a branch-base continua ativa;
- a ordem de merge está registrada;
- cada PR possui valor e testes próprios;
- não há duplicação de managers, dados ou contratos.

Se a base mudar, o PR deve ser rebaseado, portado ou encerrado. PR parado sobre branch abandonada não é backlog: é dívida técnica fantasiada de progresso.

## 5. Matriz atual de integração

Estado observado em 1º de agosto de 2026:

| PR | Tema | Situação recomendada |
|---|---|---|
| #32 | Integração v4 | Branch principal de consolidação técnica; auditar e dividir antes do merge por possuir escopo muito amplo |
| #33 | Protocolo | Portar conteúdo útil para a trilha de governança e encerrar o PR empilhado após absorção |
| #34 | Combate/progressão | Rebasear sobre a integração escolhida e manter apenas bridges, testes e bindings realmente necessários |
| #35 | Marca e padrão visual | Portar contratos válidos; binários finais continuam em PR de asset dedicado |
| #37 | Boot e governança | Absorver auditoria de boot após reconciliar com a nova governança |
| #38 | Visual Forge | Rebasear após a integração canônica; manter pipeline separado dos assets aprovados |
| #24 | Audiovisual V10 | Extrair em lotes verticais menores; não mesclar um pacote de centenas de caminhos sem revisão humana |
| #25 | Game feel | Portar incrementalmente por sistema, preservando `CombatManager` estável |
| #26 | Open Pixel Forge | Manter como ferramenta opcional; não entra no runtime nem promove asset automaticamente |

A matriz deve ser atualizada sempre que a ordem de integração mudar.

## 6. Estrutura oficial

```text
.
├── .github/             # templates, workflows e responsáveis
├── .agents/             # skills e regras para agentes
├── assets/              # assets aprovados ou claramente separados como candidatos
├── data/                # dados consumidos e contratos executáveis
├── docs/                # documentação ativa e índice canônico
├── scenes/              # cenas Godot
├── src/                 # runtime Godot
├── tests/               # testes de runtime, dados e regressão
├── tools/               # auditoria, build e produção offline
├── production/          # controle de produção e lotes
├── reports/             # relatórios versionáveis; saídas locais pesadas ficam ignoradas
├── project.godot
├── export_presets.cfg
├── AGENTS.md
├── CONTRIBUTING.md
└── README.md
```

Não criar uma segunda árvore `game/`, outro `project.godot`, frontend concorrente ou subprojeto externo dentro do repositório.

## 7. Organização de documentação

- `docs/canon/` — cânone aprovado;
- `docs/architecture/` — decisões e contratos técnicos;
- `docs/gameplay/` — combate, progressão e regras;
- `docs/art_bible/` — direção visual ativa;
- `docs/production/` — lotes, pipeline e metas;
- `docs/qa/` — auditorias, testes e evidências;
- `docs/archive/` — documentos substituídos, preservados somente para histórico.

Todo documento ativo deve indicar status, versão ou data quando houver risco de ambiguidade. Documento substituído deve apontar para seu sucessor antes de ser arquivado.

## 8. Gates por tipo de mudança

### Runtime

- parser/import Godot;
- smoke do fluxo afetado;
- regressão de save e dados;
- ausência de manager concorrente.

### Dados e cânone

- JSON/schema;
- referências e IDs;
- migração de save;
- auditoria de nomes proibidos e facções.

### Visual e áudio

- origem/licença;
- pacote de QA;
- escala, pivô, sync e legibilidade;
- integração em cena real;
- aprovação humana.

### Android e release

- exportação reproduzível;
- assinatura e arquitetura;
- instalação em aparelho físico;
- touch/safe area;
- FPS, memória, temperatura e bateria;
- save após reinício.

## 9. Política de limpeza

A limpeza ocorre em quatro passos:

1. inventariar branch, PR, issue ou arquivo;
2. identificar se foi absorvido, substituído, abandonado ou ainda necessário;
3. registrar destino e evidência;
4. somente então fechar, arquivar ou remover.

Nunca apagar trabalho apenas para “deixar bonito”. Organização profissional preserva conhecimento e elimina ambiguidade.

## 10. Regra de conclusão

Existem seis estados diferentes e eles não podem ser misturados:

1. especificado;
2. implementado;
3. integrado;
4. validado automaticamente;
5. testado por humano/aparelho;
6. pronto para release.

Quantidade de arquivos, commits, prompts ou imagens não aumenta automaticamente o estado de conclusão.
