# Fatia ouro — auditoria 2026-09-16

Repo `ringuemkt-rgb/cria-do-tatame` @ `8b162a6c`.

## O que já existe no main

- Godot 4.3, autoloads CombatManager / DataRegistry / GameFlowManager
- `TechniqueResolver.gd` — chance, custo, efeitos. Sem deny, sem `state_to_defended` até este PR
- `data/techniques.json` — ids PLAYER_* alinhados (baiana, sprawl, corte_joelho, triangulo, mata_leao, chave_braco)
- `data/ai_config.json` + `DaviAIController.gd` — alfabeto de posição antigo (`PLAYER_GUARD`, `TOP_CONTROL`)
- Catálogo v05 e BJJ KG slice — `runtime_authority: false`
- Identity Ruan GPT — pintura, não pixel 128 (`shipping=false`)

## Este PR completa (dados + resolver no commit seguinte)

- Overlay `technique_slice_ouro_v1.json` (deny / chain / score / commit)
- Mapper catálogo → PLAYER_* + espelho TOP↔BOTTOM
- Policy Davi 7 nós no alfabeto da state machine

## Ainda NÃO é jogo completo

- PRs draft #138 #136 #140
- Sprites pareados 6 fases
- Identity Davi + Ruan v1b pixel
- Terreiro / Dique layers L0–L2 shipping
- LimboAI 1.2 não instalado
