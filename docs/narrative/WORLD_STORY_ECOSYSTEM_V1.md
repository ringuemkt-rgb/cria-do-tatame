# Ecossistema de história — Cria do Tatame (v1)

Status: `CANDIDATE_OVERLAY`. Não substitui `canon_v3` / `acts_v3` / `character_bible_v1`.
Contrato máquina: `data/narrative/world_story_ecosystem_v1.json`.

## Tese e conflito

Ser forte é ser gentil.
Dominação (Chupeta / Sombra / Avesso) vs cuidado (Terreiro / Dendê / Teruko).

## Loop que o jogo precisa manter bootável

Menu → Terreiro da Luta → treino/deck → combate (CombatManager) → resultado → Cria Live → semana → save → Terreiro.

Mundo aberto **não** é GTA. É atlas pintado (10 páginas) + viagem + rotina de NPC determinística + lua/maré/chuva no presenter. Cap 3 atores visíveis no plate.

## Atos

| Ato | Lugar | Progresso | Set-piece |
|---|---|---|---|
| P0 Carro de Mão | Feira Ituberá | semente honra/sombra | pulso do Dendê |
| A1 Raiz | Terreiro / Dique | branca→azul | luta do Dique |
| A2 Circuito | Valença–Camamu | azul→roxa | Concha vs Davi |
| A3 Sombra | clandestinas | roxa→marrom | Ferro Velho |
| A4 Território | mapa em guerra | marrom→preta | Pratigi do Avesso |
| A5 Verdade | Salvador | preta | Chupeta + Estadual |

Finais: Herói da Comunidade (honra), Rei das Sombras (sombra + volta possível), Verdade (≥8 fragmentos Teruko).

## Pessoas

Lock de arte agora: `ruan_macacao`, `davi_relampago`, `mestre_dende`.
Candidatos (concept): Tinker Bell, Degodo, Leoa, Chupeta, Sombra, molecada (Bala/Pipoca/Foguete), Filó, Doro, Sumiko, Vera, Montanha.
Oni do briefing mapeia para `oni_da_lapa` até o autor fundir o ID.

## Mapa vivo

- Página ouro: Ituberá 02.
- Tempo: `week`, `day_index`, bloco (alba/manhã/tarde/noite).
- Lua: `(week*7+day_index)%8`. Avesso pede lua cheia + maré baixa.
- Facção no A2 colore rota; LEI é institucional, não 4ª cultura.
- NPCEcologyEngineV1 agenda; atlas só mostra quem o snapshot pede.

## Combate no ecossistema

Deck 6–8 técnicas. Tinker sugere (scouting), não julga. Nemesis estuda Cria Live. Heat alto encerra luta sem minigame de fuga. V2 de grappling é apresentação.

## Como atualizar daqui pra frente

1. Cena nova → ID em `acts_v3` + missão em `missions_v1`.
2. Pessoa nova → bible + `roster_candidate` neste overlay.
3. Rotina de mapa → ecology, não PNG.
4. Arte → lote visual; este arquivo não gera sprite.
