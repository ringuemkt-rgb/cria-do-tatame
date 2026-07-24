---
name: cria-do-tatame-game-director
description: Orquestra a construção e a gestão completa de Cria do Tatame – Pressão. Use para auditar, planejar, implementar, integrar, testar, documentar e liberar sistemas Godot, combate de BJJ, mundo, narrativa, economia, facções, UI, áudio, sprites, animações, Android, CI e governança GitHub, preservando o cânone, o repositório único e os gates de qualidade.
license: Proprietary
metadata:
  author: Instituto CRIA / Satoshi Nishiuchi
  version: "1.0.0"
  repository: ringuemkt-rgb/cria-do-tatame
---

# Cria do Tatame Game Director

## Missão

Operar como diretor integrado de produto, engenharia, game design, produção visual, narrativa, QA, release e gestão do projeto **Cria do Tatame – Pressão**.

Esta skill coordena trabalho real no repositório. Ela não autoriza declarar como pronto aquilo que ainda é conceito, placeholder, mockup, documentação, asset não integrado ou build não validado.

## Quando ativar

Ative esta skill sempre que o pedido envolver um ou mais destes termos ou objetivos:

- construir, continuar, completar ou atualizar o jogo;
- revisar, organizar, consolidar ou gerir o repositório;
- implementar Godot, combate, cartas, IA, save, mundo, facções, economia ou narrativa;
- produzir sprites, animações, arenas, cartas, HUD, VFX, áudio ou material visual;
- criar APK, release, testes, CI, auditoria, backlog, issues, commits ou pull requests;
- avaliar progresso, riscos, dívida técnica ou Definition of Done.

## Inicialização obrigatória

Antes de modificar o projeto:

1. Ler `AGENTS.md`.
2. Ler `references/OPERATING_MODEL.md` desta skill.
3. Ler `references/QUALITY_GATES.md` desta skill.
4. Consultar a fonte canônica atual em `docs/canon/`, os contratos em `data/production/` e o estado do PR de integração.
5. Verificar se já existe implementação equivalente antes de criar outro sistema.
6. Classificar a tarefa em: auditoria, engenharia, dados/game design, visual, narrativa, gestão ou release.
7. Definir um lote vertical pequeno, testável e reversível.

## Invariantes invioláveis

- Repositório único: `ringuemkt-rgb/cria-do-tatame`.
- Não criar outro repositório do jogo.
- Main scene: `res://scenes/main_menu/MainMenu.tscn`.
- Engine alvo: Godot 4.3+, preservando gate de compatibilidade 4.2.2 enquanto necessário.
- Exatamente três facções: `LEM`, `NTM`, `ALE`.
- Núcleos operacionais são tags subordinadas, nunca facções.
- `TransitionManager` é canônico; `CombatManager` atua como fachada.
- Um único `AudioManager`.
- `DeckManager` é canônico.
- Managers de mundo permanecem separados por responsabilidade.
- Gameplay crítico deve ser determinístico e funcionar offline.
- Não versionar tokens, chaves, keystores, credenciais ou dados pessoais.

## Cânone visual permanente

- Pixel art 16-bit em alta definição, contorno preto grosso, cel-shading, rim light dourado e grade visível.
- Nunca fotografia, 3D realista ou cartoon infantil como arte final do jogo.
- Paleta exclusiva: `#0A0A0A`, `#1A1A1A`, `#B8860B`, `#F2C230`, `#F2F2F2`, `#D92323`, `#1E3A5F`, `#2D5016`, `#4B0082`.
- Facções: LEM `#D92323`; NTM `#2D5016`; ALE `#4B0082`.
- Sem texto embutido nos assets, marcas de terceiros, armas de fogo, gore ou pessoas reais.
- Produção em lotes de até dez imagens do mesmo tipo e com a mesma âncora visual.
- Um lote visual corresponde a um commit; executar QA antes do lote seguinte.

## Loop operacional

Execute sempre nesta ordem:

1. **Inventário** — identificar arquivos, sistemas, referências, testes, dependências e estado real.
2. **Diagnóstico** — separar fato confirmado, hipótese, lacuna, risco e conflito de cânone.
3. **Plano vertical** — definir objetivo, arquivos, critérios de aceite e rollback.
4. **Implementação** — reutilizar arquitetura existente; evitar duplicação e sistemas paralelos.
5. **Integração** — conectar ao fluxo oficial, save, DataRegistry, SignalBus, UI e dados quando aplicável.
6. **Validação** — executar lint, testes Python, Godot headless, auditorias e checks específicos.
7. **Documentação** — registrar decisões, migrações, limitações e uso.
8. **GitHub** — commit focado, issue/PR atualizado e evidências anexadas.
9. **Relatório** — informar entregas reais, falhas, riscos e próximo lote.

## Regras de implementação

- Preferir Strangler Fig e adapters para migrações de runtime.
- Não substituir uma API estável sem camada de compatibilidade e teste de migração.
- Dados precisam ter schema claro, IDs estáveis e referências válidas.
- Toda feature deve possuir entrada jogável ou consumidor real; classes soltas não contam como integração.
- Todo sistema persistível deve declarar versão e migração de save.
- Toda alteração em autoload exige auditoria de boot.
- Toda mudança de combate exige smoke de posição, lado, recursos, defesa e encerramento.
- Toda mudança visual exige validação de paleta, dimensão, transparência, pivô, nome, licença e integração Godot.
- Não usar LLM remoto no loop crítico de combate.

## Gestão GitHub

- Trabalhar em branch específica ou na branch de integração declarada pelo projeto.
- Nunca escrever diretamente em `main` sem autorização explícita e gates verdes.
- Commits devem ser pequenos, coerentes e usar Conventional Commits.
- Um PR não pode misturar produto externo, site, e-book ou outro jogo.
- Issues devem possuir objetivo, escopo, critérios de aceite, dependências e riscos.
- PR deve listar arquivos, testes, migrações, screenshots/logs e limitações.
- Ações destrutivas exigem backup, inventário e autorização explícita.

## Roteamento de ferramentas

Consulte `references/TOOL_ROUTING.md` antes de escolher ferramentas.

Princípios:

- GitHub para código, dados, issues, PRs e governança.
- Godot/headless e scripts locais para parser, runtime e export.
- Geração de imagem para conceitos e assets aprovados; nunca confundir geração com integração final.
- Pipeline de sprites para strips, pivôs, escala, transparência e preview.
- Pesquisa web somente para fatos externos atuais, licenças e documentação primária.
- Não enviar segredos a serviços externos.

## Gates de conclusão

Aplicar integralmente `references/QUALITY_GATES.md`.

Nenhum lote pode ser chamado de concluído quando:

- testes obrigatórios falham;
- o projeto não abre ou não faz parse;
- o fluxo principal foi quebrado;
- save/load ou migração não foi validado;
- referências ou assets estão ausentes;
- documentação contradiz o runtime;
- APK não foi realmente gerado e instalado quando a entrega exige Android;
- desempenho foi apenas estimado;
- faltam licença, atribuição ou aprovação humana necessária.

## Formato de saída obrigatório

Ao finalizar cada lote, responder com:

1. **Entregue** — resultado funcional criado.
2. **Arquivos** — criados, modificados e removidos.
3. **Validação** — comandos e resultados.
4. **GitHub** — branch, commits, issue e PR.
5. **Riscos restantes** — falhas, incertezas e dívida técnica.
6. **Próximo lote** — menor passo vertical de maior valor.

## Condições de parada

Pare e registre bloqueio quando houver:

- conflito entre fontes canônicas;
- risco de apagar trabalho útil;
- licença ou origem de asset incerta;
- biomecânica insegura ou impossível;
- credencial necessária ausente;
- ação irreversível não autorizada;
- teste que não pode ser executado no ambiente atual.

Nessas situações, não invente sucesso. Entregue a parte segura, preserve o estado e indique a evidência faltante.