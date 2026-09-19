# Visual Production Ready v1

Status: `shipping=false`. Fila única para fabricar gráfico do slice ouro.
Não mergeia PR 145/146/144/141 só para começar a desenhar.

## Ordem

1. Identity Ruan → Identity Davi (humano aprova)
2. Idle world + idle combat
3. Prop Kombi + 3 ícones + `map_base` Ituberá sem HUD
4. Terreiro L0–L5
5. Baiana + sprawl pareados (só depois do identity lock)

Arquivos: `data/visual/visual_production_queue_v1.json`
Saída: `production/candidates/p1/` + sidecar por PNG.

## Look

Paleta hex da art-direction. Outline 1–2 px. Pivot combate (64,96). Sem foto, sem 3D, sem HUD bakeado, sem Caio Ravel.

## Runtime que consome depois

- Combate: CombatManager + (depois) GrapplingV2CombatBridge
- Mapa: MapAtlasPresenter / map_base 1536×864
- Arena: layers Terreiro / Dique

## Gate

```
python3 tools/art/validate_visual_production_queue_v1.py
python3 -m unittest tests.test_visual_production_queue_v1
```
