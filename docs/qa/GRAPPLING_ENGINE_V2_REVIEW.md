# Revisão — Grappling Engine V2 (PR #145)

Status da revisão: `HOLD_MERGE`
Branch: `feat/grappling-engine-v2`
Revisor: Grok / cria-game-build-os
Data: 2026-09-17

## Veredito

O V2 **pode entrar no jogo como camada de apresentação**. Não pode virar juiz.

O PR acerta o firewall: reducer decide luta; V2 escolhe clip. O que o PR **não** fecha é a autoridade do `project.godot`: `CombatManager` + `TechniqueResolver` + `CombatStateMachine`.

Nenhum arquivo original do PR chama `CombatManager`. Sem ponte, o V2 é laboratório paralelo.

## Sólido

- R0–R4 + firewall de score/RNG/winner
- Grip gi/no-gi, uma mão / um grip
- Motion matching 2D determinístico, sem ML no Android
- Compilador fail-closed
- Fachada `RefCounted`, não autoload
- `shipping: false` no `new_match`
- Scripts no `npm run quality`

## P0

1. Dois juízes no papel — contrato diz reducer; cena diz CombatManager. Bridge obrigatório.
2. Motion DB vazio = `NO_SELECTION`. Infra ≠ UFC. Não marcar shipping no engine.

## P1

- Deny/fake/chain do slice ouro precisa virar `reaction_id` (baiana → sprawl).
- CHANGELOG `v2.0.0` é módulo, não release do jogo (`package.json` 0.9.0).
- Relógio: frames no CombatManager, ms no V2. Bridge converte.

## Merge

Não mergear até inspeção APK + validator do bridge + zero autoload novo.
