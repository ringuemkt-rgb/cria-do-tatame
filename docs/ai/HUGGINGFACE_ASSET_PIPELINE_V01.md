# Cria do Tatame — Hugging Face Asset Pipeline v0.1

## Objetivo

Construir um pipeline aberto para produzir sprites, arenas, audio, cutscenes e metadados do Cria do Tatame usando modelos open source e uma fila de producao controlada.

## Componentes criados

- `data/ai/asset_pipeline_models_v01.json`
- `data/ai/asset_manifest_v01.json`
- `prompts/ai_asset_generation/PIXEL_ART_CHARACTER_PROMPTS.md`
- `prompts/ai_asset_generation/ARENA_AUDIO_VIDEO_PROMPTS.md`
- `tools/ai_asset_pipeline/README.md`
- `tools/ai_asset_pipeline/build_generation_queue.py`

## Fluxo profissional

```txt
Canon -> Prompt -> Modelo -> Asset bruto -> QA -> Refinamento -> Export Godot -> Teste no jogo
```

## Fase 1 — sprites

1. Usar o prompt mestre do personagem.
2. Gerar imagem base frontal e lateral.
3. Fixar seed e ficha visual.
4. Gerar acoes do manifest.
5. Exportar PNG transparente.
6. Montar spritesheet.
7. Conferir pivot, escala e silhueta.

## Fase 2 — arenas

1. Gerar cada arena em camadas.
2. Separar `bg_far`, `bg_mid`, `play_area`, `foreground` e `particles`.
3. Remover qualquer texto aleatorio.
4. Testar parallax no Godot.
5. Conferir contraste com sprites.

## Fase 3 — audio

1. Gerar loops curtos por arena.
2. Exportar musicas em OGG.
3. Exportar SFX em WAV.
4. Normalizar volume.
5. Testar repeticao sem estalo.

## Fase 4 — cutscenes

1. Gerar video curto por cena.
2. Exportar MP4 para prototipo.
3. Para release, converter para sequencia de frames ou cutscene leve.
4. Manter texto fora do video quando possivel; legendas ficam no jogo.

## Fase 5 — fila de producao

Rodar:

```bash
python tools/ai_asset_pipeline/build_generation_queue.py
```

Saidas:

```txt
tools/ai_asset_pipeline/generated_queue/characters.jsonl
tools/ai_asset_pipeline/generated_queue/arenas.jsonl
tools/ai_asset_pipeline/generated_queue/audio.jsonl
tools/ai_asset_pipeline/generated_queue/cutscenes.jsonl
```

## QA obrigatorio

- Ruan continua reconhecivel?
- Silhueta funciona em tela pequena?
- Nao ha marca real?
- Pose e esportiva, segura e compreensivel?
- O asset combina com Baixo Sul?
- O asset esta pronto para Godot ou precisa limpeza no Pixelorama?
- O arquivo segue naming convention?

## Observacao de licenca

Antes de publicar comercialmente, verificar a licenca de cada modelo e dataset no Hugging Face ou repositorio oficial. O manifest registra o pipeline, mas nao substitui auditoria de licenca.
