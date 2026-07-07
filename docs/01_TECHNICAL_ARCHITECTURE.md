# 01 - Arquitetura Técnica Godot 4.2+

## Objetivo

Criar uma base robusta, modular, data-driven e exportável para um jogo de luta/Jiu-Jitsu com carreira, mapa, reputação, facções e conteúdo narrativo.

---

## 1. Camadas da arquitetura

### Data Layer
Arquivos JSON em `data/`:

- `characters.json`
- `arenas.json`
- `techniques.json`
- `factions.json`
- `missions.json`
- `dialogues.json`
- `economy.json`
- `progression.json`
- `cria_live_posts.json`
- `settings.json`

### Runtime Layer
Scripts Godot em `src/`.

### Scene Layer
Cenas em `scenes/`, separando menus, hubs, combate, personagens e UI.

### Asset Layer
Sprites, áudio, fontes e VFX em `assets/`.

---

## 2. Autoloads oficiais

- `SignalBus.gd`: sinais globais.
- `DataRegistry.gd`: carrega JSON canônico.
- `WorldState.gd`: estado de campanha.
- `SaveManager.gd`: save/load em JSON.
- `CombatManager.gd`: fluxo de combate.
- `CareerLoop.gd`: semana, treino, descanso, luta e progressão.
- `ReputationMatrix.gd`: Honra, Hype, Sombra, Legado e Dupla Face.
- `CriaLiveManager.gd`: feed social, crise, posts e comentários.
- `FactionSystem.gd`: facções, território e influência.
- `SponsorManager.gd`: contratos e patrocinadores.
- `AudioManager.gd`: música e SFX.
- `InputManager.gd`: teclado, controle e touch.

---

## 3. Cenas principais

| Cena | Responsabilidade |
|---|---|
| `main_menu/MainMenu.tscn` | Novo jogo, continuar, opções, créditos |
| `hubs/Terreiro.tscn` | Hub principal, treino, diálogo, agenda e missões |
| `hubs/WorldMap.tscn` | Mapa do Baixo Sul e seleção de região |
| `combat/Combat.tscn` | Cena de combate posicional |
| `combat/FightArena.tscn` | Arena reutilizável |
| `skill_tree/SkillTree.tscn` | Árvore de habilidades |
| `story/DialogSystem.tscn` | Diálogos narrativos |
| `characters/Ruan.tscn` | Personagem jogável base |

---

## 4. Fluxo principal

```txt
Boot → Main Menu → Terreiro → Fight Setup → Combat → Result → Terreiro
```

---

## 5. Política técnica

- Dados primeiro, lógica depois.
- Não codificar personagens diretamente dentro de cena.
- Evitar dependência circular entre autoloads.
- UI escuta sinais; não controla regra de combate.
- Combate deve ser state machine.
- O projeto deve rodar offline.
- IA generativa fica fora do runtime principal.
