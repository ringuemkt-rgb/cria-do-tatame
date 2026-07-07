# AnimateAnyMesh para Cria do Tatame

## Objetivo

Converter o conceito do AnimateAnyMesh em um pipeline autoral para gerar material grafico do jogo Cria do Tatame: poses, animacoes, referencias 3D, sprites 2D pixel art, sheets e eventos para Godot.

## O que o AnimateAnyMesh oferece

O projeto parte de uma malha 3D estatica e um prompt de texto para gerar animacao de malha em poucos segundos. A saida pode incluir video frontal renderizado e exportacao FBX.

Para o Cria do Tatame, isso nao entra como arte final. Entra como gerador de movimento 3D intermediario.

## Conversao para nosso jogo

Fluxo recomendado:

1. Criar modelo 3D base do Ruan Macacao Silva.
2. Criar modelo 3D generico de parceiro de treino.
3. Gerar ou importar movimento 3D da tecnica.
4. Renderizar em camera ortografica lateral ou 3/4.
5. Extrair keyframes limpos.
6. Converter para guia de pixel art.
7. Montar sprite sheet no sprite-sheet-creator.
8. Limpar no Pixelorama, LibreSprite ou Krita.
9. Exportar animacao e eventos para Godot.

## Melhorias necessarias

Para servir ao jiu-jitsu, o sistema precisa de camadas extras:

- dois personagens interagindo;
- contato corporal coerente;
- pegada visivel no quimono;
- base, quadril e tronco legiveis;
- camera fixa de gameplay;
- keyframes aprovados manualmente;
- padrao PT-BR de tecnica;
- exportacao direta para spritesheet;
- QA anatomico e visual.

## Papel no pipeline oficial

O AnimateAnyMesh pode virar a etapa 3D intermediaria da Cria Pixel Art Asset Factory.

Nao substituir o artista. Nao substituir a revisao tecnica. Ele acelera a criacao de pose, timing e volume corporal.

## Saidas desejadas

Cada tecnica deve gerar:

- animacao 3D de referencia;
- render frontal ou lateral;
- keyframes PNG;
- mapa de fases;
- prompt de sprite;
- sprite sheet;
- eventos Godot;
- checklist de QA.

## Regra de qualidade

A animacao so entra no jogo se a tecnica for reconhecivel, a silhueta for clara, a pegada fizer sentido, o quadril estiver coerente e a transicao funcionar no combate mobile.
