# Regional save v6 normalization — 2026-10-23

**Status:** draft integration patch; stacked on PR #175. Human approval and Android physical test pending.

## Bug and affected save versions

`WorldMapManager.load_from_dict()` correctly recovers a legacy active destination outside the playable Baixo Sul region to Ituberá. Before this patch, `SaveManager` could leave the old destination persisted on disk. This affected v5 migration and v6 saves that already had `progression_state` and therefore did not trigger the existing migration path.

## Runtime contract

- `WorldMapManager` remains the sole authority for playable hubs. `PLAYABLE_HUB_IDS` is unchanged.
- On load, compare the persisted regional fields (`current_hub`, `unlocked_hubs`, `visited_hubs`, `travel_log`) against the normalized map state.
- Persist the normalized map during migration while preserving unknown map metadata, historical visits and historical travel logs.
- A region-only correction must **not** re-import legacy progression rewards. The original v6/progression/faction migration condition remains independent.
- Keep the original save as a byte-identical `.bak` when migration succeeds. If backup restoration fails, do not persist a migrated replacement over the recoverable source.
- Ituberá remains the hub. Salvador and Itacaré are narrative context only; no new roads, coordinates, playable locations or georeferencing are introduced.

## Regression

`tests/regional_save_v6_persistence_smoke.gd` uses isolated negative QA slot IDs, refuses collisions, creates v5/v6 fixtures with historical Salvador/Itacaré data, reloads through the real `SaveManager`, verifies normalized playable state and historical metadata, checks the original backup byte-for-byte, and removes QA files. The workflow `regional-save-v6-smoke.yml` runs Godot 4.3 import, regression and `npm run quality`.

## Integration and release gates

Review against #165 (backup safety), #167 (progression rewards), #168 (atlas), #169 (regional travel) and #175 (combined runtime). No merge to `main` without required CI, human review and save-migration checks. Physical Android verification must include restoring an actual old save, inspecting available destinations, saving/restarting and confirming the same normalized state. This patch does not certify an APK or any visual asset.

## Rollback

Revert the `SaveManager.gd` change if regression appears; preserve user save files and backups. Do not delete or rewrite real user saves as part of QA.
