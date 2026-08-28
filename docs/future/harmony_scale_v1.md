# PÓS-SLICE — referência (D232/D233)

Status: `future_reference_only`
Ativação no runtime: proibida enquanto o slice Harmony de seis técnicas não estiver validado em aparelho e nos gates humanos.

## Pergunta governante

Antes de ampliar qualquer camada, responder: **isto é necessário para provar o slice jogável agora?** Se não, permanece neste documento. A escala não altera `data/techniques.json`, deck, save, cenas ou autoloads.

## Escala para 50 técnicas

A expansão reaplica o molde 1:1 da D238 a cada técnica: um ID existente e único em card, runtime ms, sync map, HUD e mastery. Nenhum alias silencioso é aceito. O lote de cada técnica precisa trazer:

- fonte canônica e ruleset fictício aplicável;
- captura consentida e hashes;
- sequência pareada com sucesso, defesa e recuperação;
- contatos revisáveis e soltura segura;
- elegibilidade, custo e janela em ms definidos pelo runtime;
- apresentação legível a 72 px;
- sidecars de licença e derivação;
- gates 01–03 pendentes antes de qualquer integração.

O planejamento usa lotes de no máximo 20 itens, mas cada técnica continua uma unidade rastreável. Técnicas de finalização exigem ramo TAP/escape/árbitro e nunca recompensam lesão.

## Classificador futuro

O classificador é uma ferramenta offline de triagem, não um árbitro técnico. Entradas permitidas: keypoints normalizados, MOT, contatos confirmados e metadados de fase. Saídas permitidas: família provável, fase provável, confiança, articulações ausentes e candidatos a revisão.

Regras:

- baixa confiança produz `unknown`, não adivinhação;
- nenhum rótulo muda o ID canônico;
- divisão treino/teste é separada por sessão e performers para evitar vazamento;
- relatório inclui matriz de confusão por família e por fase;
- pessoa, academia, marca e organização real não viram classe do produto;
- inferência não entra no runtime nem no save.

## AQA — Animation Quality Audit

AQA agrega gates mensuráveis sem substituir revisão humana:

1. integridade de schema e identidade 1:1;
2. continuidade temporal em ms;
3. origem compartilhada e contato com trajetória;
4. apoio, centro de massa e ausência de interpenetração;
5. preservação de silhueta e leitura a 72 px;
6. paleta, outline e fringe magenta;
7. fidelidade pose/evidência com limites declarados por lote;
8. licença, hashes, seed e workflow;
9. segurança de queda, finalização e soltura;
10. assinatura humana BJJ/Animação/Arte.

Um score agregado serve apenas para ordenar revisão. Falha de segurança, licença, identidade, TAP ou decisão canônica é veto, independentemente da nota.

## Quarentena SMPL/SCAIL

SMPL e SCAIL não são dependências, ferramentas aprovadas, fontes de verdade nem caminhos de geração. Qualquer pesquisa futura fica isolada, sem import, peso, download, container, chamada de rede ou artefato distribuível. A retirada da quarentena exigirá decisão gravada, auditoria de licença e lote próprio.

## Gate de entrada futuro

A escala só pode sair deste arquivo após: slice device-validated; seis técnicas-ouro com gates 01–03 assinados; TAP físico comprovado; CI verde; decisão explícita no repositório; orçamento e fila aprovados. Até lá, 50 técnicas, classificador e AQA são referência pós-slice.
