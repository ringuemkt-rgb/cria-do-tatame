# Decisions — Unificação controlada

- **D1** Fonte única de verdade = `cria-do-tatame`. `Tatamecria` = espelho de build.
- **D2** Combate canônico = `TransitionManager` (janela de defesa, fintas, `read_level`). `CombatManager` = **fachada adapter** (deprecated, só delega). Padrão **Strangler Fig**.
- **D3** Áudio canônico = `AudioManager` (1 mixer). `CombatAudio` = **módulo/ponte** dele.
- **D4** Mundo **não** é duplicata: `WorldState`=dados, `WorldDirectorManager`=eventos, `NavigationManager`=transporte, `WorldMapManager`=render/interação do mapa. **Documente os papéis; NÃO funda.**
- **D5** Deck canônico = `DeckManager`. HUD e `test_deck.json` = **consumidores**.
- **D6** Schemas são **camadas**: `technique_catalog_v05` = mestre (biomecânica); `combat_deck_schema` = projeção jogável via chave `technique_id`. **Ligue por `technique_id`; NÃO reescreva.**
- Migração **sempre** via adapter/fachada. **PROIBIDO** reescrever um autoload existente inteiro.
