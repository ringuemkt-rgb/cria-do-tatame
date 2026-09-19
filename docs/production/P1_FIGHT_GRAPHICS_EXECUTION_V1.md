# P1 Fight Graphics Execution V1

**Status:** ACTIVE  
**Issue:** #143  
**Runtime:** Godot only  
**Default:** `shipping=false`

## Objetivo

Converter os 32 COMMANDS já existentes do vertical slice Ruan × Davi em uma fila operacional com dependências, requirement IDs determinísticos, work orders iniciais, gates de promoção e handoff explícito para o coverage ledger e o Godot.

Este documento não cria nova autoridade de arte. Ele coordena as autoridades já existentes:

`P1 queue -> Production OS v03 -> Visual Foundry -> Sprite Forge -> human/rights gates -> Godot -> runtime evidence -> coverage/shipping`.

## Estado inicial

A fila canônica continua contendo:

- 10 comandos de personagem;
- 7 técnicas BJJ pareadas;
- 10 camadas de arena;
- 5 comandos de UI;
- total: **32**.

O painel machine-readable é:

`production/p1/p1_fight_graphics_execution_v1.json`

Ele cobre todos os 32 IDs. Nenhum item é `shipping=true`.

## Foco atual

### 1. Ruan identity master — `P1-CHAR-001`

Requirement ID derivado pelo Production OS:

`p1_char:ruan_macacao:char_turnaround`

Work order:

`production/p1/work_orders/ruan_identity_master_v1.json`

O candidato pode ser produzido, mas a promoção continua bloqueada até:

- referência binária ingerida;
- SHA-256 registrada;
- aprovação humana de identidade;
- QA técnico;
- rights clearance;
- integração Godot.

### 2. Davi identity master — `P1-CHAR-006`

Requirement ID:

`p1_char:davi_relampago:char_turnaround`

Work order:

`production/p1/work_orders/davi_identity_master_v1.json`

O Davi ainda exige seleção humana de referência. O GI azul permanece apenas direção candidata até aprovação explícita.

### 3. Baiana pareada — `P1-TECH-001`

Requirement ID:

`p1_paired:t001:paired_technique`

Work order:

`production/p1/work_orders/t001_baiana_paired_v1.json`

A técnica continua bloqueada até os dois identity masters e as bases de chão estarem revisados. O pacote usa as seis fases canônicas:

`anticipation -> entry -> establish -> stabilize -> response -> recovery`

Contato e blocking permanecem `PENDING_EXPERT_BLOCKING`; nenhum detalhe biomecânico oculto é inventado.

## Ordem operacional

1. Ruan identity master.
2. Davi identity master.
3. poses/core locomotion de ambos.
4. Terreiro + Arena do Dique em camadas.
5. bases de clinch/solo.
6. sete técnicas pareadas.
7. UI de luta.
8. Godot integration.
9. captura visual do runtime.
10. Android físico.

Essa ordem preserva o `p1_visual_build_contract_v2.json`.

## Asset links

`production/coverage/asset_links_v1.json` continua sendo o ledger ativo.

Este lote **não adiciona links vazios** ao ledger. O painel contém apenas templates de futura promoção. Um template só pode virar link ativo quando:

- o `requirement_id` existir no manifesto v03 derivado;
- existir ao menos um binário real registrado em `assets/manifest_v2.json`;
- `asset_paths` apontar exatamente para esses binários;
- QA, aprovação humana e rights tiverem evidência;
- integração Godot tiver evidência.

Assim evitamos transformar planejamento em coverage falso.

## Handoff Godot

Um pacote visual pode sair de `production/candidates/` para caminhos de runtime apenas depois dos gates técnicos/humanos.

Para personagens:

- frame final `128x128 RGBA`;
- pivot `[64,96]`;
- nearest;
- escala inteira;
- identity lock;
- alpha limpo.

Para técnica pareada:

- attacker e defender separados;
- pivô compartilhado;
- `sync_map.json`;
- `contact_map.json`;
- metadata com `technique_id`, entry/exit state e fases;
- preview/contact sheet;
- binding ao consumidor de animação sem alterar autoridade do combate.

## Validação

```bash
python tools/art/validate_p1_fight_graphics_execution_v1.py
python -m unittest tests.test_p1_fight_graphics_execution_v1
```

O workflow dedicado é:

`.github/workflows/p1-fight-graphics-v1.yml`

O gate falha se:

- a fila deixar de ter os 32 comandos esperados;
- algum COMMAND ficar sem estado no painel;
- requirement IDs dos três primeiros work orders divergirem do Production OS;
- qualquer template pré-ligar binários inexistentes;
- qualquer work order declarar `shipping=true`;
- as seis fases ou entry/exit do `t001` divergirem.

## Próximo passo de produção

O próximo asset real a fabricar é o **turnaround candidato de Ruan**. Depois vem Davi. A Baiana só é liberada depois desses identity locks e das bases de solo.

A meta deste sistema é simples: cada geração deve responder quatro perguntas sem ambiguidade:

1. qual COMMAND estou satisfazendo?
2. qual `requirement_id` ele representa?
3. qual gate falta?
4. qual evidência permite entrar no Godot e no coverage ledger?

Se alguma dessas respostas estiver ausente, o asset continua candidato.
