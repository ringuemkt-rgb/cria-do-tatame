# Skill tree — bloqueio de compra durante transição (2026-11-06)

## Falha e correção

Uma entrada de toque já enfileirada podia chamar `_purchase_selected()` após `_navigate_to()` marcar `_transitioning = true`, antes de a troca de cena concluir. Como o método de compra não consultava o bloqueio, podia gastar pontos ou conceder uma carta durante a transição. Agora a compra retorna sem efeitos quando há transição em curso ou contrato inválido.

## Escopo

Somente `SkillTreeScreen.gd` e `tests/skill_tree_deck_smoke.gd`. Preserva `CombatManager`, `DeckManager`, `WorldState`, `SaveManager`, IDs, formato de save, cenas e geografia. Nenhum asset foi promovido.

## Regressão

O smoke simula `_transitioning = true`, invoca `_purchase_selected()` e compara `WorldState.to_dict()` e `DeckManager.to_dict()` antes e depois; também preserva o teste de clique repetido de navegação. Rodar `npm run quality` e `godot --headless --path . --script res://tests/skill_tree_deck_smoke.gd` com Godot 4.2.2 e 4.3. Executar import headless e teste de toque Android real antes de promover.

## Dependência / rollback

Base empilhada sobre `fix/skill-tree-packed-scene-transition-20261105` (PR #193), após #192 → #191 → #189. PR #188 é dependência paralela do editor mobile. Reverter os dois commits funcionais deste lote para rollback. Não mesclar sem CI e revisão humana.
