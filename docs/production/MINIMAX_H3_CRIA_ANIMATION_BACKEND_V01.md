# MiniMax-H3 — Cria do Tatame Animation Backend v0.1

## Papel no pipeline

MiniMax-H3 entra no Open Pixel Forge como backend audiovisual para gerar candidatos de movimento a partir de arte já aprovada. O cânone do jogo continua sendo **2.5D Pixel Art Premium**.

### O que ele pode fazer

- I2V: animar keyframes aprovados de personagens e técnicas;
- R2V: usar referências visuais canônicas para preservar identidade;
- T2V: apenas para exploração, atmosfera, VFX e previsualização;
- loops ambientais de arenas;
- cutscenes e trailers;
- estudos de timing para golpes e transições.

### O que ele não decide

- anatomia canônica do golpe;
- posição correta de grips;
- biomecânica de finalizações;
- sprites finais;
- hitboxes/hurtboxes/grabboxes;
- timing competitivo final;
- identidade visual do jogo.

## Ordem obrigatória para técnicas de jiu-jitsu

1. Referência técnica / engenharia reversa;
2. Canon Gate do personagem;
3. Keyframes 2.5D Pixel Art aprovados;
4. Sync map atacante/defensor;
5. MiniMax-H3 I2V ou R2V para candidatos intermediários;
6. seleção quadro a quadro;
7. limpeza pixel / correção anatômica;
8. atlas e metadados;
9. Biomechanics Gate;
10. Godot Runtime Gate;
11. teste Android.

## Estrutura recomendada

```text
assets/characters/<fighter>/animations/<technique>/
├── references/
├── keyframes_approved/
├── minimax_h3_candidates/
├── selected_frames/
├── cleaned_frames/
├── spritesheet.png
├── sync_map.json
├── hitboxes.json
├── metadata.json
└── qa_report.md
```

## Instalação no ComfyUI

Os pesos não devem ser versionados no Git.

Pastas esperadas:

```text
ComfyUI/models/diffusion_models/
ComfyUI/models/text_encoders/
ComfyUI/models/vae/
```

Configuração recomendada pelo repositório Comfy-Org:

- diffusion model: `minimax_h3_ref2va_int8_convrot.safetensors` quando o ambiente suportar PyTorch/CUDA compatível;
- text encoder: `qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors` para reduzir VRAM;
- VAE: `minimax_h3_video_vae_fp16.safetensors`.

Workflows oficiais suportados:

- `video_minimax_h3_i2v.json`;
- `video_minimax_h3_t2v.json`;
- `video_minimax_h3_r2v.json`.

## Preset Cria do Tatame

Toda chamada deve preservar:

- estilo: 2.5D Pixel Art Premium;
- nearest-neighbor no pós-processamento;
- silhueta forte;
- volumes legíveis;
- paleta canônica;
- personagem sem redesign;
- roupas, faixa, tatuagens e patches consistentes;
- arena e câmera coerentes com o Hub;
- contato físico correto;
- nada de membros extras, grip fantasma, interpenetração ou troca de identidade.

## Estratégia de uso

### Personagens

Use R2V/I2V com model sheet aprovado. Gere movimentos simples primeiro: idle, walk, stance, level change, grip entry, reaction, fatigue.

### Grappling pareado

Nunca gerar uma técnica completa do zero como fonte da verdade. Use keyframes aprovados de atacante e defensor, com pivô compartilhado e contatos definidos. MiniMax-H3 serve para sugerir frames entre poses.

### Arenas

Excelente uso: água, fumaça, luz, multidão, bandeiras, chuva, reflexos, vegetação, poeira, neon e loops atmosféricos.

### Cards e HUD

MiniMax-H3 não cria o master estático da carta. Pode criar motion cards, brilho de raridade, VFX de ativação e trailer da carta.

## Promotion rule

Nenhum output do MiniMax-H3 entra direto no runtime. Tudo é `candidate_only` até passar pelos gates de cânone, biomecânica, consistência temporal, pixel art e runtime.
