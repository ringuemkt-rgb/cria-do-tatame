# Cria do Tatame — Handoff de animação de personagens v02

Data: 2026-07-18
Catálogo: `data/visual/character_animation_batch_v02.json`

## Resultado

O lote converte sete ações prioritárias em material animado verificável: 34 quadros PNG
RGBA, sete spritesheets, sete GIFs, sete pranchas individuais e uma prancha geral. Também
compila as sete poses pareadas de Ruan × Davi em um animatic técnico com atlas e GIF.

| Pack | Quadros | FPS | Loop | Transição | Gate atual |
|---|---:|---:|---:|---|---|
| `davi_relampago/sprawl_v01` (`defense`) | 6 | 12 | não | `entrada_queda → clinch_neutro` | Godot/mobile |
| `leoa_quilombola/sweep_v01` | 6 | 12 | não | `guarda_fechada → montada` | oponente canônico |
| `oni_da_lapa/pressure_v01` | 5 | 10 | sim | `cem_quilos → cem_quilos` | oponente canônico |
| `mestre_dende/teaching_v01` | 4 | 8 | sim | `hub_teaching → hub_teaching` | Godot/mobile |
| `tinker_bell/recording_v01` | 4 | 8 | sim | `hub_recording → hub_recording` | Godot/mobile |
| `cassio_molho/provocation_v01` | 4 | 10 | não | `distancia_media → distancia_media` | Godot/mobile |
| `kenzo_kuroi/counter_v01` | 5 | 12 | não | `entrada_queda → clinch_neutro` | oponente canônico |

## Estrutura de cada pack

Cada diretório contém `raw_sheet.png`, `clean_sheet.png`, `frames/`, `spritesheet.png`,
`preview.gif`, `contact_sheet.png`, `manifest.json`, `metadata.json`, notas de fonte,
notas de importação e relatório de QA. O manifesto inclui SHA-256 do atlas, GIF, fontes
processadas, prancha e cada quadro, além de FPS, loop, estados, eventos e consumo de
recursos.

Os PNGs de combate usam 512×512; ações de hub/expressão usam 256×256. Todos os quadros
compartilham pivô e linha de chão derivados da âncora canônica. Os eventos de gameplay
estão preservados no manifesto e devem ser disparados pelo controlador de animação.

## Animatic Ruan × Davi

Local: `assets/graphics/characters/paired/ruan_vs_davi_baiana_v01/animatic/`.

Ordem: `distancia_media → disputa_pegada → entrada_queda → disputa_queda → cem_quilos →
resultado_tecnico → reset`. O animatic é deliberadamente marcado como `animatic_only`:
ele aprova leitura e continuidade macro, não os in-betweens finais.

## Política de promoção

- Nenhum pack substitui automaticamente `assets/sprites/`.
- Davi, Dendê, Tinker e Cássio passaram pelo QA de asset; aguardam Godot 4.2+ e mobile.
- Leoa, Oni e Kenzo usam manequim sem identidade e continuam como material-fonte.
- `CharacterAnimationLibrary.gd` já interpreta `image`, `frame_layout`, FPS e `loop` dos
  manifestos, mas a troca de catálogo só pode ocorrer depois do teste in-engine.
- Os 31 placeholders existentes permanecem como fallback até a promoção explícita.

## Reprodução e validação

```bash
python tools/visual/build_action_animation_batch.py
python tools/visual/validate_character_art.py
npm run quality
```

Prancha geral: `assets/graphics/characters/character_animation_batch_v02.jpg`.
