# Cria do Tatame — AI Asset Pipeline

Pipeline local para organizar a producao de assets com modelos open source.

## Objetivo

Criar um fluxo padronizado para transformar prompts, modelos, manifests e QA em arquivos prontos para Godot 4.2+.

## Entradas

- data/ai/asset_pipeline_models_v01.json
- data/ai/asset_manifest_v01.json
- prompts/ai_asset_generation/PIXEL_ART_CHARACTER_PROMPTS.md
- prompts/ai_asset_generation/ARENA_AUDIO_VIDEO_PROMPTS.md

## Saidas esperadas

- assets/sprites/
- assets/backgrounds/
- assets/audio/music/
- assets/audio/sfx/
- assets/videos/cutscenes/
- assets/generated_metadata/

## Etapas

1. Gerar imagens base dos personagens.
2. Validar silhueta e canon.
3. Gerar poses com controle de pose quando necessario.
4. Gerar spritesheets por acao.
5. Exportar PNG transparente.
6. Gerar fundos por camadas.
7. Gerar musicas e SFX.
8. Registrar tudo em manifests JSON.
9. Importar no Godot.
10. Fazer QA visual, sonoro e narrativo.

## Licenca

Antes de usar qualquer modelo em producao comercial, verificar a licenca real no Hugging Face ou no repositorio oficial do modelo.

## Canon

Ruan Macacao Silva, Gorila Silverback, Baixo Sul da Bahia, Terreiro da Luta e HD Pixel Art 2.5D Regional Premium.
