# Build to End v0.5 — Cria do Tatame

## Objetivo

Transformar os documentos de direcao em base implementavel para Godot 4.2+.

## Arquivos criados nesta etapa

### Core
- src/core/SignalBus.gd
- src/core/DataRegistry.gd
- src/core/SaveManager.gd

### Carreira persistente
- src/career/CareerStateManager.gd
- src/career/WorldTimeManager.gd
- src/career/RivalMemoryManager.gd
- src/career/ConsequenceScheduler.gd
- src/career/SceneContextBuilder.gd
- src/career/CriaLiveFeedManager.gd

### Combate
- src/combat/PositionalStateMachine.gd
- src/combat/TechniqueResolver.gd
- src/combat/DefenseTimingResolver.gd
- src/combat/ScoringSystem.gd
- src/combat/CombatManager.gd

### IA
- src/ai/RivalAIController.gd

### Ferramentas
- src/tools/TechniqueCodexLoader.gd
- tools/validate_data.py

### Dados
- data/combat/combat_states_v05.json
- data/techniques/technique_catalog_v05.json
- data/ai/opponent_gameplans_v05.json
- data/career/default_career_state_v05.json

## Status

A base agora tem:

- carregamento de dados JSON;
- salvamento persistente;
- carreira inicial;
- memoria de oponentes;
- eventos futuros;
- feed Cria Live;
- maquina de estados posicional;
- resolucao tecnica;
- janela de defesa;
- pontuacao;
- IA por gameplan;
- catalogo tecnico inicial;
- ferramenta de validacao de dados.

## Proximo bloco

1. Criar cenas Godot de teste.
2. Registrar autoloads no project.godot.
3. Criar HUD mobile.
4. Criar mock de combate Ruan vs Davi.
5. Adicionar testes unitarios para dados e estados.
