# Skill Tree → Deck: safe direct navigation (2026-11-02)

**Status:** IMPLEMENTED IN STACKED DRAFT BRANCH; automated CI and human review required.  
**Source branch:** `fix/skill-tree-mobile-tabs-save-guard-20261031` (PR #189, head `000c69708ac0262dad82ce676a4b5d3fa40d50b8`).  
**Independent mobile dependency:** PR #188 (responsive DeckBuilder).  
**Runtime authorities:** WorldState, SkillTreeRulesV1, DeckManager and SaveManager remain unchanged.

## Functional gap and consumer

A player unlocking `caca_ao_pescoco` or `ataque_de_braco` in the existing 51-node tree had to exit to Terreiro and then open the deck manually. The mobile skill details tab now exposes **ABRIR DECK** next to **DESBLOQUEAR**. The same existing `DeckBuilder.tscn` is opened, without a duplicate editor, new manager, changed card ID, or altered save schema.

The action row is horizontal inside the details panel so compact portrait and 640×360 landscape do not gain another 60-pixel-tall stacked row. Compact unlock captions shorten automatically and restore full wording on desktop/rotation.

## Save and navigation behavior

Both **VOLTAR AO TERREIRO** and **ABRIR DECK** call one guarded transition function. It rejects duplicate presses while changing scenes, saves through `SaveManager.save_game(1)` before navigation, stays on the tree if the save fails, and reports an error if Godot cannot open the destination. A purchased skill and card reward are never silently abandoned by the UI navigation path. This does not claim atomic disk persistence for the underlying save subsystem.

## Automated regression

```bash
npm run quality
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/skill_tree_deck_smoke.gd
godot --headless --path . --script res://tests/deck_builder_mobile_touch_smoke.gd
godot --headless --path . --script res://tests/first_run_flow_smoke.gd
```

The existing tree smoke checks the real scene, the linked `DeckBuilder.tscn`, the button signal, a duplicate-transition guard without writing a save, action-row layout, compact touch dimensions and captions after desktop restoration. The tree/deck rules smoke still covers skill points, reward cards, transactional equip and in-memory serialization.

**Not yet demonstrated by these checks:** forced disk-write failure with actual Android storage permissions, physical touch/rotation/cutout, frame-rate, visual approval, and save after process restart. These remain human/device gates.

## Integration order and review

1. Review PR #188 (mobile deck) and PR #189 (mobile skill tree) independently. Neither should be merged without required green checks and human review.
2. This change is stacked on PR #189; after #189 is accepted, rebase this PR onto updated `main`. Verify #188's responsive editor is integrated before claiming end-to-end mobile readiness.
3. Re-run repository quality, Godot 4.2.2/4.3 parser/import, tree/deck, first-run, save and Android debug export on the final combined head.
4. Keep historical unresolved review threads in #165 (save) and #168 (atlas) visible for human disposition; CI success alone does not resolve them.

Ituberá remains the hub; Salvador and Itacaré are not destinations. No roads, coordinates, world data, or unlicensed visual assets are added. Sprite Forge rights/metadata/QA/human promotion gates remain unchanged.

**Rollback:** revert this branch's SkillTreeScreen, tree smoke and QA note. No data migration or saved-state rollback is required.
