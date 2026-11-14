# QA — Árvore de habilidades em Android (31/10/2026)

**Status:** IMPLEMENTED_ON_BRANCH / AUTOMATED_QA_IN_CI / PHYSICAL_ANDROID_PENDING  
**Base:** `main`  
**Escopo:** `scenes/ui/SkillTreeScreen.gd` + `tests/skill_tree_deck_smoke.gd`.

## Problema real

A tela da árvore usava um único `HBoxContainer` com painel de caminhos de 202 px, detalhes de 320 px e uma lista central. Em viewport de 360 px, os controles obrigatórios ficavam fora da área útil. O botão de retorno também ignorava a falha de `SaveManager.save_game(1)` e podia sair da tela sem persistir o desbloqueio.

## Entrega funcional

- Em larguras menores que 980 px, os **mesmos** controles de caminhos, nós e detalhes passam para três abas `TabContainer`. Não há duplicação de nós, lógica de compra, managers ou dados.
- Selecionar um caminho abre a aba de habilidades; selecionar uma habilidade abre os detalhes e o botão de desbloqueio.
- Caminhos, lista de nós e detalhes têm rolagem vertical independente, sem scroll horizontal; a lista de cinco caminhos não fica cortada em paisagem curta. Alvos de toque de retorno, seleção e compra mantêm no mínimo 48 px de altura.
- Em desktop, os três painéis retornam à organização horizontal original; a mudança de orientação é reversível.
- A saída para o Terreiro é interrompida se a gravação do save falhar, mantendo o jogador na árvore para nova tentativa.
- `SkillTreeRulesV1`, `DeckManager`, `WorldState`, IDs dos 51 nós, recompensas, economia provisória e schema de saves permanecem inalterados.

## Verificações automatizadas

```bash
npm run quality
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/skill_tree_deck_smoke.gd
godot --headless --path . --script res://tests/runtime_smoke.gd
```

O smoke exercita 360×800, 640×360, 854×480 e retorno a 1280×720; confere abas, pais originais dos painéis, scroll dos caminhos/nós, espaço do botão de compra, larguras mínimas, alvos de toque, navegação caminho→nó→detalhes e restauração desktop. Não escreve saves reais.

## Gates pendentes

- **Android físico:** instalação, notch/safe area, orientação, gesto de rolagem, foco, legibilidade, teclado e compra com persistência após reinício.
- **Falha real de disco:** testar manualmente save indisponível e confirmar que a cena não muda.
- **Revisão humana:** contraste, navegação por abas e rótulos em celular; nenhum APK é certificado por este lote.
- **Sprite Forge:** este PR não promove nem substitui assets. Os mapas ilustrados permanecem referências artísticas, não georreferenciadas.

## Risco e rollback

O reparent de controles entre `HBoxContainer` e `TabContainer` exige verificação de Godot 4.2.2/4.3 em CI. Reverter apenas este PR restaura o layout anterior sem alterar saves, deck ou contratos de dados. Ituberá segue como hub; Salvador e Itacaré permanecem externos ao mundo jogável.
