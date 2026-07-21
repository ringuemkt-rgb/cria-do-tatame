# Mapa de duplicação e responsabilidades

## Combate

| Item | Achado | Decisão solicitada | Plano seguro |
|---|---|---|---|
| `CombatManager` autoload | Singleton ativo em `src/autoloads/CombatManager.gd`; cenas e HUD o consomem diretamente. | O manifesto declara uma futura fachada deprecated. | Não alterar em C2: não existe `TransitionManager` para receber delegação. |
| `CombatManager` do motor | `src/combat/CombatManager.gd`, referenciado pelo state machine/validador, não é autoload. | Não foi mapeado pelo manifesto. | Tratar como motor interno até existir uma transição canônica compatível. |
| `TransitionManager` | Ausente. | Declarado canônico em D2, mas ainda não implementado. | Criar somente após arbitragem: escolher se encapsula o motor existente ou se vem do workspace paralelo. |

## Áudio

| Item | Quem lê/usa | Canônico | Estado / plano |
|---|---|---|---|
| `AudioManager` | Main menu e arena chamam `play_music_cue` / `play_sfx`. | `AudioManager` | Ativo; manter como único mixer. |
| `CombatAudio` | Ausente. | Ponte/módulo de `AudioManager` (D3). | Não há duplicata ativa; a ponte pode ser adicionada mais tarde sem migração. |

## Mundo

| Componente | Papel observado | Consumidores |
|---|---|---|
| `WorldState` | Dados persistentes de jogador, semana, recursos, hub e resultado. | Save, carreira, hubs, combate, reputação. |
| `WorldDirectorManager` | Eventos, clima, diretivas de rival e estado do diretor. | Hubs, Save, facções. |
| `NavigationManager` | Ausente. | N/A; não introduzir sem decisão. |
| `WorldMapManager` | Dados de hub, custo, viagem, log e interação do mapa. | `WorldMapScreen`, hubs, Save. |

Não há fusão proposta: os papéis acima permanecem separados, conforme D4.

## Deck e schemas

| Item | Quem lê/usa | Canônico | Estado / plano |
|---|---|---|---|
| `DeckManager` | `CombatDeckHUD`, `DeckBuilder`, `CombatManager`, Save. | `DeckManager` | Ativo e já é a fonte de jogo. |
| `combat_deck_schema.json` | Validação e dados do deck. | Projeção jogável por `technique_id`. | Ativo. |
| `technique_catalog_v05` | Ausente com esse nome; há `data/techniques.json`. | Catálogo mestre indicado em D6. | Confirmar equivalência/arquivo de origem antes de C4. |
| `test_deck.json` | Ausente. | Consumidor previsto no manifesto. | Não criar sem necessidade de teste. |

## Conclusão C1

O gate de boot está verde para os caminhos existentes, mas o plano C3–C5 pressupõe sistemas que este repositório ainda não contém. Aplicar literalmente D2 agora exigiria criar a feature estrutural que a missão proíbe criar. A rota segura é arbitrar o canônico real antes de qualquer fachada.
