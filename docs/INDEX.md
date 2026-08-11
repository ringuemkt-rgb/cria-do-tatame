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
- [`../data/production/supreme_build_contract_v01.json`](../data/production/supreme_build_contract_v01.json) — metas e release gates;
- [`../data/production/release_gate_status_v01.json`](../data/production/release_gate_status_v01.json) — ledger único com evidências e pendências de release;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — inventário audiovisual;
- [`../data/production/repository_governance_v01.json`](../data/production/repository_governance_v01.json) — governança validável por máquina;
- [`../data/ai/cloud_drive_layout_v02.json`](../data/ai/cloud_drive_layout_v02.json) — árvore privada, fila, QA, DVC e política de promoção do adaptador Drive.
- [`../data/production/gpt_work_production_gate_v1.json`](../data/production/gpt_work_production_gate_v1.json) — direção STYLE-LOCK/GATE-L1 e bloqueios de migração do produtor.
- [`../data/mobile/asset_packs_v1.json`](../data/mobile/asset_packs_v1.json) — catálogo e budgets dos packs mobile.

## Produto e gameplay

- [`CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md`](CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md) — escopo de produto;
- [`gameplay/COMBAT_DECK_SYSTEM_V01.md`](gameplay/COMBAT_DECK_SYSTEM_V01.md) — deck atual integrado à `main`;
- `canon/` — personagens, facções, mundo e narrativa aprovados;
- `gameplay/` — combate, progressão, regras e economia.

## Migrações ativas

- [`migrations/V4_2_FACTIONS_SAVE.md`](migrations/V4_2_FACTIONS_SAVE.md) — explicação simples da migração para `ALE`, `LEM`, `NTM` e save v5.

## Propostas bloqueadas para revisão humana

- [`../data/production/canon_v5_migration_proposal.json`](../data/production/canon_v5_migration_proposal.json) — diferenças e gates da proposta de campanha/mundo v5; não é contrato efetivo.
- [`narrative/NARRATIVA_ROTEIRO_V2.md`](narrative/NARRATIVA_ROTEIRO_V2.md) — 40 missões, fios, finais e diálogos-fonte, ainda sem consumidor runtime.
- [`world/MUNDO_V3_PROPOSAL.md`](world/MUNDO_V3_PROPOSAL.md) — mapa, 12 arenas, elenco e árvore V3 como proposta inativa.

## Arte e produção

- `art_bible/` — identidade visual e contratos de qualidade ativos;
- `production/` — planos de lote, pipeline e metas;
- [`production/APK_VISUAL_COMPLETION_PLAN_V09.md`](production/APK_VISUAL_COMPLETION_PLAN_V09.md) — gates de vertical slice e Android;
- [`production/DRIVE_CLOUD_V1.md`](production/DRIVE_CLOUD_V1.md) — adaptador privado Google Drive, Colab, rclone e provenance Hugging Face;
- [`production/GPT_WORK_PRODUCTION_GATE_V1.md`](production/GPT_WORK_PRODUCTION_GATE_V1.md) — arranque do Lote 3, ferramentas homologadas e pausas canônicas;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — entregáveis mínimos por asset;
- [`../data/ai/model_registry_v02.json`](../data/ai/model_registry_v02.json) — auditoria e gates atuais de modelos Hugging Face.

## Engenharia e QA

- `architecture/` — decisões e integrações técnicas;
- `qa/` — auditorias e evidências;
- [`qa/RUNTIME_AUDIT_V08.md`](qa/RUNTIME_AUDIT_V08.md) — auditoria do fluxo central;
- [`../tools/audit/validate_repository_governance.py`](../tools/audit/validate_repository_governance.py) — gate de organização;
- [`../tools/audit/validate_canon_contract_v4_1.py`](../tools/audit/validate_canon_contract_v4_1.py) — gate do cânone e da D10;
- [`../tools/audit/validate_faction_migration_v4_2.py`](../tools/audit/validate_faction_migration_v4_2.py) — gate das três facções, aliases e save v5;
- [`../tools/ai_asset_pipeline/cloud/validate_cloud_pipeline.py`](../tools/ai_asset_pipeline/cloud/validate_cloud_pipeline.py) — gate offline do adaptador de nuvem.
- [`../tools/mobile/validate_mobile_packs.py`](../tools/mobile/validate_mobile_packs.py) — gate offline de budgets, catálogo e loader mobile.

## Status dos documentos

Use um destes estados no início de documentos novos quando o contexto não for óbvio:

- `CANONICAL` — fonte ativa e autoritativa;
- `ACTIVE` — documento de trabalho vigente;
- `DRAFT` — proposta ainda não integrada;
- `SUPERSEDED` — substituído; deve apontar para o sucessor;
- `ARCHIVED` — histórico, não orienta implementação.

Prompts, relatórios antigos, concept arts e branches não são automaticamente fontes canônicas.
