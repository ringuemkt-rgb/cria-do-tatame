# Cria do Tatame - Sistema Completo v0.1

## Objetivo

Consolidar o fluxo completo do jogo: campanha, hubs, cenas, combate, reputacao, Cria Live, save e producao de assets.

## Arquivos adicionados

- data/gameplay/complete_game_flow_v01.json
- data/story/campaign_cinematics_v01.json
- data/ai/rival_ai_profiles_v01.json
- data/production/full_completion_backlog_v01.json
- src/autoloads/GameFlowManager.gd
- src/autoloads/RivalAIManager.gd
- src/autoloads/CutsceneRuntime.gd

## Runtime atualizado

- project.godot registra GameFlowManager e CutsceneRuntime.
- DataRegistry.gd carrega os novos JSONs.
- SaveManager.gd salva e carrega o estado do fluxo.

## Loop central

Menu -> Hub -> Atividade -> Missao ou treino -> Combate -> Resultado -> Cria Live -> Save -> Proximo dia.

## Vertical Slice 0.2

Meta: Ruan vs Davi no Terreiro, com treino, combate, resultado, Cria Live e save.

## Proximo teste obrigatorio

1. Abrir Godot 4.2+.
2. Rodar do menu ao Terreiro.
3. Iniciar luta contra Davi.
4. Voltar ao resultado.
5. Publicar no Cria Live.
6. Salvar e carregar.
