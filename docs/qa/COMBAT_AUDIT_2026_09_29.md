# Cria do Tatame — auditoria e construção de combate

Data: 29/09/2026. Base inspecionada: `099c060` (`main`).
Branch de trabalho: `fix/positional-combat-audit-20260929`.
Status: correções integradas nesta branch; jogo completo e release ainda não aprovados.

## Diagnóstico

Existe uma base Godot jogável, com menu, Terreiro, deck, combate, resultado,
Cria Live, progressão e save. Ainda não existe evidência suficiente de um jogo
completo com o combate e a apresentação final desejados. Os testes de estrutura
e de fluxo não certificam fidelidade biomecânica, diversão, acabamento ou Android.

O principal descompasso é entre a sofisticação dos contratos de grappling e o
combate efetivamente consumido pela arena. `CombatManager` continua sendo a
autoridade; `BJJGraphReducerV2` funciona em testes e em observação paralela.
Não foi promovido silenciosamente a árbitro da cena.

## Correções entregues

1. Reaproveitado o commit `5138222` do PR #138 por cherry-pick, preservando a
   autoria: cadastro de quatro ações de Davi no QA, teste dos personagens,
   quality completo no CI, reconhecimento de cenas exportadas e empacotador PCK.
2. Ações em posição errada ou sem recursos são rejeitadas antes de gastar gás,
   foco, moral, cartas ou números aleatórios; não alimentam sinais de execução,
   scouting ou comparação shadow. Uma tentativa válida defendida continua tendo custo.
3. Chamadas diretas também respeitam mão V2, dono da técnica, oponente distinto
   e combate em andamento. Davi não pode executar a assinatura exclusiva de Ruan.
4. O RNG do resolver real é reiniciado com a seed da luta. Dez seeds, cada uma
   com cinco ações repetidas em duas execuções, são comparadas no CombatManager.
5. Um plano pré-luta inválido não apaga a mão anterior nem mistura o deck de um
   plano com o ruleset de outro. Não se troca plano durante uma luta ativa;
   arena/oponente incompatíveis com o plano são rejeitados antes do início.
6. Corner em luta só sugere técnicas disponíveis e pagáveis na posição atual.
   Custos aninhados e `exit_state` do catálogo são lidos corretamente.
7. Aliases de uma mesma técnica não ocupam várias opções de ação.
8. Arena e cartas compartilham bloqueio de entrada durante a resposta rival.
   Toques rápidos não criam múltiplas corrotinas/turnos. Cartas sem recursos são
   desabilitadas e atualizadas pelos sinais de recursos.
9. A IA da cena recebe o ID do rival selecionado. A apresentação visual e os
   textos da arena ainda são específicos do slice Ruan × Davi.
10. A regressão integrada entra no CI e também roda no PCK exportado, fora da
    árvore de código. Logs com `SCRIPT ERROR` são falha mesmo com exit code zero.

Nenhum autoload, ID persistente, versão de save ou asset final foi substituído.

## Estado real por área

| Área | Evidência atual | Falta para concluir |
|---|---|---|
| Boot e fluxo | Import Godot 4.3, 115 verificações de runtime; 178 verificações/21 cenas no smoke completo | Teste humano contínuo e casos de interrupção no aparelho |
| Combate da arena | `src/autoloads/CombatManager.gd`, resolver e deck ativos | Migrar regras/pontuação/finalização por adapter com equivalência comprovada |
| Grafo de BJJ | Fixture com 10 posições e 8 técnicas; grafo completo ausente | Fonte revisada para a meta 40 posições/120 técnicas/10 cadeias; legalidade por divisão |
| Animação pareada | Golden chain e contratos; 7 bindings físicos pendentes, nenhum aprovado | Contatos, pivôs, sincronização, defesas e transições revisadas em cena |
| Personagens | 8 registros no catálogo base; roster v3 lista 17; contrato global mira 18 | Reconciliar catálogos e fabricar pacotes completos; contagem não prova personagem jogável |
| Arenas/mundo | 7 arenas no catálogo base; mapa v4 com 40 nós e 10 páginas | Navegação, colisões, camadas aprovadas e conteúdo integrado por hub |
| Narrativa | 5 atos em dados; `missions_v1.json` contém 45 vínculos; marca `LINK_ONLY` não é missão completa | Ligar objetivos, escolhas, cenas e condições de término ao runtime |
| Finais | `endings_v2.json` tem 2 finais principais e 7 epílogos; contrato global prevê 5 finais | Reconciliar precedência/escopo antes de expandir; não inventar finais para atingir uma meta |
| Progressão/save | Save v6 e 27 verificações de Progression OS passam | Retomar luta interrompida; campanha e economia completas com testes de consequências |
| Visual | Coverage derivado: 706 requisitos, 0 aprovados, 0 integrados, 0 shipping | Produzir e registrar os assets finais, começando por Ruan/Davi/Dique/Terreiro |
| Áudio | `AudioManager.gd` sintetiza tons temporários | Foley, música e ambiência próprios/licenciados, mixagem e loudness |
| Android | Pipeline existe; `android_physical_device_v1.json` está PENDING | APK deste commit, instalação, touch, safe areas, reinício, FPS, memória e temperatura |
| Acessibilidade | Direção e requisitos documentados | Perfil sensorial realmente conectado a flash, tremor, hitstop, áudio e timer |

Os 706 requisitos são uma medida do ledger de produção. Não significam que
existem zero imagens. Existem assets e animações provisórias, mas o ledger não
comprova aprovação e integração de nenhum pacote final.

O build matrix contém referências desatualizadas: por exemplo, declara
`missions_v1_missing`, embora o arquivo de vínculos exista. Não usar o matrix
sozinho como inventário. O DataRegistry ainda consome os catálogos
`data/missions/story_missions_v01.json` e `faction_missions_v01.json`.

## O que impede o combate de corresponder ao objetivo

### P0 — árbitro e resultado

- `_check_end()` ainda admite vitória por HP/gás; `_resolve_finisher_before_transition()`
  admite HP como atalho de avaliação. Isso não representa o objetivo de BJJ
  posicional. A remoção exige junto recuperação/ações de baixa energia para não
  transformar exaustão em um combate sem saída.
- O score dos lutadores começa em zero. A arena não consome uma apuração completa
  de estabilização/posição. Ter `score_event` no resolver não concede pontos.
- O cronômetro V2 expira e emite pedido de resolução; não existe consumidor que
  feche esse resultado pela autoridade de regras. ADCC precisa ainda de fases de
  pontuação e critérios próprios. Este lote não inventa desempate nem vencedor.
- `reset_position` ainda pode devolver a luta para pé como saída de protótipo;
  não deve ser uma fuga livre de posições ruins no jogo final.

Próximo lote vertical: ligar a cadeia já existente de queda → passagem →
controle → finalização a um adapter de regras no CombatManager, mantendo o
reducer como alvo e comprovando resultados, counters, estabilização e empate.
O contrato `combat_core_v2_contract.json` bloqueia a troca de autoridade sem
harness de equivalência e evidência Android física.

### P1 — agência e leitura

A cena atual resolve a ação ao tocar e espera a resposta de Davi. O resolver
tem campos para finta/deny/chain, mas o contexto fornecido pela arena não
constitui ainda um sistema completo de defesa em tempo real. Faltam janelas
legíveis, compromisso da ação, escolha de defesa e manutenção dos dois corpos
em contato. O visual não pode decidir o resultado por frame.

### P1 — produção representativa

Priorizar apenas Ruan, Davi, Dique, Terreiro e as técnicas da golden chain.
Cada técnica deve sair com atacante/defensor, seis fases, contato, pivô,
sync_map, defesa/falha, proveniência e revisão. Não basta gerar sprites bonitos
de dois lutadores independentes. `FighterPlaceholder` ainda anima cada corpo
separadamente, incompatível com a comprovação de contato pareado final.

### P2 — expansão

Após o slice validado, expandir rival + arena + missão + técnicas + áudio + QA.
Os PRs #145, #150, #152, #153 e #154 têm sobreposições ou propostas ainda não
integradas. Foram inventariados; não foram mesclados em bloco. Havia 49 PRs
abertos na consulta desta auditoria. O PR #138 foi reaproveitado deliberadamente.

## Validação

Com Godot `4.3.stable.official.77dcf97d8`:

| Verificação | Resultado |
|---|---|
| `npm run quality` | PASS após absorção do PR #138; baseline falhava no QA de `counter_entry` de Davi |
| Import/parser headless | PASS, sem SCRIPT ERROR |
| `runtime_smoke.gd` | PASS — 115 verificações |
| `full_game_smoke.gd` | PASS — 178 verificações, 21 cenas |
| `progression_os_smoke.gd` | PASS — 27 verificações |
| `combat_core_v2_smoke.gd` | PASS, incluindo 50 seeds do reducer |
| `combat_action_safety_smoke.gd` | PASS — 95 verificações, incluindo o CombatManager real e toques concorrentes na arena |
| `grappling_golden_chain_smoke.gd` | PASS — 38/38 |
| `combat_manager_bjj_shadow_smoke.gd` | PASS — 23/23 |

O warning do full-game smoke sobre domínio `terreiro` é a recusa esperada de
postar um domínio não ativo como facção. Não foi tratado como licença para
inserir uma quarta facção.

O pacote desktop é exportado e retestado pelo
`tools/build/build_playtest_pack.py`. Os resultados e hash ficam em
`validation.json` dentro do ZIP, junto dos logs. Ele requer Godot Standard da
mesma versão. Não é APK, executável Windows autônomo nem certificação visual.

## Integração e rollback

Relacionado aos issues #102 (slice), #103 (visual) e #109 (QA/release).
As correções estão na branch indicada, para revisão via PR; `main` não foi
alterada por esta entrega. Reverter o commit de correções de combate desfaz o
lote; a absorção do PR #138 é um commit separado. Save v6 permanece compatível.

Não foi necessário criar outra engine, outro repositório, novos managers ou
uma coleção paralela de prompts. A próxima decisão de produção deve ser
fechar o árbitro/resultado e a primeira animação pareada, antes de ampliar o mapa.
