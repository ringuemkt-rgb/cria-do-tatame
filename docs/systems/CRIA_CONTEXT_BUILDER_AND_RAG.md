# Cria Context Builder e RAG Canonico

## Objetivo

Criar um sistema que monta o contexto correto para cada cena, luta, treino ou decisao de carreira, usando apenas documentos canonicos do projeto.

## Fontes canonicas

- Biblia do jogo;
- tecnica_codex;
- fluxo de combate;
- mapa Baixo Sul;
- fichas de personagem;
- fichas de arena;
- historico salvo da carreira;
- relatorios de luta;
- Cria Live;
- notas de Mestre Dende.

## Problema que resolve

Sem um montador de contexto, a IA pode esquecer:

- quem e Ruan Macacao;
- onde fica a arena;
- qual e o estilo do rival;
- que tecnica foi treinada;
- que escolha moral aconteceu;
- que regra do combate vale naquele estado.

## Fluxo

1. receber pedido de cena ou sistema;
2. identificar tipo: luta, treino, mapa, dialogo, sprite, arena, QA;
3. buscar documentos relevantes;
4. filtrar apenas canon atualizado;
5. montar contexto curto;
6. passar para IA, Codex, Manus ou ferramenta;
7. registrar resultado no log.

## Formato de contexto

```txt
Cena: treino de baiana
Personagem: Ruan Macacao Silva
Local: Terreiro da Luta
Mentor: Mestre Dende
Objetivo: melhorar entrada de queda
Tecnicas relevantes: pegada, queda de nivel, drive, estabilizacao
Estado de combate: disputa de pegada -> queda -> guarda por cima
Tom: PT-BR, tatame, direto, respeitoso
Restricoes: sem copiar video, sem marca real, sem violencia explicita
```

## Implementacao sugerida

- docs_index.json;
- CanonRegistry.gd;
- ContextBuilder.gd;
- SearchIndexBuilder.py;
- retrieve_context.py;
- context_pack.md.

## Regra

A IA nunca deve decidir com base em memoria solta quando existe documento canonico no projeto.
