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
- [`../data/visual/sprite_forge_contract_v1.json`](../data/visual/sprite_forge_contract_v1.json) — consistência quantitativa de sprites sobre o Asset Pipeline v2;
- [`../data/production/repository_governance_v01.json`](../data/production/repository_governance_v01.json) — governança validável por máquina;
- [`../data/ai/cloud_drive_layout_v01.json`](../data/ai/cloud_drive_layout_v01.json) — árvore privada e política de promoção do adaptador Drive.

## Produto e gameplay

- [`CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md`](CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md) — escopo de produto;
- [`gameplay/COMBAT_DECK_SYSTEM_V01.md`](gameplay/COMBAT_DECK_SYSTEM_V01.md) — deck atual integrado à `main`;
- [`gameplay/BJJ_REDUCER_V2_SLICE.md`](gameplay/BJJ_REDUCER_V2_SLICE.md) — contrato draft do reducer orientado a grafo para o vertical slice Ruan × Davi;
- `canon/` — personagens, facções, mundo e narrativa aprovados;
- `gameplay/` — combate, progressão, regras e economia.

## Migrações ativas

- [`migrations/V4_2_FACTIONS_SAVE.md`](migrations/V4_2_FACTIONS_SAVE.md) — explicação simples da migração para `ALE`, `LEM`, `NTM` e save v5.

## Arte e produção

- `art_bible/` — identidade visual e contratos de qualidade ativos;
- `production/` — planos de lote, pipeline e metas;
- [`architecture/CRIA_SPRITE_FORGE_V1.md`](architecture/CRIA_SPRITE_FORGE_V1.md) — perfil mestre, anchor/scale QA e handoff de sprites para o pipeline existente;
- [`production/APK_VISUAL_COMPLETION_PLAN_V09.md`](production/APK_VISUAL_COMPLETION_PLAN_V09.md) — gates de vertical slice e Android;
- [`production/DRIVE_CLOUD_V1.md`](production/DRIVE_CLOUD_V1.md) — adaptador privado Google Drive, Colab, rclone e provenance Hugging Face;
- [`../data/visual/production_manifest_v02.json`](../data/visual/production_manifest_v02.json) — entregáveis mínimos por asset;
- [`../data/ai/model_registry_v02.json`](../data/ai/model_registry_v02.json) — auditoria e gates atuais de modelos Hugging Face.

## Engenharia e QA

- `architecture/` — decisões e integrações técnicas;
- `qa/` — auditorias e evidências;
- [`qa/RUNTIME_AUDIT_V08.md`](qa/RUNTIME_AUDIT_V08.md) — auditoria do fluxo central;
- [`../tools/audit/validate_repository_governance.py`](../tools/audit/validate_repository_governance.py) — gate de organização;
- [`../tools/audit/validate_canon_contract_v4_1.py`](../tools/audit/validate_canon_contract_v4_1.py) — gate do cânone e da D10;
- [`../tools/audit/validate_faction_migration_v4_2.py`](../tools/audit/validate_faction_migration_v4_2.py) — gate das três facções, aliases e save v5;
- [`../tools/art/validate_sprite_forge.py`](../tools/art/validate_sprite_forge.py) — gate de consistência entre ações de personagens;
- [`../tools/data/validate_bjj_reducer_v2_slice.py`](../tools/data/validate_bjj_reducer_v2_slice.py) — gate fail-closed do reducer v2 e do fixture Ruan × Davi;
- [`../tools/ai_asset_pipeline/cloud/validate_cloud_pipeline.py`](../tools/ai_asset_pipeline/cloud/validate_cloud_pipeline.py) — gate offline do adaptador de nuvem.

## Status dos documentos

Use um destes estados no início de documentos novos quando o contexto não for óbvio:

- `CANONICAL` — fonte ativa e autoritativa;
- `ACTIVE` — documento de trabalho vigente;
- `DRAFT` — proposta ainda não integrada;
- `SUPERSEDED` — substituído; deve apontar para seu sucessor;
- `ARCHIVED` — histórico, não orienta implementação.

Prompts, relatórios antigos, concept arts e branches não são automaticamente fontes canônicas.

## Origem e direção adulta

- [Origem de rua e construção adulta v1](production/ORIGEM_RUA_ADULTO_V1.md) — protótipo Z1–Z5, confirmações do autor, integração planejada e conflitos ainda abertos.
