# Ground + Submission System V1

**Status:** ACTIVE

Este pacote transforma as diretivas `/ctt.combate.ground.v1` e `/ctt.submission.anatomia.v1` em runtime jogável sem duplicar a arquitetura existente. `CombatStateMachine.gd` continua sendo a única máquina posicional; `ground_graph_v01.json` é o contrato que relaciona suas posições às 21 técnicas do catálogo atual.

## Fluxo executável

```text
técnica válida no estado atual
→ GroundGraphRules confirma a aresta
→ TechniqueResolver resolve custo/chance/clash
→ CombatStateMachine muda a posição
→ uma entrada de finalização abre SubmissionExchange
→ atacante constrói controle; defensor constrói escape ou bate tap
→ tap / escape / soltura / intervenção / tempo-pontos
→ recuperação na posição de origem ou resultado da luta
```

O setup de `chave_braco`, `triangulo` e `mata_leao` não reduz vida diretamente. Ele abre uma troca determinística por turnos. O encerramento legado permanece apenas para compatibilidade e teste de regressão enquanto telas antigas são migradas.

## Anatomia como metadado seguro

`submissions_anatomy_v01.json` contém 12 famílias anatômicas abstratas para orientar:

- validação de regras Gi/No-Gi;
- sincronização de atacante e defensor;
- enquadramento visual e região de foco;
- família de resposta do gameplay;
- revisão humana de BJJ.

O arquivo deliberadamente não contém sequências de aplicação, “vetores de escape”, instruções de treino nem recompensa por lesão. O HUD mostra controle técnico e progresso de escape, reforça o tap e nunca exibe um medidor de dano articular.

## Regras e segurança

A versão de produção deve revisar o snapshot quando a IBJJF publicar atualização. A página oficial lista o Rule Book v6.0 e materiais de atualização: [IBJJF Books and Videos](https://ibjjf.com/books-videos). A atualização oficial de 2021 restringiu heel hook e knee reaping ao adulto marrom/preta No-Gi: [IBJJF New Rules Updates](https://ibjjf.com/news/new-rules-updates). Por isso, `heel_hook` permanece desativado e exige um gate explícito; nunca existe um booleano global “vale tudo”.

O contrato também trata segurança como requisito de produto. Estudos observacionais indicam que lesões em BJJ se concentram no treino/sparring e em eventos de submissão, apoiando tap precoce e tempo para resposta ([survey de praticantes](https://pmc.ncbi.nlm.nih.gov/articles/PMC8721390/)). Relatos de lesão vascular após estrangulamentos esportivos são raros, mas graves, portanto o jogo encerra em tap, soltura ou intervenção e não glorifica perda de consciência ([revisão/casos](https://pubmed.ncbi.nlm.nih.gov/35934648/)).

## Integração visual e Android

`SubmissionHUD.tscn` ocupa temporariamente o trilho tático direito da composição de referência. Ele usa o mesmo preto/dourado, tipografia runtime e barras de alto contraste do `CriaVisualTheme`. As ações continuam nos cinco botões inferiores de 64 px, preservando touch Android e o palco central limpo para os dois corpos.

## Fronteira de fontes externas

Bases de grafos e poses externas são fontes de pesquisa, não autoridades de runtime. Qualquer importador deve gerar um pacote candidato isolado contendo licença, proveniência, mapeamento de taxonomia e relatório de revisão humana. Nenhuma aresta externa substitui automaticamente o grafo canônico ou entra em asset shipping.

Próxima diretiva segura: `/ctt.stamina.ground.v1`, calibrada por estado e por ação, depois de o exchange passar smoke no Godot e playtest humano.
