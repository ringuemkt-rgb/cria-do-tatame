# Auditoria e pacote de teste — 16/09/2026

Status: ACTIVE. Base remota conferida: `8b162a6`.
Escopo entregue: destravar qualidade, testar runtime e distribuir PCK verificável.
Não representa conclusão do jogo completo.

## Alcance da revisão

Foram usados o histórico visível desta conversa, recuperação direcionada de
contexto anterior, arquivos locais e o repositório oficial. Não houve acesso
exaustivo a todos os chats privados do ChatGPT. Afirmações históricas de
"skill ativa", "arte final" ou "jogo completo" não foram aceitas como evidência.
O fetch da main confirmou a mesma base acima; branches de mapas e viagens não
foram mescladas automaticamente. Nenhum trabalho anterior foi apagado.

## Defeitos reproduzidos e corrigidos

1. `npm run quality` parava no adapter de Davi: quatro ações declaradas não
   tinham perfis (`counter_entry`, `sprawl_response`, `scramble`, `counter_whiff`).
   Foram associados perfis existentes, preservando o override obrigatório da
   assinatura, aprovação humana e `shipping=false`. Regressão percorre todos
   os personagens com contrato visual e compila todas as ações declaradas.
2. Repository Quality executava só parte do gate local. Agora chama
   `npm run quality`, com Pillow pinado e sem repetir os antigos passos cobertos.
3. O smoke completo passava no checkout, mas falhava no PCK porque a descoberta
   de cenas ignorava `.tscn.remap`. Agora resolve os caminhos originais e testa
   as cenas realmente distribuídas.
4. Faltava uma entrega leve de teste independente dos templates Android/Windows.
   O novo builder exporta PCK, testa fora do checkout, exige exit code válido,
   ausência de erros Godot e marcadores PASS, e empacota instruções, hash e logs.
   CI publica o pacote após a validação. Não é instalador nem APK.

## Evidências desta execução

| Verificação | Resultado |
|---|---|
| npm run quality | PASS após a correção |
| Importação Godot 4.2.2 | PASS, sem erro de parser |
| Runtime smoke | PASS, 115 verificações |
| Full game smoke | PASS, 174 verificações, 20 cenas |
| Progression OS | PASS, 27 verificações |
| World map life | PASS, 14 verificações |
| Grappling golden chain | PASS, 38/38 |
| PCK fora do checkout: runtime/full/progression | PASS após corrigir remap |
| Boot do menu no PCK, headless | PASS |
| Revisão gráfica do runtime | PENDING |
| Android físico | PENDING |

Os smokes exercitam sistemas e transições; não substituem uma pessoa jogando
campanha inteira, avaliando diversão, anatomia, touch ou desempenho gráfico.
Dois executáveis antigos estavam truncados; a terceira cópia íntegra identificou
`4.2.2.stable.official.15073afe3`. Nenhuma migração de engine foi feita.
`validate_qa_evidence_v1.py --release` continua bloqueando release corretamente.

## Arte disponível e lacunas

Na sessão estão disponíveis sete gerações: cinco mapas (Baixo Sul, Ituberá,
Nilo Peçanha, Valença e Camamu) e dois retratos de corpo inteiro (Ruan e Davi).
As dez imagens enviadas anteriormente pelo usuário são referências de direção.

Os mapas têm água, mangue, materiais e profundidade úteis como referência, mas
são pinturas achatadas. Repetem penhascos/ilhas/cachoeiras estilizados; não
comprovam geografia regional. Não contêm layers independentes, colisão,
navegação, estados de missão ou animação. Reduzir resolução não resolve isso.
Não há geração das cinco páginas restantes neste lote disponível.

Ruan e Davi têm silhuetas e roupas diferenciadas, mas os retratos ainda não
são identity masters aprovados, turnarounds ou sprites animados. O azul de Davi
continua candidato. Recortar um retrato não produz as ações BJJ pareadas.
As duas arenas anunciadas no último lote não chegaram a ser geradas antes da
mudança de tarefa. Nenhuma dessas imagens foi promovida para shipping aqui.

O ledger de coverage registra 706 requisitos pendentes, nenhum vínculo final
integrado e duas fontes ausentes: `data/combat/cards_v1.json` e
`data/bjj/bjj_knowledge_graph_v1.json`. Isso não
significa ausência de gráficos de protótipo: significa ausência de evidência
de promoção final no pipeline atual.

## Skills e ferramentas: operação econômica

Autoridade continua em contratos, decisões e runtime. A skill disponível
`build-cria-rpg-engine` organiza a execução; não altera os pesos do modelo.
As cinco skills locais são direção de arte, Sprite Forge, inteligência de
combate, Motion Lab e inteligência de vídeo público
(inventário exato em `.agents/skills/`). Não foi criada outra skill-mãe.

Carregar apenas a especialidade necessária: runtime/build para defeito de
execução; arte + Forge para fabricação; combate para semântica BJJ; Motion Lab
e pesquisa de vídeo somente quando houver material autorizado a processar.
Ferramentas do registry externo permanecem opcionais. Estar listado não prova
instalação, licença de asset, execução ou benefício para a build.

Este lote não usou geração de imagem, GPU remota, modelo pago adicional nem
agentes paralelos. Usou validadores e Godot locais. Os custos totais da conta
não são mensuráveis a partir desta auditoria.

## Caminho restante até o jogo completo

1. Jogar o pacote e registrar falhas observáveis do fluxo Ruan × Davi.
2. Fechar a primeira técnica pareada e as identidades Ruan/Davi; preservar
   contato, pivô, timing e transição real antes de multiplicar técnicas.
3. Produzir Terreiro/Dique em camadas e vinculá-los às cenas existentes.
4. Validar visual/touch no runtime e exportar APK com SDK/templates disponíveis;
   instalar em aparelho físico e medir save/resume, legibilidade e frame pacing.
5. Expandir campanha e conteúdo por unidades integradas, obedecendo às fontes
   atuais; não misturar contagens históricas com metas do contrato supremo.

Não há evidência suficiente para declarar campanha completa, jogabilidade
perfeita, arte final, desempenho Android aprovado ou RELEASE_READY.
