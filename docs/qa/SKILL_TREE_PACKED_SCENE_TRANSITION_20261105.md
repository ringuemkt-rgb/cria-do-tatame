# Skill Tree — transição com cena validada (2026-11-05)

**Status:** PR Draft; requer CI, revisão humana e testes Android físico.

## Problema
A navegação da árvore validava um `PackedScene` com `ResourceLoader.load()`, mas em seguida chamava `change_scene_to_file(destination)`, realizando uma segunda resolução do caminho. O recurso usado na transição não era explicitamente o mesmo validado.

## Mudança
`SkillTreeScreen._navigate_to()` continua verificando o destino **antes** do save e abortando sem navegação quando `SaveManager.save_game(1)` falha. Após preflight e save bem-sucedidos, usa `change_scene_to_packed(destination_scene as PackedScene)`. Não há alteração de IDs, formato de save, autoloads, rotas regionais ou managers.

## Regressão
`tests/skill_tree_deck_smoke.gd` mantém testes de destino ausente, recurso não-cena, fluxo de 51 nós e layouts compactos, e acrescenta contrato para não reintroduzir o carregamento duplicado. O teste do fluxo real de mudança de cena permanece dependente de QA de integração.

## Verificação necessária
1. `npm run quality`
2. `godot --headless --editor --path . --quit`
3. `godot --headless --path . --script res://tests/skill_tree_deck_smoke.gd` em Godot 4.2.2 e 4.3.
4. QA humano da navegação Árvore → Deck e Árvore → Terreiro; save/reload; touch Android físico.
5. Revisão dos PRs empilhados #189 → #191 → #192 antes de qualquer merge.

## Rollback
Reverter os commits deste PR; `change_scene_to_file(destination)` volta ao comportamento anterior sem migração de dados.
