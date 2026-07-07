# Sistema de Estado Persistente da Carreira

## Funcao

Manter o mundo do Cria do Tatame vivo entre sessoes, cenas, lutas e semanas da carreira.

## Principio

O jogo precisa lembrar tudo que importa:

- progresso do Ruan Macacao Silva;
- tecnicas desbloqueadas;
- vitorias e derrotas;
- relacao com rivais;
- reputacao;
- moral;
- treinos feitos;
- arenas liberadas;
- eventos pendentes;
- escolhas narrativas;
- historico do Cria Live.

## Estrutura de pastas sugerida

```txt
save/
  carreira_001/
    player_state.json
    world_clock.json
    rivals.json
    reputation.json
    technique_codex.json
    career_log.json
    pending_events.json
    cria_live_feed.json
    arenas.json
```

## Player State

Guarda atributos do protagonista:

- faixa;
- idade de carreira;
- gas;
- foco;
- moral;
- pegada;
- base;
- queda;
- passagem;
- raspagem;
- defesa;
- controle por cima;
- controle por baixo;
- finalizacao esportiva;
- tecnicas desbloqueadas.

## World Clock

Controla tempo de jogo:

- dia;
- semana;
- fase da campanha;
- proxima luta;
- treino marcado;
- evento pendente;
- recuperacao;
- janela de oportunidade.

## Rival Memory

Cada rival deve lembrar:

- historico contra Ruan;
- tecnica favorita;
- medo, respeito ou provocacao;
- ajustes feitos depois de lutar;
- resposta a padroes repetidos do jogador;
- impacto no Cria Live.

## Consequence Scheduler

Agenda efeitos futuros:

- rival treinou contra sua baiana;
- publico reagiu a uma luta feia;
- Mestre Dende marcou treino extra;
- patrocinador ficcional observou uma vitoria limpa;
- arena nova liberou.

## Scene Context Builder

Antes de cada cena, montar contexto curto:

- onde Ruan esta;
- que semana e;
- qual objetivo;
- quais tecnicas relevantes;
- qual rival esta presente;
- que consequencias estao ativas;
- qual tom narrativo usar.

## Integracao com Godot

Scripts sugeridos:

- SaveManager.gd;
- CareerStateManager.gd;
- WorldClockManager.gd;
- RivalMemoryManager.gd;
- ConsequenceScheduler.gd;
- SceneContextBuilder.gd;
- CriaLiveFeedManager.gd.

## Quality Gate

Um evento so e valido se:

1. altera o estado salvo;
2. pode ser explicado em PT-BR;
3. tem consequencia clara;
4. nao contradiz o canon;
5. melhora o modo carreira.
