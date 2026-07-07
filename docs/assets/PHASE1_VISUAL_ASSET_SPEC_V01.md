# Phase 1 Visual Asset Spec v0.1

## Objetivo

Criar a primeira camada visual jogavel do Cria do Tatame sem esperar arte final. Esta fase usa placeholders procedurais em Godot e prepara o pipeline para substituir por sprites pixel art finais.

## Escopo imediato

### Ruan Macacao

Acoes minimas:

- idle
- andar
- base
- grip_de_ferro
- clinch
- baiana
- corte_joelho
- cem_quilos
- montada_pesada
- sprawl
- encerramento_tecnico
- vitoria
- derrota

### Davi Relampago

Acoes minimas:

- idle
- andar
- sprawl
- quebra_base
- saida_cem_quilos
- leitura
- vitoria
- derrota

## Padrao tecnico

- PNG transparente
- 256x256 minimo por frame
- pivot na base dos pes
- 8 a 12 frames por acao final
- 12 FPS para pixel art
- manifest JSON por sprite sheet

## Estilo

HD Pixel Art 2.5D Regional Premium, silhueta clara, leitura mobile em ate 1 segundo, quimono com volume, pegada visivel, quadril coerente e paleta preto, dourado, branco sujo e azul rio.

## Pipeline final

1. Gerar pose e keyframes.
2. Criar sprite sheet no sprite-sheet-creator.
3. Limpar no Pixelorama.
4. Exportar manifest.
5. Importar no Godot.
6. Validar leitura em celular.
