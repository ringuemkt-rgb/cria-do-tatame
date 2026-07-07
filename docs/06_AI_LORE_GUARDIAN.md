# 06 - Sistema IA Lore Guardian

## Objetivo

Usar IA para gerar, revisar e validar conteúdo narrativo sem quebrar o canon.

A IA generativa **não segura o gameplay nas costas**. Ela cria e valida conteúdo. O jogo executa JSON estável, offline e testável.

---

## Dentro do jogo

- IA de luta por state machine.
- NPCs por rotina.
- Eventos por gatilho.
- Cria Live por banco de posts e templates.

---

## Fora do jogo

- Lore Guardian com RAG.
- Modelo local leve.
- Banco vetorial opcional.
- Validação por schemas.
- Geração assistida de missões, diálogos, NPCs e posts.

---

## Fluxo seguro

```txt
Documentos canônicos → Lore Guardian → JSON proposto → validação schema → revisão humana → data/*.json → Godot
```

---

## Regras

- Nunca alterar canon sem registro.
- Nunca substituir Ruan “Macacão” por versões antigas.
- Nunca misturar personagens legados na campanha principal sem tag `legacy`.
- Toda missão gerada precisa declarar: ato, região, NPCs, recompensa, risco, eixo moral e pré-requisitos.
