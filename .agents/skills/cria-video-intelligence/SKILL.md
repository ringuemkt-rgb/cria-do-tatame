---
name: cria-video-intelligence
version: 0.1.0
parent: cria-bjj-fight-intelligence@1.0.0
fail_closed: true
shipping_default: false
generative: auxiliary_only
stop_condition: CORPUS_GAP | LICENSE_UNKNOWN | SOURCE_BYTES_MISSING
---

# CRIA VIDEO INTELLIGENCE

Transforma vídeo autorizado de BJJ em evidência auditável. Não declara que “assistiu tudo”; trabalha por corpus versionado e cobertura mensurável.

## V1 — Ingestão + cadeia de custódia

Obrigatório antes de análise:
- source ID e URL/localizador estável;
- licença/termos ou autorização registrada;
- bytes/materialização disponível;
- SHA-256 dos bytes analisados;
- data de aquisição;
- modalidade/ruleset quando conhecido;
- provenance ledger.

Sem isso: `CUSTODY_BLOCKED` e V2–V6 não executam.

## V2 — Event annotation

Schema mínimo:
`{t, actor, state_before, action, state_after, grip_family, side, result, score_event}`.

Eventos sem frame/timestamp verificável recebem `UNVERIFIED`.

## V3 — Pose/keypoints

Backends candidatos: MediaPipe/MMPose/RTMPose; modelos/datasets non-commercial permanecem research-only. Guardar identidade A/B de forma estável, confidence e oclusões.

## V4–V6

V4: recuperação 3D/SMPL somente quando licenciada e tecnicamente adequada.
V5: OpenSim/biomecânica e contact graph; não inventar força/torque.
V6: estatística de transições/lateralidade/stamina com tamanho amostral e regras de agregação explícitos.

## Safety/evidence

Vídeo de terceiro é evidência/referência, nunca spritesheet copiado. Não versionar frames protegidos sem permissão. Outputs derivados devem preservar referência de fonte e status de licença.
