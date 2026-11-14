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

## Todo o elenco é suportado para authoring (não somente Ruan × Davi)

Os personagens são lidos dinamicamente do cadastro `data/combat/roster_v3.json`; nenhuma lista congelada de lutadores fica nos scripts. A meta do jogo prevê 18, mas o cadastro corrente contém 17 e a ferramenta **não inventa** o ausente. Um combate entre quaisquer dois personagens canônicos é planejável; isso **não significa** que a IA, as técnicas, as animações ou a cena já estejam prontas para todos.

```sh
python tools/cria-asset-factory/scripts/plan_combat_matchups.py \
  --all --out /tmp/cria-all-roster-matchups.json
python tools/cria-asset-factory/scripts/plan_combat_matchups.py \
  --fighter leoa --opponent jacare_do_mangue \
  --technique baiana --out /tmp/cria-leoa-jacare.json
```

O plano enumera duplas e funções atacante/defensor, mas separa o material reutilizável por técnica da identidade de cada lutador; evita gerar uma animação para cada par. A elegibilidade individual segue **UNVERIFIED**, e a transição só será final quando o grafo BJJ, os perfis técnicos e o contato forem auditados. Veja `docs/UNIVERSAL_COMBAT_AUTHORING.md`.

## Preparar trabalho de geração sem renderizar

```sh
python tools/cria-asset-factory/scripts/prepare_candidate_job.py \
  --id baiana --character leoa --opponent jacare_do_mangue --outfit gi_white \
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
