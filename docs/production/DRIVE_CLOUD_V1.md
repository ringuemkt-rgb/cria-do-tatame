# Google Drive + Colab Cloud Adapter v1

**Status:** ACTIVE — optional production tooling
**Updated:** 2026-08-11
**Scope:** binary transport, immutable provenance and candidate-batch packaging.
**Out of scope:** automatic final-art generation, automatic approval and runtime networking.

## 1. Decision

The official source of truth remains `ringuemkt-rgb/cria-do-tatame`. Git stores code, contracts, prompts and portable manifests. A private Google Drive tree stores binary candidates, approved binary packages, trained project-specific weights, references and production logs.

Drive is **not** Git LFS and does not replace Git history, review or releases. It is a private binary transport layer. The public repository stores SHA-256 provenance but does not expose OAuth material or provider file/folder IDs.

```text
GitHub contracts and queues
        |
        v
Colab research session -- exact Git commit + exact HF model SHA
        |
        v
Private Drive / assets / candidatos
        |
        v
Human art + biomechanical + license + canon QA
        |
        v
Private Drive / assets / aprovados
        |
        v
rclone copy -> local Godot asset cache -> explicit scene integration
```

No external service controls combat, save or the frame loop. After approved assets are synchronized, gameplay remains offline.

## 2. Executable Drive layout

The active layout contract is `data/ai/cloud_drive_layout_v02.json`.

```text
CriaDoTatame/
├── fila/{entradas,em_processo,saidas,mortos}/
├── assets/
│   └── {candidatos,aprovados,reprovados,quarentena_licenca}/
├── audio/{sfx,vozes,musica}/
├── models/{registry.json,staging}/
├── cache/index.json
├── data/{specs,motions,refs}/
├── qa/{relatorios,gate_l1_promocoes.json}/
├── ops/{heartbeat.json,quota_ledger.json,apps_script,backups,dvc_remote}/
├── builds/
├── colab_logs/
├── docs/
└── manifest/private_state.json
```

The v2 required tree was created and connector-verified in the private Drive on 2026-08-11. Older folders with similar names remain untouched.

## 3. What changed from the first draft

The first draft was directionally useful but unsafe to ship as code:

- `candidatos` was created under the root instead of under `assets`;
- the Python default argument evaluated a required environment variable at import time;
- folder lookup silently accepted the first duplicate;
- OAuth refresh and atomic token handling were incomplete;
- manifest writes were non-atomic and provider IDs would have leaked into a public repository;
- the notebook called undefined `processar_tecnica` and `render_para_drive` functions;
- `rclone sync` could delete local files without a deliberate destructive-mode gate;
- model refs were not resolved to immutable revisions;
- model and output licenses were not represented as adoption gates.

The v1 adapter fixes those problems. It uses the Google Drive API v3 client, exact unique folder resolution, resumable uploads, atomic JSON writes, file locking, SHA-256, a public/private manifest split and non-destructive `rclone copy` by default.

## 4. Private OAuth setup

Create an installed-application OAuth client in the Google Cloud project that owns the Drive API consent screen. Download its client file outside the repository, then install dependencies:

```bash
python -m venv .venv-drive
. .venv-drive/bin/activate
python -m pip install -r tools/ai_asset_pipeline/cloud/requirements-drive.txt
```

Recommended private paths:

```bash
CRIA_CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/cria-do-tatame/drive"
export CRIA_DRIVE_CLIENT_SECRET="$CRIA_CONFIG_ROOT/client_secret.json"
export CRIA_DRIVE_TOKEN="$CRIA_CONFIG_ROOT/token.json"
export CRIA_DRIVE_STATE="$CRIA_CONFIG_ROOT/state.json"
```

If `XDG_CONFIG_HOME` is not defined, use a private operating-system configuration folder. Never copy these files into the checkout.

The client requests Drive scope because it must resolve a pre-existing private project folder. The local token belongs only on a trusted machine and should be revoked if that machine is lost.

Initialize or verify the hierarchy:

```bash
python tools/ai_asset_pipeline/cloud/drive_client.py init-tree
python tools/ai_asset_pipeline/cloud/drive_client.py verify-tree
```

If exact-name lookup is ambiguous, set the private root ID for the session:

```bash
export CRIA_DRIVE_ROOT_ID="<private-folder-id>"
python tools/ai_asset_pipeline/cloud/drive_client.py verify-tree
```

Provider IDs are written only to the private state file. `data/ai/cloud_asset_manifest_v01.json` contains portable hashes and logical paths.

## 5. Build a deterministic candidate batch

Generate the canonical production queue first:

```bash
python tools/ai_asset_pipeline/build_production_queue_v02.py
```

Prepare a small Ruan × Davi technique batch:

```bash
python tools/ai_asset_pipeline/cloud/prepare_batch.py \
  --output-dir tools/ai_asset_pipeline/generated_outputs/candidate_batches \
  --kind paired_technique_animation \
  --target baiana_single_leg \
  --limit 1
```

The ZIP contains:

- `batch.json` — state, Git commit, task IDs and promotion policy;
- `tasks.jsonl` — selected canonical queue rows;
- `model_registry.json` — model provenance or a per-session resolved snapshot;
- `SHA256SUMS` — internal integrity checks.

The state is `prepared_for_candidate_generation`, not `generated`, `approved` or `integrated`.

Upload one ZIP:

```bash
python tools/ai_asset_pipeline/cloud/drive_client.py upload-batch \
  tools/ai_asset_pipeline/generated_outputs/candidate_batches/candidate_batch_<id>.zip
```

The automated destination allowlist contains only `assets/candidatos` and `assets/quarentena_licenca`.

## 6. Colab workflow

Open `tools/ai_asset_pipeline/colab_pipeline.ipynb` in Google Colab and select a GPU runtime when one is available. The notebook:

1. mounts the private Drive;
2. verifies every required folder;
3. checks out an exact Git commit;
4. installs the small Colab dependency set;
5. builds the canonical paired-technique queue;
6. resolves `ByteDance/AnimateDiff-Lightning` from `main` to an immutable Hub commit SHA;
7. writes that model snapshot to `manifest/`;
8. creates one deterministic `baiana_single_leg` candidate bundle;
9. writes a receipt to `colab_logs/`.

This notebook proves the Git/Hub/Drive provenance path. It intentionally does not pretend that a text-to-video result is a finished BJJ spritesheet. GPU rendering, pose extraction, attacker/defender synchronization, pixel cleanup and Godot import belong to later vertical lots with their own tests.

## 7. Hugging Face adoption gates

The audited registry is `data/ai/model_registry_v02.json`. Every execution resolves a mutable ref such as `main` to a commit SHA and stores the SHA in a per-batch snapshot.

| Model | Observed license metadata | Decision |
|---|---|---|
| `black-forest-labs/FLUX.1-schnell` | Apache-2.0, gated, safetensors | Candidate concepts after terms acceptance and immutable SHA capture |
| `Onodofthenorth/SD_PixelArt_SpriteSheet_Generator` | Apache-2.0 | Research only; candidate output still requires full QA |
| `xinsir/controlnet-openpose-sdxl-1.0` / `yzd-v/DWPose` | Apache-2.0 | Candidate tooling; never biomechanical approval |
| `ByteDance/AnimateDiff-Lightning` | CreativeML Open RAIL-M | Short motion reference research only |
| `Wan-AI/Wan2.2-T2V-A14B` / `I2V-A14B` | Apache-2.0, safetensors | Candidate generation only when free-session VRAM fits |
| `Comfy-Org/MiniMax-H3` | Custom/other | Blocked pending exact license and workflow review |
| `facebook/musicgen-large` | CC BY-NC 4.0 | Blocked for commercial shipping |
| `stabilityai/stable-audio-open-1.0` | Custom/other, gated | Blocked pending license and access review |

Resolve a registered research model without downloading it:

```bash
python tools/ai_asset_pipeline/cloud/resolve_hf_models.py \
  --model ByteDance/AnimateDiff-Lightning \
  --allow-research \
  --output /private/path/hf_snapshot.json
```

If a future generator downloads weights, it must use `resolved_revision`, keep base-model cache ephemeral under `/content`, and record the complete dependency/license chain. Project-specific trained weights may be persisted under Drive `models/`; huge base checkpoints should not be copied there by default.

## 8. Safe local sync with rclone

Configure a private rclone remote named `gdrive`, then verify access:

```bash
rclone config
bash tools/ai_asset_pipeline/cloud/drive_sync.sh check
```

Preview and pull approved assets without deleting local files:

```bash
bash tools/ai_asset_pipeline/cloud/drive_sync.sh --dry-run pull-approved
bash tools/ai_asset_pipeline/cloud/drive_sync.sh pull-approved
```

The default local cache is `assets/cloud_approved/`. It is ignored by Git because Drive owns these binaries.

Push candidate output:

```bash
bash tools/ai_asset_pipeline/cloud/drive_sync.sh --dry-run push-candidates /path/to/batch-or-folder
bash tools/ai_asset_pipeline/cloud/drive_sync.sh push-candidates /path/to/batch-or-folder
```

`mirror-approved` uses `rclone sync` and can delete local files. It requires both a reviewed `--dry-run` and `CRIA_ALLOW_RCLONE_DELETE=YES`. Routine operations use `copy`.

## 9. Promotion gate

Moving a package from `candidatos` to `aprovados` requires evidence for:

- source model, exact revision and complete license chain;
- original fictional content, with no copied athlete, academy, brand or footage;
- Ruan/Davi canon and regional art direction;
- attacker/defender pivots, contact points, timing and `sync_map`;
- safe and technically intelligible BJJ biomechanics;
- mobile silhouette, nearest-neighbor pixel quality and stable proportions;
- required files from `data/visual/production_manifest_v02.json`;
- human QA sign-off and a real Godot consumer plan.

Promotion remains manual in the active adapter. The delegated GATE-L1-B regime is recorded in `gpt_work_production_gate_v1.json`, but is inactive until governance migration; reserved assets always require a human decision. The mobile pack builder accepts only sidecars already marked `LIBERADO` and approved, and rejects delegated promotion for reserved assets.

## 10. Cost and availability reality

The workflow can run at zero direct software cost, but it has no free-tier SLA:

- the common 15 GB Google quota is shared with other Google storage products;
- Colab GPU type and availability are not guaranteed;
- sessions disconnect and quotas vary;
- repeatedly downloading multi-gigabyte models consumes time and bandwidth;
- Drive and Hugging Face may enforce API, transfer or access limits;
- custom/gated model licenses may prohibit the intended use even when download is technically possible.

Treat “R$ 0” as a possible operating mode, not a capacity guarantee.

## 11. Validation and rollback

Run the adapter gate directly or through the full repository gate:

```bash
python tools/ai_asset_pipeline/cloud/validate_cloud_pipeline.py
npm run quality
```

Rollback is simple because no Godot runtime or autoload is changed:

1. stop using the notebook/client;
2. remove the optional local `assets/cloud_approved/` cache;
3. revoke the local OAuth token if needed;
4. revert this adapter commit;
5. retain or archive private Drive binaries according to the production decision.

No existing Drive folder is deleted by this workflow.
