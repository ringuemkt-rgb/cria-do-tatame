# Relatório — primeira sessão jogável Ruan × Davi

**Data:** 2026-10-24
**Estado de conclusão:** implementado e validado automaticamente em branch; ainda não integrado à `main`
**Fase do roadmap:** P1 — primeiro fluxo vertical jogável

## Entregue

O Terreiro agora inicia a cinemática canônica `intro_terreiro`; a pessoa pode avançar ou pular as falas, e o marco é salvo ao concluir. A recomendação seguinte abre uma tela de treino técnico com três repetições de Grip de Ferro. Ao concluir, o `TrainingManager` existente desconta a energia definida pelos dados e atualiza a maestria de `grip_de_ferro`.

Ao terminar uma luta real entre Ruan e Davi, o runtime marca `primeira_luta_davi` e deixa o post de combate pendente. A tela Cria Live conclui `primeiro_post_cria_live` somente se encontrar uma postagem com `source_event=combat_finished`, então salva o fluxo. Os managers de combate, treino, Cria Live e saves existentes continuam sendo as autoridades.

Isto fecha um recorte jogável da primeira sessão; **não declara o jogo completo**.

## Arquivos

| Situação | Caminho | Finalidade |
|---|---|---|
| Modificado | `src/autoloads/GameFlowManager.gd` | Conclusão idempotente de marcos e recomendação do treino respaldada pelo ID real `rolagem_tecnica`. |
| Modificado | `src/autoloads/CutsceneRuntime.gd` | Marcar a cutscene como concluída antes do sinal de persistência. |
| Modificado | `scenes/hubs/TerreiroDaLuta.gd` | Abrir a cutscene inicial e encaminhar o botão de treino para a nova tela quando esse for o próximo passo. |
| Criado | `scenes/ui/CutsceneOverlay.gd` | Controles de fala, pular/continuar e save da abertura. |
| Criado | `scenes/ui/CutsceneOverlay.tscn` | Overlay mobile-first no tema escuro/dourado do jogo. |
| Criado | `scenes/training/TrainingScreen.gd` | Interação de três repetições integrada ao `TrainingManager`, à maestria e ao save. |
| Criado | `scenes/training/TrainingScreen.tscn` | Tela de treino com contador, barra de progresso e alvos de toque amplos. |
| Modificado | `scenes/combat/CombatArenaBase.gd` | Registrar fim da primeira luta Ruan × Davi e o post pendente antes do save. |
| Modificado | `scenes/ui/CriaLiveUI.gd` | Concluir o marco após exibir o post real e salvar antes de voltar ao Terreiro. |
| Modificado | `tests/runtime_smoke.gd` | Incluir as duas novas cenas na lista de cenas obrigatórias. |
| Criado | `tests/first_run_flow_smoke.gd` | Smoke de integração da abertura, treino, fim da luta, Cria Live e marcos persistidos. |
| Modificado | `package.json` | Adicionar `npm run test:first-run-flow`. |

## Integração

**Consumidor real:** `TerreiroDaLuta.tscn`, `CutsceneRuntime`, `TrainingManager`, `CombatArenaBase.tscn`, `CriaLiveManager`, `CriaLiveUI.tscn` e `SaveManager`.

**Fluxo afetado:** menu principal → Terreiro → abertura → três repetições técnicas → pré-luta existente → combate Ruan × Davi → resultado existente → post automático no Cria Live → próxima missão recomendada. A animação pareada continua sendo apenas apresentação: `CombatManager` segue decidindo posições, ações e resultado.

**Migração/compatibilidade:** não foi alterada a versão do save. `GameFlowManager` já persiste `completed_steps` e `flow_flags`; o novo flag `first_davi_combat_post_pending` usa o fallback existente (`false`) para saves antigos. A chave do treino passou de um identificador não executável (`repeticao_drill`) para o dado real `rolagem_tecnica`.

## Validação

| Comando/teste | Resultado | Evidência |
|---|---|---|
| `GODOT_SILENCE_ROOT_WARNING=1 godot --headless --editor --path . --quit` | PASS | Import/parser concluído, exit code 0, Godot 4.7.2. |
| `npm run test:first-run-flow` | PASS | `checks=20 failures=0`; exercita as telas, evento de combate, Cria Live e save. O processo reportou quatro instâncias `ObjectDB` não liberadas ao sair; não falhou, mas permanece como aviso a investigar. |
| `GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . --script res://tests/runtime_smoke.gd` | PASS | `checks=138 failures=0`. |
| `GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . --script res://tests/full_game_smoke.gd` | PASS | 183 verificações; 24 cenas carregadas. |
| `npm run quality` | PASS | Exit code 0 em todos os validadores e testes da cadeia. |
| `gh pr checks 178 --repo ringuemkt-rgb/cria-do-tatame` | PASS | 15 checks remotos reportados como successful; 0 failing, 0 pending, 0 skipped. A descrição do check CodeRabbit indica que a revisão foi pulada por a PR estar em draft. |
| `git diff --check` | PASS | Nenhum erro de whitespace. |

**Testes não executados:** exportação/instalação Android, teste em aparelho físico, revisão visual humana e homologação de release. O resultado sintético dentro do smoke prova o vínculo dos sinais e marcos; não substitui uma luta jogada por uma pessoa.

## GitHub

- **Branch:** `feat/ruan-davi-first-run-flow-20261023`
- **Commit(s):** `ce0103c1cdc48e384422a1e29b3de412e78f14d0` — `feat(game): wire first-run Ruan-Davi flow`
- **Issue:** não criada
- **PR:** [#178 — conectar primeira sessão Ruan × Davi](https://github.com/ringuemkt-rgb/cria-do-tatame/pull/178) — draft
- **Base/dependências:** empilhada sobre a branch `fix/runtime-quality-integration-20261018` do PR #175. Integrar #175 primeiro; depois atualizar/reexecutar CI de #178. Nenhum merge foi feito e a `main` não foi alterada.

## Riscos e limitações

Os sprites atuais de Ruan e Davi continuam como candidatos no manifesto (`shipping=false`); nenhuma prancha/concept foi promovida. O renderer de combate permanece no preview procedural pareado existente, portanto esta entrega **não conclui a animação pixel-art final dos personagens**. A interface foi validada por carregamento e interação headless, não por revisão visual em Android. O smoke do novo fluxo também emitiu um aviso não fatal de quatro objetos `ObjectDB` ao encerrar.

A validação local usou Godot 4.7.2; a CI remota da PR reportou todos os checks como successful. Ainda falta a verificação em aparelho físico. A PR está aberta como draft e depende de #175.

## Próximo lote

Após a integração de #175, atualizar/rebasear #178 e repetir os checks. Em seguida, fazer revisão humana da primeira sessão e, em trilha visual separada, aprovar/normalizar os identity masters e sprites de idle/locomoção de Ruan e Davi. Só então ligar arte aprovada ao renderer e validar uma técnica pareada real na cena. Gate de saída: playtest completo do fluxo em Android, save após reinício e revisão visual sem bloqueadores.
