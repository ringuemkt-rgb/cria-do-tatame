# Sprite Atlas Manifest Standard v0.6

## Objetivo

Padronizar sprites de tecnicas do Cria do Tatame para Godot, QA e ferramentas de curadoria.

## Arquivos por tecnica

```txt
assets/sprites/ruan/<technique_id>/
  sprite_sheet.png
  manifest.json
  preview.gif
  source_notes.md
```

## Manifest minimo

```json
{
  "character_id": "ruan_macacao",
  "technique_id": "baiana",
  "image": "sprite_sheet.png",
  "frame_layout": [
    {"state":"entrada", "x":0, "y":0, "w":128, "h":128, "fps":8, "loop":false}
  ]
}
```

## Regras

- fundo transparente;
- retangulos absolutos, sem depender de grid oculto;
- cada acao tem fps e loop;
- todo atlas deve ter preview animado;
- nomes em snake_case;
- nenhuma marca real visivel.
