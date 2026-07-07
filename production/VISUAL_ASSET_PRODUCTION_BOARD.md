# Visual Asset Production Board — Cria do Tatame

Este quadro organiza a produção visual para Manus, artistas e validação humana.

## Prioridade P0 — precisa existir para o protótipo jogar

| Asset | Pasta | Status esperado | Observação |
|---|---|---|---|
| Ruan Macacão idle | `assets/sprites/characters/ruan_macacao/white_belt/` | placeholder ou sprite final | silhueta pesada |
| Davi Relâmpago idle | `assets/sprites/characters/davi_relampago/` | placeholder ou sprite final | silhueta leve |
| Terreiro da Luta arena | `assets/sprites/arenas/terreiro_da_luta/` | camadas mínimas | bg + play_area |
| HUD combate | `assets/sprites/ui/hud/` | funcional | vida/gás/foco/grip/controle/moral |
| Botões mobile | `assets/sprites/ui/buttons/` | funcional | Pegada, Defesa, Transição, Pressão, Finalização |
| Ícones principais | `assets/sprites/ui/icons/` | funcional | grip, foco, moral, honra, hype, sombra |

## Prioridade P1 — vertical slice premium

| Asset | Pasta | Uso |
|---|---|---|
| Arena do Dique | `assets/sprites/arenas/arena_do_dique/` | evento oficial Salvador |
| Main Menu background | `assets/sprites/ui/menu/` | tela inicial |
| Skill Tree UI | `assets/sprites/ui/skill_tree/` | Caminho da Pressão |
| Cria Live panel | `assets/sprites/ui/cria_live/` | reputação e feed |
| Submission VFX | `assets/sprites/vfx/submission/` | finalizações |
| Impact/Pressure VFX | `assets/sprites/vfx/pressure/` | pressão e grip |

## Prioridade P2 — campanha completa

- Mestre Dendê.
- Tinker Bell.
- Cássio Molho.
- Kenzo Kuroi.
- Leoa Quilombola.
- Oni da Lapa.
- Manguezal Profundo.
- Ferro Velho da Lapa.
- Budokan das Águas.
- Praia de Pratigi.
- Colônia Nishimura.
- Porto.
- Zambiapunga.
- Cachoeira Pancada Grande.

## Definition of Done visual

Um asset só pode sair de `draft` para `approved` se:

1. Lê bem em tela pequena.
2. Usa paleta oficial.
3. Mantém silhueta clara.
4. Não copia asset comercial.
5. Está no formato e pasta corretos.
6. Tem nome em snake_case.
7. Funciona sem filtro borrado no Godot.
8. Reforça Jiu-Jitsu, Baixo Sul e Gorila Silverback.

## Pipeline recomendado

1. Gerar concept.
2. Escolher melhor direção.
3. Reduzir para sprite/pixel art.
4. Separar camadas.
5. Importar no Godot com filtro desligado.
6. Testar em cena mobile.
7. Aprovar ou refazer.

## Regra final

Asset bonito que atrapalha leitura de combate deve ser recusado.
