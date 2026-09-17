# CRIA DO TATAME — Animation Batch Gold 01

Status: `candidate-only`  
Data: 2026-08-10  
Visual: **2.5D Pixel Art Premium**  
Runtime: Godot 4.3+ / Android-first

## 1. Auditoria resumida do repositório

O `main` continua como fonte integrada e bootável. O manifesto audiovisual principal já define uma linha de produção coerente com:

- 11 personagens listados no lote audiovisual;
- perfis `fighter_core`, `fighter_clinch`, `fighter_ground`, `mentor` e `story_npc`;
- 23 técnicas pareadas com estados de entrada/saída e metas de frames;
- 12 arenas em cinco camadas;
- 18 superfícies de UI;
- pacotes de áudio separados por domínio;
- combate em ~72 px, hub em célula de 64 px, oito direções, filtro `nearest`, outline e rim light controlados;
- contrato de entrega exigindo raw/clean sheet, spritesheet, frames, preview GIF, contact sheet, metadata, import notes e QA.

A arquitetura já não é o principal gargalo. O gargalo atual é transformar referências e candidatos em **frames consistentes, pareados, biomecanicamente corretos e aprovados no Android**.

## 2. Estado das branches/PRs relevantes

### PR #57 — Hub/cartas/biomecânica

É a base visual deste lote. Congela a linguagem 2.5D Pixel Art Premium, a paleta, o protocolo biomecânico e a árvore Pressão / Leitura / Raiz do Mangue.

### PR #56 — Fundação audiovisual do combate

Entrega HUD, grafo de solo, stamina por ação, finalização segura, briefs visuais e ferramentas de pós-processamento. Ainda não contém sprites pareados finais de Ruan × Davi.

### PR #55 — Festival Maré Alta / Pratigi

Entrega uma arena jogável candidata, mas a arte e o áudio finais permanecem pendentes e o teste Android físico ainda é gate.

### PR #54 — Vertical Slice Ouro

Congela Ruan × Davi, Gi/No-Gi, HUD Gás/Controle/Pegada/Fluxo, deck e oito técnicas prioritárias, além dos contratos de pivô, contato, sync map, hitbox e QA.

### PRs #24/#25/#26

Continuam úteis como fontes seletivas: audiovisual/mundo V10, game feel e Open Pixel Forge. Não devem ser absorvidos monoliticamente sem rebase e gates atuais.

## 3. Direção de produção

A cadeia de autoridade fica:

```text
GPT
  direção técnica e artística
    ↓
Open Pixel Forge
  orquestração, seeds, candidatos, atlas e metadata
    ↓
MiniMax-H3
  movimento generativo candidato (I2V/R2V/T2V)
    ↓
QA biomecânico
  autoridade final sobre anatomia, alavanca, base e sincronização
    ↓
Godot
  verdade do runtime, colisões, eventos e Android
```

MiniMax-H3 nunca é autoridade de biomecânica e não promove asset automaticamente.

## 4. Conteúdo do Lote Ouro 01

Foram produzidas dez pranchas de revisão/geração em 1536×1024, cobrindo:

1. core motion de Ruan;
2. clinch/pummeling pareado;
3. quedas (single/double/sprawl);
4. cadeia de transições de solo;
5. fluxo posicional completo;
6. finalizações pareadas;
7. defesas, escapes e scramble;
8. motion de arena/parallax;
9. motion de HUD/cartas/recursos;
10. progressão, graduação e apresentação.

As pranchas são **candidate master sheets**. Elas não são sprites finais.

## 5. Técnicas pareadas prioritárias

O catálogo principal de produção inclui:

- `clinch_entry` — 12 frames alvo;
- `pummeling` — 16;
- `grip_break` — 12;
- `baiana_single_leg` — 36;
- `double_leg` — 36;
- `body_lock_trip` — 28;
- `foot_sweep` — 24;
- `sprawl` — 20;
- `guard_pull` — 20;
- `raspagem_tesoura` — 28;
- `hip_bump_sweep` — 28;
- `knee_cut_pass` — 30;
- `over_under_pass` — 32;
- `leg_drag_pass` — 28;
- `mount_transition` — 22;
- `back_take` — 30;
- `bridge_escape` — 24;
- `elbow_escape` — 24;
- `armbar` — 42;
- `triangle` — 42;
- `kimura` — 38;
- `guillotine` — 36;
- `mata_leao` — 40.

## 6. Regra biomecânica obrigatória

Antes de aprovar uma animação pareada, revisar:

- cabeça e linha cervical;
- coluna e inclinação do tronco;
- escápula/ombro;
- cotovelo e punho;
- quadril e centro de massa;
- joelhos;
- tornozelos e pés;
- pegadas de tecido ou No-Gi;
- base e pontos de apoio;
- direção da força;
- continuidade entre keyframes;
- ausência de interpenetração de membros;
- preparação, contato, estabilização, defesa e release/tap.

Técnica bonita mas biomecanicamente impossível = **REPROVADA**.

## 7. Conversão das pranchas para runtime

Cada sequência aprovada deve gerar:

```text
assets/characters/<fighter>/animations/<animation>/
├── raw_sheet.png
├── clean_sheet.png
├── spritesheet.png
├── frames/
├── preview.gif
├── contact_sheet.png
├── metadata.json
├── import_notes.md
└── qa_report.md
```

Para técnica pareada:

```text
<technique>/
├── attacker/
├── defender/
├── sync_map.json
├── hitbox.json
└── ...
```

## 8. Critérios de aprovação

### Canon Gate

- Ruan é Ruan “Macacão” Silva;
- visual segue 2.5D Pixel Art Premium;
- sem marca real, uniforme institucional real ou deriva visual.

### Biomechanics Gate

- poses e contatos plausíveis;
- técnica reconhecível sem depender do texto;
- atacante e defensor sincronizados.

### Visual Gate

- silhueta legível em tela pequena;
- pixel grid coerente;
- paleta e contraste consistentes;
- sem blur/antialiasing borrado.

### Game Gate

- pivô e chão estáveis;
- frame count/tempo compatível com o evento;
- sync map, hitbox/hurtbox/grabbox coerentes;
- sem teleporte entre posições.

### Device Gate

- Android físico;
- safe area e leitura mobile;
- desempenho sustentado ≥45 FPS para o vertical slice;
- temperatura/memória/bateria observadas.

## 9. Próxima etapa técnica

1. selecionar a melhor prancha de referência para Ruan e Davi;
2. extrair somente os keyframes do vertical slice;
3. normalizar anatomia e escala;
4. produzir atacante/defensor separados;
5. gerar `sync_map.json`;
6. montar spritesheets nearest;
7. integrar no `FighterPlaceholder`/consumer atual sem criar runtime paralelo;
8. executar parser/import, smoke e teste Android;
9. somente depois promover de `candidate` para `shipping`.
