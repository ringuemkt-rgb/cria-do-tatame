# Validation Commands v0.6

## Data

```bash
python tools/cria_forge/cria_forge.py validate
```

## Technique Pack

```bash
python tools/cria_forge/cria_forge.py technique baiana
python tools/cria_forge/cria_forge.py technique knee_cut
```

## Godot

Abrir o projeto no Godot 4.2+ e verificar:

- project.godot carrega;
- autoloads aparecem;
- cena MainMenu abre;
- scripts compilam;
- dados JSON carregam.

## Build Web

Exportar Web depois de criar export_presets.cfg.

## Relatorios

Saida padrao:

```txt
reports/cria_forge/
```
