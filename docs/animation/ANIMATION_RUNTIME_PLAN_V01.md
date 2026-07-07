# Animation Runtime Plan v0.1

## Objetivo

Transformar o vertical slice em combate visualmente legivel antes da arte final.

## Estrategia

1. Fase placeholder: FighterPlaceholder.gd anima escala, rotacao, deslocamento e brilho.
2. Fase sprite sheet: cada acao recebe atlas PNG e manifest JSON.
3. Fase AnimationPlayer: importar frames, criar animacoes one-shot e loops.
4. Fase AnimationTree: conectar estados da state machine BJJ.

## Animacoes por personagem

- idle: loop
- walk: loop
- stance: loop curto
- grip_attempt: one-shot
- grip_success: one-shot
- clinch: loop de controle
- takedown: one-shot
- guard: loop posicional
- pass: one-shot
- mount: one-shot
- technical_setup: one-shot
- technical_lock: loop curto
- technical_finish: one-shot esportivo
- win: one-shot
- lose: one-shot

## Eventos de animacao

- frame_de_pegada
- frame_de_contato
- frame_de_transicao
- frame_de_estabilizacao
- frame_de_resultado

## Regra

A animacao deve comunicar posicao, base, pegada e proxima transicao. Bonito sem leitura nao entra no jogo.
