# Animation Runtime Plan v0.1

## Objetivo

Transformar o vertical slice em combate visualmente legivel antes da arte final.

## Estrategia

1. Fase placeholder: FighterPlaceholder.gd anima escala, rotacao, deslocamento e brilho.
2. Fase sprite sheet: cada acao recebe atlas PNG e manifest JSON.
3. Fase AnimationPlayer: importar frames, criar animacoes one-shot e loops.
4. Fase AnimationTree: conectar estados da state machine BJJ.

## Animacoes por personagem

- idle: loop
- walk: loop
- stance: loop curto
- grip_attempt: one-shot
- grip_success: one-shot
- clinch: loop de controle
- takedown: one-shot
- guard: loop posicional
- pass: one-shot
- mount: one-shot
- technical_setup: one-shot
- technical_lock: loop curto
- technical_finish: one-shot esportivo
- win: one-shot
- lose: one-shot

## Eventos de animacao

- frame_de_pegada
- frame_de_contato
- frame_de_transicao
- frame_de_estabilizacao
- frame_de_resultado

## Regra

A animacao deve comunicar posicao, base, pegada e proxima transicao. Bonito sem leitura nao entra no jogo.

## Implementação de preview pareado (11/10/2026)

**Estado:** IMPLEMENTADO EM BRANCH / NÃO É ANIMAÇÃO FINAL, NÃO É SHIP-READY.
**PR-base:** #157 (combate estável e testes de ações); PR #161 compartilha a mesma base e precisa de reconciliação antes da integração.

### Arquivos consumidos pelo jogo

- `src/characters/FighterRigPreviewV1.gd`: silhueta articulada procedural com posturas de pé, pegada, shot, sprawl, guarda, passagem, montada, finalização, impacto e vitória. É apenas fallback provisório enquanto não existem sprites aprovados; nenhuma biomecânica inferida.
- `src/characters/FighterPlaceholder.gd`: mantém suporte aos atlases existentes via `CharacterAnimationLibrary`; quando ausentes, desenha rig provisório com kimono da cor de cada lutador.
- `data/animation/combat_pair_preview_v1.json`: mapeamento **visual**, versão 1.0.0, de 21 IDs do catálogo para dez perfis de apresentação sincronizada. `shipping=false`.
- `src/animation/CombatPairTimelineV1.gd`: único relógio visual de seis fases dos dois lutadores, ancorado à posição que `CombatManager` resolveu. Sem autoload. Não altera estado de combate.
- `scenes/combat/CombatArenaBase.gd`: utiliza a timeline após uma ação aceita do jogador ou IA e espera o encerramento visual antes de enviar a tela de resultado. Erros/rejeições não geram animação.
- `tests/combat_paired_motion_smoke.gd` e `.github/workflows/paired-combat-preview-v1.yml`: testes no Godot headless, incluindo regressão do fluxo de combate.

### Semântica das seis fases

1. anticipation — anuncia a intenção/pegada;
2. entry — entrada, mudança de nível ou aproximação;
3. establish — compromisso visual e posição de contato **ilustrativa**;
4. stabilize — postura de consolidação visual; a pontuação real permanece no juiz;
5. response — defender responde de forma pareada;
6. recovery — ambos assumem a postura do estado autoritativo final.

A duração dos movimentos ilustrativos não é igual a 3 s de estabilização regulamentar. O timer e o escore permanecem exclusivamente no combate real.

### Como validar

```bash
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/combat_paired_motion_smoke.gd
godot --headless --path . --script res://tests/combat_action_safety_smoke.gd
godot --headless --path . --script res://tests/runtime_smoke.gd
npm run quality
```

### Limites e trabalho restante

**Não promova esse preview como arte final.** Faltam animações RGBA normalizadas de 128×128, pivô [64,96], seis fases por técnica em GI e No-Gi, sprites de atacante e defensor sincronizados, checagem de contato e oclusão, cenas e frames comparados contra fontes com autorização, curadoria humana e teste Android físico. As imagens de conceito são referência visual, não sprites importáveis automaticamente. O renderer procedural não decide quais contatos são reais nem exige dependência de IA online.

### Integração futura

Quando os pacotes de `assets/sprites/<fighter>/<action>/manifest.json` forem aprovados, `FighterPlaceholder` já priorizará esses atlases. Antes de aprovar uma técnica pareada definitiva, adicionar no motion binding as trilhas/markers aprovados para ambos os personagens; substituir somente a camada de visualização, preservando os IDs e a autoridade `CombatManager`.
