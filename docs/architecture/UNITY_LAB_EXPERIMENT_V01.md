# Unity Lab v0.1 — avaliação descartável

**Status:** DRAFT / NOT CANONICAL / NOT SHIPPING — 2026-10-11
**Engine de produção:** Godot 4.3+ — sem alterações à main
**Engine experimental:** Unity 6.3 LTS, Universal 2D (somente em projeto temporário externo)

## Conflito de governança e decisão proposta

O usuário solicitou avaliar Unity preservando Godot. AGENTS.md, docs/DECISIONS.md (D1–D6, D9) e data/production/supreme_build_contract_v01.json proíbem segundo runtime (secondary_runtime_forbidden=true). Este documento NÃO modifica essa regra. Propõe autorização humana para um laboratório EXTERNO, descartável, sem segunda árvore em Git, sem runtime concorrente e sem qualquer promoção automática.

Não adicionar Unity Assets, Packages, ProjectSettings, assemblies, builds ou saves ao repositório principal. O laboratório é somente um instrumento de comparação; se a política não permitir, parar sem executar o editor.

## Objetivo e timebox

Até cinco dias úteis ou 20 horas: medir custo, paridade visual e desempenho móvel de um replay de Ruan × Davi. O escopo limita-se a uma arena 2D, dois avatares temporários, HUD read-only e quatro transições da golden chain; o combate real, deck, progressão e saves continuam sob autoridade do Godot.

## Dados oficiais usados em modo somente leitura

- data/combat/golden_chain_ruan_davi_v1.json: quatro transições, seis fases, shipping=false.
- data/ruan_deck_inicial.json: 5 ativos / 3 passivos / mão inicial 3.
- data/techniques.json: conferir técnica por ID de carta.
- data/progression/skill_graph_v1.json: cinco caminhos e 51 nós.
- data/world/world_map_v4.json: dez páginas / 40 locais, georreferência ainda não homologada.

Importação: copiar arquivos JSON sem transformação de conteúdo e salvar SHA-256 no laboratório. Cópias são descartáveis e não substituem os dados oficiais. IDs da golden chain BJJ não devem ser confundidos com IDs do catálogo legado de técnicas.

## Contrato técnico

Godot (fonte e árbitro): CombatManager / BJJGraphReducerV2 / DeckManager / WorldState.
Unity (somente leitura): DTO de JSON → validação → playback visual pareado → HUD informativo → métricas.
Nenhuma decisão de score, winner, transição autoritativa, save, IA ou regra é produzida pelo Unity.

## Critérios de aceitação

1. Importador preserva bytes e hashes; rejeita alteração na cardinalidade/IDs.
2. Reprodução das quatro transições em ordem e das seis fases; não há alteração em estado de jogo oficial.
3. HUD reflete as três cartas iniciais e nomes das ações, sem criar outra autoridade de deck.
4. Testes PlayMode/EditMode e Android físico com screenshot e logs; sem inferir aprovação a partir de código.
5. Antes de comparar engines: mesma resolução 1280x720, sprites licenciados idênticos, efeitos equivalentes, áudio, simulação/input, cena e configuração do aparelho.
6. Três sessões por engine/dispositivo em classes Android básica/intermediária/alta; registrar p95/p99 frame time, FPS p5/p50, memória residente, inicialização, APK, bateria, temperatura, input-to-photon e crashes.
7. Perfis acessíveis equivalentes: touch, safe area, contraste, redução de flashes/movimento.

## Decisão, riscos e encerramento

Pesos de decisão: paridade/autoridade 25%; desempenho Android 25%; custo de port/manutenção 20%; pipeline visual 15%; release 10%; acessibilidade 5%. Referência exploratória: pelo menos 20% de redução reprodutível no p95 frame-time com paridade e custos aceitáveis, em duas classes Android. Esses percentuais são critérios propostos, NÃO medições.

Não se autoriza migração automática, mesmo se Unity vencer algum benchmark. Seriam obrigatórias nova ADR, orçamento, compatibilidade de saves e aprovação. Sem paridade/evidência o padrão é manter Godot e descartar o protótipo.

### Evidência atual

Confirmados por GitHub: fonte Godot, golden chain 4x6, deck 5/3/3, skills 5/51, atlas 10/40. Unity Editor, build, Test Runner, PlayMode, Android físico e perfis de memória/FPS ainda NÃO EXECUTADOS. Nenhuma alteração runtime nem assets finais neste PR.

### Rollback

Fechar PR e descartar o projeto experimental externo; não há schema de save, autoload, project.godot ou dependência alterada.

## Atualização experimental v0.2 (11/10/2026)

Pacote descartável **fora deste repositório** atualizado em artefato de conversa `cria_unity_lab_v02.zip`, sem edição de `main` ou dependências Godot.

- Código C# de **replay visual não autoritativo** isolado em `CriaReplayTimeline`, seis fases e quatro etapas, pausa/retomada, reprodução sequencial e retorno a checkpoints do fixture.
- Projeções visuais de meia-guarda, controle lateral, montada e finalização sem reset artificial para posição de pé, com sprites/fundo procedurais identificados como **LAB ONLY** (não arte final, não biomecânica homologada).
- HUD de inspeção somente leitura do deck, mapa e skills. Não foi criado engine de regras, IA, save, pontuação ou vencedor em Unity.
- Integridade reforçada: cinco arquivos JSON copiados sem edição, fingerprint SHA-256 agregada, verificação pós-importação, checagem de 5+3/3, 5 caminhos/51 nós e 10 páginas/40 pontos.
- Três `asmdef` propostos no kit externo (runtime, EditMode, PlayMode) e probe Editor não mutável; proteção contra sobrescrita de cena existente.
- Comparador proposto rejeita falta de `parity_approved=yes`, drift nos artefatos/snapshots/Android, crashes, métricas ausentes e menos de três runs.

**Evidência real:** `25` testes Python locais passaram e o ZIP foi validado quanto à integridade. **Não executados:** compilação no Unity Editor, Test Runner, PlayMode, Android e medição comparativa. Esses itens permanecem bloqueadores; o sucesso da CI documental no GitHub não é evidência de Unity funcionando. O pacote Unity não foi comitado para respeitar `secondary_runtime_forbidden` e decisões D1/D9.

**Próximo gate humano:** abrir projeto temporário com Unity 6.3 LTS e Unity Test Framework, importar os JSON do clone oficial, executar testes C# e PlayMode, capturar log/screenshot 1280×720. Não autoriza migração.

## Atualização experimental v0.3 — 12/10/2026

**Natureza:** artefato local descartável, apenas documentação neste GitHub. Nenhum projeto Unity foi incluído na árvore oficial. Godot, `main`, saves e contratos canônicos permanecem inalterados.

**Correção real do kit v0.2:** o importador exigia `Assets/CriaUnityLab/Resources/Canon` previamente criada, mas o ZIP não a incluía; a v0.3 passa a criá-la após validar origem/destino e recusar estruturas não-Univeral-2D.

**Infraestrutura entregue para executar fora deste repo:**

- `tools/install_overlay.py` confere um projeto real gerado por Unity Hub (manifest, ProjectVersion, URP, 2D e Test Framework), sem substituir arquivos ou editar `Packages`/`ProjectSettings`;
- importador Python preserva bytes e hashes de cinco JSON e produz lista serializável no `source_manifest`;
- `CriaSnapshotGuard.cs` revalida os cinco SHA-256 e a fingerprint agregada em runtime C#, recusando snapshot inválido antes de visualização;
- Editor asmdef explícito e menus para criação de cena, validação, captura real de Game View e futura exportação Android debug ARM64/IL2CPP; a captura só é reconhecida depois de confirmar PNG e suas dimensões reais;
- `tools/run_unity_checks.py` executa Editor de verdade quando instalado e exige marcador de importação e arquivos XML NUnit >0 testes, sem falha nem skip;
- validação sintética/instalador/guardas: **39 testes Python passaram** (incluindo duas verificações do instalador único com fixtures sintéticas); estrutura com **4 assemblies** passou em verificador offline.

**Bloqueios explícitos:** não há Unity Editor, Unity Hub, compilador C#, Android SDK, clone local completo dos cinco JSON ou aparelho conectado no ambiente que montou o kit. Portanto, **não executados**: importação dos cinco arquivos oficiais em Unity real, compilação de C#, EditMode, PlayMode, screenshot verdadeiro, build Android ou benchmark Godot × Unity. Não existem evidências válidas para qualquer um desses gates. Scripts prontos não são resultados.

**Critério de próxima entrega:** em projeto Unity Universal 2D temporário: importar cinco JSON do clone Godot, rodar hash guard e NUnit/PlayMode com logs reais, capturar PNG efetivo da Game View, só então considerar APK experimental. A política `secondary_runtime_forbidden=true` continua vigente e não foi excepcionalizada por este PR.
