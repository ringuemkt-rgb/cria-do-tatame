# GAME_BUILD_PROTOCOL — Protocolo Mestre de Construção do *Cria do Tatame*

**Versão:** 1.0  
**Data:** 2026-07-24  
**Status:** CANÔNICO / VINCULANTE  
**Escopo:** governa **como** o jogo é construído: processo, engenharia, repositório, criatividade, QA, release e gestão.

> Modelos e agentes não possuem memória confiável entre sessões. Este protocolo vive no Git como `protocol-as-code`. Todo assistente que trabalhar neste repositório deve carregá-lo antes de propor ou executar mudanças.

---

## 0. Precedência e governança

A ordem completa está em `docs/DOC_PRECEDENCE.md`. Resumo:

1. `docs/CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md` e seu contrato executável;
2. este `GAME_BUILD_PROTOCOL.md` para processo e gestão;
3. GDD-CDT v4.x, GDD-SYSTEMS v4.x e decisões canônicas atuais;
4. contratos de produção visual e reconciliação técnica vigentes;
5. bíblias numeradas, dados canônicos e ADRs atuais;
6. `AGENTS.md`, README e resumos de entrada;
7. documentos históricos, somente como referência.

Em conflito, o trabalho para, o conflito é registrado e a decisão canônica mais recente e explicitamente aprovada prevalece.

---

## 1. Papéis

| Papel | Responsabilidade |
|---|---|
| **Produtor / Dono** | Decide cânone, aprova gates e autoriza ações irreversíveis. |
| **Diretor-Gestor** | Verifica o repositório, diagnostica o gargalo, decide a próxima jogada, instrui o executor e fecha gates com evidência. |
| **Executor-Committer** | Implementa código, dados, cenas, assets, testes e documentação; commita conforme este protocolo. |

Um mesmo agente pode ocupar mais de um papel, mas não pode relaxar as regras correspondentes.

---

## 2. Handshake de abertura

Toda iteração de trabalho começa com um handshake curto contendo:

- estado da `main`: SHA curto e mensagem do último commit;
- PRs abertos e topologia de empilhamento;
- status de CI do commit relevante: verde, vermelho, em fila ou desconhecido;
- delta desde o handshake anterior;
- fonte e horário da verificação.

### Modo degradado

Quando a verificação ao vivo falhar, truncar ou não puder ser feita, declarar explicitamente:

> Verificação parcial; usando snapshot de `<ISO-8601>`; sem nova chamada porque `<motivo>`.

Nunca afirmar que algo está verde, mergeado, pronto ou publicado sem evidência. Para fechar a leitura localmente:

```bash
git fetch --all --prune
git log --oneline -5 origin/main
gh pr list --state open --json number,title,isDraft,headRefName,baseRefName,statusCheckRollup
```

Antes de instruir alteração em arquivo ou sistema específico, abrir esse arquivo, a árvore relevante e os contratos consumidores.

---

## 3. Domínios ativos simultaneamente

### 3.1 Engenharia de jogos

- Godot 4.3+ como alvo; manter compatibilidade 4.2.2 enquanto o gate legado existir.
- Combate de BJJ por oito posições simétricas + lado relativo, vinte cartas, seis rulesets e cinco comandos contextuais.
- Posição, recursos, timing, defesa, tap e escape são soberanos; cartas especializam ações, não substituem o grappling.
- World Director e Faction Director v3 separados por responsabilidade.
- Save atômico, versionado, com migração e roundtrip.
- Gameplay crítico determinístico e offline.
- Android: 60 FPS alvo, 30 FPS mínimo funcional, gate de produção ≥45 FPS sustentados em aparelho físico; orçamento de 16,67 ms por frame; memória de combate ≤512 MB; atlas ≤4096 px; até 24 vozes simultâneas.
- Safe area, alvos touch ≥48 dp, contraste, remapeamento e opção de reduzir flash.

### 3.2 Engenharia de repositório

- Repositório único: `ringuemkt-rgb/cria-do-tatame`.
- Stacked PRs, Conventional Commits e CI como porteiro.
- Git LFS para binários grandes quando aplicável.
- Dependências pinadas; APK fora da raiz, distribuído como artifact/release com SHA-256.
- Nenhum asset sem licença ou origem registrada.
- Branches mortas ou noop devem ser removidas após verificação e merge.
- Node e Python servem somente para validação, automação e pipeline; Godot é o único runtime do jogo.

### 3.3 Criativo

- Pixel art 16-bit/2.5D, adulta e regional, sem fotografia ou 3D realista como arte final.
- Três facções: LEM, NTM e ALE; núcleos são tags subordinadas.
- Ruan por eras, sem duplicar faixa ou estado de carreira em movesheets.
- Cinco atos, cinco finais e TUPA-200 como crítica artística fictícia.
- HUD funcional preserva leitura de posição, recursos, moral e comandos.
- Som organizado por ato, arena, posição e intensidade.

### 3.4 Regra anti-alucinação

Quando API, schema, arquivo, licença, biomecânica ou estado do repositório forem incertos, verificar fonte primária ou abrir o arquivo antes de instruir commit. Se a verificação não for possível, declarar a lacuna e não inventar sucesso.

---

## 4. Loop de gestão

```text
1. VERIFICAR    Handshake ao vivo e delta.
2. DIAGNOSTICAR Identificar um gargalo com evidência.
3. DECIDIR      Escolher uma jogada de maior alavancagem.
4. INSTRUIR     Definir arquivos, patch, testes, commit e rollback.
5. COMMITAR     Executor aplica e registra um lote focado.
6. REVERIFICAR  Confirmar que entrou e não causou regressão.
7. FECHAR GATE  Atualizar manifestos e status somente com evidência.
```

A regra do funil é uma próxima jogada principal por iteração, não uma lista difusa de tarefas.

---

## 5. Regras de engenharia de repositório

1. Uma feature corresponde a um PR vertical com código, dados, cena, teste e documentação do mesmo tema.
2. Um personagem completo corresponde a um PR vertical próprio; prancha, frames, atlas, integração e QA ficam no mesmo fluxo.
3. Evitar commit-bomba e mistura de produtos externos.
4. Usar commits como `feat(combat):`, `fix(save):`, `art(ruan):`, `test(gut):`, `docs(protocol):` e `chore(struct):`.
5. Nada mergeia com CI vermelha, lint canônico vermelho ou conflito documental aberto.
6. Respeitar a topologia dos PRs; filho não mergeia sem a base validada.
7. Não sobrescrever contratos verdes sem reconciliação explícita e teste de migração.
8. Assets grandes usam LFS quando apropriado; APK, ZIP e builds não são versionados na raiz.
9. Toda exclusão exige inventário, backup e relatório de migração.
10. Depois do merge e verificação, remover branches mortas e atualizar a topologia.

---

## 6. Regras de engenharia do jogo

- Fluxo mínimo preservado: `MainMenu → Terreiro → Combate → Resultado → Save → avanço de semana → Terreiro`.
- Sem gacha, loot box ou poder comprado com Molho.
- Sem finalização automática: submissão exige preparação, encaixe, resposta, tap ou escape.
- CPS/prancha densa não é sprite final.
- Sprite final é produzido em resolução nativa, limpo manualmente, normalizado, com pivô, atlas, manifest, preview, cena de teste e QA.
- Animação pareada exige `sync_map` e revisão biomecânica.
- Todo sistema persistível declara versão e migração.
- Toda mudança de autoload exige auditoria de boot.
- Toda mudança de combate exige smoke de posição, lado, recursos, janela defensiva, submissão e encerramento.

---

## 7. Distinções e cânone inviolável

### 7.1 Três distinções

1. **Prancha densa ≠ sprite de jogo.**
2. **Design aprovado ≠ runtime executável.**
3. **Um personagem completo = um PR vertical**, não um commit-bomba.

### 7.2 Cânone

- Facções: LEM, NTM e ALE; o lint bloqueia uma quarta facção.
- Ruan: `campaign_start` aos 19 e `promo_mature` aos 28; faixa vem do equipment/career stage.
- Tinker Bell permanece `design_aprovado` como lutador e `story_npc` na campanha até migração completa.
- Mestre Pedrinho permanece `planned` até possuir ID, passport, perfil e agenda.
- Oni: lore “Oni da Lapa”; display “ONI DO SUL”.
- Moral é estado bipolar, não recurso consumível.
- Slots por arquétipo: PRESSÃO=6; TÁTICO=5; terceiro arquétipo permanece em aberto até decisão canônica.
- Tom 14+ sem gore; oponente em técnica sempre adulto; nenhuma difamação de pessoa ou povo real.
- Identidade: “Ser forte é ser gentil”, “De cria pra cria” e “Jiu-jitsu é tudo”.
- IDs legados proibidos não entram em UI, campanha, save novo ou marketing final.

### 7.3 Três camadas de cor

- **Marca:** `#F2C230 #F2F2F2 #0A0A0A #D92323 #1E5BFF`.
- **Arte pixel:** `#0A0A0A #1A1A1A #B8860B #F2C230 #F2F2F2 #D92323 #1E3A5F #2D5016 #4B0082`.
- **HUD funcional:** VIDA verde; GÁS azul; FOCO dourado; GRIP magenta; CONTROLE ciano; buff verde; debuff vermelho; moral baixa `#4B0082`.

O lint aplica a allow-list correspondente ao tipo de superfície; não deve reprovar HUD com regra de sprite nem marca com regra de HUD.

### 7.4 Texto e tipografia

- Sprites e frames: sem texto embutido.
- Logo: lettering permitido e travado por brand book.
- UI: texto sempre em `Label`, nunca rasterizado em imagem.
- Títulos: Bebas Neue Bold; textos: Barlow Condensed, respeitando licenças e fallback documentado.

---

## 8. Gates e definição de pronto

| Camada | Evidência mínima |
|---|---|
| **Runtime** | fluxo principal, combate v4.1, IA Davi, save roundtrip e smokes/GUT verdes |
| **Conteúdo** | atlas, manifest, preview, cena, licença, `sync_map` quando necessário e QA humano |
| **Release** | APK ARM64 instalado e jogado em aparelho físico, ≥45 FPS sustentados, SHA-256, acessibilidade, áudio e licenças aprovados |

Rótulos proibidos sem evidência: “jogo completo”, “arte final”, “áudio final”, “APK pronto” e “release ready”. Até o gate correspondente, usar “núcleo”, “vertical slice”, “alpha”, “beta”, “RC”, `design_aprovado` ou `planned`.

---

## 9. Template de resposta

```text
🛰️ HANDSHAKE  estado verificado ou modo degradado + delta
🔍 DIAGNÓSTICO gargalo atual e evidência
🎯 DECISÃO     próxima jogada de maior alavancagem
📦 ENTREGA     artefato, patch, código, dados ou instrução executável
✅ GATE        critério fechado, evidência e verificação seguinte
```

---

## 10. Invioláveis

Três facções; três distinções; três camadas de cor; Godot como único runtime; sem gacha; sem poder por Molho; sem finalização automática; 14+ sem gore; oponente adulto; CI como porteiro; rótulos de pronto somente com evidência.

---

## 11. Topologia de PRs

A topologia é estado operacional, não cânone permanente. Deve ser confirmada em cada handshake.

Snapshot verificado em 2026-07-24:

```text
main (f098ab5 — Deck de Combate e disputas de nível)
 └─ #32 release/v4-integration → main
      ├─ #25 release/unify-and-feel → #32
      │    └─ #26 feat/open-pixel-forge-v1 → #25
      └─ #24 agent/visual-audio-world-v10 → #32
```

No snapshot, #32 e #26 estavam mergeáveis; #25 e #24 estavam não mergeáveis. A ordem de integração deve respeitar bases e gates; o snapshot não autoriza merge automático.

---

## 12. Auto-verificação

O protocolo só é considerado ativado quando:

- `docs/GAME_BUILD_PROTOCOL.md` existe;
- `AGENTS.md` o referencia na seção 0;
- `docs/DOC_PRECEDENCE.md` declara a precedência;
- o SUPREME referencia este protocolo como camada de processo;
- a skill `cria-do-tatame-game-director` o carrega;
- o validador da skill verifica esses vínculos;
- um handshake posterior confirma o estado ao vivo.

Comandos:

```bash
python .agents/skills/cria-do-tatame-game-director/scripts/validate_skill.py
npm run validate:skill
npm run quality
```

---

## Apêndice A — Glossário

- **Handshake:** leitura do estado vivo do projeto no início da iteração.
- **Delta:** diferença entre dois handshakes.
- **Gargalo:** fator único que mais bloqueia o avanço.
- **Jogada:** ação de maior alavancagem escolhida para a iteração.
- **Gate:** condição binária sustentada por evidência.
- **Stacked PR:** PR cuja base é outra branch de feature.
- **Commit-bomba:** commit que mistura grande volume e temas desconexos.
- **PR vertical:** entrega completa de um tema, do contrato ao QA.
- **Design aprovado:** conteúdo aceito, ainda não executável.
- **Runtime executável:** conteúdo integrado, testado e consumido pelo jogo.
- **Modo degradado:** operação transparente sem leitura ao vivo completa.

## Apêndice B — Comandos de verificação

```bash
# Handshake leve
git fetch --all --prune
git log --oneline -5 origin/main
gh pr list --state open --json number,title,isDraft,headRefName,baseRefName,statusCheckRollup

# Inspeção profunda da integração
gh pr view 32 --json title,body,headRefName,baseRefName,mergeable,statusCheckRollup,files

# Diff e topologia
git log --graph --oneline --decorate --all -30
git diff --stat origin/main...HEAD

# Gates do repositório
python .agents/skills/cria-do-tatame-game-director/scripts/validate_skill.py
npm run quality

# Godot headless, quando instalado
godot --headless --path . --editor --quit
godot --headless --path . --script tests/runtime_smoke.gd

# Integridade de binários e release
git lfs ls-files
sha256sum builds/android/*.apk
```

Comandos podem variar por sistema operacional; qualquer alteração deve ser documentada no PR correspondente.