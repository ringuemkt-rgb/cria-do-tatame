# Cria do Tatame — Candidatos Hugging Face para Produção Audiovisual V0.1

## Regra de uso

Modelos de IA servem para gerar material bruto, conceito, variações e protótipos. Nenhuma saída entra diretamente no jogo sem limpeza, revisão anatômica, conferência de licença, rastreabilidade do prompt e QA no Godot.

O combate principal deve continuar offline e determinístico. Nenhum modelo sustenta o loop de gameplay em tempo real.

## Pixel art e sprites

### `nerijs/pixel-art-xl`

- Uso sugerido: conceitos de personagem, props e estudos de arena em SDXL.
- Pontos fortes: estilo pixel art consolidado e alta adoção.
- Licença informada no Hub: CreativeML Open RAIL-M.
- Link: https://huggingface.co/nerijs/pixel-art-xl

### `Onodofthenorth/SD_PixelArt_SpriteSheet_Generator`

- Uso sugerido: prototipação de spritesheets simples e poses-base.
- Pontos fortes: foco explícito em spritesheets.
- Limite: modelo antigo; consistência anatômica e transparência precisam de pós-processamento forte.
- Licença informada no Hub: Apache-2.0.
- Link: https://huggingface.co/Onodofthenorth/SD_PixelArt_SpriteSheet_Generator

### `UmeAiRT/FLUX.1-dev-LoRA-Modern_Pixel_art`

- Uso sugerido: key art e estudos visuais com estética pixel art moderna.
- Limite: depende de FLUX.1-dev; verificar termos do modelo-base antes de uso comercial.
- Licença informada para o LoRA: MIT.
- Link: https://huggingface.co/UmeAiRT/FLUX.1-dev-LoRA-Modern_Pixel_art

### `tarn59/pixel_art_style_lora_z_image_turbo`

- Uso sugerido: geração rápida de variações de cenário e props.
- Licença informada no Hub: Apache-2.0.
- Link: https://huggingface.co/tarn59/pixel_art_style_lora_z_image_turbo

### `Limbicnation/pixel-art-lora`

- Uso sugerido: estudo de personagens e assets de jogo.
- Pontos fortes: tags específicas para game asset, sprite e character design.
- Licença informada no Hub: Apache-2.0.
- Link: https://huggingface.co/Limbicnation/pixel-art-lora

## Áudio e música

### `stabilityai/stable-audio-open-1.0`

- Uso sugerido: protótipos de ambiências e efeitos sonoros originais.
- Limite: conferir licença específica e restrições antes de distribuição comercial.
- Link: https://huggingface.co/stabilityai/stable-audio-open-1.0

### `stabilityai/stable-audio-open-small`

- Uso sugerido: experimentação local mais leve para SFX e loops curtos.
- Limite: conferir licença específica.
- Link: https://huggingface.co/stabilityai/stable-audio-open-small

### `ACE-Step/Ace-Step1.5`

- Uso sugerido: prototipação musical original para hubs, arenas e bosses.
- Licença informada no Hub: MIT.
- Link: https://huggingface.co/ACE-Step/Ace-Step1.5

### `facebook/musicgen-small`

- Uso sugerido: estudos temporários de direção musical.
- Proibição para release comercial sem revisão: licença informada CC-BY-NC-4.0 é não comercial.
- Link: https://huggingface.co/facebook/musicgen-small

## Pipeline recomendado

```text
manifesto v0.2
→ fila JSONL individual
→ geração bruta em ambiente isolado
→ registro de modelo, versão, seed, prompt e licença
→ Pixel Snapper / LibreSprite / edição humana
→ separação de frames e pivôs
→ metadata e hitboxes
→ importação Godot
→ teste no BattleHub
→ QA e aprovação
```

## Metadados obrigatórios por geração

```json
{
  "provider": "huggingface",
  "model_id": "author/model",
  "revision": "commit-or-tag",
  "license_review": "pending|approved|rejected",
  "prompt_file": "prompt-used.txt",
  "seed": 0,
  "generated_at": "ISO-8601",
  "human_cleanup": true,
  "approved_for_runtime": false
}
```

## Política de licença

- Não confiar apenas no nome da licença exibido na busca.
- Ler o model card e a licença do modelo-base e adaptador.
- Registrar a revisão/commit usado.
- Rejeitar modelos ou datasets sem origem clara.
- Não usar outputs que reproduzam personagens, marcas ou estilos protegidos de forma identificável.
- Música temporária com licença não comercial nunca pode permanecer no APK de distribuição.
