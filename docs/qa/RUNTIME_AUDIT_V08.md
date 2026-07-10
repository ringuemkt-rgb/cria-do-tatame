# Cria do Tatame — Runtime Audit V0.8

## Objetivo

Revisar o jogo completo no nível de arquitetura, dados, fluxo principal, combate, save/load, UI, referências de recursos e automação de QA. O foco desta rodada é reduzir falhas que impedem o projeto de abrir, lutar, salvar, retornar ao hub e ser preparado para exportação.

## Escopo auditado

- `project.godot` e autoloads.
- Classes globais GDScript.
- Registro e validação de dados JSON.
- Main Menu.
- Terreiro da Luta.
- Combate posicional.
- Resolução de técnicas.
- Resultado do combate.
- Save/load.
- Referências `res://`.
- Contratos entre cenas e scripts.
- CI estático e Godot headless.

## Problemas críticos encontrados

### 1. Colisões de nomes globais

Os arquivos modulares abaixo declaravam `class_name` com o mesmo nome dos autoloads:

- `src/core/SignalBus.gd`
- `src/core/DataRegistry.gd`
- `src/core/SaveManager.gd`
- `src/combat/CombatManager.gd`

Isso poderia causar conflito no parser e ambiguidade entre classe global e singleton.

### 2. Efeitos invertidos nas técnicas

Campos como `opponent_grip_reduction: 8` podiam aumentar o recurso do adversário em vez de reduzi-lo. A resolução foi normalizada para deltas canônicos com sinais explícitos.

### 3. Combate não respeitava posição

O runtime principal executava técnicas sem validar corretamente `entry_state` e `exit_state`. A state machine existia, mas não governava integralmente a escolha e execução das ações da arena.

### 4. Botões fixos em todas as posições

A arena exibia sempre o mesmo conjunto de ações. Agora os botões são preenchidos a partir das técnicas válidas para a posição atual, proprietário e recursos disponíveis.

### 5. Tela de resultado incompleta

A cena possuía apenas resultado e retorno ao hub. O script esperava detalhes e fluxo de Cria Live que não existiam na árvore final.

### 6. QA insuficiente

O workflow antigo validava principalmente JSON. Não verificava colisões globais, referências quebradas, contratos de cena, carregamento headless, save roundtrip ou inicialização real do combate.

## Upgrades aplicados

### Arquitetura

- `SignalBus` modular renomeado para `CoreSignalBus`.
- `DataRegistry` modular renomeado para `JsonDataRegistry`.
- `SaveManager` modular renomeado para `CareerSaveStore`.
- `CombatManager` modular renomeado para `CombatSimulationEngine`.

### Combate

- Integração do `TechniqueResolver` ao singleton `CombatManager`.
- Integração real com `CombatStateMachine`.
- Técnicas filtradas por posição, personagem e recursos.
- Custos e efeitos normalizados.
- Erros estruturados para técnica inexistente, combate inativo e lutador ausente.
- Finalização técnica, controle posicional e exaustão tratados no ciclo principal.
- Estado reiniciado ao abrir novo combate.

### UI e fluxo

- Main Menu responsivo com opção de áudio.
- Hub com status, faixa, energia e próxima ação recomendada.
- Arena com botões contextuais e custo em tooltip.
- Tela de resultado com método, recompensas, Cria Live e retorno seguro.
- Proteção contra navegação duplicada.

### Save/load

- Armazenamento modular com criação de diretórios validada.
- Escrita temporária antes da substituição do arquivo final.
- Smoke test de roundtrip em slot isolado.

## Novos validadores

### Auditoria estática

```bash
python tools/cria_forge/cria_forge.py validate
python tools/validate_complete_game.py
python tools/validate_runtime_contracts.py
```

`validate_runtime_contracts.py` verifica:

- JSON inválido.
- Main scene.
- Autoloads.
- Colisão de nomes globais.
- Referências `res://` inexistentes.
- Cenas obrigatórias.
- Nodes esperados por script.
- Canon do protagonista.
- IDs e transições das técnicas.
- Custos e probabilidades.
- Métodos essenciais.
- Possíveis segredos versionados.

### Godot headless

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/runtime_smoke.gd
```

O smoke test verifica:

- Autoloads centrais.
- DataRegistry.
- Cenas principais.
- Instanciação e `_ready()`.
- Save/load roundtrip.
- Inicialização do combate.
- Técnica inexistente tratada com segurança.
- Direção correta dos efeitos de redução.

## Workflow

Arquivo:

```txt
.github/workflows/runtime-audit.yml
```

Gates:

1. validação de dados;
2. validação da estrutura completa;
3. contratos estáticos;
4. import/parser do Godot 4.2.2;
5. smoke test headless;
6. upload de relatórios/logs.

## Limites honestos

Mesmo com os gates, a liberação de APK exige:

- workflow verde;
- Godot local ou CI com export templates;
- Android SDK/JDK configurados;
- `export_presets.cfg` de Android;
- assets finais importados;
- teste manual em aparelho físico;
- teste de desempenho, controles touch e diferentes proporções de tela.

## Definition of Done desta rodada

- [ ] Auditoria estática verde.
- [ ] Parser/import headless verde.
- [ ] Runtime smoke verde.
- [ ] Main Menu → Hub → Combate → Resultado → Hub validado.
- [ ] Save roundtrip validado.
- [ ] Nenhuma colisão entre autoload e `class_name`.
- [ ] Nenhuma referência essencial quebrada.
- [ ] PR revisado antes do merge.

## Veredito

Esta rodada transforma a garantia de funcionamento em um processo verificável. Nenhum documento deve declarar o jogo ou APK como finalizado enquanto os gates automatizados e o teste físico não estiverem verdes.
