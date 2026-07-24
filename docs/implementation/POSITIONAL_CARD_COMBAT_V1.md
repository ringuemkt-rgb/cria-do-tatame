# Positional Card Combat v1

## Objetivo

Implementar o coração jogável de Cria do Tatame como jiu-jitsu posicional orientado por cartas do Hub de Habilidades.

## Fluxo implementado

1. O Hub desbloqueia e treina técnicas por treino, mestre, skill tree ou flag narrativa.
2. O jogador monta um deck de 12 cartas, com no máximo duas cópias por técnica.
3. Ao iniciar a luta, o runtime saca uma mão contextual de três cartas.
4. A posição compartilhada define quais cartas podem ser usadas.
5. Jogar uma carta consome gás, foco, grip e/ou pressão.
6. O defensor recebe uma janela de resposta específica: sprawl, frame, base, bridge, elbow escape ou defesa de finalização.
7. Sucesso altera posição, recursos, integridade, guarda, pressão e pontos.
8. A mão é redesenhada após cada mudança posicional.
9. A luta termina por finalização, desistência ou pontos.

## Arquivos

- `src/combat/PositionalCardCombat.gd`: orquestrador do loop.
- `src/hub/SkillHubLoadout.gd`: desbloqueio, treino e montagem do deck.
- `data/combat/hub_skill_cards_v1.json`: dez cartas canônicas e decks iniciais.
- `tests/test_positional_card_combat_data.py`: gates de schema e contratos.

## Posições

`standing -> clinch -> guard/half -> side_control -> mount/back_control -> submission`

A posição é única e compartilhada. `top_id` e `bottom_id` definem o lado relativo dos lutadores.

## Recursos

- Integridade
- Gás
- Foco
- Grip 0–3
- Pressão
- Guarda
- Tensão moral

## Regras de integridade

- Sem gacha, loot box ou compra de poder com Molho.
- Cartas sujas podem existir futuramente apenas como escolha narrativa do underground e devem subir tensão moral.
- O motor não substitui `CombatManager`, `DeckManager` ou `CombatStateMachine`; ele deve ser integrado por fachada após auditoria.

## Próxima integração

1. Criar `PositionalCombatAdapter.gd` para traduzir estados legados `PLAYER_TOP_GUARD` etc.
2. Conectar `CombatDeckHUD.gd` à mão contextual e estados bloqueados.
3. Criar Submission HUD acessível.
4. Conectar animações por `animation_id`.
5. Adicionar IA que escolhe cartas por perfil e posição.
6. Executar smoke test no Godot 4.3 e validar Android touch.
