# Combat Harmony Spec v1 — slice ouro

Status: `specified_not_integrated`
Lote: `M30 harmony-slice-v1`
Base: `lead/calibracao-v1` / `cfbc572`
Autoridade humana: Mestre Satoshi

## 1. Propósito e limites

Combat Harmony é o contrato que mantém evidência biomecânica, derivação visual e resposta do jogo na mesma identidade técnica. Ele não cria um segundo simulador, não decide o resultado de uma luta e não promove arte automaticamente.

Dois princípios são inegociáveis:

> **captura = evidência, IA = derivado**

> **runtime decide, animação apresenta**

`CombatManager`, seus resolvedores e os catálogos ativos continuam sendo a autoridade de posição, elegibilidade, custo, janela, resultado e save. Vídeo, keypoints, contatos inferidos, render neural, sprites e VFX apenas documentam ou apresentam essa decisão.

O slice cobre exatamente seis IDs existentes em `data/techniques.json`, na ordem do tutorial ativo: `grip_de_ferro`, `baiana`, `sprawl`, `corte_joelho`, `cem_quilos` e `encerramento_tecnico`. A ligação card → runtime → sync map → HUD → mastery é 1:1 por `technique_id` (D238).

## 2. Registro de decisão aplicado

| Decisão | Estado nesta base | Aplicação no Harmony |
|---|---|---|
| D229 | conhecida pela ordem M-MASTER | tempo canônico em ms; buffer 100 ms; treino +67 ms; mestre −33 ms; conversão para Hz somente no runtime |
| D230 | conhecida pela ordem M-MASTER | A/B/X/Y contextuais; RB quinta; RT defesa; LB especial; segurar B vira TAP somente em `submission_defense=true` e a UI troca o contexto |
| D231 | conhecida pela ordem M-MASTER | TAP > pausa/menu > defesa > contextual; nenhum evento prioritário pode ser engolido |
| D232 | conhecida pela ordem M-MASTER | escala de 50 técnicas, classificador e AQA ficam em `docs/future/` |
| D233 | conhecida pela ordem M-MASTER | qualquer ampliação responde primeiro se é necessária para provar o slice |
| D234–D237 | corpo ausente no commit-base | `missing_body_blocked`; nenhum valor dependente dessas decisões pode ser integrado |
| D238 | conhecida pela ordem M30 | um único `technique_id` atravessa card, runtime, sync, HUD e mastery |
| D239 | corpo ausente no commit-base | `missing_body_blocked`; nenhuma suposição substitui a decisão |

Registrar esses bloqueios aqui não cria cânone: preserva a dúvida conforme as Cláusulas 23–25 e impede que uma lacuna pareça decisão.

## 3. Camada 1 — evidência de movimento

### 3.1 Entrada autorizada

- captura consentida com dois performers, técnica e segurança definidas antes da tomada;
- dois celulares a 60 fps quando disponível, sincronizados por clap visual;
- vídeo original imutável, hash SHA-256, resolução, fps, data, responsáveis e termo de consentimento;
- sem strikes, impacto de cabeça ou continuação depois do tap;
- keypoints 2D e MOT mantêm o hash da captura que lhes deu origem.

`tools/harmony/pose2d.py` normaliza keypoints em coordenadas 0–1 sem alterar o vídeo-fonte. A confiança permanece visível; ponto ausente não é interpolado silenciosamente. A saída é evidência processada, nunca animação aprovada.

### 3.2 Contatos como rascunho

`tools/harmony/contact_draft.py` mede proximidade entre pares de articulações declarados no contrato. O resultado sempre carrega `draft_only=true`. Proximidade 2D não prova pressão, pegada, legalidade nem contato em profundidade; um revisor de BJJ precisa confirmar cada intervalo.

## 4. Camada 2 — derivação e fidelidade

### 4.1 Fases pareadas

`tools/harmony/phase_check.py` exige:

- seis técnicas e cinco identidades 1:1 por técnica;
- tempo canônico em milissegundos;
- origem compartilhada, dois atores e ramos de sucesso, defesa e recuperação;
- fases contínuas e ordenadas;
- contatos com início, fim, participantes e revisor humano pendente;
- finalização com TAP soberano e soltura explícita;
- ausência de SMPL/SCAIL no caminho executável.

O preview pode usar 12 fps e 48 quadros, mas quadro é apenas amostragem de apresentação. O contrato converte seus marcadores para ms; nenhuma regra de jogo depende do fps do sprite.

### 4.2 Render derivado

`tools/harmony/render2pixel` monta ou envia um workflow ComfyUI com seed fixo. O padrão é `--dry-run`; envio exige servidor local explícito, checkpoint identificado, licença resolvida e sidecar. A saída recebe `state=ai_derived_candidate`, `shipping=false` e gates humanos pendentes.

O render nunca recebe permissão para:

- alterar ID, estado, timing ou resultado da técnica;
- completar articulação oculta e depois tratá-la como evidência;
- usar atleta, academia, marca ou organização real como identidade do produto;
- promover arquivo para `assets/` de runtime;
- chamar SMPL ou SCAIL. Ambos ficam em quarentena documental, sem import, download ou execução.

### 4.3 Diferença de fidelidade

`tools/harmony/fidelity_diff.py` compara keypoints derivados com a evidência normalizada. Limites são argumentos obrigatórios do lote, não constantes canônicas. O relatório mede RMSE, P95, pontos ausentes e preservação de identidade; um PASS automático significa somente “dentro do limite medido”.

## 5. Camada 3 — apresentação dirigida pelo runtime

1. O runtime avalia estado, deck, custo e ação elegível.
2. O resolvedor registra a técnica e o ramo determinístico.
3. O sync map escolhe a apresentação com o mesmo `technique_id` e ramo.
4. A animação toca na origem compartilhada; contatos são marcadores visuais, não hitboxes soberanas.
5. O HUD explica elegibilidade, defesa e porquê do resultado.
6. Em `submission_defense=true`, segurar B é rotulado como TAP e passa à prioridade máxima.
7. TAP interrompe pressão, agenda soltura e bloqueia reentrada até a recuperação segura.

Se um clip faltar, o runtime usa `fallback_animation` e preserva o resultado. Se o runtime não conhece o ID, o clip é recusado. **Nenhum input morto:** toda entrada gera ação válida, motivo de indisponibilidade ou feedback de contexto.

## 6. QA闭环 — ciclo fechado de qualidade

O ciclo só fecha quando cada falha volta à sua fonte correta:

1. **Ingestão:** conferir consentimento, hashes, fps e participantes.
2. **Pose:** normalizar keypoints; falha de detecção volta à captura ou marca ponto ausente.
3. **Contato:** gerar rascunho; falha de profundidade vai ao revisor, nunca é “corrigida” como fato por IA.
4. **Fase:** validar continuidade, ms, origem, ramos e TAP.
5. **Derivação:** renderizar candidato com seed, workflow e licença no sidecar.
6. **Fidelidade:** comparar derivado versus evidência com limites declarados pelo lote.
7. **Revisão:** gates 01 BJJ, 02 Animação e 03 Arte, assinados apenas pelo Mestre Satoshi.
8. **Destino:** aprovado permanece candidato até integração separada; reprovado volta à captura/cleanup ou vai a mortos com log.

Estados permitidos neste lote: `evidence`, `draft`, `ai_derived_candidate`, `clean_candidate`, `rejected`. Estados `human_approved`, `integrated` e `device_validated` são proibidos aqui.

## 7. Uso das ferramentas

```bash
python tools/harmony/pose2d.py --self-test
python tools/harmony/contact_draft.py --self-test
python tools/harmony/phase_check.py data/combat/harmony_contract_v1.json data/ux/combat_hub_v1.json
python tools/harmony/fidelity_diff.py --self-test
tools/harmony/render2pixel --self-test
tools/harmony/render2pixel --technique baiana --input evidence.json --output-dir /tmp/harmony-request
```

O último comando apenas materializa request e sidecar. Para enviar a um ComfyUI local, use `--submit --server http://127.0.0.1:8188` depois de resolver checkpoint e licença no workflow.

## 8. Aceite do M30

- os dois JSONs carregam sem erro;
- `phase_check.py` passa nas seis técnicas e no hub;
- quatro utilitários e `render2pixel` passam nos self-tests;
- nenhum caminho executável referencia SMPL/SCAIL;
- D230/D231 aparecem tanto no contrato quanto no hub;
- todo render traz seed e sidecar; nenhum é promovido;
- `python tools/validate_data.py` e `npm run quality` passam;
- CI da branch fica verde antes de qualquer próximo lote.
