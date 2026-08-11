# GPT WORK Production Gate v1

Este lote registra a direção STYLE-LOCK/GATE-L1 e a infraestrutura de produção sem promover nenhum binário. O contrato está em `data/production/gpt_work_production_gate_v1.json`; enquanto as divergências abaixo não forem migradas nos contratos executáveis, o status permanece `direction_issued_pending_canon_migration`.

Rastreamento: issue GitHub #60.

## Estado do arranque

- Árvore privada v2: `data/ai/cloud_drive_layout_v02.json`.
- Cinco specs e vinte ativos planejados: `data/ai/lote3_arranque_specs_v01.json`.
- Checkpoint público sem IDs privados: `data/ai/lote3_arranque_checkpoint_v01.json`.
- Leoa está pronta para preparação; Ruan, Nado, Bia e Oni carregam `hold_codes` explícitos.
- Todo resultado visual/sonoro entra como candidato; promoção para `assets/aprovados` exige registro humano em `qa/gate_l1_promocoes.json`.
- O regime delegado GATE-L1-B foi registrado, porém permanece inativo até uma migração de governança revisada; o empacotador já rejeita reservados promovidos por método delegado.
- FLUX.1 schnell, Wan2.2, ControlNet e DWPose exigem revisão imutável registrada por corrida. Pesos aceitos usam somente `.safetensors`.

## Bloqueios canônicos

1. Ruan é faixa branca no dado executável atual, enquanto a direção exige faixa-azul com dois graus.
2. Nado não possui ID, ficha ou âncora visual canônica no repositório.
3. Bia existe no domínio de facção, mas não no elenco de `data/characters.json`.
4. O papel de Oni e a geografia/hierarquia das três facções divergem dos contratos ativos.

Esses pontos exigem migração revisável; arte gerada antes dela poderia consolidar informação errada.

## DVC privado

Instale DVC com suporte ao Google Drive e mantenha a URL com o ID da pasta fora do Git. O script aceita somente uma URL privada por variável de ambiente e grava a configuração em `.dvc/config.local`, que é ignorado pelo Git:

```bash
export CRIA_DVC_REMOTE_URL='gdrive://ID_PRIVADO_DA_PASTA'
bash tools/ai_asset_pipeline/cloud/configure_dvc_drive.sh
dvc add caminho/do/lote
dvc push
```

O primeiro `dvc push` abre OAuth do Google. Nunca copie token, credencial ou ID privado para arquivos versionados.

## Validação

```bash
npm run validate:production-gate
npm run validate:cloud
npm run validate:mobile-packs
npm run test:cloud
npm run test:mobile-packs
```

O gate verifica as três facções, STYLE-LOCK 480×270, ferramentas homologadas, bloqueios comerciais, pesos `.safetensors`, seis fases de hitbox, árvore do Drive, 20 ativos e ausência de IDs privados.
