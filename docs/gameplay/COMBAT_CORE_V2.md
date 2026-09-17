# Combat core v2 — contrato reconciliado

O spec de loop (draw → escolha → IA → reduce → animação → resolução) está certo.
A frase “reducer v2 é autoridade da luta” **não**. Juiz = `CombatManager` autoload. Reducer é `RefCounted` chamado pelo juiz depois do parity gate.

## O que o repo já tem

- CombatManager + TechniqueResolver + Clash + FrameData + StateMachine
- DeckManager **já é autoload** (`/root/DeckManager`). Não nasça o segundo. Envolva.
- `src/combat/CombatManager.gd` é clone — alias ou delete, não autoridade.
- Gate BJJ FAIL-CLOSED (40/120/10 + paired anim).
- Resolver ainda usa `rng.randomize()` — seed é o primeiro patch.

## Ordem real

1. Seed + `requires_gi` no resolver atual.
2. Fatia ouro Ruan×Davi (6 cadeias + sync_map).
3. Deck 6–8 em cima do DeckManager existente.
4. Hub pré-luta (scouting é candidate se Tinker não estiver lock).
5. Parity v1≈v2. Só então `execute_technique` chama o reducer.
6. CriaLive lê `clip_quality`. Não julga.

Wincon de submissão = posição + grip + tap. `vida` é feel, não vitória.
Virada do Cria: 1× por luta, flag no state.
Facção só enviesa deck/scouting/heat.
