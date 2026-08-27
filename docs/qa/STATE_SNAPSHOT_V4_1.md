# State Snapshot — Lote V4.1

**Status:** ACTIVE EVIDENCE  
**Capturado:** 2026-08-01  
**Base:** `main` em `068cbad979986baf09f870cc6580b7c88f10794f`  
**Branch:** `docs/v4-1-canon-contracts`

## 1. Histórico recente da base

```text
068cbad chore(repo): profissionalizar governança e fonte única do jogo
246201e fix(runtime): restaurar smoke verde na main
f098ab5 feat(combat): implementar Deck de Combate e disputas de nível
8469035 feat: integrar apresentação premium e contrato supremo de produção
f3e8584 fix: concluir auditoria integral e validar APK Android
d97e565 feat: adicionar Faction Director v2 com territórios, guerras e sucessão
21f6b78 feat: adicionar Cria World Director com clima, NPCs, rivais e NFTs
167043c feat: adicionar IA local opcional com fallback offline
21081cc feat: tornar a IA de Davi funcional no combate
67cb8b7 fix: fechar bloqueadores P0 do vertical slice
0fb5495 build: preparar export APK e pipeline audiovisual v0.9
54b13bf feat: consolidar runtime, combate posicional e QA headless
e8ba0a5 Consolidar Cria do Tatame em repositório único
256003e feat: Add ai_config.json - Davi's behavioral and technique database (2/3)
6cb4b09 Add graphic material pipeline guide
```

## 2. Pull requests

### Abertos no início do lote

| PR | Título resumido | Base | Estado |
|---:|---|---|---|
| #24 | marco audiovisual e mundo v10 | `release/v4-integration` | draft, não mergeável |
| #25 | unificação e game feel | `release/v4-integration` | draft, não mergeável |
| #26 | Open Pixel Forge | `release/unify-and-feel` | draft, mergeável na base empilhada |
| #32 | integração v4 monolítica | `main` | draft, não mergeável; branch-fonte |
| #33 | protocolo de construção | `release/v4-integration` | draft, mergeável na base empilhada |
| #34 | árvore/deck/rulesets/bindings | `release/v4-integration` | draft, mergeável na base empilhada |
| #35 | padrão visual e logo | `docs/game-build-protocol-v1` | draft, mergeável na base empilhada |
| #37 | governança/boot legado | `docs/visual-quality-and-logo-v1` | draft, mergeável na base empilhada |
| #38 | Visual Forge | `main` | draft, mergeável |

### Integrados imediatamente antes deste lote

- #40 — correção do runtime smoke;
- #39 — profissionalização do repositório;
- #42 — sincronização técnica usada para atualizar a branch da profissionalização.

## 3. Inventário de extensões

A API conectada usada para este snapshot não expõe uma listagem recursiva completa da árvore. O ambiente de execução local também não conseguiu resolver o host do GitHub para clonar o repositório. Portanto, este documento **não inventa contagens exatas**.

Último inventário histórico disponível, apenas como orientação e não como gate:

| Extensão | Referência histórica | Situação |
|---|---:|---|
| `.gd` | aproximadamente 86 | requer contagem em checkout completo |
| `.tscn` | aproximadamente 14 | requer contagem em checkout completo |
| `.json` | 105 ou mais | cresceu com contratos de produção |
| `.png` | não afirmado | requer contagem em checkout completo |
| `.wav/.ogg/.mp3` | próximo de zero na `main` estável | áudio atual é majoritariamente procedural; validar em checkout |

Comando de evidência para ambiente com checkout completo:

```bash
find . -type f -name '*.gd' | wc -l
find . -type f -name '*.tscn' | wc -l
find . -type f -name '*.json' | wc -l
find . -type f -name '*.png' | wc -l
find . -type f \( -name '*.wav' -o -name '*.ogg' -o -name '*.mp3' \) | wc -l
```

## 4. Autoloads da `main`

Foram encontrados **26 autoloads**, não 30. Todos os caminhos estavam presentes e os smokes da base `068cbad` ficaram verdes.

| Nome | Caminho |
|---|---|
| SignalBus | `src/autoloads/SignalBus.gd` |
| DataRegistry | `src/autoloads/DataRegistry.gd` |
| DeckManager | `src/autoloads/DeckManager.gd` |
| LocalAIManager | `src/autoloads/LocalAIManager.gd` |
| WorldState | `src/autoloads/WorldState.gd` |
| WorldDirectorManager | `src/autoloads/WorldDirectorManager.gd` |
| NFTManager | `src/autoloads/NFTManager.gd` |
| SaveManager | `src/autoloads/SaveManager.gd` |
| CombatManager | `src/autoloads/CombatManager.gd` |
| CareerLoop | `src/autoloads/CareerLoop.gd` |
| ReputationMatrix | `src/autoloads/ReputationMatrix.gd` |
| CriaLiveManager | `src/autoloads/CriaLiveManager.gd` |
| AudioManager | `src/autoloads/AudioManager.gd` |
| TinkerBondManager | `src/autoloads/TinkerBondManager.gd` |
| MissionManager | `src/autoloads/MissionManager.gd` |
| StorySceneDirector | `src/autoloads/StorySceneDirector.gd` |
| FactionManager | `src/autoloads/FactionManager.gd` |
| FactionDirectorManager | `src/autoloads/FactionDirectorManager.gd` |
| FactionAIPlanBridge | `src/autoloads/FactionAIPlanBridge.gd` |
| WorldMapManager | `src/autoloads/WorldMapManager.gd` |
| GearManager | `src/autoloads/GearManager.gd` |
| TrainingManager | `src/autoloads/TrainingManager.gd` |
| HubActivityManager | `src/autoloads/HubActivityManager.gd` |
| CriaLiveInteractionManager | `src/autoloads/CriaLiveInteractionManager.gd` |
| GameFlowManager | `src/autoloads/GameFlowManager.gd` |
| CutsceneRuntime | `src/autoloads/CutsceneRuntime.gd` |

## 5. Cena principal e versão

- `run/main_scene`: `res://scenes/main_menu/MainMenu.tscn`;
- cabeçalho de `project.godot`: Godot `4.2+`;
- contrato supremo: mínimo `4.2.2`, produção `4.3+`;
- roadmap: validação final em Godot 4.3;
- decisão: upgrade 4.2 → 4.3 permanece fora deste lote e deve ocorrer em PR separado.

## 6. Estado dos gates da base

O commit base `068cbad` foi integrado após aprovação dos workflows de governança, dados, runtime smoke, full game hardening e exportação/inspeção do APK Android.

Os resultados deste branch devem ser obtidos pela CI do PR. Nenhum sucesso local é alegado porque o checkout completo não estava disponível no ambiente conectado.

## 7. Arquivos-chave

| Alvo | Estado na `main` |
|---|---|
| `src/autoloads/CombatManager.gd` | presente; runtime estável |
| `src/autoloads/DeckManager.gd` | presente; único deck manager |
| `src/autoloads/AudioManager.gd` | presente; único audio manager |
| `src/combat/transition_manager.gd` | ausente; não criar neste lote |
| `data/factions.json` | presente; catálogo legado |
| Bíblia narrativa | `docs/narrative/MASTER_CANON_BIBLE_V01.md` |
| `data/characters.json` | presente |
| `data/story/story_scenes_v01.json` | presente |
| `data/finais_adultos.json` | presente |
| manifests de Ruan | presentes sob `assets/sprites/ruan_macacao/` |

## 8. Reconciliação com o PR #32

O PR #32 possui 90 commits e 83 arquivos alterados. Ele inclui cânone, facções/save, combate v4, mundo, economia, finais e acessibilidade, por isso não deve ser mesclado diretamente.

Portado neste lote:

- IDs futuros `LEM`, `NTM`, `ALE`;
- aliases legados;
- política de exatamente três facções futuras;
- classificação de instituições/eixos/grupos aposentados;
- integração incremental e proibição de merge monolítico.

Não portado:

- runtime de facções;
- save v5;
- managers v4;
- cartas/posições/rulesets;
- Arena e Submission HUD;
- economia, mapa, finais e terreno;
- alteração de `project.godot`.

Divergência resolvida por autoridade superior deste lote:

- PR #32 usa “Os Aleluiados”;
- D10 aprovada usa **“Os Aleluiado”**.

## 9. Inventário D10

### Alteração segura aplicada

| Arquivo | Classificação | Ação |
|---|---|---|
| `data/factions.json` | `FACTION_DISPLAY` | `Os Aleluia` → `Os Aleluiado`; ID `os_aleluia` preservado |

### Ocorrências preservadas para revisão semântica

A busca na `main` encontrou referências em:

- `docs/archived/systems/FACTION_DIRECTOR_V2.md`;
- `docs/narrative/MASTER_CANON_BIBLE_V01.md`;
- `data/factions/faction_director_v02.json`;
- `data/factions/faction_drama_bible_v01.json`;
- `src/autoloads/FactionManager.gd`;
- `data/lore/character_bible_v01.json`;
- `data/lore/world_bible_v01.json`;
- `data/story/faction_scenes_v01.json`;
- `data/player/player_progression.json`;
- `data/missions/faction_missions_v01.json`;
- `data/world/faction_territories_v02.json`;
- `data/world/world_director_config_v01.json`;
- `data/customization/customization_options.json`;
- `src/autoloads/MissionManager.gd`;
- `tests/faction_director_smoke.gd`;
- `tests/test_world_director_data.py`;
- `tests/test_faction_director_data.py`.

Essas ocorrências permanecem `D10_AMBIGUO` neste lote porque várias combinam display, IDs, testes e estado persistível. A correção em massa poderia quebrar referências. Elas devem ser tratadas no V4.2 com mapper, migração de save e atualização coordenada dos testes.

## 10. Conclusão do snapshot

O Lote V4.1 pode alterar documentação, contratos, validadores e o display inequívoco da entrada legada. Runtime, autoloads, save e estrutura ativa de facções permanecem congelados até o V4.2.
