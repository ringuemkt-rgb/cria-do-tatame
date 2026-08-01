# Índice da Documentação

Este arquivo é a porta de entrada da documentação ativa. Antes de criar um documento novo, verifique se o assunto já possui fonte canônica.

## Comece aqui

- [`../README.md`](../README.md) — visão do produto, instalação e comandos principais;
- [`../AGENTS.md`](../AGENTS.md) — regras obrigatórias para agentes;
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — fluxo de contribuição;
- [`DECISIONS.md`](DECISIONS.md) — decisões arquiteturais e canônicas D1–D13;
- [`REPOSITORY_GOVERNANCE.md`](REPOSITORY_GOVERNANCE.md) — fonte única, branches, PRs e gates;
- [`ROADMAP.md`](ROADMAP.md) — sequência oficial de construção.

## Contratos executáveis

- [`../data/production/canon_contract_v4_1.json`](../data/production/canon_contract_v4_1.json) — cânone v4.1, autoridades de runtime, facções e aliases;
- [`../data/production/faction_migration_v4_2.json`](../data/production/faction_migration_v4_2.json) — três facções ativas, aliases e save v5;
- [`../data/visual/brand_identity_v01.json`](../data/visual/brand_identity_v01.json) — logo oficial, elementos protegidos, derivados obrigatórios e bloqueio jurídico de shipping;
- [`../data/visual/visual_canon_contract_v2.json`](../data/visual/visual_canon_contract_v2.json) — estilo 2D/2.5D, estados de asset, batch policy, HUD, mapa, arena, segurança e QA visual;
- [`../data/visual/reference_audit_v2.json`](../data/visual/reference_audit_v2.json) — auditoria estruturada do acervo de imagens enviado pelo criador;
- [`../assets/branding/logo_oficial_cria_do_tatame.svg`](../assets/branding/logo_oficial_cria_do_tatame.svg) — fonte visual oficial aprovada pelo criador;
- [`../data/production/supreme_build_contract_v01.json`](../data/production/supreme_build_contract_v01.json) — metas e release gates;
- [`../data/production/release_gate_status_v01.json`](../data/production/release_gate_status_v01.json) — ledger único com evidências e pendências de release;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — inventário audiovisual;
- [`../data/production/repository_governance_v01.json`](../data/production/repository_governance_v01.json) — governança validável por máquina.

## Skills operacionais

- [`../.agents/skills/cria-visual-canon-director/SKILL.md`](../.agents/skills/cria-visual-canon-director/SKILL.md) — direção canônica de personagens, técnicas, arenas, mapas, HUD, facções, marca, lotes e integração Godot;
- [`../.agents/skills/cria-visual-canon-director/references/VISUAL_RECONCILIATION.md`](../.agents/skills/cria-visual-canon-director/references/VISUAL_RECONCILIATION.md) — reconciliação detalhada do material de inspiração;
- [`../.agents/skills/cria-visual-canon-director/references/QUALITY_GATES.md`](../.agents/skills/cria-visual-canon-director/references/QUALITY_GATES.md) — bloqueadores, rubrica e gates por categoria;
- [`../.agents/skills/cria-visual-canon-director/references/PRODUCTION_RECIPES.md`](../.agents/skills/cria-visual-canon-director/references/PRODUCTION_RECIPES.md) — estruturas, metadata e prompts de produção.

## Produto e gameplay

- [`CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md`](CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md) — escopo de produto;
- [`gameplay/COMBAT_DECK_SYSTEM_V01.md`](gameplay/COMBAT_DECK_SYSTEM_V01.md) — deck atual integrado à `main`;
- `canon/` — personagens, facções, mundo e narrativa aprovados;
- `gameplay/` — combate, progressão, regras e economia.

## Migrações ativas

- [`migrations/V4_2_FACTIONS_SAVE.md`](migrations/V4_2_FACTIONS_SAVE.md) — migração para `ALE`, `LEM`, `NTM`, aliases e save v5; atualização para “Os Aleluiados” é apenas display.

## Arte e produção

- [`art_bible/VISUAL_CANON_SYSTEM_V2.md`](art_bible/VISUAL_CANON_SYSTEM_V2.md) — sistema visual canônico, padrões, reconciliações e ordem de produção;
- `art_bible/` — identidade visual e contratos de qualidade ativos;
- `production/` — planos de lote, APK, animação, áudio e conteúdo;
- [`../data/visual/brand_identity_v01.json`](../data/visual/brand_identity_v01.json) — contrato da marca e do Silverback oficial;
- [`../data/visual/visual_canon_contract_v2.json`](../data/visual/visual_canon_contract_v2.json) — contrato visual geral;
- [`production/APK_VISUAL_COMPLETION_PLAN_V09.md`](production/APK_VISUAL_COMPLETION_PLAN_V09.md) — gates de vertical slice e Android;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — entregáveis mínimos por asset.

## Engenharia e QA

- `architecture/` — decisões e integrações técnicas;
- `qa/` — auditorias e evidências;
- [`qa/RUNTIME_AUDIT_V08.md`](qa/RUNTIME_AUDIT_V08.md) — auditoria do fluxo central;
- [`../tools/audit/validate_repository_governance.py`](../tools/audit/validate_repository_governance.py) — gate de organização;
- [`../tools/audit/validate_canon_contract_v4_1.py`](../tools/audit/validate_canon_contract_v4_1.py) — gate do cânone e da D10;
- [`../tools/audit/validate_faction_migration_v4_2.py`](../tools/audit/validate_faction_migration_v4_2.py) — gate das três facções, aliases e save v5;
- [`../tools/audit/validate_brand_identity_v01.py`](../tools/audit/validate_brand_identity_v01.py) — gate do logo, hash, Silverback, protagonista e bloqueio jurídico;
- [`../tools/audit/validate_visual_canon_v2.py`](../tools/audit/validate_visual_canon_v2.py) — gate da skill, contrato 2D/2.5D, referências, facções, governança e integração visual;
- [`../tests/test_visual_canon_skill_v2.py`](../tests/test_visual_canon_skill_v2.py) — regressão da skill e do contrato visual.

## Status dos documentos

Use um destes estados no início de documentos novos quando o contexto não for óbvio:

- `CANONICAL` — fonte ativa e autoritativa;
- `ACTIVE` — documento de trabalho vigente;
- `DRAFT` — proposta ainda não integrada;
- `SUPERSEDED` — substituído; deve apontar para o sucessor;
- `ARCHIVED` — histórico, não orienta implementação.

Prompts, relatórios antigos, concept arts e branches não são automaticamente fontes canônicas.
