# Cria Game Forge Commands v0.6

## Comandos humanos

### Validar projeto

```bash
python tools/cria_forge/cria_forge.py validate
```

### Gerar pacote de tecnica

```bash
python tools/cria_forge/cria_forge.py technique baiana
```

## Comandos de IA sugeridos

### /cria-forge-technique

Entrada: nome da tecnica.
Saida: briefing, gameplay_card, sprite_request e qa_report.

### /cria-forge-qa

Entrada: pasta ou sistema.
Saida: relatorio de qualidade.

### /cria-forge-sprite

Entrada: technique_id.
Saida: sprite_request e manifest_stub.

### /cria-forge-godot

Entrada: feature.
Saida: dados e scripts para Godot.
