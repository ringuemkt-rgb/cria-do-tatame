# Positional Card Combat v1

## Objetivo

Implementar o coração jogável de Cria do Tatame como jiu-jitsu posicional orientado por cartas do Hub de Habilidades.

## Fluxo

Hub de Habilidades → deck de 12 → mão contextual → posição simétrica + lado → carta válida → janela de defesa → recursos/pontos/transição → finalização, desistência, pontos, rito ou objetivo especial do ruleset.

## Modelo canônico v4.1-FINAL

A fonte da verdade passa a ser composta por oito posições simétricas:

- `STANDING`
- `CLINCH`
- `GUARD`
- `HALF`
- `SIDE_CONTROL`
- `MOUNT`
- `BACK_CONTROL`
- `SUBMISSION`

`top`, `bottom` e `any` são armazenados separadamente como lado do jogador. O lado do oponente é derivado e nunca persistido duas vezes.

## Dados canônicos recebidos

- `data/combat/cards.json`: 20 cartas — 10 limpas canônicas, 6 sujas e 4 de raiz/história.
- `data/combat/position_data.json`: transições genéricas para as oito posições.
- `data/combat/rulesets.json`: `OFICIAL`, `CLANDESTINA`, `RITO`, `FESTIVAL`, `DOJO` e `MORAL`.
- `tests/test_gdd_systems_v41_data.py`: contratos de schema e invariantes de design.

## Implementação já existente nesta branch

- `src/combat/PositionalCardCombat.gd`: protótipo do orquestrador de combate.
- `src/hub/SkillHubLoadout.gd`: protótipo do Hub e loadout.
- `data/combat/hub_skill_cards_v1.json`: catálogo inicial anterior ao pacote final.
- `tests/test_positional_card_combat_data.py`: gates do primeiro vertical slice.

## Reconciliação obrigatória antes do merge

1. Trocar o modelo provisório pelo contrato canônico de 8 posições + lado.
2. Carregar cartas, posições e rulesets dos JSONs canônicos.
3. Implementar enforcement das cartas sujas por ruleset: desclassificação, uso livre ou falha do rito.
4. Executar `efeito_extra` somente por vocabulário fechado.
5. Avaliar requisitos como `leoa_vinculo>=2` sem executar expressões arbitrárias.
6. Criar adapter para os aliases legados de `CombatStateMachine`.
7. Conectar `CombatDeckHUD`, touch, IA, animações e Submission HUD.
8. Rodar testes Python, GUT e smoke headless do Godot 4.3.

## Regras de integridade

- Sem gacha, loot box ou compra de poder com Molho.
- Cartas sujas são decisões narrativas e mecânicas de risco; nunca progressão premium.
- O motor não substitui `CombatManager`, `DeckManager` ou `CombatStateMachine` sem adapter e testes.

## Nota de integridade documental

A mensagem `GDD-SYSTEMS v4.1-FINAL` foi truncada durante `data/skill_tree/tree.json`, no nó `foco_leitura_quadril`. O restante da Seção 3 e as Seções 4–6 não foram recebidos integralmente e não foram reconstruídos como se fossem aprovados.
