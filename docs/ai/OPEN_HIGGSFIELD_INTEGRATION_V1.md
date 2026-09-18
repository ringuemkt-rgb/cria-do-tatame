# OpenHiggsfield x CRIA DO TATAME — Integration v1

## Status

**ACTIVE AS AN OPTIONAL EXTERNAL CANDIDATE-GENERATION ADAPTER.**

This integration does not replace CRIA's canonical Asset Pipeline v2, Visual Foundry,
Sprite Forge, canon manifests, provenance rules, human approval, or Godot runtime QA.

Upstream audited source:

- repository: `wide-trace/open-higgsfield`
- pinned revision: `b16a0efe4d7e2707b56f8ccb02387fd2a9d2eddf`
- hosted studio: `https://openhiggsfield.ai`
- upstream API contract documented as:
  - `POST /{model}`
  - `GET /requests/{id}/status`
  - `Authorization: Key <id:secret>`

## License posture

No repository LICENSE file and no license declaration were found at the audited
revision. Therefore CRIA does **not** copy upstream source code into this repository.

The local adapter is an independent transport implementation based on the public
API contract. OpenHiggsfield remains an external optional tool until upstream
licensing is clarified.

## Why it is useful

OpenHiggsfield provides one catalog-driven studio for image and video generation.
For CRIA it can act as a candidate generator for:

- character concept/reference iterations;
- arena and environmental concepts;
- HQ/story scene candidates;
- image-to-video cutscene candidates;
- reference-conditioned motion/video candidates.

It is never allowed to promote outputs directly to shipping.

## Pipeline position

```text
CRIA canon / production manifest
        |
        v
candidate-generation job
        |
        v
OpenHiggsfield-compatible external API
        |
        v
generated candidate media
        |
        v
provenance + rights + identity lock
        |
        v
Visual Foundry / Sprite Forge / video QA
        |
        v
human approval
        |
        v
Godot integration + runtime evidence
        |
        v
shipping candidate
```

## Credentials

Do not place credentials in Git.

Required only when the adapter is actually executed:

```bash
HF_API_BASE_URL=<generation-api-origin>
OPEN_HIGGSFIELD_API_KEY=<id:secret>
```

The upstream browser studio stores its platform key in an httpOnly cookie. CRIA
does not attempt to extract or reuse that browser cookie. The pipeline uses an
explicit environment-only credential.

## Adapter

```text
tools/ai_asset_pipeline/open_higgsfield/adapter.py
```

The adapter is deliberately low-level. It accepts a provider-native JSON body so
CRIA does not invent model parameters that the upstream catalog may not support.

Example:

```bash
python tools/ai_asset_pipeline/open_higgsfield/adapter.py submit \
  --model "<model-id>" \
  --body-json '{"prompt":"..."}'
```

Status:

```bash
python tools/ai_asset_pipeline/open_higgsfield/adapter.py status \
  --request-id "<request-id>"
```

## Fail-closed rules

1. Missing base URL -> stop.
2. Missing/malformed `id:secret` credential -> stop.
3. Unknown model-specific schema -> do not guess; use provider-native body.
4. Generated output -> candidate only.
5. No provenance or rights record -> no promotion.
6. Identity drift -> reject/re-generate.
7. No Godot runtime evidence -> no shipping.

## ChatGPT/MCP note

This repository integration does not by itself install OpenHiggsfield as a native
ChatGPT plugin. A ChatGPT-visible custom MCP still needs a publicly reachable MCP
server and an explicit user connection in ChatGPT. Until then, the existing
Higgsfield/other connected media tools can be used interactively, while this
adapter remains available to the CRIA build pipeline once its API origin and key
are configured.
