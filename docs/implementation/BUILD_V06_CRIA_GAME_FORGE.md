# Build v0.6 — Cria Game Forge

## Objetivo

Integrar o melhor dos sistemas analisados em uma arquitetura autoral para o Cria do Tatame.

## Sistemas analisados

- GodotMaker;
- claude-code-game-development;
- agent-game-forge;
- godot-2d-web-game-skill;
- tower-defense-skill;
- XianTu;
- clik-engine;
- sprite-gen.

## Arquivos criados

### Producao
- docs/production/EXTERNAL_SYSTEMS_ANALYSIS_MATRIX_V06.md
- docs/production/CRIA_GAME_FORGE_SYSTEM_V06.md

### Configuracao
- .criaforge/config.yaml
- .criaforge/agents.yaml
- .criaforge/quality_gates.yaml
- .criaforge/workflows/technique_to_gameplay.yaml
- data/production/cria_forge_manifest_v06.yaml

### Ferramentas
- tools/cria_forge/README.md
- tools/cria_forge/cria_forge.py
- src/tools/CriaForgeBridge.gd

### Web, QA e arte
- docs/web/WEB_MOBILE_EXPORT_GUIDE_V06.md
- docs/qa/CRIA_QA_HARNESS_V06.md
- docs/art/SPRITE_ATLAS_MANIFEST_STANDARD_V06.md

### Godot
- project.godot atualizado com physics ticks e interpolation.

## Resultado

O projeto agora possui um sistema proprio chamado Cria Game Forge, com cinco camadas:

1. Studio OS;
2. Runtime Core;
3. Motion Lab;
4. Asset Factory;
5. QA Harness.

## Proximo passo

Rodar localmente:

```bash
python tools/cria_forge/cria_forge.py validate
python tools/cria_forge/cria_forge.py technique baiana
```

Depois abrir no Godot e criar a cena de combate Ruan vs Davi.
