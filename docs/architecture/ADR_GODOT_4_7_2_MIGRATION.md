# ADR — Migração futura para Godot 4.7.2

**Status:** PROPOSED / SEPARATE LOT
**Decisão:** D19
**Data:** 2026-08-27

## Contexto

O runtime e a CI atuais estão auditados em Godot 4.2.2. A versão 4.7.2 não pode entrar por lote de arte, cânone ou conteúdo.

## Decisão

A migração terá branch própria e não faz parte de `lead/calibracao-v1`.

## Gates obrigatórios

1. inventário de APIs, addons e importers;
2. import/parser limpo;
3. runtime, full-game e faction smokes;
4. save/load e migração de save;
5. export Android ARM64;
6. export e smoke Windows;
7. export e smoke Web/PWA;
8. perfil de desempenho;
9. rollback documentado;
10. teste físico e decisão humana.

Até esses gates, 4.7.2 é candidata, não versão integrada.
