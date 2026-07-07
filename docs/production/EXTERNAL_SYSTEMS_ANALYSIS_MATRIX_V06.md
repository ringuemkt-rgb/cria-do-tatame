# Analise de Sistemas Externos v0.6

## Objetivo

Analisar sistemas externos de producao de jogos, agentes, Godot, web, sprite e narrativa persistente para construir um sistema autoral do Cria do Tatame.

## Principio

Nada deve ser copiado diretamente. Este documento aproveita ideias de arquitetura, workflow e qualidade, mantendo o jogo autoral, brasileiro, em Godot 4.2+, com jiu-jitsu posicional e HD Pixel Art 2.5D.

## Fontes analisadas

| Sistema | Melhor parte aproveitada | Uso no Cria |
|---|---|---|
| GodotMaker | ideia -> GDD -> tarefas -> implementacao -> testes -> screenshot -> avaliacao -> fix loop | ciclo automatico de build e QA para Godot |
| claude-code-game-development | biblioteca de prompts, exemplos, game loop, input, AI, performance, testing | base de prompts e checklists tecnicos |
| agent-game-forge | IDE local-first, daemon, visual scene editor, sprite pipeline, JSON editavel | Cria Forge local-first e editor de cenas/assets |
| godot-2d-web-game-skill | Godot como logica e browser como UI, bridge Godot-Web, performance web | export web/mobile e HUD overlay |
| tower-defense-skill | config como data layer, arte sem invadir logica, meta loop, feedback visual, balance sim | data-driven combat, gamefeel e validacao de equilibrio |
| XianTu | narrativa AI, multiplos saves, mundo aberto, relacoes, mobile e temas | modo carreira vivo e relacoes persistentes |
| clik-engine | config declarativa, logs estruturados, harness de testes, input manager, debug e sistemas modulares | Cria Runtime Inspector e bulk playtest |
| sprite-gen | base image -> rows -> alpha frames -> manifest -> curation webview -> atlas final | fabrica de sprites do Ruan e tecnicas BJJ |

## Decisao de arquitetura

O sistema final se chama Cria Game Forge.

Ele possui cinco camadas:

1. Cria Studio OS: agentes, workflow, backlog e quality gates.
2. Cria Runtime Core: Godot, dados JSON, save, combate e carreira.
3. Cria Asset Factory: sprites, pixel art, atlas, manifest e QA visual.
4. Cria Motion Lab: pesquisa autorizada, pose, keyframes e fichas biomecanicas.
5. Cria QA Harness: validacao de dados, simulacao, logs e playtest repetivel.

## Regra de licenca

Usar conceitos, nao copiar codigo. Repos com licenca restritiva ou nao comercial devem ser tratados apenas como referencia conceitual ate validacao juridica.
