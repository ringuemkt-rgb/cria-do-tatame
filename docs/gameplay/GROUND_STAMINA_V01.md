# Stamina de Solo V01

**Status:** integrada na vertical slice; calibracao inicial, nao dado biomecanico clinico.

**Fonte executavel:** `data/combat/ground_stamina_v01.json`.

O combate atual e resolvido por acoes. Por isso, a stamina de solo adiciona um custo de gas no momento em que uma tecnica e resolvida. Ela nao usa `_process`, cronometro de parede ou dreno invisivel por segundo.

## Regras

- cada um dos 14 estados da unica `CombatStateMachine` possui uma sobretaxa entre `0` e `2` de gas;
- posicoes defensivas exigentes custam mais do que posicoes dominantes equivalentes;
- abaixo de 50, 25 e 10 de gas, a chance e a eficacia de acoes tecnicas de finalizacao caem em faixas limitadas;
- tap e soltura nunca sao reduzidos pela fadiga;
- stamina nao causa dano de vida, lesao ou resultado grafico;
- todo calculo e offline, deterministico e dirigido pelo `CombatManager` existente.

`GroundStaminaRules` apenas interpreta os dados. O resolver continua sendo a autoridade da tecnica, e `SubmissionExchange` continua sendo a autoridade da troca segura controle x escape.

## Validacao

`python tools/audit/validate_ground_stamina.py` compara os estados com o grafo canonico, verifica os limites e impede autoload, `_process`, dano ou outcome de lesao.
