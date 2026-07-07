# Cria Pixel Art Asset Factory

## Objetivo

Produzir sprites, poses, animações, HUD e ilustrações 2D pixel art de alta qualidade para o jogo Cria do Tatame.

## Estilo oficial

HD Pixel Art 2.5D Regional Premium.

Características:
- silhueta clara;
- leitura rápida no celular;
- anatomia coerente;
- quimono com volume real;
- pegada visível;
- quadril e base bem desenhados;
- sombra e profundidade controladas;
- identidade do Baixo Sul da Bahia;
- Ruan Macacão Silva como referência principal.

## Pipeline de sprite

1. Receber ficha da técnica.
2. Receber keyframes aprovados.
3. Gerar prompt visual.
4. Gerar pose base com controle por esqueleto.
5. Converter para pixel art.
6. Limpar manualmente no Pixelorama, LibreSprite ou Krita.
7. Montar sprite sheet.
8. Testar animação em FPS baixo, médio e alto.
9. Exportar para Godot.
10. Validar no combate real.

## Pacote por técnica

Cada técnica deve ter pasta própria:

- pesquisa.md;
- biomecanica.md;
- prompt_sprite.txt;
- sprite_sheet.png;
- frames;
- animacao_preview.gif;
- tecnica_godot.json;
- qa_visual.md.

## Critério visual

A pose só é aprovada se responder:

1. qual técnica está acontecendo;
2. quem está por cima;
3. quem está por baixo;
4. onde está a pegada;
5. onde está o quadril;
6. onde está a base;
7. qual é a próxima transição.

## Negative prompt padrão

Evitar: anatomia quebrada, braços extras, perna fundida, kimono derretido, rosto real de atleta famoso, logo real, marca de academia real, sangue, violência gráfica, pose impossível, sprite borrado, pixel art inconsistente, proporção mudando entre frames.
