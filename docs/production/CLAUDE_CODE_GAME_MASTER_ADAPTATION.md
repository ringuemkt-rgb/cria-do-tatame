# Adaptacao Claude Code Game Master para Cria do Tatame

## Objetivo

Adaptar a logica de Game Master persistente para o modo carreira do Cria do Tatame.

A referencia principal usa a ideia de um harness que mantem memoria duravel, regra propria, estado em disco e um mundo que continua entre sessoes. Para nosso jogo, isso vira o sistema de carreira persistente, mundo vivo, rivalidade, reputacao, treinos, lutas e consequencias.

## O que aproveitamos

- estado persistente em disco;
- memoria de campanha;
- regras carregadas sob demanda;
- contexto montado antes de cada cena;
- mudancas salvas antes da narracao;
- consequencias que amadurecem com o tempo;
- agentes especialistas ativados por contexto;
- busca em fonte canonica e documentos do projeto.

## Adaptacao para Cria do Tatame

No nosso jogo, o Game Master nao narra fantasia. Ele controla o modo carreira esportivo e regional:

- agenda semanal;
- treinos;
- lutas;
- evolucao de faixa;
- relacao com Mestre Dende;
- relacao com rivais;
- reputacao no Cria Live;
- mapa do Baixo Sul;
- eventos de arena;
- patrocinadores ficcionais;
- consequencias de vitorias, derrotas, lesoes esportivas leves e escolhas morais.

## Loop persistente

1. montar contexto;
2. carregar estado do atleta;
3. carregar estado da semana;
4. carregar rival, arena e objetivo;
5. resolver acao do jogador;
6. aplicar consequencias;
7. salvar estado;
8. mostrar resultado em PT-BR.

## Regra persist-before-feedback

Nada muda no jogo ate ser salvo no estado. Primeiro salva, depois mostra ao jogador.

## Sistemas derivados

- CareerStateManager;
- WorldClockManager;
- RivalMemoryManager;
- ReputationTimeline;
- TechniqueCodexMemory;
- TrainingProgressionManager;
- CriaLiveFeedManager;
- ConsequenceScheduler;
- SceneContextBuilder.

## Diferenca para a referencia

A referencia e voltada para campanhas narrativas. O Cria do Tatame usa a mesma logica de persistencia, mas para um jogo de jiu-jitsu com combate posicional, arte 2D pixel art, Godot, PT-BR e progressao esportiva.

## Licenca e cuidado

A referencia usa licenca nao comercial. Portanto, este documento registra apenas uma adaptacao conceitual autoral. Nao copiar codigo, arquivos, prompts, comandos ou assets da referencia sem validar licenca e permissao.
