# Cria do Tatame — Repositório Supremo

Este documento estabelece `ringuemkt-rgb/cria-do-tatame` como a única fonte oficial do jogo.

## Regra de autoridade

1. `main` deste repositório é a fonte canônica de código, dados, lore e produção.
2. Godot 4.2+ é a engine oficial.
3. Android, PC e Web são alvos de exportação do mesmo projeto Godot.
4. Conteúdo narrativo e mecânico deve ser data-driven sempre que possível.
5. Nenhum repositório legado pode voltar a ser fonte de verdade.

## Repositórios absorvidos

| Repositório legado | Material aproveitado | Destino |
|---|---|---|
| `Modelo-teste-cria-do-tatame-` | validadores Node, manifesto de assets, disciplina de schemas, prototipação rápida e documentação de pipeline | `tools/node/`, `docs/` e workflow de qualidade |
| `Cria-do-tatame-` | referência histórica de build Android | substituída pelo pipeline oficial Godot; não importar Gradle legado |
| `Cria-do-Tatame02` | nenhum código exclusivo relevante | descartar |
| `Tatamecria` | nenhum código exclusivo relevante | descartar |

## Estrutura canônica

```text
cria-do-tatame/
├── project.godot                 # entrada oficial da engine
├── scenes/                       # composição de cenas Godot
├── src/                          # runtime GDScript
├── data/                         # conteúdo estável e versionado
├── schemas/                      # contratos de dados
├── assets/                       # arte, áudio, fontes e animações
├── ai_lore_guardian/             # validação de canon, nunca gameplay crítico
├── tools/
│   ├── node/                     # validadores auxiliares e manifests
│   ├── build/                    # automação de exportação
│   └── validate_complete_game.py # auditoria de integração
├── tests/                        # testes automatizados
├── production/                   # backlog, sprints e handoffs
└── docs/                         # GDD, bíblias, arquitetura e QA
```

## Critérios para importar legado

Um arquivo antigo só entra quando:

- resolve uma necessidade ainda não atendida;
- não contradiz o canon atual;
- não cria uma segunda engine ou segundo runtime;
- passa por validação de segurança, licença e manutenção;
- recebe nome e localização coerentes com a arquitetura oficial.

Arquivos antigos não são copiados em massa. Conceitos úteis são reimplementados no padrão atual.

## Definition of Done da consolidação

- [x] Repositório oficial identificado.
- [x] Canon centralizado.
- [x] Ferramentas Node úteis absorvidas.
- [x] Pipeline de qualidade contínua definido.
- [x] Política para agentes e contribuições documentada.
- [ ] Branch de consolidação revisada e integrada em `main`.
- [ ] Repositórios legados excluídos no painel do GitHub.

## Repositórios a excluir após o merge

- `ringuemkt-rgb/Cria-do-tatame-`
- `ringuemkt-rgb/Cria-do-Tatame02`
- `ringuemkt-rgb/Tatamecria`
- `ringuemkt-rgb/Modelo-teste-cria-do-tatame-`

Antes da exclusão, confirme que esta branch foi incorporada em `main` e que o projeto abre no Godot sem erro fatal.
