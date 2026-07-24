# Consolidação oficial dos repositórios — Cria do Tatame

## Fonte única

`ringuemkt-rgb/cria-do-tatame` é o **único repositório canônico** para código, dados, documentação, assets aprovados, builds, testes e releases de **Cria do Tatame – Pressão**.

Branch de integração vigente:

- `release/v4-integration`

Pull request de consolidação:

- `#32 release(v4): consolidar hardening, cânone, facções e combate posicional`

## Repositórios duplicados desativados

Os repositórios abaixo são protótipos históricos ou duplicatas e não devem receber novas alterações:

- `ringuemkt-rgb/Cria-do-tatame-` — protótipo Android/Gradle antigo;
- `ringuemkt-rgb/Modelo-teste-cria-do-tatame-` — modelo de produção anterior;
- `ringuemkt-rgb/Tatamecria` — placeholder antigo de APK.

Eles podem ser apagados manualmente após eventual backup, porque o conector disponível nesta sessão não expõe exclusão de repositório. Até a exclusão, seus READMEs devem apontar para o repositório canônico.

## Projetos que NÃO são duplicatas

Não apagar como parte desta consolidação:

- `ringuemkt-rgb/Bahia-Kaiju-Battle` — jogo separado;
- `ringuemkt-rgb/agent-sprite-forge` — ferramenta de produção visual;
- `ringuemkt-rgb/sprite-gen` — ferramenta auxiliar;
- `ringuemkt-rgb/sprite-sheet-creator` — ferramenta auxiliar;
- demais repositórios de MotoJá, ONG, Figma, Expo ou outros produtos.

## Política operacional

1. Nenhuma feature do jogo nasce em outro repositório.
2. Ferramentas externas produzem candidatos; somente assets aprovados entram neste repositório.
3. `main` representa a linha estável.
4. `release/v4-integration` recebe a migração canônica e o vertical slice.
5. PRs antigos são fechados quando absorvidos, substituídos ou pertencentes a outro produto.
6. Não apagar histórico útil antes de ele ser absorvido ou documentado.
7. Nenhum PR pode declarar jogo completo sem boot, testes, Android físico, desempenho, acessibilidade e licenças verdes.

## Definition of Done do repositório único

- cânone v4 incorporado;
- exatamente três facções;
- saves legados migrados;
- combate por cartas integrado à fachada existente;
- Hub, deck, skill tree e persistência;
- mundo, Cria Live, economia e finais conectados;
- visual, áudio e animações aprovados;
- Godot 4.3+;
- Android ARM64 e Windows;
- CI, smoke tests, GUT e device testing verdes.
