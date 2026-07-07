# Hybrid Game Forge Runtime Handoff v0.7

## Decisao

Nao escolher A, B ou C. Executar os tres blocos.

## A — DataRegistry

DataRegistry agora carrega os dez JSONs canonicos da pasta data e gera validation_report basico.

## B — CombatManager

CombatManager agora usa recursos:

- gas;
- focus;
- grip;
- grip_integrity;
- control;
- moral.

Tambem executa tecnica data-driven quando o id existe no DataRegistry.

## C — Fluxo de cenas

O fluxo minimo foi criado:

```txt
Main Menu -> Terreiro da Luta -> Combat Arena Base -> Result Screen -> Terreiro da Luta
```

## Regra seguinte

A proxima etapa deve ser corrigir erros de parse no Godot local e trocar os placeholders por sprites/HUD finais.
