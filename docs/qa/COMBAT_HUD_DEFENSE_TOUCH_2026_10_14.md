# HUD de combate — janela de defesa touch (14/10/2026)

**Status:** alteração candidata em branch empilhada sobre #157; sem aprovação para merge.

## Falha reproduzível por leitura do runtime

Durante o turno de Davi, `CombatArenaBase._execute_player_action` desabilita os comandos normais do HUD. Quando Davi ataca, `_await_player_defense` abre uma janela de resposta e habilita o botão da defesa, mas `CombatDeckHUD._on_card_pressed` rejeitava a seleção porque o bloqueio de ações normais ainda estava ativo. O jogador perdia a oportunidade de executar `sprawl` mesmo com o botão visível.

## Correção funcional

A guarda de `_on_card_pressed` mantém a rejeição de botões desabilitados e de ataques durante o turno rival, mas permite selecionar a opção mostrada **enquanto `defense_mode` estiver ativo**. A cena continua validando a janela e a primeira defesa selecionada; `CombatManager` continua autoridade de regras, recursos, resultado e RNG. Nenhum autoload, save, regra ou asset foi modificado.

## Testes e revisão

- `tests/combat_hud_defense_regression.gd` instancia o HUD, simula o bloqueio de ataques e confirma que tocar na defesa emite `combat_v2_defense_selected`.
- `Combat Core V2` executa o novo smoke com Godot 4.2.2 e exige marcador PASS sem SCRIPT ERROR.
- A CI não substitui teste manual de touch, legibilidade e latência no Android físico.
- Depende do #157 e precisa ser retestado com #166 (animação pareada), #167 (deck/equipagem) e a janela de defesa no fluxo Ruan × Davi.
- **Rollback:** reverter o commit do HUD e do smoke. `main` e saves não são alterados.
