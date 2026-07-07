# 🦍🥋 Cria do Tatame – Pressão

Repositório oficial de produção do jogo **Cria do Tatame – Pressão**.

**Gênero:** luta 2D + Action RPG de carreira + Jiu-Jitsu Brasileiro posicional  
**Engine:** Godot 4.2+  
**Plataformas-alvo:** Android APK, PC e Web  
**Visual:** HD Pixel Art 2.5D premium, preto/dourado, Baixo Sul da Bahia  
**Protagonista canônico:** Ruan “Macacão” Silva  
**Símbolo:** Gorila Silverback  
**Frase central:** Ser forte é ser gentil.  
**Slogan:** De cria pra cria. Luta. Disciplina. Evolução.

---

## 1. Objetivo do repositório

Este repositório deve funcionar como **base profissional para Manus AI, Codex, Godot e equipe humana** construírem o jogo completo.

A regra de ouro do projeto:

> Primeiro precisa abrir, rodar, salvar, lutar, avançar a semana e exportar. Depois vem o brilho.

O jogo não é beat’em up genérico. O núcleo é **Jiu-Jitsu como sistema**: base, pegada, pressão, queda, passagem, controle, montada, costas, finalização e consequência moral.

---

## 2. Estrutura principal

```txt
.
├── project.godot
├── README.md
├── CHANGELOG.md
├── AGENTS.md
├── docs/
│   ├── 00_MASTER_GDD.md
│   ├── 01_TECHNICAL_ARCHITECTURE.md
│   ├── 02_COMBAT_BIBLE.md
│   ├── 03_CHARACTER_BIBLE.md
│   ├── 04_ARENA_BIBLE.md
│   ├── 05_ART_DIRECTION.md
│   ├── 06_AI_LORE_GUARDIAN.md
│   ├── 07_PRODUCTION_ROADMAP.md
│   ├── 08_ASSET_PIPELINE.md
│   └── 09_MANUS_MASTER_PROMPT.md
├── data/
│   ├── characters.json
│   ├── arenas.json
│   ├── techniques.json
│   ├── factions.json
│   ├── missions.json
│   ├── dialogues.json
│   ├── economy.json
│   ├── progression.json
│   ├── cria_live_posts.json
│   └── settings.json
├── src/
│   ├── autoloads/
│   ├── combat/
│   ├── characters/
│   ├── systems/
│   └── ui/
├── scenes/
│   ├── main_menu/
│   ├── hubs/
│   ├── combat/
│   ├── skill_tree/
│   ├── story/
│   └── characters/
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
├── tools/
├── production/
├── tests/
└── ai_lore_guardian/
```

---

## 3. Como abrir no Godot

1. Instale **Godot 4.2+**.
2. Clone o repositório:

```bash
git clone https://github.com/ringuemkt-rgb/cria-do-tatame.git
cd cria-do-tatame
```

3. Abra o arquivo `project.godot` no Godot.
4. Rode a cena inicial configurada.

---

## 4. Como validar dados

```bash
python tools/validate_json.py
python tools/export_data_report.py
```

Todos os sistemas de conteúdo devem ser **data-driven**. Personagens, arenas, técnicas, missões, facções, diálogos e posts do Cria Live entram por JSON antes de virar lógica fixa.

---

## 5. Como gerar APK Android

O projeto é Godot-first. O fluxo correto é:

1. Instalar export templates do Godot.
2. Configurar Android SDK/JDK.
3. Configurar `export/export_presets.cfg`.
4. Rodar export pelo Godot ou script:

```bash
bash tools/build/build_android.sh
```

O script é um ponto de partida. Ajuste o caminho do binário do Godot conforme a máquina.

---

## 6. MVP obrigatório

- Main menu funcional.
- Terreiro da Luta navegável.
- Ruan jogável.
- Davi Relâmpago como rival inicial.
- Arena do Dique e Terreiro da Luta.
- Combate com vida, gás, foco, grip e controle.
- Ações contextuais mobile.
- Técnicas iniciais data-driven.
- Save/load.
- Primeiro ato jogável.
- Build Android debug documentado.

---

## 7. Prioridade atual para Manus

Executar `docs/09_MANUS_MASTER_PROMPT.md`.

Manus deve trabalhar nesta ordem:

1. Auditar estrutura atual.
2. Garantir que `project.godot` abre.
3. Validar JSON.
4. Criar/ligar cenas mínimas.
5. Implementar menu → hub → luta → resultado → save.
6. Só depois polir arte, animação e áudio.

---

## 8. Canon obrigatório

O protagonista oficial é **Ruan “Macacão” Silva**. Qualquer documento antigo com Caio Ravel ou Ruan “Cria” deve ser tratado como legado, não como canon atual.

Canon atual:

- Origem: Ituberá, Baixo Sul da Bahia.
- Idade: 19 anos no início, 28 no final.
- Símbolo: Gorila Silverback.
- Estilo: pressão pesada, grip de ferro, top game dominante.
- Poder mecânico: Silverback Grip.
- Frase eixo: Ser forte é ser gentil.

---

## 9. Definition of Done da base

A base só é considerada pronta quando:

- Abre no Godot sem erro fatal.
- Main menu entra no hub.
- Hub inicia combate.
- Combate altera estados e recursos.
- Resultado retorna ao hub.
- Save/load funciona localmente.
- JSON é validado.
- APK debug possui caminho documentado.

---

## 10. Status

Base profissional em montagem. Este repositório é o **oficial**. Repositórios antigos/teste devem ser descartados depois que este consolidar toda a estrutura.
