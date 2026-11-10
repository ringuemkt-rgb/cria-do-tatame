# CRIA Asset Factory — Gold Slice (offline authoring)

**Status:** candidate-only · `shipping=false` · `qa_status=pending`.

Esta fábrica vive **somente** em `tools/cria-asset-factory/` do jogo oficial. Não cria segundo `project.godot`, CombatManager, DeckManager, AudioManager ou qualquer autoload.

## Fluxo

`data/techniques.json` (fonte de gameplay) → `data/transitions/*.json` (authoring) → frames fornecidos/licenciados → palette snap 128×128 nearest → attacker + defender com `sync_map.json` → quality gate → **revisão humana** → cena Godot / `npm run quality` → eventual aprovação por mantenedor.

A aprovação **nunca é automática**. Uma execução PASS da fábrica não aprova asset, pontuação, legalidade ou release.

## Instalação

Python 3.10+, FFmpeg no PATH para extração/áudio e Pixelorama recomendado para edição manual. Opcional: `python -m pip install -e tools/cria-asset-factory/`.

## Validação de dados, sem imagens

```bash
python tools/cria-asset-factory/scripts/quality_gate.py
```

## Processar frames existentes (sem gerar imagens do nada)

```bash
python tools/cria-asset-factory/scripts/extract_frames.py --help
python tools/cria-asset-factory/scripts/build_spritesheet.py --help
python tools/cria-asset-factory/scripts/build_paired_technique.py --help
python tools/cria-asset-factory/scripts/build_combat_animation.py --help
python tools/cria-asset-factory/scripts/quality_gate.py --candidate /work/candidates/baiana
```

Imagens e áudio **não estão incluídos neste PR**. Entradas externas exigem licença/consentimento. Não altere catálogo/overlay original para adaptar esta fábrica; use revisão e adapter futuros.

**Handoff oficial:** `AGENTS.md`, `docs/DECISIONS.md`, `data/production/supreme_build_contract_v01.json`, `data/visual/sprite_forge_contract_v1.json`. Quality integral somente no repositório do jogo:
`npm run quality`.
