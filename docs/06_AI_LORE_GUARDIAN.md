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

## Protocolo visual obrigatório

Toda saída narrativa que descreva aparência, cenário, HUD, mapa, arena, facção, mascote, tipografia, cor ou composição deve consultar:

- [`ART_PROTOCOL.md`](ART_PROTOCOL.md) — fonte única de verdade da execução visual;
- [`../data/art_tokens.json`](../data/art_tokens.json) — tokens machine-readable;
- [`../data/visual/visual_canon_contract_v2.json`](../data/visual/visual_canon_contract_v2.json) — contrato visual geral.

O Lore Guardian não pode criar paleta, fonte, ícone, proporção ou HUD fora do protocolo. Quando texto narrativo e direção visual divergirem, o texto é corrigido para o protocolo; IDs, fatos de cânone, licença e origem continuam subordinados aos contratos executáveis correspondentes.

Saída de IA permanece `reference_only` ou `production_candidate` até revisão humana, QA, integração Godot e teste aplicável.
