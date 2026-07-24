# Exclusão manual dos repositórios duplicados

## Fonte única preservada

**Não excluir:** `ringuemkt-rgb/cria-do-tatame`

Este é o único repositório canônico do jogo **Cria do Tatame – Pressão**.

## Duplicados desativados e autorizados para exclusão

Após confirmar que não existe arquivo exclusivo necessário, excluir somente:

1. `ringuemkt-rgb/Cria-do-tatame-`
2. `ringuemkt-rgb/Modelo-teste-cria-do-tatame-`
3. `ringuemkt-rgb/Tatamecria`

Os READMEs desses três repositórios já apontam para o canônico e informam que estão desativados.

## Não excluir

- `ringuemkt-rgb/Bahia-Kaiju-Battle` — outro jogo;
- `ringuemkt-rgb/agent-sprite-forge` — ferramenta visual;
- `ringuemkt-rgb/sprite-gen` — ferramenta visual;
- `ringuemkt-rgb/sprite-sheet-creator` — ferramenta visual;
- qualquer repositório que não seja um clone/protótipo direto de Cria do Tatame.

## Procedimento seguro no GitHub

Para cada um dos três duplicados:

1. Abra o repositório.
2. Acesse **Settings**.
3. Abra **General**.
4. Role até **Danger Zone**.
5. Antes da exclusão, use **Download ZIP** ou crie um backup local da branch padrão.
6. Selecione **Delete this repository**.
7. Digite o nome completo solicitado pelo GitHub.
8. Confirme a exclusão.

## Gate antes de excluir

- [ ] O PR #32 e a branch `release/v4-integration` existem no canônico.
- [ ] O histórico necessário dos GDDs está em `docs/canon/`.
- [ ] Dados, scripts, cenas e assets necessários estão no canônico ou em PR útil documentado.
- [ ] Nenhum link de produção, CI ou documentação aponta para o duplicado.
- [ ] Foi gerado backup ZIP.

## Limite da automação atual

A integração GitHub usada nesta execução permite editar arquivos, branches, issues e pull requests, mas não oferece operação de exclusão ou arquivamento de repositório. Por isso a remoção física exige a confirmação manual acima.
