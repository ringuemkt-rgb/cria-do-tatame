# Sistema de Deck de Combate v1 — A Mente no Tatame

## Objetivo

O deck representa estudo, repetição e especialização. Ele não substitui o combate posicional: uma carta só produz bônus se a técnica existir no catálogo, estiver na mão, for compatível com o estado atual e puder pagar seus recursos.

## Contratos

- 5 cartas ativas equipadas;
- 3 fundamentos passivos;
- mão determinística de 3 cartas;
- níveis 1 a 5 limitados pela faixa;
- XP individual por uso: 10 no sucesso e 3 na tentativa válida;
- aperfeiçoamento no Terreiro por XP da técnica ou treino pago com Mestre Dendê;
- carta usada vai para rotação e a próxima é comprada sem alocação por frame;
- deck e XP persistem no save;
- técnicas vêm exclusivamente de `data/techniques.json`.

## Disputa de nível

`TechniqueClashResolver.gd` combina nível, potência-base, controle, foco, pegada/guarda e qualidade de timing. A defesa é reduzida quando há diferença de dois níveis, mas os resultados permanecem limitados:

| Delta | Resultado | Modificador |
|---|---|---:|
| > 15 | domínio técnico | +0,25 |
| 5 a 15 | vantagem | +0,12 |
| 0 a 4,99 | disputa | +0,03 |
| < 0 | janela de contra | -0,18 |

O bônus total é limitado entre -0,30 e +0,35. Mesmo em domínio técnico, o sucesso continua dependendo de posição, custo e simulação. `instant_finish` é sempre falso. Em finalizações válidas, o clash apenas define a vantagem inicial da pressão técnica/tap-escape.

## Integração

1. `DeckManager` carrega `ruan_deck_inicial.json` e registra a mão.
2. O HUD permite selecionar uma carta compatível sem pausar.
3. `CombatManager.execute_technique()` procura a carta ligada à técnica.
4. `TechniqueClashResolver` compara ataque e defesa.
5. `TechniqueResolver` recebe apenas o modificador limitado.
6. `FrameDataSystem` produz hit-stop, VFX, áudio e janela de contra como dados de apresentação.
7. O resultado concede XP, gira a mão e é persistido pelo `SaveManager`.

## UI

O Terreiro abre o `DeckBuilder`, com coleção à esquerda e slots do Gi à direita. O jogador pode tocar para equipar ou arrastar para substituir um slot. Durante a luta, `CombatDeckHUD` reutiliza três botões fixos e só habilita cartas válidas na posição atual.

Atalhos: teclas `1`, `2`, `3`; controle pelo direcional esquerdo, cima e direito; touch pelos três botões fixos. A ativação não pausa a simulação.

## Segurança e canon

- O sistema usa Ruan “Macacão” Silva e o canon atual.
- Não há técnicas inventadas nem referência a liga comercial.
- Finalizações terminam em tap, escape ou intervenção técnica.
- Não há animação de lesão como prêmio.
- IA generativa não participa do runtime.

## Validação

```bash
python tools/validate_lore_output.py data/ruan_deck_inicial.json
npm run quality
```

O validador rejeita técnica inexistente, carta duplicada, slot incompatível, carta bloqueada equipada, excesso de slots, nível acima da faixa e identificadores legados.
