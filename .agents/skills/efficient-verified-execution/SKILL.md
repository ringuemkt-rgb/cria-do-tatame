---
name: efficient-verified-execution
description: Execute tarefas longas de construção, correção e retomada de projetos com economia de contexto e chamadas, reutilizando evidência válida e carregando especialidades sob demanda. Use quando o usuário pedir autonomia com baixo gasto de tokens/créditos, especialmente no Cria do Tatame. Não substitui as regras do projeto nem os testes necessários.
---

# Execução eficiente com evidência

## Objetivo

Reduzir retrabalho e custo por resultado útil verificado. Uma resposta curta
que deixa o trabalho incompleto não é economia. Um documento longo que repete
instruções já disponíveis também não é ganho de capacidade.

Esta skill organiza decisões e uso de ferramentas. Não muda modelo, pesos,
janela de contexto, limite da conta, preço, quota ou esforço interno. Não
prometer perfeição, ativação global em outros chats ou percentual de economia.

## Núcleo de execução

1. Identifique entrega observável, restrições atuais e próximo bloqueio real.
   Preserve o pedido completo; um lote organiza a execução, não reduz o escopo.
2. Consulte instruções vinculantes e estado atual do projeto. Retome por
   checkpoint/commit/diff; não reconstrua todo o histórico por padrão.
3. Carregue apenas a skill especializada exigida pelo trabalho escolhido.
   Nome no catálogo ou lembrança de conversa não prova instalação nem execução.
4. Reutilize evidências enquanto código, inputs, engine e ambiente relevantes
   forem os mesmos. Se algo mudou, invalide só o que depende dessa mudança,
   sem dispensar gates obrigatórios do projeto.
5. Execute o menor conjunto de operações que resolve o bloqueio e verifica
   o resultado. Amplie a investigação quando houver falha ou incerteza material.
6. Prossiga para os próximos passos autorizados até entregar o objetivo ou
   encontrar um bloqueio concreto. Não pare para pedir autorização já dada.
7. Preserve um checkpoint quando necessário para retomada: resultado, revisão,
   evidências, falhas abertas e próxima ação. Atualize o registro existente.
8. Comunique resultado, teste e limitação material com concisão. Não despeje
   logs, catálogo de ferramentas, raciocínio interno ou conteúdo já conhecido.

## Seleção de detalhe

- Tarefa simples: resolva diretamente com este núcleo.
- Trabalho extenso, pesquisa, geração cara ou retomada: consulte somente as
  seções necessárias de [procedures.md](references/procedures.md).
- Cria do Tatame: consulte [cria.md](references/cria.md) e as autoridades locais.
  A referência orienta o trabalho; não congela estado de branch, PR ou engine.

## Limites que preservam qualidade

- Não trocar versão/modelo, remover teste, reduzir qualidade visual ou alterar
  conteúdo pedido só para economizar. Explique tradeoff material quando existir.
- Não fazer geração paga especulativa, retries idênticos sem diagnóstico,
  pesquisa sem pergunta definida ou delegação duplicada do mesmo problema.
- Não inferir aprovação visual, rights, teste físico ou release a partir de
  validação estática. `PENDING` e `UNKNOWN` continuam resultados legítimos.
- Não converter números de tokens aproximados em créditos ou dinheiro sem
  telemetria e regra de cobrança verificáveis. Registre consumo desconhecido.
- Não omitir leitura obrigatória, busca necessária ou evidência crítica em
  nome de um orçamento arbitrário. Não criar regras superiores às do projeto.
- Melhorar esta skill somente com falha observada e mudança reversível,
  validada e versionada; nunca alegar autoaperfeiçoamento contínuo em background.
