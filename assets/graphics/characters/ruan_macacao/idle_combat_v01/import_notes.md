# Importação Godot

- Importar `spritesheet.png` sem filtro e sem mipmaps.
- Criar quatro regiões absolutas de 256×256 conforme `manifest.json`.
- Usar pivô `(137, 238)`, 8 FPS e loop.
- Associar apenas ao estado `distancia_media`; a animação não altera estado nem recurso.
- Não substituir o placeholder runtime atual antes de validar escala, z-order e transição no Godot.
