# LEDGER — lead/calibracao-v1

**Lote:** `lead/calibracao-v1`
**Data UTC:** 2026-08-27
**Base:** `origin/main@749fe5d493e38761701430e225fa536f5a4904e8`
**Autoridade humana reservada:** Mestre Satoshi
**Merge:** proibido neste lote

## Escopo executado

- D12–D47 registrados em `docs/DECISIONS.md` e materializados nos contratos JSON do mesmo lote.
- Cláusulas 23–30 incorporadas ao Prompt Mestre Visual/Grappling.
- Finais centralizados em `data/finais_adultos.json`; `EndingsCalculator.gd` não contém IDs nem limiares canônicos.
- Cores e territórios iniciais de ALE/LEM/NTM reconciliados no catálogo, contrato de migração, Director e geografia.
- Ruan e Davi corrigidos nos dados; cinco personagens definidos como `defined_not_produced`.
- Contrato discreto da infiltração, tokens compartilhados de HUD/mapa/árvore/hub e orçamento de stages adicionados.
- NFT, World Director e Faction Director movidos para `docs/archived/`; consumidores legados apontam para o arquivo arquivado para não quebrar boot/save.
- `apk` e ZIP legado removidos do Git; `index.html` do PWA preservado e laboratório unificado em `tools/audit/visual_lab.html`.
- `agent-sprite-forge` registrado como ferramenta externa MIT fixada em commit, nunca como gerador final de BJJ pareado.
- Gate dedicado de entrega GDScript adicionado à CI.

## Estados de evidência

| Entrega | Estado | Evidência |
|---|---|---|
| D12–D47 e Cláusulas 23–30 | `validated` | `npm run validate:lead-calibration`; 4 testes contratuais |
| `EndingsCalculator.gd` e consumidores | `integrated` | import headless limpo; runtime smoke 120/120 |
| Fações/geografia/tokens/infiltração | `validated_not_runtime_promoted` | `npm run quality`; 24 testes Python diretos |
| Arquivos de sistemas antigos | `archived_compatibility_retained` | runtime e full-game smokes verdes |
| Arte candidata/final | `not_created_in_lote_00` | promoção automática proibida |
| Gates humanos 01–06 | `unsigned` | somente Mestre Satoshi pode assinar |

## Gates locais

| Comando | Resultado |
|---|---|
| `npm run quality` | PASS |
| testes Python diretos (`tests/test_*.py`) | 24 PASS |
| Godot 4.2.2 `--headless --editor --import` | PASS, sem erro de script/parse/compile |
| `tests/runtime_smoke.gd` | PASS, 120 checks, 0 failures |
| `tests/full_game_smoke.gd` | PASS, 156 checks, 14 cenas |
| `tests/faction_director_smoke.gd` | PASS, 40 checks |
| `git diff --check` | PASS |

## Logs versionados

| Caminho | SHA-256 |
|---|---|
| `reports/gdscript_delivery/godot_import.log` | `d967a5dd9e46d1b2515537f699b9232a6be58092d61760f4b48833e6e3582058` |
| `reports/gdscript_delivery/runtime_smoke.log` | `93ce840aa63255227e8b29af0f53551ed3daf2d350c2aadfbcda8494e9991f2d` |
| `reports/gdscript_delivery/full_game_smoke.log` | `60d583cd8ca1fb5ee8a074a56225a9e6874ae09a197488240089a6fa8ad64587` |
| `reports/gdscript_delivery/faction_director_smoke.log` | `a36445711734a22f9e1dea18a11a4c2b9fc0e8cb07544081d42cff103a1f050d` |

## Higiene e recuperação

| Removido do Git | Tamanho | SHA-256 | Recuperação |
|---|---:|---|---|
| `apk` (arquivo NDJSON legado; não era diretório) | 9.203 B | `1fc49f66723ded3832ac0d62b404bbfc2cb329714a12fa46c45c13d460078bc3` | histórico Git da base |
| `CRIA_DO_TATAME_COMPLETE_100_MOBILE_GITHUB_APK_READY_v1_2.zip` | 3.409.463 B | `347941a35dc977df1220a43a548192b6290ca50744b2b6835fb7e76338c5cdd1` | histórico Git da base; publicação futura em Release é reservada ao Mestre |

## Resoluções registradas

- O `index.html` raiz é o launcher PWA ativo; `index-1.html` não existia na base atual.
- O catálogo solicitado de nove stages é formado por nove pacotes de produção e dez variantes de luz/cenário, conforme D41.
- Não havia arquivo de trama com organização policial real em `main`; o limite de pesquisa e ficcionalização foi registrado em `docs/research/INSTITUTIONAL_REFERENCE_BOUNDARY.md`.
- A migração Godot 4.7.2 permanece apenas em ADR separado, sem alterar o runtime 4.2.2.

## Estado remoto

- Push: pendente ao registrar este checkpoint.
- PR: pendente ao registrar este checkpoint.
- CI remota: pendente.
- Merge: não executar.
- Próximo lote externo: Manus 10 somente após existência do PR deste lote.
