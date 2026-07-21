# QA visual e mecânico

## Aprovado no asset

- Identidade, gi, patches, facing e paleta permanecem estáveis.
- Quatro quadros RGBA de 256×256; sprite sheet 1024×256.
- Linha de chão compartilhada em `y=238`; variação de altura visível de no máximo 2 px.
- Quadro 01 é pixel-identical ao seed aprovado.
- Movimento comunica respiração e microtransferência de peso sem trocação ou mudança de estado.
- Alpha, cantos e bordas foram verificados; nearest-neighbor preservado.

## Pendente

- Godot não está instalado neste ambiente, portanto importação e visualização in-engine ainda não foram executadas.
- O placeholder de `assets/sprites/ruan_macacao/idle/` não foi sobrescrito sem esse gate.
