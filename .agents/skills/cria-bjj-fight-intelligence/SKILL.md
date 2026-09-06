---
name: cria-bjj-fight-intelligence
version: 1.0.0
status: canonical_candidate
project: CRIA DO TATAME
fail_closed: true
shipping_default: false
generative: auxiliary_only
human_bjj_gate: required
---

# CRIA BJJ FIGHT INTELLIGENCE

Router de domínio para Brazilian Jiu-Jitsu GI/NO-GI, biomecânica, cinesiologia, vídeo técnico, animação pareada e contratos de combate do CRIA DO TATAME.

## Autoridade

1. `data/production/` e cânone executável vigente;
2. ruleset e catálogo de técnicas consumido;
3. evidência de combate real com licença/proveniência;
4. biomecânica/cinesiologia medida ou revisada;
5. position/connection/contact graph;
6. reducer e `CombatManager` existentes;
7. motion/pixel presentation;
8. geração de IA somente como candidata.

Arte, VLM, LLM e motion generativo nunca promovem técnica nem asset.

## Gramática

`POSITION → CONNECTION → CONTROL → KUZUSHI → TRANSITION → STABILIZE → THREAT → REACTION → NEXT_STATE`

Transição: `READ → CONNECT → KUZUSHI → COMMIT → TRANSITION → STABILIZE`.
Finalização: `CONTROL → ISOLATE → POSITION → LOCK → THREAT → TAP → RELEASE`.
Escape: `SURVIVE → FRAME → CREATE_SPACE → HIP_MOVE → RECOVER_STRUCTURE → RE-GUARD`.

## Módulos vinculados

- `cria-video-intelligence@0.1.0` — ingestão, custódia, anotação, pose e evidência;
- `cria-pixel-motion-pipeline@0.1.0` — paired master motion → pixel frames;
- `cria-combat-runtime@0.1.0` — contrato de conexão/branches/stamina para adapter futuro do runtime existente.

## Regras fail-closed

- `UNKNOWN != PASS`;
- licença desconhecida bloqueia ingestão além de V1;
- mocap ausente bloqueia claim biomecânico medido;
- conflito com `production_manifest_v02.json` permanece DRAFT/BLOCKED até decisão explícita;
- `human_bjj_gate` só aceita decisão de revisor humano;
- técnica pareada exige atacante, defensor, shared origin, timing, `sync_map` e contact graph;
- nenhuma nova skill cria manager/autoload/runtime concorrente;
- `shipping=true` é proibido neste pacote.

## Frame contract de referência

128×128 por ator, pivot `[64,96]`, apresentação a 12 fps, nearest-neighbor, sem anti-aliasing. Valores por técnica podem permanecer candidatos até reconciliados com o manifesto visual canônico.

## Outputs

- dossier técnico;
- rule/position/contact graph;
- motion spec;
- sync map plan;
- biomech QA;
- corpus evidence ledger;
- frame plan;
- runtime adapter spec;
- verdict: `CANDIDATE | REWORK | BLOCKED`.
