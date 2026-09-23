# Aplicação ao Cria do Tatame

## Autoridade e retomada

Repositório oficial: `ringuemkt-rgb/cria-do-tatame`.
Ler o `AGENTS.md` atual e cumprir sua inicialização. Esta skill é auxiliar
de eficiência; não substitui contratos, cânone, direção de arte ou combate.
Não criar outra engine, outro runtime ou novos managers equivalentes.

Para a retomada seguinte, conferir o estado real do PR #138 e da main. Em
16/09/2026, esse PR continha correções de QA de Davi, paridade CI/local e
builder de PCK. Esse registro é histórico, não prova de merge ou CI atual.
Não reproduzir o conserto se já foi integrado.

## Roteamento econômico

| Trabalho | Carregar quando necessário | Evidência útil |
|---|---|---|
| Boot, input, save e pacote | build-cria-rpg-engine e governança local | Importação, fluxo, roundtrip, artefato exportado |
| Estado/técnica/IA BJJ | cria-combat-intelligence | Legalidade, determinismo, counters e regressão |
| Identidade/cenário/UI | cria-art-direction | Cânone, legibilidade, referência e revisão visual |
| Sprites/animação | Direção + cria-sprite-forge; combate se BJJ | Frames reais, pivô, sync, contato e integração |
| Captura/pose/mocap | cria-grappling-motion-lab | Material autorizado e evidência física revisada |
| Pesquisa de vídeos | cria-public-video-intelligence | Pergunta concreta, source ledger e direitos |

Localizar os arquivos reais antes de invocar. Skills especializadas indisponíveis
devem ser reportadas; uma referência textual não equivale a uma ferramenta.

## Prioridade por entrega

1. Corrigir falha reproduzível que bloqueia abrir, controlar, lutar ou salvar.
2. Validar o pacote distribuído, não apenas o checkout.
3. Fechar Ruan × Davi: identidade, técnica pareada, feedback, Terreiro/Dique.
4. Testar toque, retorno do app e persistência no Android físico quando houver
   aparelho e build; não substituir evidência física por inferência.
5. Expandir conteúdo pelo pipeline que já funciona, em pacotes integrados.

Essa ordem é padrão de projeto, não licença para ignorar pedido específico
atual. Se o usuário pedir uma arena, produza a arena com seus critérios.

## Arte e completude

Mapa achatado = concept/base candidata. Sua decomposição precisa de layers
endereçáveis, navegação/colisão de dados e integração real. Retrato não é sheet
de animação. GIF é preview, não prova isolada de funcionamento em Godot.
Não transformar geração em aprovação humana; mantenha `shipping=false`
enquanto faltarem gates. Não usar screenshots como prova de gameplay completo.

Reutilizar o ledger de coverage e a matriz existentes. Quantidade de requisitos
pendentes não é quantidade exata de horas, falhas de runtime ou percentual de
produto faltante. Distinguir gráficos de protótipo de assets finais validados.

## Sessão econômica sugerida

- Entrada: revisão atual, diff relevante, objetivo e bloqueio.
- Trabalho: implementação existente + uma especialidade necessária.
- Saída: avanço integrado, teste e evidência recuperável.
- Checkpoint: estado para que a próxima sessão não repita a investigação.

Manter planos curtos no diálogo e detalhe nos arquivos existentes. Não criar
uma nova camada de "Production OS" para cada retomada. Só ampliar ferramentas
quando um problema medido exigir capacidade ausente.
