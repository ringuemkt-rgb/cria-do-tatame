# Regional destination preview — vertical slice (2026-11-19)

## Purpose
`WorldMapManager.preview_travel_to(hub_id)` exposes a read-only preflight for the existing atlas/destination UI. It does not create roads, georeferenced maps, or an alternative world manager.

## Contract
- A destination outside `PLAYABLE_HUB_IDS`, not unlocked, or without a hub entry returns `ok: false, reason: unavailable`.
- The current hub returns `ok: true, already_here: true`, zero cost and zero hours.
- Valid other hubs return canonical `hub_id`, `name`, `cost`, `hours`, `advances_day`, and `affordable` based on current `WorldState.money`.
- Invalid numeric cost or time fails closed with `reason: invalid_travel_data`.
- The method never debits funds, changes calendar, emits travel, changes location, writes save, or generates paths. The existing `travel_to` remains the sole mutating command.

## Tests
```sh
godot --headless --path . --script res://tests/regional_travel_preview_smoke.gd
npm run quality
```

## Integration and release gates
- Future atlas wiring must call preview on destination selection, then call `travel_to` only after explicit confirmation; preview does **not** reserve a price.
- #167–#169 historical integration and #164/#166 combat-animation dependencies require independent review before merge.
- Godot headless, repository CI, human review, rights/provenance for Sprite Forge, and Android physical testing remain separate gates. No new art is promoted here.
