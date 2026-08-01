# Índice da Documentação

Este arquivo é a porta de entrada da documentação ativa. Antes de criar um documento novo, verifique se o assunto já possui fonte canônica.

## Comece aqui

- [`../README.md`](../README.md) — visão do produto, instalação e comandos principais;
- [`../AGENTS.md`](../AGENTS.md) — regras obrigatórias para agentes;
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — fluxo de contribuição;
- [`DECISIONS.md`](DECISIONS.md) — decisões arquiteturais e canônicas D1–D11;
- [`REPOSITORY_GOVERNANCE.md`](REPOSITORY_GOVERNANCE.md) — fonte única, branches, PRs e gates;
- [`ROADMAP.md`](ROADMAP.md) — sequência oficial de construção.

## Contratos executáveis

- [`../data/production/canon_contract_v4_1.json`](../data/production/canon_contract_v4_1.json) — cânone v4.1, autoridades de runtime, facções e aliases;
- [`../data/production/faction_migration_v4_2.json`](../data/production/faction_migration_v4_2.json) — três facções ativas, aliases e save v5;
- [`../data/visual/visual_production_director_v1.json`](../data/visual/visual_production_director_v1.json) — direção visual executável, pixel art, GI/No-Gi, animação pareada, UI, licenças e quality score;
- [`../data/visual/templates/visual_asset_brief_v1.json`](../data/visual/templates/visual_asset_brief_v1.json) — template obrigatório para briefs e QA de assets;
- [`../data/production/supreme_build_contract_v01.json`](../data/production/supreme_build_contract_v01.json) — metas e release gates;
- [`../data/production/release_gate_status_v01.json`](../data/production/release_gate_status_v01.json) — ledger único com evidências e pendências de release;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — inventário audiovisual;
- [`../data/production/repository_governance_v01.json`](../data/production/repository_governance_v01.json) — governança validável por máquina.

## Skills vinculantes

- [`../.agents/skills/cria-visual-production-director/SKILL.md`](../.agents/skills/cria-visual-production-director/SKILL.md) — **cria-visual-production-director**, autoridade operacional para personagem, arena, mapa, HUD, facção, sprite, animação e integração visual.

## Produto e gameplay

- [`CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md`](CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md) — escopo de produto;
- [`gameplay/COMBAT_DECK_SYSTEM_V01.md`](gameplay/COMBAT_DECK_SYSTEM_V01.md) — deck atual integrado à `main`;
- `canon/` — personagens, facções, mundo e narrativa aprovados;
- `gameplay/` — combate, progressão, regras e economia.

## Migrações ativas

- [`migrations/V4_2_FACTIONS_SAVE.md`](migrations/V4_2_FACTIONS_SAVE.md) — explicação simples da migração para `ALE`, `LEM`, `NTM` e save v5.

## Arte e produção

- `art_bible/` — identidade visual e contratos de qualidade ativos;
- [`art_bible/VISUAL_RECONCILIATION_AND_PRODUCTION_STANDARD_V2.md`](art_bible/VISUAL_RECONCILIATION_AND_PRODUCTION_STANDARD_V2.md) — revisão detalhada do acervo, correções canônicas e padrão de produção;
- `production/` — planos de lote, APK, animação, áudio e conteúdo;
- [`production/APK_VISUAL_COMPLETION_PLAN_V09.md`](production/APK_VISUAL_COMPLETION_PLAN_V09.md) — gates de vertical slice e Android;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — entregáveis mínimos por asset.

## Engenharia e QA

- `architecture/` — decisões e integrações técnicas;
- `qa/` — auditorias e evidências;
- [`qa/RUNTIME_AUDIT_V08.md`](qa/RUNTIME_AUDIT_V08.md) — auditoria do fluxo central;
- [`../tools/audit/validate_repository_governance.py`](../tools/audit/validate_repository_governance.py) — gate de organização;
- [`../tools/audit/validate_canon_contract_v4_1.py`](../tools/audit/validate_canon_contract_v4_1.py) — gate do cânone e da D10;
- [`../tools/audit/validate_faction_migration_v4_2.py`](../tools/audit/validate_faction_migration_v4_2.py) — gate das três facções, aliases e save v5;
- [`../tools/audit/validate_visual_production_director_v1.py`](../tools/audit/validate_visual_production_director_v1.py) — gate da skill, pixel art 2D/2.5D, nomes, BJJ, mobile, licenças e integração visual.

## Status dos documentos

Use um destes estados no início de documentos novos quando o contexto não for óbvio:

- `CANONICAL` — fonte ativa e autoritativa;
- `ACTIVE` — documento de trabalho vigente;
- `DRAFT` — proposta ainda não integrada;
- `SUPERSEDED` — substituído; deve apontar para o sucessor;
- `ARCHIVED` — histórico, não orienta implementação.

Prompts, relatórios antigos, concept arts e branches não são automaticamente fontes canônicas.
