# AGENTS.md — Cria do Tatame

Este arquivo orienta Codex, Manus, agentes locais e qualquer assistente automatizado que trabalhe neste repositório.

## 0. PROTOCOLO MESTRE DE CONSTRUÇÃO — vinculante

Toda construção deste jogo segue `docs/GAME_BUILD_PROTOCOL.md`.

Regras resumidas:

- iniciar cada iteração com Handshake de Abertura: estado ao vivo do repo, PRs, CI e delta;
- seguir o loop verificar → diagnosticar → decidir → instruir → commitar → reverificar → fechar gate;
- uma feature corresponde a um PR vertical; usar Conventional Commits; CI é porteiro;
- respeitar stacked PRs e não integrar filho sem base validada;
- prancha densa não é sprite; design aprovado não é runtime; rótulos de pronto exigem evidência;
- Godot é o único runtime; existem exatamente três facções; sem gacha, poder por Molho ou finalização automática;
- em conflito, seguir `docs/DOC_PRECEDENCE.md` e interromper a implementação até reconciliação.

Assistentes sem memória persistente carregam estes arquivos em toda sessão:

1. `docs/GAME_BUILD_PROTOCOL.md`;
2. `docs/DOC_PRECEDENCE.md`;
3. `.agents/skills/cria-do-tatame-game-director/SKILL.md`;
4. módulos `references/` da skill;
5. contrato SUPREME e cânone aplicável ao lote.

Validar a ativação com:

```bash
python .agents/skills/cria-do-tatame-game-director/scripts/validate_skill.py
```

## Skill operacional obrigatória

Para qualquer tarefa de construção, continuidade, auditoria, arte, narrativa, gestão, QA ou release do jogo, carregar e seguir:

`.agents/skills/cria-do-tatame-game-director/SKILL.md`

Também são obrigatórios os módulos referenciados pela skill:

- `references/OPERATING_MODEL.md`;
- `references/QUALITY_GATES.md`;
- `references/TOOL_ROUTING.md`.

A skill orquestra a execução do protocolo e não substitui as fontes canônicas.

## Missão

Construir **Cria do Tatame – Pressão**, jogo Godot 4.3+ para Android, PC e Web, preservando compatibilidade 4.2.2 enquanto o gate legado permanecer ativo, com combate tático de Jiu-Jitsu Brasileiro, carreira, reputação, mundo vivo do Baixo Sul da Bahia e identidade visual pixel art preto/dourado premium.

## Fonte única de verdade

`ringuemkt-rgb/cria-do-tatame` é o único repositório oficial do jogo.

- Não criar outro repositório para protótipo, APK, arte, lore ou versão alternativa.
- Protótipos devem viver em branches ou pastas explicitamente delimitadas.
- Documentos antigos não podem substituir dados e bíblias canônicas atuais.
- Antes de criar algo, procurar implementação equivalente neste repositório.

## Regra de ouro

Não transformar o projeto em galeria de arte. Primeiro deve abrir, rodar, salvar, lutar, avançar a semana e exportar.

## Cânone inviolável

- Protagonista: Ruan “Macacão” Silva.
- Símbolo: Gorila Silverback.
- Origem: Ituberá, Baixo Sul da Bahia.
- Estilo: pressão pesada, grip de ferro, top game dominante.
- Poder: Silverback Grip.
- Frase eixo: Ser forte é ser gentil.
- Facções: exatamente `LEM`, `NTM` e `ALE`.

Qualquer referência antiga a Caio Ravel ou Ruan “Cria” é legado e não deve ir para UI, campanha principal ou dados finais.

## Ordem técnica obrigatória

1. Executar o Handshake do protocolo.
2. Executar `npm run validate:skill`.
3. Executar `npm run quality` quando o ambiente permitir.
4. Garantir que `project.godot` abre no Godot suportado pelo lote.
5. Ligar e validar autoloads.
6. Preservar o fluxo Main Menu → Terreiro → Combate → Resultado → Save.
7. Implementar combate por posição e lado relativos de BJJ.
8. Integrar carreira semanal, reputação, Cria Live, facções e patrocinadores.
9. Só depois polir sprites, áudio, VFX e cutscenes.

O escopo completo e os gates de produção vivem em `docs/CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md`, `docs/GAME_BUILD_PROTOCOL.md`, nos documentos canônicos atuais e em `data/production/supreme_build_contract_v01.json`.

## Contratos de arquitetura

- Gameplay crítico deve ser determinístico e executável offline.
- IA pode criar, revisar e classificar conteúdo; não pode sustentar o loop principal em tempo real.
- Dados em `data/` precisam manter IDs estáveis e referências válidas.
- Sistemas novos devem possuir ponto de entrada claro, teste ou checklist e documentação mínima.
- Código temporário deve conter prazo ou condição objetiva de remoção.
- Não criar singleton, manager, deck, áudio ou cânone paralelo.

## Restrições

- Não usar assets comerciais sem licença.
- Não copiar jogos existentes.
- Não criar sistema de soco/chute genérico como núcleo.
- Não afirmar APK pronto sem build validado.
- Não apagar arquivos úteis sem relatório de migração.
- Não introduzir segunda engine, segundo cânone ou segundo backend de conteúdo.
- Não versionar segredos, chaves, tokens, keystores ou credenciais.

## Saída esperada de cada agente

Todo agente deve entregar:

1. arquivos criados;
2. arquivos modificados;
3. testes executados;
4. erros encontrados;
5. riscos ou dívidas técnicas;
6. próximo passo recomendado.

## Protocolo de autonomia

- Trabalhar em lotes verticais jogáveis e commits focados.
- Executar o validador da skill e os gates aplicáveis antes e depois de cada lote.
- Usar ferramentas externas somente nas funções autorizadas pelo contrato supremo, protocolo e skill.
- Fixar versão e auditar licença antes de incorporar ferramenta externa.
- Parar diante de conflito de cânone, licença incerta, biomecânica insegura, credencial ausente ou ação destrutiva.
- Nunca confundir conceito, placeholder, mockup ou fila de produção com asset final integrado.