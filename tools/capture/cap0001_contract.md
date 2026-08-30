# CAP_0001 — contrato de captura pareada

**Status:** `BLOCKED`

**Janela proposta:** 30/08/2026, 08:00–11:00 (`America/Bahia`)
**Promoção:** proibida; captura produz evidência, não animação aprovada.

## Registro da janela — 30/08/2026

**Gate avaliado em:** 30/08/2026, 08:10:38 (`America/Bahia`)
**Resultado:** `BLOCKED`
**Sessão executada:** não

| Pré-condição obrigatória | Estado | Evidência disponível no gate |
|---|---|---|
| dois performers adultos | `NOT_CONFIRMED` | nenhum roster ou ateste de presença |
| responsável de segurança | `NOT_CONFIRMED` | nenhuma designação e aceite registrados |
| tatame íntegro | `NOT_CONFIRMED` | nenhuma inspeção pré-sessão registrada |
| celular A em 60 fps | `NOT_CONFIRMED` | nenhum teste de gravação registrado |
| celular B em 60 fps | `NOT_CONFIRMED` | nenhum teste de gravação registrado |
| dois consentimentos assinados | `NOT_CONFIRMED` | nenhum termo assinado e nenhum SHA-256 registrados |

Aplicado o regime fail-closed: ausência de confirmação não foi convertida em ausência física, mas impede a captura. Nenhuma tomada foi iniciada, nenhum vídeo bruto foi ingerido, nenhum derivado foi produzido e nenhuma promoção foi realizada. O registro legível por máquina está em `tools/capture/cap0001_ledger.json`.

## Equipe e segurança

- dois performers adultos com experiência suficiente para executar o blocking em baixa intensidade;
- um responsável de segurança com autoridade para interromper qualquer tomada;
- dois celulares independentes em 60 fps, tripés fixos, relógio sincronizado e tatame íntegro;
- sem strikes, impacto de cabeça, crank cervical, projeção de alta amplitude ou resistência competitiva;
- TAP verbal, manual ou físico interrompe a ação e exige soltura imediata;
- aquecimento, rehearsal lento e intervalo entre ramos são obrigatórios.

Se performers, segurança, tatame, celulares ou consentimento não estiverem confirmados, a sessão vira `BLOCKED` e não é improvisada.

## Consentimento e proveniência

Cada performer assina consentimento antes da gravação. O ledger registra caminho do termo, versão, data/hora, escopo de uso e SHA-256; nenhum arquivo bruto é processado antes dessa verificação. Identidade civil não entra em filenames ou no produto.

## Matriz de captura

As seis técnicas-ouro são `grip_de_ferro`, `baiana`, `sprawl`, `corte_joelho`, `cem_quilos` e `encerramento_tecnico`. Cada uma cobre entrada, execução segura, defesa, sucesso, falha/recuperação e, quando houver finalização, TAP/soltura. Os ramos obedecem ao contrato Harmony 1:1; nenhuma categoria nova é inventada em campo.

## Saídas

- vídeos brutos imutáveis das duas vistas, com SHA-256;
- keypoints 2D derivados, confiança e articulações ausentes;
- MOT com IDs persistentes dos dois performers;
- relatório de plausibilidade por fase e contato;
- ledger de tomada, técnica, ramo, início/fim em ms, câmera, consentimento e incidentes;
- sidecar de licença/consentimento para cada derivado.

Keypoints, MOT e plausibilidade são auxiliares. Recriação por IA é derivado visual, nunca evidência. Revisores BJJ e Animação validam contato e fase; nenhuma saída integra runtime neste lote.

## Critério de encerramento

A sessão só conclui quando os seis IDs possuem os ramos contratados ou uma lacuna `BLOCKED` explicitamente registrada. Agendamento no repositório não confirma presença, local nem autorização externa.
