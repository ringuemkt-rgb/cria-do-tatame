# Pratigi — Festival Maré Alta, Rota Paralela

**Status:** IMPLEMENTED — vertical slice de runtime; arte e áudio finais ainda pendentes de produção humana.
**Versão:** 1.0.0
**Escopo:** arena jogável de Pratigi, aposta interna opcional, heat, interdição, maré visual, Cria Live e acesso pelo mapa.

## Decisão de produto

`praia_de_pratigi_festival` é uma variante ficcional e paralela de `praia_de_pratigi`. Não substitui a praia canônica diurna, não representa festival real e não altera a Arena do Dique, que permanece circuito oficial em Salvador.

A variante testa a tese “violência com consequência”:

- o público e o palco elevam hype e exposição;
- a aposta usa apenas dinheiro já existente no save, com limite e retorno explícitos;
- o heat cresce de forma legível;
- no limite, o combate é encerrado com segurança;
- não existe ação de fugir, esconder prova ou enfrentar autoridade;
- tap e parada técnica permanecem obrigatórios.

## Fluxo executável

```text
Terreiro → Mapa do Baixo Sul → Pratigi (Ato 2)
→ pré-luta e aposta opcional → combate canônico Ruan × Davi
→ heat/aviso/interdição ou resultado
→ Cria Live + reputação + save → resultado/mapa
```

## Componentes

- `PratigiFestivalArena.tscn`: cena completa, HUD, cantos, mediador, DJ, crowd e marcadores de produção;
- `PratigiFestivalBackdrop.gd`: representação procedural temporária mobile-first;
- `AnimatedWaterLine.gd`: frente do mar animada e modo de movimento reduzido;
- `ClandestineEventDirector.gd`: estado, aposta, exposição, warning, interdição e liquidação;
- `pratigi_festival_v01.json`: balanceamento e políticas de segurança;
- `validate_pratigi_festival.py`: gate de dados, consumidor, cena e limites éticos;
- `pratigi_festival_smoke.gd`: smoke headless do diretor e do parse da cena.

## Rollback

Remover o hub `pratigi_festival`, o botão do mapa, a variante em `arenas.json` e os arquivos listados acima. As alterações aditivas de `CombatArenaBase`, `CombatManager`, `AudioManager` e `CriaLiveManager` podem ser revertidas separadamente sem migração de save; os dados persistidos vivem em `story_flags` e são ignorados por versões anteriores.

## Limitações reais

- backdrop, crowd, mediador e DJ são arte procedural representativa, não asset final aprovado;
- os tons do `AudioManager` são cues funcionais, não trilha final;
- a maré desta cena é visual e comprimida para apresentação; navegação marítima regional continua em lote próprio;
- teste em Android físico permanece obrigatório antes de promoção para shipping.
