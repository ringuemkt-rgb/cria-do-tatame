# EPIC 72 — BJJ Intelligence Foundation

**Status:** ACTIVE / CANDIDATE CONTRACTS  
**Base:** `main @ cfb1afa18b0b4bdc5c3eb567276ea1d83823ce98`  
**Issue:** #85

## Objetivo

Adicionar skills e dados fail-closed para vídeo técnico, motion pixel e futuros adapters de combate sem tocar no runtime crítico.

## Autoridade preservada

`CombatManager` continua única autoridade de combate. As novas skills são conhecimento/produção offline e não alteram `project.godot`, autoloads ou cenas.

## Dossiê #003

A proposta `raspagem_tesoura` conflita com `production_manifest_v02`: proposta 24 frames / `guard.closed_bottom` / mount ou side; autoridade atual 28 frames / `player_bottom_guard` / `player_top_guard`. O dossiê fica `DRAFT_CONFLICT_PENDING_RESOLUTION`; nenhum dado ativo foi substituído.

## Dossiê #001 human gate

G1–G7 permanecem recomendações. G2 recomenda rework de head position; G8 está bloqueado por evidência. A IA não pode assinar `human_bjj_gate`, logo a decisão humana fica PENDING.

## Corpus baiana V1–V3

O prompt menciona um clipe de referência, mas não fornece exact source ID, licença/autorização nem bytes materializados. A skill V define `LICENSE_UNKNOWN | SOURCE_BYTES_MISSING` como condição de parada. Resultado correto:

- V1: `CUSTODY_BLOCKED`;
- V2: `NOT_STARTED_BLOCKED_BY_V1`;
- V3: `NOT_STARTED_BLOCKED_BY_V1`;
- claim: `NO_VIDEO_ANALYSIS_PERFORMED`.

## Rollback

Remover os arquivos adicionados neste EPIC e restaurar `package.json`; nenhum runtime/asset precisa de rollback.
