# Roadmap Oficial — Cria do Tatame – Pressão

**Status:** ACTIVE  
**Atualizado:** 2026-08-01  
**Fonte:** `main` + inventário dos PRs abertos.

## Princípio

A prioridade é fechar um vertical slice excelente antes de expandir o elenco e o mundo. Sistemas, arte e documentação só contam quando estão integrados ao fluxo jogável.

## Marco 0 — Repositório profissional

**Objetivo:** tornar o repositório a fonte única, com governança, templates e gates claros.

- [x] Política de contribuição;
- [x] CODEOWNERS;
- [x] templates de issue e PR;
- [x] índice documental;
- [x] governança validável por máquina;
- [ ] revisar e classificar todas as branches;
- [ ] decidir destino de todos os PRs abertos;
- [ ] remover branches temporárias somente após absorção ou descarte registrado;
- [ ] configurar proteção de `main` na interface do GitHub.

**Saída:** ninguém inicia trabalho sem saber base, ordem de integração, teste e Definition of Done.

## Marco 1 — Integração canônica v4

**Objetivo:** portar o conteúdo útil do PR #32 em lotes pequenos e seguros.

Ordem:

1. cânone e contratos executáveis;
2. migração de três facções e save;
3. dados de 20 cartas, posições e rulesets;
4. adapter de combate sem segundo singleton;
5. Arena v4 e Submission HUD;
6. economia, mapa, informante e finais;
7. terrain modifiers e acessibilidade.

Cada lote deve passar `npm run quality`, parser/import e smoke específico antes do próximo.

**Saída:** `main` contém o runtime v4 sem regressão do fluxo já funcional.

## Marco 2 — Vertical slice ouro Ruan × Davi

**Objetivo:** entregar o fluxo completo representativo da qualidade final.

Fluxo obrigatório:

```text
Menu
→ Novo jogo/load
→ Terreiro
→ diálogo/treino
→ desbloqueio e deck
→ Arena do Dique
→ luta Ruan × Davi
→ defesa/finalização/pontos
→ resultado
→ Cria Live
→ retorno ao Terreiro
→ save/reload
```

Critérios:

- touch completo;
- ao menos cinco posições legíveis;
- janela de defesa e Submission HUD;
- sprites pareados e sincronizados;
- Arena do Dique com camadas finais representativas;
- áudio original/licenciado e mixado;
- sem placeholder nas ações obrigatórias;
- acessibilidade básica;
- Android físico com mínimo sustentado de 45 FPS.

## Marco 3 — Act 1 vertical

**Objetivo:** provar carreira, mundo e produção repetível.

- seis personagens completos;
- seis arenas;
- vinte técnicas pareadas;
- tutorial e primeiras missões;
- mapa navegável;
- treino, recuperação, lesão e progressão;
- facções LEM, NTM e ALE funcionais;
- Cria Live e consequências;
- abertura e encerramento do Ato 1.

A expansão ocorre em pacotes: **rival + arena + técnicas + áudio + missão + QA**.

## Marco 4 — Campanha completa

Metas do contrato supremo:

- 18 personagens;
- 15 arenas;
- 50 técnicas pareadas;
- 40 missões;
- 5 atos;
- 5 finais;
- 18 telas de UI;
- 100 SFX;
- 20 músicas;
- 12 ambiências.

Nenhum pacote entra em shipping sem licença, QA e integração.

## Marco 5 — Certificação e release candidate

- Godot 4.3 validado;
- Android ARM64 e Windows reproduzíveis;
- matriz de aparelhos fraco/intermediário/forte;
- instalação, atualização e reinstalação;
- perfil de FPS, memória, temperatura, bateria e tamanho;
- save e migração entre versões;
- acessibilidade;
- auditoria de licenças;
- loudness e mixagem;
- keystore segura fora do Git;
- artefatos assinados e hashes publicados.

## Regra de prioridade

1. P0 — boot, save, fluxo principal e integração;
2. P1 — vertical slice, touch, combate e assets representativos;
3. P2 — Act 1 e expansão vertical;
4. P3 — campanha completa e polimento;
5. P4 — funcionalidades opcionais, serviços remotos ou cosméticos.

Multiplayer, NFT, IA remota e expansão massiva não podem ultrapassar o combate offline, o touch e o vertical slice na fila.
