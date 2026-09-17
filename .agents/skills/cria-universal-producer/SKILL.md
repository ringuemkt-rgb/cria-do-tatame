---
name: cria-universal-producer
description: "Orquestra qualquer agente de IA no Cria do Tatame por capacidades reais, autoridades do repositório e workflows verticais. Use em tarefas multidomínio, implementação de features completas, produção de assets até Godot, mapas/mundo, combate, QA e release. Não cria runtime novo, não assume ferramentas ausentes e não autoriza shipping."
---

# CRIA Universal Producer v1

## Missão

Transformar a capacidade disponível no agente atual em trabalho **real, pequeno, testável, reversível e integrado** no repositório soberano `ringuemkt-rgb/cria-do-tatame`.

Esta skill é uma camada de **roteamento**, não um novo motor. `AGENTS.md`, contratos executáveis, Godot, Production OS e skills especialistas continuam acima dela.

## Bootstrap obrigatório

1. Leia `AGENTS.md`.
2. Leia `docs/REPOSITORY_GOVERNANCE.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md` e `docs/INDEX.md`.
3. Leia:
   - `data/production/canon_contract_v4_1.json`;
   - `data/production/supreme_build_contract_v01.json`;
   - `data/production/agent_production_contract_v1.json`.
4. Se houver shell, rode:

```bash
python tools/agents/detect_capabilities.py --write reports/agent_bootstrap/capabilities.json
```

5. Se a plataforma oferecer capacidades nativas que o detector local não enxerga, declare **somente as realmente presentes**:

```bash
python tools/agents/detect_capabilities.py \
  --declare github_remote,web_research,vision,image_generate,image_edit \
  --write reports/agent_bootstrap/capabilities.json
```

6. Escolha o maior tier seguro do contrato. Não finja um tier superior.
7. Procure implementação, issue ou PR equivalente antes de criar sistema novo.

## Princípio principal

```text
CAPACIDADES REAIS
      ↓
AUTORIDADE DO DOMÍNIO
      ↓
MENOR WORKFLOW VERTICAL
      ↓
IMPLEMENTAÇÃO / ASSET CANDIDATO
      ↓
VALIDAÇÃO DISPONÍVEL
      ↓
INTEGRAÇÃO REAL
      ↓
EVIDÊNCIA
      ↓
GATES HUMANOS / RIGHTS / DEVICE
      ↓
SHIPPING SOMENTE PELA AUTORIDADE EXISTENTE
```

## Tiers

### T0 — Observer

Pode ler, auditar, comparar e especificar. Não pode dizer que alterou arquivos, rodou Godot, integrou asset ou testou aparelho.

### T1 — Author

Pode editar código/dados/docs/testes e trabalhar por branch/PR. Se não possui Godot, entrega contratos e código com validação estática honesta; runtime permanece pendente.

### T2 — Asset Author

Além de T1, tem visão + IO binário + algum gerador/editor de imagem. Produz **candidatos**, nunca shipping automático. Deve carregar Art Direction e Sprite Forge quando aplicável.

### T3 — Runtime Integrator

Tem Godot CLI ou evidência equivalente de CI com Godot. Pode integrar cenas/resources, rodar headless e capturar runtime. Não substitui teste físico.

### T4 — Motion Producer

Tem vídeo/motion tooling e fonte rights-cleared. Para BJJ deve carregar Combat Intelligence + Grappling Motion Lab; observação oclusa pode permanecer `UNKNOWN`.

### T5 — Release Operator

Tem build Godot, ADB, aparelho Android real e gate humano. É o único tier capaz de produzir evidência física de Android, ainda sujeito aos release gates do projeto.

## Roteamento por domínio

### Multidomínio / feature vertical

Fique nesta skill como producer, mas delegue autoridade:

- cânone/world/narrativa → contratos de cânone;
- combate/BJJ → `cria-combat-intelligence`;
- vídeo/mocap/pose → `cria-grappling-motion-lab`;
- visual → `cria-art-direction`;
- sprites/animação → `cria-sprite-forge`;
- Godot/runtime → `project.godot`, `src/`, `scenes/`, testes;
- release → `supreme_build_contract` + release ledger.

Uma função pode ser exercida pelo **mesmo agente**. Não crie dezenas de agentes só porque existem papéis no organograma.

### Arte / personagem / sprite

Carregue:

1. `cria-art-direction`;
2. `cria-sprite-forge`;
3. Combat Intelligence se for técnica BJJ;
4. Motion Lab se a técnica for derivada de captura/vídeo.

Contrato mínimo de lutador:

```text
identity master aprovado
→ action grid por família
→ normalização comum
→ 128x128 RGBA
→ pivot 64,96
→ nearest / integer scaling
→ scale profile
→ preview + métricas
→ provenance / rights
→ Godot integration
```

Regras herdadas do upstream MIT `0x0funky/agent-sprite-forge` já adaptadas pelo projeto:

- ação por sheet antes do atlas final;
- evitar geração crua 1×N para corpo;
- master/anchor de personagem para escala;
- pés como referência para ações grounded;
- body e FX destacados separados;
- profile de escala compartilhado entre ações;
- atlas final montado deterministicamente.

### BJJ pareado

Nunca trate como dois GIFs independentes.

```text
reducer / graph
→ motion spec
→ attacker + defender
→ shared origin
→ 6 fases
→ sync_map
→ contact_map
→ paired render/sprite streams
→ biomechanical QA
→ Godot
→ runtime evidence
```

A IA pode sugerir pose/arte. Legalidade, score e estado pertencem ao reducer e dados canônicos.

### Visual Foundry 3D → 2D

Use quando recorrência e sincronização justificarem um master 3D:

```text
identity lock
→ 3D master
→ retopo/UV/material
→ rig
→ paired animation / pose
→ ortho RGBA render
→ pixel pass
→ Sprite Forge
→ Godot
```

- Blender headless é a rota preferida.
- Blender MCP é ponte opcional de authoring.
- TripoSG/TripoSR/TRELLIS.2/UniRig/Instant Meshes/QuadriFlow continuam candidatos sujeitos ao perfil Visual Foundry e licença.
- 3D é intermediário de fabricação; não altera o runtime 2D por conta própria.

### Geração visual

Ordem de preferência:

1. geração/edição nativa disponível no agente;
2. perfil Qwen Pixel Art auditado;
3. workflow externo ComfyUI quando instalado e legalmente adequado;
4. se nada estiver disponível, produza **spec/COMMAND** e pare no gate de candidato.

Não use script procedural para fingir arte final quando o pedido requer arte desenhada.

### Godot

Preferência:

1. Godot CLI local;
2. ponte MCP opcional auditada, quando conectada;
3. edição de arquivos + CI como fallback.

MCP é interface. `CombatManager`, reducers, scenes e dados continuam autoridade.

Nunca crie segundo `project.godot`.

### Mapas e mundo

A arte pode ser produzida por Visual Foundry, geração 2D, Blender ou DCC manual, mas runtime permanece nos managers/dados existentes.

Não coloque LLM movendo NPC por frame. Mundo vivo = estado determinístico + agendas + apresentação.

### Motion Lab

Prioridade para material comercial:

1. captura CRIA própria com consentimento/release;
2. FFmpeg para normalização;
3. Pose2Sim/MMPose/RTMPose/SAM2 para candidatos de pose/máscara;
4. CVAT/Label Studio para revisão;
5. Blender/OpenSim para inspeção/refino;
6. DVC/FiftyOne para lineage/QA quando necessário.

Checkpoints/datasets têm licença própria; licença do código não resolve direitos do modelo ou do vídeo.

### Áudio

Use `AudioManager` existente. Ferramentas de authoring são externas; áudio gerado/gravado exige provenance e rights. Não crie segundo sistema de áudio.

## Tool slots e fallback

Consulte `agent_production_contract_v1.json`; nunca programe lógica dependente de nome de fornecedor quando uma capacidade é suficiente.

Exemplos:

- `image_generate` pode ser fornecido pelo agente atual, Qwen ou pipeline externo;
- `godot_cli` pode ser local enquanto `godot_mcp` é apenas conveniência;
- `blender_cli` é suficiente; `blender_mcp` não é requisito;
- `pixel_editor` pode ser Pixelorama/Krita, mas Sprite Forge continua o gate técnico;
- falta de `image_generate` não bloqueia specs, manifests e integration scaffolds.

## Workflows canônicos

Escolha o menor arquivo aplicável em `.criaforge/workflows/`:

- `technique_to_gameplay.yaml`;
- `visual_asset_to_runtime.yaml`;
- `paired_bjj_to_runtime.yaml`;
- `map_world_to_runtime.yaml`;
- `release_vertical_slice.yaml`.

Uma feature só conta como concluída quando sua definição de pronto vertical foi satisfeita. Arquivo isolado, prompt, imagem bruta, JSON sem consumidor ou CI parcial não são feature pronta.

## Quality

Sempre que possível:

```bash
npm run validate:agent-production-os
npm run test:agent-production-os
npm run quality
```

Godot quando aplicável:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/runtime_smoke.gd
```

Android release claim exige build instalado e executado em aparelho físico.

## Saída obrigatória

Todo agente termina com:

1. **Entregue** — o que realmente funciona;
2. **Arquivos** — criados/modificados/removidos;
3. **Integração** — consumidor real;
4. **Validação** — comandos realmente executados e resultados;
5. **GitHub** — branch/commit/issue/PR quando disponíveis;
6. **Riscos** — incerteza, licença, biomecânica, performance;
7. **Capacidades ausentes** — gates que não puderam ser executados;
8. **Próximo lote** — menor passo vertical de maior valor.

## Stop conditions

Pare sem inventar sucesso se houver:

- conflito de autoridade/cânone;
- licença ou provenance incertos para reutilização;
- necessidade de capacidade inexistente sem fallback seguro;
- biomecânica BJJ não observável ou insegura;
- tentativa de promover candidato sem gate humano/rights;
- teste físico exigido sem dispositivo;
- ação irreversível sem autorização.
