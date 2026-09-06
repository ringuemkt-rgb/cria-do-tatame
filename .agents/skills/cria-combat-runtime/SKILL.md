---
name: cria-combat-runtime
version: 0.1.0
parent: cria-bjj-fight-intelligence@1.0.0
fail_closed: true
shipping_default: false
generative: auxiliary_only
runtime_implementation_status: SPEC_ONLY
runtime_authority: CombatManager
---

# CRIA COMBAT RUNTIME — DOMAIN ADAPTER SPEC

Especifica como evidência BJJ pode alimentar o runtime existente. **Não cria segundo manager, reducer, singleton ou autoload.** Qualquer implementação futura entra por adapter/fachada no `CombatManager` canônico e exige lote próprio.

## Connection quality antes do botão

Componentes candidatos:
- `grip_security`;
- `head_position`;
- `hip_connection`;
- `inside_position`;
- `elbow_position`;
- `frame_integrity`;
- `base_integrity`.

Nenhum threshold numérico é canônico até calibração.

## Branches

Uma técnica pode possuir branches com `diverge_at` no `sync_map`. A branch só muda presentation/state quando o reducer autoritativo aceitar o evento. Sprite não move estado de gameplay.

## Stamina

Separar conceitos candidatos:
- `grip_isometric_cost`;
- `pressure_cost`;
- `scramble_burst_cost`;
- `failed_attack_cost`;
- `recovery_under_control`.

Valores = `PENDING_CALIBRATION`.

## Pontuação/ruleset

Scoring e legalidade são adapters versionados por ruleset; o motion físico não define ponto. Estabilização só gera score quando o ruleset adapter vigente confirmar os requisitos.

## Proibições

- LLM/VLM no loop crítico;
- network AI para decidir combate;
- segundo CombatManager;
- números de balanceamento inventados;
- promoção de dossier candidato para runtime sem migração e testes.
