# Prime Agent Pilot — Ruan × Davi v0.1

Você é um executor externo do Cria Game Forge trabalhando somente nesta branch candidata. Leia e obedeça `AGENTS.md`, `README.md`, `docs/REPOSITORY_GOVERNANCE.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md`, `docs/INDEX.md`, `data/production/canon_contract_v4_1.json` e `data/production/supreme_build_contract_v01.json` antes de editar qualquer arquivo.

## Objetivo observável

Auditar o fluxo jogável representativo:

`Main Menu → Terreiro → treino/deck → combate Ruan × Davi → resultado → Cria Live → avanço da semana → save/reload → Terreiro`.

Trabalhe em modo **characterize_then_patch**:

1. inventarie consumidores, sinais, cenas e testes do fluxo;
2. encontre uma falha P0/P1 reproduzível;
3. escreva um teste/regressão que caracterize a falha;
4. corrija no máximo **um** defeito diretamente relacionado ao fluxo;
5. altere no máximo **um arquivo de runtime**;
6. rode os gates disponíveis e deixe apenas um diff candidato revisável.

## Escopo permitido

Arquivos de runtime permitidos, no máximo um deles:

- `src/autoloads/CombatManager.gd`
- `src/autoloads/MissionManager.gd`
- `src/combat/TechniqueClashResolver.gd`
- `src/autoloads/SaveManager.gd`

Prefira mudanças em `tests/`, `reports/` e `docs/qa/` para caracterização/evidência.

## Hipóteses a verificar — não assuma que são verdade

- pode existir caminho de finalização automática que contrarie a soberania de tap/escape;
- `MissionManager` pode aceitar ID inexistente e persistir estado inválido;
- save/load ou retorno ao Terreiro pode ter lacuna de regressão.

Confirme no código e nos testes antes de corrigir qualquer uma delas.

## Proibido

- editar `project.godot`;
- editar `.github/workflows/`;
- editar `AudioManager.gd`;
- alterar cânone ou contratos supremos;
- criar manager/runtime concorrente;
- adicionar dependência;
- escrever em `assets/aprovados/`;
- fazer `git push`, merge, tag ou release;
- usar ou procurar credenciais;
- introduzir finalização automática;
- fornecer instrução direcional de escape para técnica de alto risco.

## Validação

No mínimo execute `npm run quality`. Se `./godot` estiver disponível, execute também import/parser e os smokes existentes relevantes.

## Saída

Ao terminar, gere `reports/prime_agent/pilot_summary.md` contendo:

- falha escolhida e evidência;
- arquivos alterados;
- teste criado/ajustado;
- comandos executados e resultados;
- riscos remanescentes;
- por que o patch é reversível;
- estado final `PENDING_HUMAN`.

Não faça commit nem promoção. O humano controla GATE-L4 e merge.
