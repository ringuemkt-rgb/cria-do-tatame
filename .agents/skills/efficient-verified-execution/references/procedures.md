# Procedimentos sob demanda

Leia apenas a seção relacionada ao bloqueio atual. Os exemplos não impõem
um número fixo de chamadas, agentes, testes ou tokens.

## 1. Retomada e memória de trabalho

Prioridade de recuperação:

1. Pedido atual e decisões explícitas já presentes na conversa.
2. Instruções do projeto e checkpoint mais recente com revisão identificada.
3. Estado do checkout, diff e arquivos consumidores da área afetada.
4. Histórico direcionado somente para decisões ausentes que mudariam a ação.

Não pedir ao usuário para recontar informação recuperável. Não afirmar acesso
integral a chats inacessíveis. Se uma memória disser "feito", localizar o
arquivo, commit ou artefato correspondente antes de usar como fato.

Checkpoint mínimo, apenas quando a tarefa justificar persistência:

```yaml
objective: resultado ainda procurado
revision: commit ou versão observada
working_changes: caminhos e finalidade
verified: comando, resultado, ambiente e caminho da evidência
pending: limitações ou trabalho não executado
next_action: próximo passo concreto
authorization: limites relevantes já estabelecidos pelo usuário
```

Não salvar credenciais ou dumps de contexto. Preferir atualizar o registro
ativo a acumular relatórios que dizem a mesma coisa. Uma retomada lê o resumo
e confirma as dependências; só abre logs completos quando precisa diagnosticar.

## 2. Busca e leitura econômica

Comece com descoberta de caminhos/nomes e buscas específicas. Leia o arquivo
completo quando suas regras exigirem, ou quando um trecho não bastar para
entender invariantes e efeitos. Não fazer amostragem que omita autoridade.

Para respostas extensas de ferramentas, solicite campos e limites adequados.
Guarde o resultado completo quando necessário, mas exponha no contexto apenas
o que sustenta a decisão. Erros e exceções relevantes não devem ser truncados.

Agrupe leituras independentes; mantenha mutações e suas dependências em ordem.
Antes de repetir uma leitura, pergunte qual informação mudou ou ficou faltando.
Depois de uma busca sem resultados, mude a hipótese ou o escopo, não repita a
mesma consulta com palavras equivalentes indefinidamente.

## 3. Engenharia e depuração

Fluxo preferido: reproduzir → localizar consumidor → corrigir causa → verificar
cenário afetado → gates obrigatórios → integração → pacote de entrega.

| Situação | Ação econômica que preserva qualidade |
|---|---|
| Falha conhecida reproduzível | Ler stack/log e dependência direta antes de auditar toda a árvore |
| Dado sem referência | Corrigir autoridade e consumidor; evitar um segundo catálogo |
| Mudança isolada | Teste direcionado primeiro; suíte completa no gate requerido |
| Pacote funciona só no checkout | Executar artefato fora da árvore de fontes |
| Build falhou | Preservar logs e impedir que artefato velho pareça build nova |
| PR já contém solução | Inspecionar diff/base/testes antes de reimplementar |
| Testes passaram, visual desconhecido | Declarar limite; executar revisão visual quando possível |

Um teste novo deve detectar risco real, não espelhar linhas da implementação.
Não reexecutar toda a suíte após mudança exclusivamente editorial sem motivo,
exceto se instruções vinculantes exigirem. Não suprimir falha de regressão para
encerrar o lote. Preserve alterações alheias e use branch/worktree apropriado.

## 4. Validade de evidência

Considere quatro dimensões: revisão de código, inputs/dados, versão da
ferramenta e ambiente relevante. Um PASS só cobre o cenário observado.

- Editou shader: a validação JSON continua útil; a captura visual pode caducar.
- Editou migração de save: repetir roundtrip e compatibilidade de versões.
- Mudou exportador/engine: repetir importação e testes do artefato.
- Alterou só a explicação da entrega: não inventar invalidação do gameplay.
- O teste verifica estrutura: não converter em prova de completude de conteúdo.

Registre diferenças, não percentuais arbitrários de conclusão. Uma imagem
com nome de arena não prova colisão, animação, missão ou integração.

## 5. Pesquisa externa

Defina a dúvida que bloqueia uma decisão e o critério que a resolve. Consulte
fontes primárias e atuais quando necessário. O melhor momento para encerrar
é quando a evidência permite a decisão, não quando todas as fontes possíveis
foram coletadas. Reabra a busca diante de contradição relevante.

Não pesquisar um framework inteiro para resolver um erro de um campo JSON.
Não instalar uma dependência só porque é popular. Para uma candidata, avaliar:
compatibilidade, licença, custo de integração, testes e benefício observável.
Comparar com a implementação existente. Se não houver ganho verificável,
registrar a decisão curta e continuar a construção.

## 6. Geração visual e serviços com custo

Antes de gerar, confirmar ID/objetivo, referência correta, enquadramento,
dimensões, uso final e critérios de aceitação. Reutilizar assets autorizados
quando isso atende ao pedido; não reutilizar para evitar criação explicitamente
solicitada. Um lote de assets distintos pede briefs distintos.

Produzir uma amostra representativa quando a consistência do lote ainda é
incerta. Inspecionar antes de multiplicar variantes. Se falhou por identidade,
anatomia ou composição, ajustar uma causa concreta. Não gerar dezenas de
tentativas sem comparar resultados. Preservar fonte e candidato anterior.

Quotas e rate limits não autorizam contorno por outra conta/provedor. Explicar
bloqueio real, preservar progresso e usar somente alternativas autorizadas.
Não declarar custo zero: ausência de API externa não prova ausência de cobrança.

## 7. Uso de agentes e modelos

Usar somente capacidades disponíveis e delegação autorizada pelas instruções.
Não criar agentes para dar aparência de produção. Uma frente delegada deve
ter resultado delimitado, arquivos/dados necessários e critério de retorno;
o agente principal deve ter trabalho independente útil durante a execução.

Evitar forks completos de histórico quando um breve contrato basta. Não
delegar a mesma análise para vários agentes sem necessidade concreta de revisão
independente. Não afirmar mudança de modelo ou esforço interno sem controle
disponível e execução comprovada. "Astra 6" não é uma configuração desta skill.

## 8. Falhas e recuperação

Distinguir erro transitório, dado incorreto, permissão ausente e defeito do
produto. Um retry deve ter motivo (serviço recuperado, input corrigido, rota
autorizada disponível). Não repetir ação externa não idempotente sem verificar
se a primeira tentativa já produziu efeito.

Se uma credencial ou aparelho físico impedir o próximo passo, concluir antes
o trabalho independente útil. Relatar exatamente o que bloqueia a entrega,
o que já existe e a ação humana mínima necessária. Não pedir autorização genérica.

## 9. Controle de gasto sem telemetria fictícia

Quando disponíveis, observar chamadas, tempo, retries, bytes/tokens reportados,
execuções pagas e resultados entregues. Na ausência de medição, usar descrição
qualitativa: "reutilizei a validação desta revisão" ou "não gerei novas imagens".

Não estimar créditos pela quantidade de palavras da resposta, não prometer
economia de 50/90%, e não tratar um resumo curto como redução garantida da
cobrança total. O objetivo verificável é eliminar operações redundantes.

## 10. Evolução controlada

Ao observar retrabalho recorrente, registrar caso, causa e mudança proposta.
Alterar o menor procedimento que trata a causa. Validar cenário anterior e
um caso em que a nova regra não deve se aplicar. Versionar e manter rollback.
Não absorver cada exceção como regra global. Remover instrução substituída
somente após inspecionar seu uso. Melhorias acontecem durante tarefas ativas,
não num processo autônomo permanente presumido.

## 11. Exemplos de decisão

- "Continue o jogo": confirmar revisão e último bloqueio, executar próximo
  incremento e suas verificações; não reler todos os chats por padrão.
- "Revise todos os chats": recuperar o que é acessível, declarar alcance e
  comparar promessas com artefatos; não afirmar exaustividade impossível.
- "Gere todas as arenas": extrair lista canônica, briefs e dependências,
  produzir/avaliar os assets solicitados; não substituir por um manifesto.
- "Garanta perfeição": traduzir em critérios de teste verificáveis e limites,
  sem prometer ausência absoluta de defeitos.
- "Economize créditos": cortar chamadas redundantes; preservar requisitos,
  conteúdo e validação; não mudar silenciosamente a plataforma/modelo.
