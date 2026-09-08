# CRIA ART DIRECTION — Palette Reference v1

**Status:** ACTIVE AUTHORING REFERENCE  
**Authority:** `data/visual/ui_theme_v2.json` + active visual/runtime contracts.

## Runtime/UI tokens

| Token | Hex | Uso |
|---|---:|---|
| panel_bg | `#0B0B0D` | painel, fundo profundo |
| border_gold | `#C9971C` | borda, ornamento, seleção |
| text_offwhite | `#EDE6D6` | texto, gi, highlights claros |
| river_blue | `#1E3A5F` | água profunda, sombra fria, institucional |
| mangrove_green | `#2D5016` | mata, mangue, recuperação |
| terracotta | `#B85C38` | telha, madeira, sombra quente |
| sand_light | `#D4A574` | areia, madeira clara, pele clara |
| danger_red | `#8B0000` | perigo, conflito, bloqueio |
| mystery_purple | `#4B0082` | segredo, Avesso, mistério |

## Gameplay faction tokens

| Faction | Hex | Significado |
|---|---:|---|
| ALE | `#FF9408` | ordem/fé/proteção |
| LEM | `#4A6741` | mangue/maré/memória |
| NTM | `#3FE3F5` | rua/hype/comércio |
| LEI | `#1E3A5F` | institucional |

## Ceremonial / map badge variants

Estas famílias são auxiliares e não substituem os gameplay tokens:

- ALE: royal blue + gold + off-white;
- LEM: purple/wine + gold;
- NTM: red/orange + gold, blue secondary allowed;
- secret areas: violet/purple haze + high-contrast lock/eye treatment.

## Feedback/accessibility tokens currently present

- advantage: `#39FF14`;
- neutral: `#D4A574`;
- disadvantage: `#8B0000`;
- colorblind replacement for danger red: `#FF8C00`;
- colorblind replacement for advantage green: `#00BFFF`.

## Shading guidance

- cold shadow bias: `#1E3A5F`;
- hot/conflict shadow bias: `#8B0000` when narratively appropriate;
- warm rim/highlight family: `#C9971C`;
- bright cloth/text/highlight family: `#EDE6D6`.

Do not infer a new faction token from a banner or generated image. Faction gameplay color changes require a data/canon migration.

## Rarity authoring palette

Rarity colors may be used only if the corresponding rarity exists in gameplay data:

- common `#9E9E9E`;
- uncommon `#4CAF50`;
- rare `#2196F3`;
- epic `#9C27B0`;
- legendary `#FFD700`.

The presence of these colors here does not create a rarity system or authorize arbitrary card stats.
