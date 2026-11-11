# CRIA Asset Factory — Gold Slice (offline authoring)

**Status:** candidate-only · `shipping=false` · `qa_status=pending`.

Esta fábrica vive **somente** em `tools/cria-asset-factory/` do jogo oficial. Não cria segundo `project.godot`, CombatManager, DeckManager, AudioManager ou qualquer autoload.

## Fluxo

`data/techniques.json` (fonte de gameplay) → `data/transitions/*.json` (authoring) → referência fornecida/licenciada → conceito candidato (opcional ComfyUI) → palette snap 128×128 nearest → attacker + defender com `sync_map.json` → quality gate → **revisão humana** → cena Godot / `npm run quality` → eventual aprovação pelo mantenedor.

A aprovação **nunca é automática**. Uma execução PASS não aprova asset, pontuação, legalidade ou release.

## Instalação segura (CPU, sem compra e sem pesos de IA)

```sh
python tools/cria-asset-factory/scripts/bootstrap.py --check
python tools/cria-asset-factory/scripts/bootstrap.py --install-core
python tools/cria-asset-factory/scripts/quality_gate.py
```

O instalador atua **somente** sobre o ambiente virtual `tools/cria-asset-factory/.venv`. FFmpeg e Pixelorama são dependências externas opcionais, e GPU/Qwen/ComfyUI não são iniciados nem baixados automaticamente. Os adaptadores registrados estão em `config/integrations.json`; veja `docs/INSTALL_OPEN_SOURCE.md`.

## Preparar trabalho de geração sem renderizar

```sh
python tools/cria-asset-factory/scripts/prepare_candidate_job.py \
  --id baiana --character ruan_macacao --outfit gi_white \
  --phase anticipation --out /tmp/cria-baiana-job.json
```

Com workflow API JSON existente do ComfyUI em execução **local**:

```sh
python tools/cria-asset-factory/scripts/comfyui_adapter.py \
  --job /tmp/cria-baiana-job.json --workflow /work/workflow_api.json \
  --prompt-node 6
```

Sem `--submit`, essa chamada só valida o payload. Com `--submit`, solicita inferência na instalação **local própria**; não baixa resultados ou promove shipping.

## Ferramentas de autoria existentes

```sh
python tools/cria-asset-factory/scripts/extract_frames.py --help
python tools/cria-asset-factory/scripts/build_spritesheet.py --help
python tools/cria-asset-factory/scripts/build_paired_technique.py --help
python tools/cria-asset-factory/scripts/build_combat_animation.py --help
python tools/cria-asset-factory/scripts/quality_gate.py --candidate /work/candidates/baiana
```

Candidatos e áudio não estão incluídos neste PR. Entradas externas exigem licença e consentimento. Não alterar o catálogo para adaptar a fábrica; usar revisão e adapter futuro separado.

**Handoff oficial:** `AGENTS.md`, `docs/DECISIONS.md`, `data/production/supreme_build_contract_v01.json`, `data/ai/qwen_pixel_art_profile_v1.json`. A validação integral é `npm run quality` no repositório oficial.
