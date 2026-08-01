# Auditoria do Repositório — 1º de agosto de 2026

**Status:** ACTIVE  
**Branch auditada:** `main` em `f098ab57c0eae545ae097b6d5ea02c39788324e5`

## Resultado executivo

O repositório contém uma base Godot real e auditada, mas a construção está fragmentada entre muitas branches e PRs empilhados. O risco dominante não é ausência de implementação: é integração concorrente, documentação com precedência ambígua e branches que permanecem abertas depois de absorção ou abandono.

## Inventário observado

- 1 repositório canônico;
- 36 branches remotas encontradas;
- 9 pull requests abertos;
- `main` sem atividade integrada desde 18/07/2026;
- branch `release/v4-integration` com grande volume de mudanças ainda fora de `main`;
- PRs visuais, game feel e ferramentas partindo de bases diferentes;
- issues antigas descrevendo estados já parcialmente superados.

## Branches encontradas

### Permanentes ou temporariamente estratégicas

- `main`;
- `release/v4-integration` — integração canônica proposta;
- `chore/repository-professionalization-v1` — governança criada por esta auditoria.

### Trabalho ativo que precisa de decisão de integração

- `agent/visual-audio-world-v10`;
- `build/epic-0-foundation-governance`;
- `docs/game-build-protocol-v1`;
- `docs/visual-quality-and-logo-v1`;
- `feat/cria-visual-forge-v1`;
- `feat/open-pixel-forge-v1`;
- `feature/combat-integration-contract`;
- `release/unify-and-feel`.

### Branches já associadas a PRs mesclados ou fechados

Devem ser verificadas contra o commit de merge antes da remoção:

- `audit/full-game-hardening-2026-07`;
- `consolidation/supreme-repository-2026-07`;
- `feature/faction-director-v2`;
- `feature/functional-ai`;
- `feature/local-ai-dialogue`;
- `feature/world-director-ai-nft-v1`;
- `fix/p0-bugs`;
- `upgrade/apk-visual-pipeline-v09`;
- `upgrade/runtime-audit-v08`;
- `rescue/sprint-0-complete`;
- `ringuemkt-rgb-patch-1`;
- `codex/build-visao-de-cria-system`;
- `codex/create-comprehensive-e-book-production-system`;
- `codex/visual-format-v10`;
- `agent/repository-hardening-2026-07`;
- `docs/gdd-cdt-v4-canon`;
- `feat/positional-card-combat-v1`.

### Branches sem destino profissional explícito

Precisam de inspeção e, se não contiverem trabalho exclusivo, remoção:

- `delete-me-noop`;
- `test-noop`;
- `visual-test-branch-safe`;
- `visual-pipeline-completo`;
- `visual-pipeline-full`;
- `feature/assets-pipeline`;
- `feature/autoloads-foundation`;
- `codex/vertical-slice-system`;
- `docs/cps-standard-v43`.

## Pull requests abertos

| PR | Base | Diagnóstico |
|---|---|---|
| #24 | `release/v4-integration` | Audiovisual muito amplo; extrair em lotes revisáveis |
| #25 | `release/v4-integration` | Não mergeável; portar game feel incrementalmente |
| #26 | `release/unify-and-feel` | Ferramenta opcional empilhada sobre PR instável |
| #32 | `main` | Integração v4 valiosa, porém grande demais para merge cego |
| #33 | `release/v4-integration` | Governança/protocolo deve ser absorvido pela trilha profissional |
| #34 | `release/v4-integration` | Bridges úteis; precisa rebase e gates verdes |
| #35 | `docs/game-build-protocol-v1` | Padrão visual empilhado; separar contrato de binários finais |
| #37 | `docs/visual-quality-and-logo-v1` | Auditoria de boot útil sobre cadeia documental longa |
| #38 | `main` | Visual Forge útil, mas deve acompanhar a integração canônica |

## Problemas de governança encontrados

1. ausência de CODEOWNERS;
2. ausência de guia formal de contribuição;
3. ausência de templates estruturados para bug e lote;
4. ausência de índice canônico de documentação;
5. ausência de gate executável de governança;
6. múltiplas branches com nomes de teste, legado ou produto externo;
7. PRs empilhados sobre bases diferentes;
8. estado de conclusão frequentemente descrito em documentos e PRs, não em uma release ledger única;
9. `main` funcional, porém distante do volume de trabalho já produzido fora dela.

## Correções aplicadas nesta auditoria

- `.editorconfig` e `.gitattributes`;
- CODEOWNERS;
- template de PR;
- formulários de bug e lote;
- `CONTRIBUTING.md` e `SECURITY.md`;
- governança, índice e roadmap;
- contrato executável de fonte única;
- validador Python;
- workflow de governança;
- integração do validador ao `npm run quality`;
- reconstrução do README e do protocolo de agentes.

## Plano de limpeza segura

### Fase 1 — Integrar governança

Mesclar o PR de profissionalização após checks verdes.

### Fase 2 — Classificar branches

Para cada branch:

1. comparar com `main`;
2. identificar commits exclusivos;
3. vincular a PR/issue;
4. marcar como `portar`, `absorvida`, `abandonada` ou `manter`;
5. remover somente depois do registro.

### Fase 3 — Quebrar a integração v4

Portar o PR #32 em lotes:

- cânone e contratos;
- facções/save;
- combate e dados;
- mundo/economia;
- terreno/acessibilidade.

### Fase 4 — Portar os pacotes laterais

- #25 por módulos de game feel;
- #24 por pacotes verticais de asset;
- #26 como ferramenta opcional;
- #38 depois que os contratos visuais estiverem reconciliados.

### Fase 5 — Fechar e remover legado

Fechar PRs substituídos com comentário de destino e remover branches absorvidas ou vazias.

## Limite desta rodada

Esta auditoria não apaga branches nem mescla os PRs de produto. A prioridade foi criar os controles necessários para que a limpeza seja rastreável, reversível e sem perda de trabalho.
