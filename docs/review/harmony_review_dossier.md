# Dossiê humano — Combat Harmony Slice v1

**Status:** `DRAFT_HUMAN_REVIEW_UNSIGNED`
**Lote:** `M31 harmony-review-gates`
**Base remota:** `lead/harmony-v1` / PR #74 / `4165fc8d`
**Fonte examinada:** `data/combat/harmony_contract_v1.json`
**SHA-256 da fonte após M31:** `90a93ea42cedf8c600e73002fd5b82c70117411b4e9be93f9ab65ed27c85db16`
**Assinante humano autorizado:** Mestre Satoshi

## 1. Regra de uso

Este dossiê organiza evidência para decisão humana. Ele não integra cards, não aprova animação, não altera o runtime e não assina nenhum gate. Campos ausentes permanecem `missing_body_blocked`; espaço em branco não é permissão para estimar um valor.

Princípios vinculantes:

- **captura = evidência; IA = derivado**;
- **runtime decide; animação apresenta**;
- tempo canônico do gameplay em milissegundos;
- TAP tem prioridade soberana e exige soltura imediata visível;
- arte, pose, proximidade 2D e render não provam contato, pressão ou legalidade;
- somente Mestre Satoshi pode marcar a decisão humana final.

## 2. Estado das lacunas que afetam todas as técnicas

| Campo solicitado | Evidência disponível | Estado para revisão |
|---|---|---|
| `frame_ms` | preview a 12 fps | `83,333 ms/frame`, derivado de `1000 ÷ 12`; apresentação apenas |
| janela-base | `base_defense_window_ms` | `250 ms` em todas as seis técnicas |
| `early_ms` | nenhum corpo decisório define a partição | `missing_body_blocked` |
| `perfect_ms` | nenhum corpo decisório define a partição | `missing_body_blocked` |
| `late_ms` | nenhum corpo decisório define a partição | `missing_body_blocked` |
| ruleset por técnica | ausente no contrato Harmony | `missing_body_blocked` |
| ramos 1–3 | presentes por técnica | revisáveis |
| ramos 4–6 | ausentes no contrato | três slots `missing_body_blocked` por técnica |

O buffer de 100 ms e os ajustes de dificuldade `treino +67 ms` / `mestre −33 ms` não definem early/perfect/late e não podem ser reaproveitados para isso.

## 3. Controles D230

| Controle | Contexto normal | `submission_defense=true` | Feedback obrigatório |
|---|---|---|---|
| Stick esquerdo | movimento/footwork | movimento permitido pelo runtime | visual + sonoro + háptico quando disponível |
| A | contextual 1 | contextual 1 se elegível | aceito, bufferizado, contexto ou motivo |
| B | contextual 2 | **segurar = TAP** | troca explícita do rótulo para `TAP` |
| X | contextual 3 | contextual 3 se elegível | aceito, bufferizado, contexto ou motivo |
| Y | contextual 4 | contextual 4 se elegível | aceito, bufferizado, contexto ou motivo |
| RB | contextual 5 | contextual 5 se elegível | aceito, bufferizado, contexto ou motivo |
| RT | defesa | defesa, sem consumir TAP | janela e motivo visíveis |
| LB | especial | especial, sem consumir TAP | elegibilidade e custo visíveis |
| Start | pausa/menu | subordinado ao TAP | confirmação visual/sonora |

## 4. Cadeia de prioridade D231

| Prioridade | Entrada | Regra de consumo |
|---:|---|---|
| 1 | TAP | sempre tratado primeiro; interrompe pressão e agenda soltura |
| 2 | pausa/menu | processa somente depois de preservar TAP |
| 3 | defesa | processa se elegível; nunca engole TAP |
| 4 | contextual | executa, entra no buffer ou explica indisponibilidade |

**Invariante:** nenhum input pode desaparecer silenciosamente.

---

## 5. Técnica 01 — Grip de Ferro

| Campo | Valor de fonte |
|---|---|
| ID / nome | `grip_de_ferro` / Grip de Ferro |
| Categoria | `pegada` |
| Ruleset | `________________` — `missing_body_blocked` |
| Entry → exit | `PLAYER_STANDING_NEUTRAL` → `PLAYER_TOP_CLINCH` |
| Preview | 48 frames · 12 fps · 4.000 ms |
| `frame_ms` | 83,333 ms, apresentação apenas |
| Janela-base | 250 ms |
| Early / perfect / late | `____ / ____ / ____ ms` — `missing_body_blocked` |

### Contatos declarados

| ID | A ↔ B | Intervalo | Revisor exigido |
|---|---|---:|---|
| `primary_grip` | `ruan.right_hand` ↔ `davi.left_sleeve` | 1.167–2.500 ms | BJJ pendente |

### Seis slots de ramo

| Slot | Ramo | Estado |
|---:|---|---|
| 1 | `success` | fonte presente |
| 2 | `defended` | fonte presente |
| 3 | `safe_recovery` | fonte presente |
| 4 | `________________` | `missing_body_blocked` |
| 5 | `________________` | `missing_body_blocked` |
| 6 | `________________` | `missing_body_blocked` |

**Nota de segurança:** confirmar trajetória contínua da mão, apoio estável e soltura da manga; grip não autoriza torção de dedos, pescoço ou puxão brusco. **TAP:** NA no ramo atual; permanece soberano se o runtime entrar em defesa de finalização.

### Checklist humano

| Verificação | PASS / FAIL / NA | Evidência/observação |
|---|---|---|
| Identidade, categoria e estados conferem | ☐ PASS ☐ FAIL ☐ NA | |
| Ruleset foi preenchido por decisão válida | ☐ PASS ☐ FAIL ☐ NA | |
| Early/perfect/late foram aprovados em ms | ☐ PASS ☐ FAIL ☐ NA | |
| Grip e apoios são biomecanicamente seguros | ☐ PASS ☐ FAIL ☐ NA | |
| Seis ramos estão definidos | ☐ PASS ☐ FAIL ☐ NA | |
| Recuperação mostra soltura e base neutra | ☐ PASS ☐ FAIL ☐ NA | |
| TAP/priority não sofre regressão | ☐ PASS ☐ FAIL ☐ NA | |

**Assinatura:** Quem `________________` · Quando `____/____/______ ____:____` · Decisão `☐ PASS ☐ FAIL ☐ NA`

---

## 6. Técnica 02 — Baiana

| Campo | Valor de fonte |
|---|---|
| ID / nome | `baiana` / Baiana |
| Categoria | `queda` |
| Ruleset | `________________` — `missing_body_blocked` |
| Entry → exit | `PLAYER_STANDING_NEUTRAL` → `PLAYER_TOP_GUARD` |
| Preview | 48 frames · 12 fps · 4.000 ms |
| `frame_ms` | 83,333 ms, apresentação apenas |
| Janela-base | 250 ms |
| Early / perfect / late | `____ / ____ / ____ ms` — `missing_body_blocked` |

### Contatos declarados

| ID | A ↔ B | Intervalo | Revisor exigido |
|---|---|---:|---|
| `primary_grip` | `ruan.right_hand` ↔ `davi.gi_torso` | 900–2.500 ms | BJJ pendente |
| `leg_control_contact` | `ruan.left_arm` ↔ `davi.right_leg` | 1.167–2.500 ms | BJJ pendente |
| `tatame_contact` | `davi.support_chain` ↔ `tatame` | 2.500–4.000 ms | BJJ pendente |

### Seis slots de ramo

| Slot | Ramo | Estado |
|---:|---|---|
| 1 | `success` | fonte presente |
| 2 | `sprawl_defense` | fonte presente |
| 3 | `safe_recovery` | fonte presente |
| 4 | `________________` | `missing_body_blocked` |
| 5 | `________________` | `missing_body_blocked` |
| 6 | `________________` | `missing_body_blocked` |

**Nota de segurança:** exigir mudança de nível, coluna/cabeça coerentes, contato controlado e nenhuma queda sobre a cabeça. O defensor precisa conseguir iniciar sprawl sem interpenetração. **TAP:** NA no ramo atual; soberania global preservada.

### Checklist humano

| Verificação | PASS / FAIL / NA | Evidência/observação |
|---|---|---|
| Identidade, categoria e estados conferem | ☐ PASS ☐ FAIL ☐ NA | |
| Ruleset foi preenchido por decisão válida | ☐ PASS ☐ FAIL ☐ NA | |
| Early/perfect/late foram aprovados em ms | ☐ PASS ☐ FAIL ☐ NA | |
| Entrada, base, cabeça e queda são seguras | ☐ PASS ☐ FAIL ☐ NA | |
| Três contatos permanecem contínuos | ☐ PASS ☐ FAIL ☐ NA | |
| Seis ramos estão definidos | ☐ PASS ☐ FAIL ☐ NA | |
| TAP/priority não sofre regressão | ☐ PASS ☐ FAIL ☐ NA | |

**Assinatura:** Quem `________________` · Quando `____/____/______ ____:____` · Decisão `☐ PASS ☐ FAIL ☐ NA`

---

## 7. Técnica 03 — Sprawl

| Campo | Valor de fonte |
|---|---|
| ID / nome | `sprawl` / Sprawl |
| Categoria | `defesa` |
| Ruleset | `________________` — `missing_body_blocked` |
| Entry → exit | `PLAYER_STANDING_NEUTRAL` → `PLAYER_STANDING_NEUTRAL` |
| Preview | 48 frames · 12 fps · 4.000 ms |
| `frame_ms` | 83,333 ms, apresentação apenas |
| Janela-base | 250 ms |
| Early / perfect / late | `____ / ____ / ____ ms` — `missing_body_blocked` |

### Contatos declarados

| ID | A ↔ B | Intervalo | Revisor exigido |
|---|---|---:|---|
| `defensive_frame` | `davi.forearm` ↔ `ruan.shoulder` | 1.167–2.500 ms | BJJ pendente |
| `leg_control_contact` | `davi.hip_line` ↔ `ruan.shoulder_line` | 1.833–3.333 ms | BJJ pendente |
| `tatame_contact` | `davi.feet` ↔ `tatame` | 0–4.000 ms | BJJ pendente |

### Seis slots de ramo

| Slot | Ramo | Estado |
|---:|---|---|
| 1 | `success` | fonte presente |
| 2 | `reattack` | fonte presente |
| 3 | `safe_recovery` | fonte presente |
| 4 | `________________` | `missing_body_blocked` |
| 5 | `________________` | `missing_body_blocked` |
| 6 | `________________` | `missing_body_blocked` |

**Nota de segurança:** antebraço deve enquadrar o ombro, nunca aplicar crank no pescoço; quadril comunica peso sem esmagamento impossível; peito do pé prepara qualquer arrasto e a soltura fica visível. **TAP:** NA no ramo atual; soberania global preservada.

### Checklist humano

| Verificação | PASS / FAIL / NA | Evidência/observação |
|---|---|---|
| Identidade, categoria e estados conferem | ☐ PASS ☐ FAIL ☐ NA | |
| Ruleset foi preenchido por decisão válida | ☐ PASS ☐ FAIL ☐ NA | |
| Early/perfect/late foram aprovados em ms | ☐ PASS ☐ FAIL ☐ NA | |
| Frame está no ombro e não no pescoço | ☐ PASS ☐ FAIL ☐ NA | |
| Apoios, quadril e contatos são plausíveis | ☐ PASS ☐ FAIL ☐ NA | |
| Seis ramos estão definidos | ☐ PASS ☐ FAIL ☐ NA | |
| TAP/priority não sofre regressão | ☐ PASS ☐ FAIL ☐ NA | |

**Assinatura:** Quem `________________` · Quando `____/____/______ ____:____` · Decisão `☐ PASS ☐ FAIL ☐ NA`

---

## 8. Técnica 04 — Corte de Joelho

| Campo | Valor de fonte |
|---|---|
| ID / nome | `corte_joelho` / Corte de Joelho |
| Categoria | `passagem` |
| Ruleset | `________________` — `missing_body_blocked` |
| Entry → exit | `PLAYER_TOP_GUARD` → `PLAYER_TOP_SIDE` |
| Preview | 48 frames · 12 fps · 4.000 ms |
| `frame_ms` | 83,333 ms, apresentação apenas |
| Janela-base | 250 ms |
| Early / perfect / late | `____ / ____ / ____ ms` — `missing_body_blocked` |
| Card/mastery | completos somente em dados; não equipáveis; runtime ausente |

### Contatos declarados

| ID | A ↔ B | Intervalo | Revisor exigido |
|---|---|---:|---|
| `primary_grip` | `ruan.upper_body_frame` ↔ `davi.shoulder_line` | 500–2.500 ms | BJJ pendente |
| `leg_control_contact` | `ruan.knee_line` ↔ `davi.thigh_line` | 1.167–2.500 ms | BJJ pendente |
| `tatame_contact` | `davi.support_chain` ↔ `tatame` | 0–4.000 ms | BJJ pendente |

### Seis slots de ramo

| Slot | Ramo | Estado |
|---:|---|---|
| 1 | `success` | fonte presente |
| 2 | `guard_recovery` | fonte presente |
| 3 | `safe_recovery` | fonte presente |
| 4 | `________________` | `missing_body_blocked` |
| 5 | `________________` | `missing_body_blocked` |
| 6 | `________________` | `missing_body_blocked` |

**Nota de segurança:** mostrar controle de pernas/quadril antes da pressão de tronco; joelho segue trajetória legível, sem torção forçada; defensor mantém frame e caminho de recuperação. **TAP:** NA no ramo atual; soberania global preservada.

### Checklist humano

| Verificação | PASS / FAIL / NA | Evidência/observação |
|---|---|---|
| Identidade, categoria e estados conferem | ☐ PASS ☐ FAIL ☐ NA | |
| Ruleset foi preenchido por decisão válida | ☐ PASS ☐ FAIL ☐ NA | |
| Early/perfect/late foram aprovados em ms | ☐ PASS ☐ FAIL ☐ NA | |
| Controle de perna precede pressão de tronco | ☐ PASS ☐ FAIL ☐ NA | |
| Card/mastery continuam fora do runtime | ☐ PASS ☐ FAIL ☐ NA | |
| Seis ramos estão definidos | ☐ PASS ☐ FAIL ☐ NA | |
| TAP/priority não sofre regressão | ☐ PASS ☐ FAIL ☐ NA | |

**Assinatura:** Quem `________________` · Quando `____/____/______ ____:____` · Decisão `☐ PASS ☐ FAIL ☐ NA`

---

## 9. Técnica 05 — Cem Quilos

| Campo | Valor de fonte |
|---|---|
| ID / nome | `cem_quilos` / Cem Quilos |
| Categoria | `controle` |
| Ruleset | `________________` — `missing_body_blocked` |
| Entry → exit | `PLAYER_TOP_SIDE` → `PLAYER_TOP_SIDE` |
| Preview | 48 frames · 12 fps · 4.000 ms |
| `frame_ms` | 83,333 ms, apresentação apenas |
| Janela-base | 250 ms |
| Early / perfect / late | `____ / ____ / ____ ms` — `missing_body_blocked` |

### Contatos declarados

| ID | A ↔ B | Intervalo | Revisor exigido |
|---|---|---:|---|
| `primary_grip` | `ruan.near_arm` ↔ `davi.far_shoulder` | 1.167–3.333 ms | BJJ pendente |
| `tatame_contact` | `ruan.support_chain` ↔ `tatame` | 0–4.000 ms | BJJ pendente |
| `tatame_contact_defender` | `davi.support_chain` ↔ `tatame` | 0–4.000 ms | BJJ pendente |

### Seis slots de ramo

| Slot | Ramo | Estado |
|---:|---|---|
| 1 | `stabilized` | fonte presente |
| 2 | `frame_escape` | fonte presente |
| 3 | `safe_recovery` | fonte presente |
| 4 | `________________` | `missing_body_blocked` |
| 5 | `________________` | `missing_body_blocked` |
| 6 | `________________` | `missing_body_blocked` |

**Nota de segurança:** pressão deve ser apresentada por base, apoio e distribuição de peso, sem deformação, sufocamento gráfico ou compressão impossível; o frame defensivo e a saída continuam legíveis. **TAP:** NA no ramo atual; soberania global preservada.

### Checklist humano

| Verificação | PASS / FAIL / NA | Evidência/observação |
|---|---|---|
| Identidade, categoria e estados conferem | ☐ PASS ☐ FAIL ☐ NA | |
| Ruleset foi preenchido por decisão válida | ☐ PASS ☐ FAIL ☐ NA | |
| Early/perfect/late foram aprovados em ms | ☐ PASS ☐ FAIL ☐ NA | |
| Base e distribuição de peso são plausíveis | ☐ PASS ☐ FAIL ☐ NA | |
| Frame/escape permanece legível | ☐ PASS ☐ FAIL ☐ NA | |
| Seis ramos estão definidos | ☐ PASS ☐ FAIL ☐ NA | |
| TAP/priority não sofre regressão | ☐ PASS ☐ FAIL ☐ NA | |

**Assinatura:** Quem `________________` · Quando `____/____/______ ____:____` · Decisão `☐ PASS ☐ FAIL ☐ NA`

---

## 10. Técnica 06 — Encerramento Técnico

| Campo | Valor de fonte |
|---|---|
| ID / nome | `encerramento_tecnico` / Encerramento Técnico |
| Categoria | `finalizacao` |
| Ruleset | `________________` — `missing_body_blocked` |
| Entry → exit | `PLAYER_SUBMISSION_ATTACK` → `RESET` |
| Preview | 48 frames · 12 fps · 4.000 ms |
| `frame_ms` | 83,333 ms, apresentação apenas |
| Janela-base | 250 ms |
| Early / perfect / late | `____ / ____ / ____ ms` — `missing_body_blocked` |
| Card/mastery | completos somente em dados; não equipáveis; runtime ausente |

### Contatos declarados

| ID | A ↔ B | Intervalo | Revisor exigido |
|---|---|---:|---|
| `control_contact` | `ruan.control_chain` ↔ `davi.defense_chain` | 1.000–3.300 ms | BJJ pendente |
| `tap_signal` | `davi.free_hand` ↔ `ruan_or_tatame` | 2.800–3.300 ms | BJJ pendente |
| `release_visible` | `ruan.control_chain` ↔ `davi.defense_chain` | 3.300–4.000 ms | BJJ pendente |

### Seis slots de ramo

| Slot | Ramo | Estado |
|---:|---|---|
| 1 | `tap_release` | fonte presente |
| 2 | `escape_release` | fonte presente |
| 3 | `referee_release` | fonte presente |
| 4 | `________________` | `missing_body_blocked` |
| 5 | `________________` | `missing_body_blocked` |
| 6 | `________________` | `missing_body_blocked` |

**Nota de segurança:** sequência obrigatória `setup → isolation → alignment → control → technical_pressure → tap/escape → release`; sem hiperextensão, crank cervical, dor gráfica ou manutenção de pressão após o sinal.

**TAP SOBERANO:** segurar B com `submission_defense=true` tem prioridade 1; deve interromper `technical_pressure`, produzir `immediate_release`, mostrar soltura e impedir reentrada até `release_recovery`. Pausa, defesa, contextual e evento de animação não podem consumi-lo.

### Checklist humano

| Verificação | PASS / FAIL / NA | Evidência/observação |
|---|---|---|
| Identidade, categoria e estados conferem | ☐ PASS ☐ FAIL ☐ NA | |
| Ruleset foi preenchido por decisão válida | ☐ PASS ☐ FAIL ☐ NA | |
| Early/perfect/late foram aprovados em ms | ☐ PASS ☐ FAIL ☐ NA | |
| Setup/controle antecedem pressão técnica | ☐ PASS ☐ FAIL ☐ NA | |
| TAP interrompe antes de pausa/defesa/contextual | ☐ PASS ☐ FAIL ☐ NA | |
| Soltura imediata e recuperação estão visíveis | ☐ PASS ☐ FAIL ☐ NA | |
| Card/mastery continuam fora do runtime | ☐ PASS ☐ FAIL ☐ NA | |
| Seis ramos estão definidos | ☐ PASS ☐ FAIL ☐ NA | |

**Assinatura:** Quem `________________` · Quando `____/____/______ ____:____` · Decisão `☐ PASS ☐ FAIL ☐ NA`

---

## 11. Fechamento dos seis gates

| Gate | Decisão | Assinante | Data/hora | Evidência anexada |
|---|---|---|---|---|
| 01 BJJ | ☐ PASS ☐ FAIL ☐ NA | `________________` | `________________` | `________________` |
| 02 Animação | ☐ PASS ☐ FAIL ☐ NA | `________________` | `________________` | `________________` |
| 03 Arte | ☐ PASS ☐ FAIL ☐ NA | `________________` | `________________` | `________________` |
| 04 Gameplay | ☐ PASS ☐ FAIL ☐ NA | `________________` | `________________` | `________________` |
| 05 Acessibilidade | ☐ PASS ☐ FAIL ☐ NA | `________________` | `________________` | `________________` |
| 06 Direitos | ☐ PASS ☐ FAIL ☐ NA | `________________` | `________________` | `________________` |

**Decisão geral do Harmony Board:** `☐ PASS ☐ FAIL ☐ NA`
**Quem:** `________________` · **Quando:** `____/____/______ ____:____`
**Condição obrigatória:** assinatura somente por Mestre Satoshi; qualquer outro nome mantém o dossiê `unsigned`.
