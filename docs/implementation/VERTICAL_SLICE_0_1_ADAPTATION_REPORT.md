# Vertical Slice 0.1 — Adaptation Report

## Decisao

O pacote recebido foi adaptado ao repositorio real, sem colar cegamente caminhos conflitantes.

## Ajustes principais

- Mantido o caminho canonico `data/`, em vez de `assets/data/`.
- Mantidos os autoloads em `src/autoloads/`, conforme `AGENTS.md` e README.
- `project.godot` foi alinhado aos autoloads canonicos.
- `SignalBus` foi expandido para cobrir combate, carreira, reputacao, Cria Live, dialogo e fluxo.
- `DataRegistry` agora carrega e valida os dez JSONs canonicos.
- `WorldState` foi expandido para semana, faixa, energia, reputacao, sponsors, tecnicas, resultado e progresso.
- `SaveManager` salva o estado completo do `WorldState`.
- `CombatManager` calcula gas, foco, grip integrity, controle, Silverback Grip e resultado.
- `CareerLoop` executa atividades semanais e avanca dia.
- `ReputationMatrix` foi alinhada ao novo modelo de delta e valor final.
- `CriaLiveManager` gera feed a partir de luta, treino e crise.

## Runtime minimo

```txt
MainMenu -> TerreiroDaLuta -> CombatArenaBase -> ResultScreen -> TerreiroDaLuta
```

## Observacao

A mensagem original do pacote foi cortada no meio da Parte 2. A `CombatStateMachine.gd` foi completada com uma versao funcional, compativel com o runtime atual.

## Proxima etapa

Abrir no Godot 4.2+, rodar o fluxo local e corrigir qualquer erro de parse ou caminho.
