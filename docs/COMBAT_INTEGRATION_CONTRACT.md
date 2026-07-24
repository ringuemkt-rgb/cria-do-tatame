# CRIA DO TATAME – PRESSÃO — CONTRATO DE INTEGRAÇÃO DO COMBATE

**Status:** contrato técnico canônico para a integração v4.3.  
**Escopo:** árvore de habilidades, catálogo de cartas, loadout por personagem, combate posicional, rulesets de arena, finais e bindings de animação.  
**Base:** `release/v4-integration`. Este documento não declara sistemas inexistentes como concluídos; ele define as interfaces obrigatórias e os testes que provam as pontes.

---

## 1. Regra de precedência das camadas

| Camada | Autoridade | Não pode fazer |
|---|---|---|
| **Moveset / CPS-A** | Vocabulário físico e audiovisual do personagem: estados, movimentos e frame-ranges. | Decidir sozinho se uma ação é jogável ou se vence a luta. |
| **Cartas** | Ações jogáveis do catálogo global: origem, destino, lado, custo, janela, moral e resposta defensiva. | Ignorar posição, lado, recursos, ruleset, tap ou escape. |
| **Técnicas centrais / CPS-B** | Domínio, prioridade, eficiência e identidade do personagem sobre cartas específicas. | Criar uma segunda lista incompatível com o catálogo global. |
| **Árvore de habilidades** | Desbloqueia acesso, amplia consistência, concede pontos de deck e publica consequências persistentes. | Comprar poder com Molho ou aplicar regras diretamente pela UI. |
| **Arena / ruleset** | Autoriza, restringe ou ressignifica ações e caminhos de vitória. | Ser tratada como skin sem impacto mecânico. |
| **Animation manifest** | Traduz IDs semânticos em estados, atlas, frames pareados e `sync_map`. | Conter regra de gameplay. |

A cadeia autoritativa é:

```text
progressão → acesso → loadout → posição/lado → recursos/janela → ruleset
           → transição do FSM → binding de animação → consequência narrativa
```

---

## 2. Regra canônica de carta jogável

Existe uma única autoridade pública para a decisão: `pode_jogar(...)`. HUD, IA, tutorial, acessibilidade e comandos devem consumir o mesmo resultado; nenhum deles reimplementa a regra.

Uma carta só pode ser executada quando todas as condições forem verdadeiras:

```text
CATÁLOGO
∧ ACESSO DO PERSONAGEM
∧ POLÍTICA MORAL DO SAVE
∧ LOADOUT/MÃO
∧ POSIÇÃO E LADO
∧ FLAGS NARRATIVAS
∧ RULESET
∧ RECURSOS
∧ JANELA/FASE
```

A avaliação ocorre nesta ordem:

1. a carta existe no catálogo mestre;
2. o lutador existe no combate;
3. a carta está no loadout do lutador;
4. a política persistente daquele lutador permite a classe moral da carta;
5. a carta está na mão contextual;
6. posição de origem e lado relativo são compatíveis;
7. flags narrativas exigidas estão satisfeitas;
8. o ruleset permite a categoria moral;
9. recursos são suficientes;
10. a fase permite decisão e não há transição, defesa, submissão ou encerramento bloqueando a ação.

O retorno nunca é apenas booleano:

```text
PlayabilityResult
├── allowed / ok
├── reason_code / reason
├── localized_reason_key
├── specialized_slot
├── resource_preview
└── predicted_transition
```

Os códigos oficiais estão em `data/combat/playability_reason_codes.json`.

---

## 3. Catálogo mestre, acesso e Código do Cria

O catálogo mestre preserva todas as cartas para NPCs, debugging, replay, migração e conteúdo narrativo. O nó **Código do Cria** não apaga o registro global: ele publica uma política persistente no save do jogador.

```text
perfil do jogador:
  forbidden_morals = ["suja"]

SkillHubLoadoutV41:
  bloqueia desbloqueio por dono;
  bloqueia inclusão no loadout;
  sanitiza save legado;
  sanitiza recompensas futuras;
  preserva o catálogo global para outros personagens.
```

Os guards obrigatórios são:

- `unlock_for_owner()`;
- `can_include()`;
- `_sanitize_deck()`;
- `import_state()`.

---

## 4. Passivos da árvore no combate

A árvore não é consultada a cada frame. Antes da luta, progressão, equipamentos e flags mundiais produzem um **snapshot imutável de passivos** por lutador.

```text
Skill Tree + equipment + WorldState
                 ↓
CombatPassiveSnapshot normalizado
                 ↓
PositionalCardCombatV41 / Submission HUD / terreno / IA
```

Multiplicadores começam em `1.0`; bônus aditivos começam em `0.0`. Campos mínimos suportados:

- `sweet_spot_mult`;
- `dreno_foco_arena_mult`;
- `fadiga_dano_mult`;
- `gas_cost_mult`;
- `focus_cost_mult`;
- `submission_attack_mult`;
- `submission_defense_mult`;
- `grip_inicial`;
- `grip_por_pegada`;
- `vida_max_bonus`;
- `gas_max_bonus`;
- `foco_max_bonus`.

Um passivo só é considerado implementado quando existe teste numérico que falha sem a ponte.

---

## 5. Autoridade dos rulesets sobre vitória

Nenhum sistema emite `combat_finished` ou chama o encerramento sem consultar o ruleset ativo. O fluxo obrigatório é:

```text
evento técnico → VictoryCandidate → try_resolve_victory()
              → ruleset.caminhos_vitoria → aceita ou rejeita
```

| Ruleset | Caminhos aceitos |
|---|---|
| `OFICIAL` | finalização, pontos, desistência |
| `CLANDESTINA` | finalização, desistência |
| `RITO` | ceder |
| `FESTIVAL` | finalização, pontos |
| `DOJO` | nenhum |
| `MORAL` | resistir_discurso |

Consequências obrigatórias:

- finalizar tecnicamente no `MORAL` não encerra a luta;
- finalizar tecnicamente no `RITO` não encerra a luta;
- `DOJO` nunca produz vencedor convencional;
- pontos só encerram rulesets que aceitam `pontos`;
- objetivos especiais são resolvidos por `resolve_ruleset_objective()`.

---

## 6. Efeitos persistentes e finais

A árvore publica consequências no `WorldState`; o resolvedor de finais não consulta a tela ou o nó da árvore diretamente.

```text
respeito_nao_humilhar desbloqueado
        ↓
WorldState.story_flags["moral_nao_humilhar"] = true
        ↓
EndingResolverV4 avalia o final Cria de Verdade
```

A mesma regra vale para qualquer `path_gate_final`: a progressão publica uma flag serializável e o final lê essa flag.

---

## 7. Fachada entre deck legado e v4.1

Durante a migração coexistem o `DeckManager` legado e o `SkillHubLoadoutV41`. A regra é:

1. o catálogo e a progressão v4.1 são a fonte de verdade nova;
2. o legado é fachada de compatibilidade;
3. proibições morais e desbloqueios passam pela política v4.1 antes de chegar ao legado;
4. migração não pode ressuscitar carta removida;
5. a UI não decide elegibilidade.

A remoção definitiva do legado depende de smoke tests equivalentes e decisão explícita de migração.

---

## 8. Binding de animação

`cards.json`, `moveset.json` e `techniques_<id>.json` representam conceitos diferentes e não precisam compartilhar nomes físicos. Um `animation_manifest.json` por personagem faz a tradução.

```text
card_id → move_id/move_number → technique_id → animation_state
        → attacker_frames / defender_frames / sync_map / hitbox
```

O combate solicita um ID semântico. `AnimationBindingResolver` devolve o binding concreto. Alterar atlas ou regenerar frames não pode exigir alteração da lógica da carta.

---

## 9. Mapa produtor → consumidor

| Dado | Produtor | Consumidor obrigatório |
|---|---|---|
| `desbloqueia_carta` | progressão | `SkillHubLoadoutV41.unlock_for_owner` |
| `deck_points` | progressão | capacidade do loadout |
| `passivo_stat` | progressão/equipamento | `CombatPassiveSnapshot` e runtime |
| `remove_cartas_sujas` | progressão | política persistente por dono |
| `path_gate_final` | progressão | `WorldState` → `EndingResolverV4` |
| `origem/lado/custo` | carta | `pode_jogar` e Position FSM |
| `caminhos_vitoria` | ruleset | `try_resolve_victory` |
| `frames_anim` | carta | `AnimationBindingResolver` |
| `move_number/frame_range` | CPS-A | animation manifest |
| `technique_id` | CPS-B | animation manifest e IA de arquétipo |

---

## 10. Testes de ponte obrigatórios

- `Olho de Peixe` ou snapshot equivalente altera `sweet_spot_mult` em exatamente 15%;
- `Código do Cria` impede carta suja em loadout novo;
- importação de save legado remove carta suja do dono protegido;
- recompensa futura não desbloqueia carta suja para o dono protegido;
- Kimura no `OFICIAL` pode finalizar;
- Kimura no `MORAL` não emite vitória;
- finalização no `RITO` não emite vitória convencional;
- `Cria de Verdade` é bloqueado sem `moral_nao_humilhar`;
- uma carta de teste resolve binding completo no manifest;
- carta com posição inválida retorna `POSITION_INVALID`;
- recursos insuficientes retornam `RESOURCE_INSUFFICIENT`.

---

## 11. Definition of Done

A integração só está pronta quando:

- há uma única autoridade para `pode_jogar`;
- loadout e migração respeitam políticas por dono;
- passivos produzem mudanças mensuráveis;
- MORAL, RITO e DOJO bloqueiam vitórias convencionais no runtime;
- finais leem consequências persistentes;
- bindings de animação são validados;
- testes falham se qualquer ponte for removida;
- nenhuma tela de UI contém regra de gameplay própria.
