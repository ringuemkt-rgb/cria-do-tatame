# Terreiro — Árvore de habilidades e Deck V1

**Data:** 2026-10-11  
**Status:** IMPLEMENTED_ON_FEATURE_BRANCH / NOT_SHIPPING  
**Base:** main  
**Issue:** #107 (G6 — Progression & Economy)

## Runtime e fontes únicas

- `WorldState.skill_points` e `WorldState.unlocked_skills` guardam pontos e habilidades, usando os campos já persistidos em `SaveManager`.
- `DeckManager` continua sendo a única autoridade para coleção, slots e desbloqueio de cartas. Não foi criado outro manager ou autoload.
- `data/progression/skill_graph_v1.json` conserva os cinco caminhos e os 51 IDs canônicos; `SkillTreeRulesV1` lê esse grafo sem alterar os arquivos do cânone.
- `data/progression/skill_tree_playable_slice_v1.json` define **provisoriamente** um ponto por nó e pré-requisito sequencial na mesma trilha. São decisões de prototipagem até ajuste oficial de economia/atributos.
- `SkillTreeScreen.tscn` apresenta seletores de caminhos, lista de pré-requisitos, estado de desbloqueio, custo, recompensa e botão de aquisição. A decisão de gasto é do `SkillTreeRulesV1`, nunca da tela.
- `TerreiroDaLuta` oferece acesso real à árvore de habilidades, ao construtor de cartas e ao atlas existente.

## Recompensas concretas

Duas habilidades aprovam o desbloqueio de **cartas já existentes**, via `DeckManager.unlock_card`:

| Habilidade | Carta no catálogo | Técnica |
|---|---|---|
| `caca_ao_pescoco` | `card_mata_leao_01` | `mata_leao` |
| `ataque_de_braco` | `card_chave_braco_01` | `chave_braco` |

Nenhuma técnica é inventada. Se a carta não existir ou violar o requisito de faixa, a habilidade é recusada **antes** de gastar pontos. Todos os outros nós são marcadores persistidos de evolução até que os modificadores e o balanço sejam definidos pelo sistema de combate autorizado.

## Correções do DeckBuilder

1. `equip_card` passou a usar construção transacional; um deck cheio não pode apagar cartas antes de retornar o erro.
2. Arrastar uma carta já equipada para outro slot faz a troca entre os dois, sem duplicação.
3. Arrastar uma carta da coleção para slot ocupado substitui a carta anterior; nenhuma carta é removida da coleção.
4. `unequip_card` suporta o botão **REMOVER** em cada slot preenchido, funcional em Android/touch, além de clique direito ou tecla de cancelamento no desktop.
5. A última carta ativa não pode ser removida, evitando um deck sem ações jogáveis.

A mão canônica inicial de **três cartas**, os cinco slots ativos, os três passivos e os presets V2 foram preservados. PR #87 (mão de quatro cartas) permanece fora deste lote e requer reconciliação explícita, não alteração furtiva do contrato.

## QA

```bash
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/skill_tree_deck_smoke.gd
godot --headless --path . --script res://tests/runtime_smoke.gd
npm run quality
```

O smoke cobre IDs, grafo, dependências, saldo de pontos, compra duplicada, duas cartas-recompensa, equipagem transacional, slots, remoção e round-trip da serialização, sem gravar por cima dos saves reais do usuário.

## Limitações e rollback

- A árvore não atribui atributos de luta sem calibragem; os capstones são marcadores de progressão até a regra ser revisada.
- O layout é interface real Godot (não uma imagem de referência transformada em botão); falta revisão UX em tela pequena e aprovação final de arte.
- Reverter o PR remove tela, serviço, policy e atualizações do deck; o formato de save original permanece intacto.
- Os IDs já desbloqueados em save continuam válidos mesmo sem a tela (não apagar histórico).
