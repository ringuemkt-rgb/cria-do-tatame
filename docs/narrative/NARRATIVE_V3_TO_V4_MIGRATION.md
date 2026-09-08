# Narrative v3 → v4 candidate migration

Status: **candidate, not runtime authority**.

Current runtime/canonical authority remains `data/narrative/canon_v3.json` until explicit promotion.

## Purpose

Materialize the approved full-script direction without silently rewriting existing persistent IDs, endings or runtime assumptions.

## Stable identities

The five act IDs remain unchanged:

- `ato_1_o_chao` — display subtitle `RAIZ`
- `ato_2_o_molde` — display subtitle `CIRCUITO`
- `ato_3_o_nome` — display subtitle `SOMBRA`
- `ato_4_a_queda` — display subtitle `TERRITORIO`
- `ato_5_o_legado` — display subtitle `VERDADE`

`Parte Zero — O Carro de Mão` is a new pre-Act-1 prologue and does not renumber the five acts.

## Intentional v4 deltas

1. Vera remains `vera_salles`, but recruitment moves from optional Act 3 to mandatory end of Act 2.
2. Tinker knows the operation from Act 2; the Act-5 reveal becomes the hidden final operational detail / reason for his distancing, not a first-time PF reveal.
3. Chupeta is a new character candidate for coercion/betting/militia. He cannot replace Cassio, Sombra or Montenegro until character-registry migration is approved.
4. Pipoca survives and represents the next generation at risk. Biel remains the irreversible Act-4 loss.
5. Dendê admits that he perpetuated silence; the migration does not make him sole author of Teruko's erasure.
6. Teruko's name remains forbidden in public/spoken material before `truth_fragments >= 8`; after the gate, the name may be spoken, printed and sung by the Coro.
7. `A Verdade` remains an overlay compatible with either main ending, not a third mutually exclusive main ending.
8. Against Chupeta, Ruan releases the submission and stabilizes positional control before intervention. The mechanical payoff is restraint, not prolonged submission.
9. Act 5 retains restitution, Davi rematch, Byaku rematch, Dandara and Instituto CRIA.
10. The wheelbarrow motif returns in the hero ending.

## Explicit non-migrations

- No save IDs are renamed.
- No mission IDs are changed in this batch.
- `canon_v3.json`, `acts_v3.json`, `dialogues.json` and `endings_v2.json` are not edited.
- Rating remains the current 16+ tone contract pending a separate content-rating review.
- Runtime managers and scenes are unchanged.

## Promotion gate

Promotion to active narrative authority requires:

1. `validate_narrative_v4_candidate.py` pass;
2. repository quality pass;
3. human canon approval;
4. mission/runtime mapping plan;
5. character-registry decision for Chupeta;
6. save migration review if any persistent narrative state changes.

Rollback is deletion of the v4 candidate files; v3 remains untouched throughout this phase.
