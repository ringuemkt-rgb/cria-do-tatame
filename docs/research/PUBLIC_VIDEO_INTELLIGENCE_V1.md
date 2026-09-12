# Public Video Intelligence V1

## Objetivo

O CRIA DO TATAME passa a tratar vídeos públicos de lutas, aulas e campeonatos como uma camada de inteligência observacional, não como um banco de assets ou autorização implícita para download/treino.

O sistema deve conseguir escolher sozinho o que pesquisar, ranquear fontes, extrair o que o ambiente realmente permite observar, cruzar achados com regras/BJJ graph e devolver apenas o delta relevante para o projeto.

## Princípio central

```text
URL pública != permissão
metadata != transcript
transcript != observação visual
observação visual != biomecânica gold
biomecânica observada != regra/canon
referência pública != direito de treinar/retargetar/shippar asset
```

## Fontes YouTube

Use a API oficial do YouTube para descoberta/metadados quando disponível.

Referências operacionais oficiais:

- Search API: `https://developers.google.com/youtube/v3/docs/search/list`
- Video metadata: `https://developers.google.com/youtube/v3/docs/videos/list`
- Caption download: `https://developers.google.com/youtube/v3/docs/captions/download`
- Terms of Service: `https://www.youtube.com/t/terms`

Fato operacional importante: a API oficial de captions exige autorização e permissão de edição do vídeo para download da faixa. Portanto, ela não é um caminho genérico para baixar legendas de vídeos públicos de terceiros.

Também não se cria um downloader/scraper automático de YouTube como parte deste sistema. Quando o audiovisual de um terceiro só pode ser visto dentro do player/plataforma, a análise visual depende de uma superfície autorizada de visualização no ambiente de execução. Se isso não existir, a fonte fica `VISUAL_ACCESS_UNAVAILABLE` e o diretor escolhe outra.

## Arquitetura

```text
PROJECT GAPS
    ↓
QUERY PLANNER
    ↓
AUTHORIZED DISCOVERY / METADATA
    ↓
RIGHTS + ACCESS CLASSIFICATION
    ↓
INFORMATION GAIN RANKING
    ↓
┌─────────────────────────────┐
│ metadata only               │ → METADATA_ONLY
│ transcript legitimately     │ → TRANSCRIPT_ONLY / transcript evidence
│ audiovisual legitimately    │ → timestamped visual observations
└─────────────────────────────┘
    ↓
SIX-PHASE / EXCHANGE ANALYSIS
    ↓
RULES + BJJ GRAPH CROSS-CHECK
    ↓
MULTI-SOURCE TRIANGULATION
    ↓
PROJECT IMPACT
    ↓
GAMEPLAY / MOTION / SPRITE / RESEARCH PRIORITY
```

## O que o diretor decide sozinho

O usuário não precisa selecionar:

- qual técnica pesquisar primeiro;
- qual atleta/campeonato procurar;
- qual fonte duplicada descartar;
- se vale mais uma luta completa ou uma aula para resolver uma lacuna;
- qual fonte tentar depois de uma URL inacessível;
- qual observação merece cross-check;
- quais achados afetam gameplay, Motion Factory ou Sprite Forge.

A função `tools/research/plan_public_video_research_v1.py` deriva as próximas pesquisas diretamente da golden chain e do ledger já acumulado.

## Competition lane

Para lutas reais, registrar quando observável:

- posição inicial e mudanças de iniciativa;
- entry de queda, clinch, guard pull ou scramble;
- passagem, sweep, controle, escape, submission attempt;
- tempo de estabilização;
- contra-ataques e falhas;
- score/referee/boundary events;
- repetições de padrões;
- sinais de custo físico relevantes ao modelo de fatigue;
- contexto GI/No-Gi e ruleset.

Highlights muito curtos recebem penalidade porque cortam preparação, falha, estabilização e recuperação.

## Instruction lane

Para vídeo-aulas, separar rigorosamente:

`o que o instrutor afirma` de `o que é visualmente observável`.

Extrair apenas síntese transformada:

- pré-requisitos;
- grips/ties;
- base/cabeça/quadril;
- frames/wedges;
- sequência mecânica;
- erros comuns;
- counters;
- GI/No-Gi;
- segurança;
- timestamps.

Não copiar longos trechos de transcrição nem reproduzir a aula.

## Championship lane

Para campeonatos:

- ruleset/divisão;
- mapa de posições recorrentes;
- técnicas/counters recorrentes;
- scoring-event candidates;
- estilos de atletas;
- situações raras mas game-critical;
- cobertura atual do BJJ graph;
- gaps de gameplay.

Frequências derivadas de amostras pequenas devem permanecer `candidate`, não estatística populacional.

## Visual evidence

Visual claim exige acesso visual real.

Se o ambiente só retorna título, descrição, thumbnail ou snippet:

```text
status = METADATA_ONLY
visual_claims = forbidden
```

Se há transcript mas não vídeo:

```text
status = TRANSCRIPT_ONLY
mechanics_observed = false
```

Se o audiovisual está acessível por meio autorizado:

```text
status = VISUAL_READY
observations = timestamped
occlusion = explicit
confidence = multidimensional
```

## Grappling e o problema da oclusão

Um braço escondido não significa grip ausente.

Um joelho escondido não significa posição conhecida.

Uma câmera broadcast única não resolve geometria 3D confiável.

Portanto:

- `UNKNOWN_OCCLUDED` é um estado normal;
- contato escondido nunca vira fato por interpolação;
- a Motion Lab continua exigindo multiview controlado para claims biomecânicos gold;
- vídeos públicos são excelentes para comportamento competitivo, transições, decisões, contexto e failure cases.

## Triangulação mínima desejável

Para elevar uma descoberta de vídeo público a forte recomendação de gameplay:

```text
regra oficial
+ 2 ou mais exemplos competitivos independentes
+ explicação técnica confiável quando útil
+ coerência com o BJJ graph
```

Para elevar movimento a referência física forte:

```text
triangulação pública
+ captura CRIA/licenciada
+ Motion Lab
+ Motion Factory
+ Sprite Forge
+ Godot QA
```

## Informação útil para o jogo

O diretor converte achados em quatro saídas:

### Gameplay

- nova transição candidata;
- counter/failure branch ausente;
- timing/stabilization candidate;
- decisão tática recorrente;
- situação de boundary/referee relevante.

### Motion

- movimento que merece captura própria;
- pose/key state que precisa de referência controlada;
- interação dupla cujo espaçamento/contact QA precisa de Motion Factory.

### Sprite

- ação que precisa de nova animação;
- silhouette/timing inadequado;
- diferença GI/No-Gi que impede mirror/reuse.

### Research

- claim contradito;
- ruleset incerto;
- posição rara sem cobertura suficiente;
- necessidade de fonte oficial ou multiview.

## Relatório padrão ao usuário

O produto final da rotina não é uma lista de tudo que foi clicado.

É:

```text
ESTADO DO PROJETO
- evidência nova
- confiança alterada
- impacto no gameplay
- impacto no Motion Factory
- impacto no Sprite Forge
- blockers reais
- próximo alvo autônomo
```

## Comandos

```bash
python tools/research/validate_public_video_intelligence_v1.py
python -m unittest discover -s tests -p 'test_public_video_intelligence_v1.py'
python tools/research/plan_public_video_research_v1.py --limit 12 --json
```

## Definition of done

A infraestrutura está pronta quando validator, testes, planner e CI passam.

Uma observação pública só é considerada utilizável quando provenance, access mode, timestamp, evidence mode, confidence, occlusion e authority cross-check estão explícitos. Nenhum desses estados concede automaticamente direitos para Motion Factory, treinamento de modelos ou asset shipping.
