# Matriz de PRs — 13/08/2026

## Resumo

- total aberto observado: **23 PRs**;
- `main`: `d99780ffb42aff4f66e71a62f9e24f6f8f8d0a2e`;
- merge durante o congelamento: **proibido**;
- prioridade: reduzir pilhas e reconciliar fonte de verdade antes de escala.

## Matriz crítica

| PR | Papel | Base atual | Estado | Dependência | Decisão de congelamento |
|---|---|---|---|---|---|
| #24 | marco visual/áudio/mundo v10 | `release/v4-integration` | Draft | legado seletivo | NÃO merge monolítico; extrair somente material aprovado |
| #48 | logo/brand oficial | `main` histórico | Draft / conflito | início da cadeia visual | revisar risco jurídico do wordmark e reconciliar com HEAD |
| #51 | Visual Canon + skill 2D/2.5D | #48 | Draft | #48 | manter empilhado; portar decisões válidas após cânone v5 |
| #52 | ART_PROTOCOL v1 | #51 | Draft | #48→#51 | manter empilhado; não retargetear antes da decisão visual |
| #61 | GPT WORK v2 / GATE-L1 / packs / DVC | `main@d99780f` | Draft / mergeable | blocker estrutural | **PRIORIDADE 1 após cânone**; migrar para 4 gates reais |
| #63 | campanha 40 missões / Mundo V3 | #61 | Draft / mergeable | #61 + decisão canônica | reescrever/portar sobre cânone final; não mergear como está |
| #65 | Visual QA V2 | #61 | Draft / mergeable | #61 | rebase após #61; manter sem poder de promoção |
| #66 | paired-motion/mocap prototype | `main@d99780f` | Draft | captura própria + Visual QA futuro | lateral; contrato/QA apenas, sem shipping |
| #67 | Atlas BJJ + authoring specs | `main@d99780f` | Draft / mergeable | cânone/fundação + citações | lateral; research-only, sem mocap inventado |

## Topologia

```text
main
├── #61
│   ├── #63
│   └── #65
├── #66
└── #67

#48 → #51 → #52
```

### Interpretação

- #63 e #65 são **irmãos** baseados em #61.
- #66 e #67 não devem entrar na cadeia #61/#63/#65; são linhas de pesquisa/produção offline independentes.
- #48/#51/#52 formam uma cadeia visual antiga e devem ser reconciliados seletivamente, não absorvidos às cegas.

## Ordem recomendada de tratamento

1. `ctt.canon.reconciliacao.v5` — definir aliases, personagens, geografia, campanha, cultura e contagens.
2. `ctt.pr61.fechar.v1` — Stack v3.1, L1 licença, L2 provenance, L3 rights, L4 humano; PackLoader smoke.
3. `ctt.pr65.visual_qa.v1` — rebasear sobre #61 final e validar fixtures/CI.
4. `ctt.pr63.narrativa.v1` — portar dados/state machine/tests sobre o cânone final.
5. decidir #48→#51→#52 por cherry-pick/port de contratos válidos, evitando merge monolítico legado.
6. manter #66/#67 Draft até existir captura/citação/provenance e conexão formal com Visual QA.
7. depois: multiplataforma → slice ouro → testes físicos → limpeza de branches.

## Regras de decisão por categoria

### MERGE CANDIDATE
Somente quando: base atualizada + CI verde + sem conflito canônico + revisão humana + nenhum gate de release falsificado.

### PORT / CHERRY-PICK
Preferido para PRs antigos que misturam assets, contratos e runtime já parcialmente supersedidos.

### SUPERSEDE / CLOSE
Usar quando a intenção já foi incorporada por contrato mais novo ou quando manter a pilha custa mais do que portar o conteúdo útil.

### HOLD DRAFT
Usar para pesquisa, mocap, atlas, Visual QA e produção que ainda dependem de GATE-L4 ou de um PR-base.

## P0 de governança

- `main` não possui proteção no snapshot;
- nenhuma ação disponível nesta sessão expôs escrita de branch protection; configuração permanece ação administrativa externa ao commit;
- 23 PRs abertos é a dívida operacional a reduzir;
- nenhum merge foi executado por esta diretiva.
