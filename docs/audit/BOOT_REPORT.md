# Boot report

Gerado por `python tools/audit/audit_boot.py .` em 2026-07-21.

| Item | Resultado |
|---|---|
| Cena principal | `res://scenes/main_menu/MainMenu.tscn` — presente |
| Autoloads registrados | 27 |
| Autoloads ausentes | 0 |
| Referências quebradas em `.tscn` | 0 |
| Gate estático | `ok=true` |

| Autoload | Caminho | Existe |
|---|---|---:|
| SignalBus | `src/autoloads/SignalBus.gd` | sim |
| DataRegistry | `src/autoloads/DataRegistry.gd` | sim |
| DeckManager | `src/autoloads/DeckManager.gd` | sim |
| LocalAIManager | `src/autoloads/LocalAIManager.gd` | sim |
| WorldState | `src/autoloads/WorldState.gd` | sim |
| WorldDirectorManager | `src/autoloads/WorldDirectorManager.gd` | sim |
| NFTManager | `src/autoloads/NFTManager.gd` | sim |
| SaveManager | `src/autoloads/SaveManager.gd` | sim |
| CombatManager | `src/autoloads/CombatManager.gd` | sim |
| CareerLoop | `src/autoloads/CareerLoop.gd` | sim |
| ReputationMatrix | `src/autoloads/ReputationMatrix.gd` | sim |
| CriaLiveManager | `src/autoloads/CriaLiveManager.gd` | sim |
| AudioManager | `src/autoloads/AudioManager.gd` | sim |
| TinkerBondManager | `src/autoloads/TinkerBondManager.gd` | sim |
| MissionManager | `src/autoloads/MissionManager.gd` | sim |
| StorySceneDirector | `src/autoloads/StorySceneDirector.gd` | sim |
| FactionManager | `src/autoloads/FactionManager.gd` | sim |
| FactionDirectorManager | `src/autoloads/FactionDirectorManager.gd` | sim |
| FactionAIPlanBridge | `src/autoloads/FactionAIPlanBridge.gd` | sim |
| WorldMapManager | `src/autoloads/WorldMapManager.gd` | sim |
| GearManager | `src/autoloads/GearManager.gd` | sim |
| TrainingManager | `src/autoloads/TrainingManager.gd` | sim |
| HubActivityManager | `src/autoloads/HubActivityManager.gd | sim |
| CriaLiveInteractionManager | `src/autoloads/CriaLiveInteractionManager.gd` | sim |
| GameFlowManager | `src/autoloads/GameFlowManager.gd` | sim |
| CutsceneRuntime | `src/autoloads/CutsceneRuntime.gd` | sim |

## Divergências que bloqueiam C2–C6

- O repositório tem 27 autoloads, não 30.
- A arquitetura prescrita ainda não existe: não há `TransitionManager`, `NavigationManager`, `CombatAudio`, `test_deck.json` nem os caminhos minúsculos exigidos pela implementação literal do auditor fornecido.
- Há dois scripts chamados `CombatManager`: o singleton ativo em `src/autoloads/CombatManager.gd` e o motor em `src/combat/CombatManager.gd`; não são uma dupla `CombatManager`/`TransitionManager`.
- O contrato constitucional fixa mínimo Godot 4.2.2 e produção 4.3+, em conflito com a fixação exclusiva em 4.2+ do pedido de integração.

Essas divergências exigem arbitragem antes de introduzir uma fachada para um canônico inexistente.
