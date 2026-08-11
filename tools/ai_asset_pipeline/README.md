# Cria do Tatame — AI Asset Pipeline

Pipeline offline e opcional para organizar a produção de assets com modelos open source.

## Objetivo

Criar um fluxo padronizado para transformar prompts, modelos, manifests e QA em candidatos preparados para Godot 4.2+. Nenhuma saída gerada entra automaticamente em shipping.

## Entradas

- `data/visual/production_manifest_v02.json` — inventário audiovisual canônico;
- `data/ai/asset_pipeline_models_v01.json` — catálogo histórico de pesquisa;
- `data/ai/model_registry_v02.json` — decisões atuais de licença e adoção;
- `data/ai/asset_manifest_v01.json`;
- `prompts/ai_asset_generation/PIXEL_ART_CHARACTER_PROMPTS.md`;
- `prompts/ai_asset_generation/ARENA_AUDIO_VIDEO_PROMPTS.md`.

## Saídas esperadas

- `assets/sprites/`;
- `assets/backgrounds/`;
- `assets/audio/music/`;
- `assets/audio/sfx/`;
- `assets/videos/cutscenes/`;
- `assets/generated_metadata/`.

## Etapas

1. Gerar a fila canônica de produção.
2. Fixar commit do Git e revisão imutável do modelo.
3. Gerar candidatos em lote pequeno.
4. Validar silhueta, cânone, origem e licença.
5. Gerar e sincronizar atacante/defensor quando for técnica pareada.
6. Limpar e exportar pixel art determinística.
7. Registrar SHA-256 e metadados.
8. Obter QA humano técnico, visual e narrativo.
9. Sincronizar somente o lote aprovado.
10. Integrar em uma cena real e testar no Godot/Android.

## Fila v2

```bash
python tools/ai_asset_pipeline/build_production_queue_v02.py
```

## Adaptador Google Drive + Colab

O adaptador privado de binários está em `tools/ai_asset_pipeline/cloud/`. Leia o guia completo:

```text
docs/production/DRIVE_CLOUD_V1.md
```

Validação offline:

```bash
python tools/ai_asset_pipeline/cloud/validate_cloud_pipeline.py
```

## Licença e segurança

Antes de usar qualquer modelo em produção comercial, verifique a licença do modelo, do modelo-base, de adapters, datasets e material de referência. Tokens, IDs privados do Drive e configurações OAuth ficam fora do Git.

## Cânone

Ruan Macacão Silva, Gorila Silverback, Baixo Sul da Bahia, Terreiro da Luta e HD Pixel Art 2.5D Regional Premium.
