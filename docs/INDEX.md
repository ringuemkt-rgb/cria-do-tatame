# Índice da Documentação

Este arquivo é a porta de entrada da documentação ativa. Antes de criar um documento novo, verifique se o assunto já possui fonte canônica.

## Comece aqui

- [`../README.md`](../README.md) — visão do produto, instalação e comandos principais;
- [`../AGENTS.md`](../AGENTS.md) — regras obrigatórias para agentes;
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — fluxo de contribuição;
- [`DECISIONS.md`](DECISIONS.md) — decisões arquiteturais e canônicas D1–D15;
- [`REPOSITORY_GOVERNANCE.md`](REPOSITORY_GOVERNANCE.md) — fonte única, branches, PRs e gates;
- [`ROADMAP.md`](ROADMAP.md) — sequência oficial de construção.

## Contratos executáveis

- [`../data/production/canon_contract_v4_1.json`](../data/production/canon_contract_v4_1.json) — cânone v4.1 e emendas D10, D14 e D15;
- [`../data/production/faction_migration_v4_2.json`](../data/production/faction_migration_v4_2.json) — três facções ativas, aliases, display e save v5;
- [`../data/world/baixo_sul_map_v2.json`](../data/world/baixo_sul_map_v2.json) — sete municípios, quinze arenas e limite geográfico jogável;
- [`../data/production/vertical_slice_gold_v1.json`](../data/production/vertical_slice_gold_v1.json) — Ruan × Davi, HUD, deck, oito técnicas, assets e gate Android;
- [`../data/production/supreme_build_contract_v01.json`](../data/production/supreme_build_contract_v01.json) — metas e release gates;
- [`../data/production/release_gate_status_v01.json`](../data/production/release_gate_status_v01.json) — ledger único com evidências e pendências de release;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — inventário audiovisual;
- [`../data/production/repository_governance_v01.json`](../data/production/repository_governance_v01.json) — governança validável por máquina.

## Produto e gameplay

- [`CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md`](CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md) — escopo de produto;
- [`gameplay/COMBAT_DECK_SYSTEM_V01.md`](gameplay/COMBAT_DECK_SYSTEM_V01.md) — deck atual integrado à `main`;
- `canon/` — personagens, facções, mundo e narrativa aprovados;
- `gameplay/` — combate, progressão, regras e economia.

## Mundo canônico

- [`../data/world/baixo_sul_map_v2.json`](../data/world/baixo_sul_map_v2.json) — fonte única para municípios, arenas e rotas novas;
- Ituberá é o hub principal;
- Ponte do Saicí e Pratigi pertencem a Ituberá;
- Zambiapunga pertence a Nilo Peçanha;
- Salvador, São Paulo e Itacaré não são nós jogáveis.

## Migrações ativas

- [`migrations/V4_2_FACTIONS_SAVE.md`](migrations/V4_2_FACTIONS_SAVE.md) — explicação da migração para `ALE`, `LEM`, `NTM` e save v5.

## Arte e produção

- `art_bible/` — identidade visual e contratos de qualidade ativos;
- `production/` — planos de lote, APK, animação, áudio e conteúdo;
- [`production/APK_VISUAL_COMPLETION_PLAN_V09.md`](production/APK_VISUAL_COMPLETION_PLAN_V09.md) — gates de vertical slice e Android;
- [`../data/production/vertical_slice_gold_v1.json`](../data/production/vertical_slice_gold_v1.json) — pacote de produção prioritário;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — entregáveis mínimos por asset.

## Engenharia e QA

- `architecture/` — decisões e integrações técnicas;
- `qa/` — auditorias e evidências;
- [`qa/RUNTIME_AUDIT_V08.md`](qa/RUNTIME_AUDIT_V08.md) — auditoria do fluxo central;
- [`../tools/audit/validate_repository_governance.py`](../tools/audit/validate_repository_governance.py) — gate de organização;
- [`../tools/audit/validate_canon_contract_v4_1.py`](../tools/audit/validate_canon_contract_v4_1.py) — gate do cânone e das decisões P0;
- [`../tools/audit/validate_faction_migration_v4_2.py`](../tools/audit/validate_faction_migration_v4_2.py) — gate das três facções, aliases e save v5;
- [`../tools/audit/validate_p0_canon_baixo_sul.py`](../tools/audit/validate_p0_canon_baixo_sul.py) — gate de Os Aleluiados, mapa do Baixo Sul e vertical slice ouro.

## Status dos documentos

Use um destes estados no início de documentos novos quando o contexto não for óbvio:

- `CANONICAL` — fonte ativa e autoritativa;
- `ACTIVE` — documento de trabalho vigente;
- `DRAFT` — proposta ainda não integrada;
- `SUPERSEDED` — substituído; deve apontar para o sucessor;
- `ARCHIVED` — histórico, não orienta implementação.

Prompts, relatórios antigos, concept arts e branches não são automaticamente fontes canônicas.
