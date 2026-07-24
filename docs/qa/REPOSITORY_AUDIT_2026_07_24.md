# Auditoria do repositório — 24/07/2026

## Escopo e referência

- Repositório: `ringuemkt-rgb/cria-do-tatame`
- Base auditada: `main` em `f098ab57c0eae545ae097b6d5ea02c39788324e5`
- Engine de validação: Godot `4.2.2.stable.official`
- Objetivo: endurecer boot, dados, testes e critérios de conclusão sem reescrever sistemas em desenvolvimento nos PRs #25 e #26.

## Estado encontrado

| Área | Evidência | Resultado inicial |
|---|---|---|
| Qualidade declarada | `npm run quality` | Passava |
| Auditoria estrutural | `python tools/audit_full_game.py` | 0 erros; 2 avisos |
| JSON validado pelo gate padrão | `tools/validate_json.py` | Apenas 20 arquivos da raiz |
| JSON existente em `data/` | busca recursiva | 70 arquivos |
| Boot Godot 4.2.2 | importação headless | Falhava |
| Causa P0 | `FighterPlaceholder.gd` | constante `AnimationLibrary` colidia com classe nativa |
| Testes Python | `pytest -q` | não faziam parte do gate canônico |
| Alegação de conclusão | contrato supremo | metas validadas, mas execução dos gates não era rastreada |

O principal falso positivo era objetivo: os validadores estáticos ficavam verdes enquanto o Godot recusava o script do lutador e, por consequência, `CombatArenaBase.gd`.

## Correções deste lote

1. Renomeada a constante conflitante para `CharacterAnimationFactory`.
2. Validação JSON Python e Node tornada recursiva.
3. Auditoria integral incorporada ao `npm run quality`.
4. Criado ledger versionado para os 12 release gates.
5. Contrato supremo agora bloqueia declaração de conclusão enquanto houver gate sem evidência.
6. Testes de integridade adicionados para JSON e ledger.
7. Workflow `Repository Quality` passou a executar o gate canônico e toda a suíte Python.
8. Workflow `Full Game Hardening` passou a rodar em `main` e `release/**`, com concorrência e limites de tempo.
9. Relatórios gerados localmente foram excluídos do versionamento.
10. Workflows que executam o gate canônico agora instalam `Pillow`, e a auditoria de runtime aguarda a importação completa dos recursos Godot com `--import`.

## Validação após as correções

| Verificação | Resultado |
|---|---|
| `npm run quality` | aprovado |
| JSON recursivo | 70/70 arquivos em `data/` |
| Importação Godot headless | aprovada |
| `runtime_smoke.gd` | 115 verificações; 0 falhas |
| `faction_director_smoke.gd` | 26 verificações; aprovado |
| `full_game_smoke.gd` | 146 verificações; 14 cenas carregadas |
| Testes Python | 19 testes aprovados |

## Métricas estruturais atuais

- 74 scripts GDScript;
- 26 autoloads;
- 14 cenas;
- 105 arquivos JSON no repositório, dos quais 70 ficam em `data/`;
- 71 sinais declarados e 60 emitidos diretamente;
- 41 entradas no `DataRegistry`;
- 31 pacotes de animação validados.

## Lacunas que continuam abertas

- Os catálogos não representam o alvo final: o núcleo reporta 8 personagens, 21 técnicas, 3 missões e 7 arenas.
- O manifesto visual reporta 11 personagens, 23 técnicas pareadas e 12 arenas; esses números são escopo de produção, não prova de assets finais integrados.
- Os 12 release gates permanecem pendentes no ledger até receberem evidência vinculada a um commit.
- Faltam teste físico Android, medição de desempenho sustentada, revisão de acessibilidade, auditoria de loudness e aprovação humana do cânone/arte.
- Há 11 sinais sem emissão direta detectada; podem ser contratos futuros, mas precisam ser resolvidos ou documentados antes do release.
- O APK solicita `INTERNET` para integrações opcionais de IA/NFT; o loop crítico continua obrigado a funcionar offline.

## Regra de avanço

Nenhum documento, PR ou agente deve declarar “jogo completo”, “arte final”, “APK pronto” ou “release ready” enquanto `completion_ready` for `false` em `tools/validate_supreme_build_contract.py`. Cada gate aprovado deve registrar commit, data e URL ou artefato verificável no ledger.
