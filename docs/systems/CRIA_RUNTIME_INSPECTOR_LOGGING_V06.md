# Cria Runtime Inspector e Logging v0.6

## Objetivo

Tornar o jogo facil de depurar por humano e por IA.

## Principios

- todo sistema importante gera log estruturado;
- cada luta pode gerar snapshot;
- cada tecnica registra estado inicial, estado final e resultado;
- cada bug precisa de estado reproduzivel.

## Prefixos de log sugeridos

```txt
[CRIA:COMBAT]
[CRIA:CAREER]
[CRIA:AI]
[CRIA:ART]
[CRIA:QA]
[CRIA:SAVE]
```

## Snapshot minimo

```json
{
  "state": "disputa_pegada",
  "player_gas": 70,
  "opponent_gas": 65,
  "last_technique": "baiana",
  "score": {"player": 2, "opponent": 0}
}
```

## Uso

Quando a IA for corrigir o jogo, ela deve olhar primeiro o snapshot e os logs, nao apenas o visual.
