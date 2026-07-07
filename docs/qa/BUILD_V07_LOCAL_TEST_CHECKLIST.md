# Build v0.7 — Local Test Checklist

## Godot

- [ ] Abrir project.godot.
- [ ] Verificar autoloads: SignalBus, DataRegistry, WorldState, SaveManager, CombatManager, CareerLoop, ReputationMatrix, CriaLiveManager.
- [ ] Rodar MainMenu.tscn.

## Fluxo

- [ ] Novo Jogo cria WorldState limpo.
- [ ] SaveManager salva slot 1.
- [ ] Menu entra no Terreiro.
- [ ] Botao de treino entra no combate.
- [ ] Combate inicia Ruan vs Davi.
- [ ] Botao Pegada altera recursos.
- [ ] Botao Pressao altera recursos.
- [ ] Botao Tecnico pode encerrar combate quando controle/foco forem suficientes.
- [ ] Resultado salva e volta ao Terreiro.

## Erros esperados para corrigir localmente

- caminho de cena com pasta inexistente;
- JSON faltando campo stats;
- tecnica sem gas_cost/focus_cost;
- autoload faltando por conflito de path.
