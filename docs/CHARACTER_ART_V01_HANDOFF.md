# Cria do Tatame — Character Art v01 Handoff

Data: 2026-07-18
Escopo canônico: os oito personagens de `data/characters.json`.

## Entrega deste lote

| Personagem | Folha-modelo | Retrato RGBA | Seed 256 RGBA | Tira animada |
|---|---:|---:|---:|---:|
| Ruan Macacão | aprovado | aprovado | aprovado | `idle_combat_v01`, asset QA aprovado |
| Davi Relâmpago | aprovado | aprovado | aprovado | `idle_combat_v01`, asset QA aprovado |
| Mestre Dendê | aprovado | aprovado | aprovado | `idle_v01`, asset QA aprovado |
| Tinker Bell | aprovado | aprovado | aprovado | `idle_v01`, asset QA aprovado |
| Cássio Molho | aprovado | aprovado | aprovado | `idle_combat_v01`, asset QA aprovado |
| Kenzo Kuroi | aprovado | aprovado | aprovado | `idle_combat_v01`, asset QA aprovado |
| Leoa Quilombola | aprovado | aprovado | aprovado | `idle_combat_v01`, asset QA aprovado |
| Oni da Lapa | aprovado | aprovado | aprovado | `idle_combat_v01`, asset QA aprovado |

### Biblioteca completa de poses-fonte

O catálogo visual de personagem em `data/visual/graphic_asset_catalog_v01.json` agora
possui cobertura de fonte para todos os oito personagens. Foram extraídas e normalizadas
50 key poses RGBA 512×512, sem classificar essas poses como animações finais.

| Personagem | Key poses | Cobertura adicional |
|---|---:|---|
| Ruan Macacão | 11 | stance, grip, clinch, takedown, posições, finalização técnica, vitória e derrota |
| Davi Relâmpago | 6 | walk, sprawl, counter, scramble, loss e respect |
| Mestre Dendê | 3 | teaching, arms_crossed e dialogue |
| Tinker Bell | 6 | phone, filming, concerned, celebrating, leaving e dialogue |
| Cássio Molho | 6 | stage, stance, offer, provocation, contract e stage_composed |
| Kenzo Kuroi | 6 | walk, stance, reading, punish_error, counter e silent_bow |
| Leoa Quilombola | 6 | walk, base, sweep_setup, sweep, root_pressure e victory |
| Oni da Lapa | 6 | walk, stance, burst, pressure, underground_win e loss |

Também foi construída a sequência biomecânica pareada Ruan × Davi com sete chaves:
`distancia_media → disputa_pegada → entrada_queda → disputa_queda → cem_quilos →
resultado_tecnico → reset`.

### Lote de animação prioritária v02

As key poses aprovadas foram convertidas em sete packs candidatos, totalizando 34 quadros
normalizados e sete GIFs de revisão. Davi atua com Ruan canônico; os contatos de Leoa,
Oni e Kenzo ainda usam manequim neutro e permanecem classificados como fonte até a troca
por oponente canônico.

| Personagem | Ação | Quadros | Resolução | Status |
|---|---|---:|---:|---|
| Davi Relâmpago | `defense` / sprawl | 6 | 512×512 | asset QA; Godot/mobile pendente |
| Leoa Quilombola | `sweep` | 6 | 512×512 | fonte; oponente canônico pendente |
| Oni da Lapa | `pressure` | 5 | 512×512 | fonte; oponente canônico pendente |
| Mestre Dendê | `teaching` | 4 | 256×256 | asset QA; Godot/mobile pendente |
| Tinker Bell | `recording` | 4 | 256×256 | asset QA; Godot/mobile pendente |
| Cássio Molho | `provocation` | 4 | 256×256 | asset QA; Godot/mobile pendente |
| Kenzo Kuroi | `counter` | 5 | 512×512 | fonte; oponente canônico pendente |

O animatic Ruan × Davi também foi montado com sete quadros, atlas e GIF. Ele valida ordem,
estados e eventos, mas ainda precisa de in-betweens antes de ser tratado como animação
de combate contínua. O handoff detalhado está em `docs/CHARACTER_ANIMATION_BATCH_V02_HANDOFF.md`.

Pranchas de revisão:

- `assets/source/characters/roster_model_sheets_v01.jpg`
- `assets/source/apixel/characters/main_cast_v01.png` (3840×2160)
- `assets/source/apixel/movements/baiana_sequence_v01.png` (3840×2160 RGBA)
- `assets/graphics/characters/character_portrait_roster_v01.png`
- `assets/graphics/characters/character_seed_roster_v01.png`
- `assets/graphics/characters/character_idle_roster_v01.png`
- `assets/graphics/characters/character_action_pose_roster_v01.jpg`
- `assets/graphics/characters/character_animation_batch_v02.jpg`
- `assets/graphics/characters/paired/ruan_vs_davi_baiana_v01/contact_sheet.png`
- `assets/graphics/characters/paired/ruan_vs_davi_baiana_v01/animatic/preview.gif`
- `assets/graphics/characters/ruan_macacao/idle_combat_v01/contact_sheet.png`
- `assets/graphics/characters/ruan_macacao/idle_combat_v01/preview.gif`

## Contrato técnico

- Retrato: 512×512, PNG RGBA, alpha real.
- Seed: 256×256, PNG RGBA, nearest-neighbor.
- Pivô: centro inferior derivado da caixa alfa aprovada.
- Idles: 4 quadros por personagem, 8 FPS e loop; lutadores usam
  `distancia_media → distancia_media`, mentor/aliado usam contexto de hub.
- Key pose: 512×512, PNG RGBA, pivô inferior central e 20 px de margem.
- Sequência pareada: 7 chaves RGBA 512×512; contatos e resultado técnico seguros.
- Nenhum asset usa marca, academia, atleta ou personagem real.
- Nenhum movimento introduz soco, chute, arma ou violência explícita.

O manifesto verificável é `data/visual/character_art_manifest_v01.json`. O comando
`npm run validate:character-art` confere elenco canônico, caminhos, SHA-256, tamanhos,
alpha, cantos, escala, linha de chão, lock do frame 01, as 50 poses, as 7 chaves
pareadas, os 7 packs/34 quadros do lote v02, o animatic e os dois targets 4K do brief
Apixel.

## Ferramentas reprodutíveis

```bash
python tools/visual/chroma_key_asset.py entrada.png saida.png --key green --size 256
python tools/visual/normalize_sprite_strip_to_anchor.py \
  --input clean_sheet.png \
  --anchor idle_seed.png \
  --out-dir frames \
  --frames 4 \
  --frame-size 256 \
  --lock-frame1
python tools/visual/build_character_pose_library.py
python tools/visual/build_action_animation_batch.py
npm run validate:character-art
```

## Estado de integração

Os retratos, seeds, oito tiras idle, 50 key poses, sete packs prioritários e sete chaves
pareadas passaram por QA de arquivo. Não foram promovidos sobre `assets/sprites/` porque
o executável Godot não está presente neste ambiente e o gate in-engine não pôde ser
executado. Os 31 packs atuais continuam explicitamente marcados como placeholders; esse
estado não foi escondido nem reclassificado. Os packs v02 são candidatos, e os três packs
com manequim permanecem fontes até substituição canônica.

## Próximo lote recomendado

1. Instalar/fornecer Godot 4.2+ e testar idles e packs v02 com `CharacterAnimationLibrary`.
2. Gerar in-betweens da sequência Ruan × Davi sem alterar as sete chaves aprovadas.
3. Substituir o manequim de Leoa, Oni e Kenzo pelo oponente canônico de cada encontro.
4. Produzir VFX/SFX sincronizados nos eventos dos manifestos.
5. Após o gate visual, mecânico e mobile, promover cada pack mantendo fallback.
