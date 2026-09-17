# CRIA Game Forge v1 — Operator Commands

**Status:** ACTIVE

## Bootstrap

```bash
python tools/agents/detect_capabilities.py --write reports/agent_bootstrap/capabilities.json
```

Add only session-native capabilities actually present:

```bash
python tools/agents/detect_capabilities.py \
  --declare github_remote,web_research,vision,image_generate,image_edit \
  --write reports/agent_bootstrap/capabilities.json
```

## Universal OS gates

```bash
npm run validate:agent-production-os
npm run test:agent-production-os
npm run validate:external-tools
npm run test:external-tools
```

## Full repository

```bash
npm run quality
```

## Visual production

```bash
npm run assets:foundry-queue
npm run validate:visual-foundry
npm run validate:sprite-forge
npm run derive:sprite-forge-v2
npm run validate:sprite-forge-v2
```

## Combat and paired BJJ

```bash
npm run validate:combat-intelligence
npm run test:combat-intelligence
npm run validate:bjj-reducer-v2
npm run test:bjj-reducer-v2
npm run validate:grappling-motion-lab
npm run test:grappling-motion-lab
```

## Godot runtime

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/runtime_smoke.gd
```

Optional MCP bridges may make the same operations available to an agent, but do not replace the commands as reproducible project evidence.

## Android candidate

Linux:

```bash
npm run build:android:linux
```

Windows:

```powershell
npm run build:android:windows
```

A release/device PASS additionally requires a real Android device and ADB evidence according to the release workflow.

## Workflow selection

```text
technique/rule          -> .criaforge/workflows/technique_to_gameplay.yaml
character/arena/UI      -> .criaforge/workflows/visual_asset_to_runtime.yaml
paired grappling        -> .criaforge/workflows/paired_bjj_to_runtime.yaml
map/hub/world           -> .criaforge/workflows/map_world_to_runtime.yaml
release vertical slice  -> .criaforge/workflows/release_vertical_slice.yaml
```
