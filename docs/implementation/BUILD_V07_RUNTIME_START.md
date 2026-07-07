# Build v0.7 — Runtime Start

## Objetivo

Executar os blocos A, B e C juntos:

- A: DataRegistry lendo e validando dados canonicos.
- B: CombatManager calculando recursos de combate BJJ.
- C: fluxo minimo de cenas Main Menu -> Terreiro -> Combate -> Resultado -> Save.

## Arquivos modificados

- project.godot
- src/autoloads/SignalBus.gd
- src/autoloads/DataRegistry.gd
- src/autoloads/CombatManager.gd
- src/autoloads/WorldState.gd
- scenes/main_menu/MainMenu.gd

## Arquivos criados

- src/combat/CombatStateMachine.gd
- scenes/hubs/TerreiroDaLuta.tscn
- scenes/hubs/TerreiroDaLuta.gd
- scenes/combat/CombatArenaBase.tscn
- scenes/combat/CombatArenaBase.gd
- scenes/result/ResultScreen.tscn
- scenes/result/ResultScreen.gd

## Fluxo atual

```txt
MainMenu.tscn
-> TerreiroDaLuta.tscn
-> CombatArenaBase.tscn
-> ResultScreen.tscn
-> TerreiroDaLuta.tscn
```

## Status

A base agora tem caminho minimo de runtime para abrir, salvar, entrar no hub, iniciar combate, alterar recursos e voltar ao hub.

## Proxima validacao local

1. Abrir project.godot no Godot 4.2+.
2. Confirmar autoloads.
3. Rodar MainMenu.
4. Clicar Novo Jogo.
5. Iniciar treino contra Davi.
6. Usar botoes de combate.
7. Confirmar retorno ao Terreiro depois do resultado.
