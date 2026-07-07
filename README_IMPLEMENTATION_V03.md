# Cria do Tatame — Implementation v0.3

Este pacote adiciona a base técnica do **Cria Positional Grappling Engine**, o núcleo de combate autoral do jogo **Cria do Tatame – Pressão**.

## Regra de produção

O objetivo é atingir qualidade de produto grande, com responsividade, leitura visual, carreira, progressão, IA e feedback de alto nível. O projeto **não copia código, assets, marcas, animações, nomes licenciados ou sistemas proprietários** de jogos comerciais.

## Canon obrigatório

- Protagonista: **Ruan “Macacão” Silva**.
- Símbolo: **Gorila Silverback**.
- Estilo: pressão pesada, grip de ferro, top game dominante.
- Frase moral: **Ser forte é ser gentil.**
- Combate: Jiu-Jitsu posicional, técnico, esportivo, com tap/escape/intervenção segura.
- Hub inicial: **Terreiro da Luta — Ituberá, BA**.
- Circuito oficial: **Arena do Dique — Salvador, BA**.

## Arquivos adicionados

```txt
src/core/SignalBus.gd
src/core/CombatConstants.gd
src/combat/FighterStats.gd
src/combat/CombatInputRouter.gd
src/combat/PositionalStateMachine.gd
src/combat/DefenseTimingResolver.gd
src/combat/TechniqueResolver.gd
src/combat/TransitionResolver.gd
src/combat/ScoringSystem.gd
src/combat/TechnicalFinishEngine.gd
src/combat/ArenaModifierSystem.gd
src/combat/RivalAIController.gd
src/combat/CombatManager.gd

data/techniques_dynamic_grapple_v03.json
data/rival_gameplans_v03.json

docs/implementation/UFC_QUALITY_IMPLEMENTATION_PLAN.md
```

## Vertical Slice alvo

```txt
Ruan “Macacão” Silva vs Davi Relâmpago
Arena: Terreiro da Luta
Estados mínimos: DISTANCIA_MEDIA, GRIP_FIGHT, CLINCH_NEUTRO, QUEDA_DISPUTA, GUARDA_FECHADA_TOP, SIDE_CONTROL, MONTADA, COSTAS, TECHNICAL_FINISH_SETUP, TECHNICAL_FINISH_CONTROL, TAP_OR_ESCAPE, RESET
```

## Filosofia do combate

```txt
Não aperte botão para bater.
Construa posição para dominar.
Finalize com respeito.
```

## Próxima etapa

1. Criar cenas Godot correspondentes.
2. Registrar autoloads: `SignalBus`, `CombatManager`.
3. Conectar HUD aos sinais do `SignalBus`.
4. Substituir placeholders por spritesheets HD Pixel Art 2.5D.
5. Testar o loop completo: pegada → clinch → queda → controle → finalização técnica → tap/escape.
