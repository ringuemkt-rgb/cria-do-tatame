# Web e Mobile Export Guide v0.6

## Objetivo

Preparar o Cria do Tatame para rodar bem em web e mobile usando Godot 4.2+.

## Regras

- Godot controla logica, fisica, sprites, camera e combate.
- UI critica do jogo fica no Godot.
- Em export web, overlays externos podem ser usados para paginas, ranking, analytics e menus fora da luta.
- Evitar criar Labels dinamicamente em loop.
- Usar PNGs otimizados.
- Manter assets grandes fora da primeira cena.
- Fisica em 60 ticks.
- Testar em Android e navegador.

## Configuracao aplicada

- viewport 1280x720;
- canvas_items expand;
- physics_ticks_per_second 60;
- physics_interpolation true;
- texture filter nearest;
- renderer mobile.

## QA web/mobile

1. abrir menu;
2. iniciar cena teste;
3. verificar input touch;
4. verificar leitura do HUD;
5. verificar FPS;
6. verificar memoria;
7. validar sprites pixel art sem blur.
