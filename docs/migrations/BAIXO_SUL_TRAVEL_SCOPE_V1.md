# Baixo Sul — escopo regional e compatibilidade de save

**Data:** 2026-10-11
**Status:** IMPLEMENTED_ON_BRANCH / AWAITING_CI / NOT_RELEASE_READY
**Dependency:** independent of PR #168; merge in the same regional-map release after review.

## Requirement
Preserve Ituberá as the main hub and limit active travel to available supported Baixo Sul scene destinations. User-provided image boards are art direction, not GPS or authoritative road topology. Salvador remains a read-only narrative/historical hub in legacy save metadata rather than a playable regional destination. Existing 10-page/40-node map data is left intact.

## Runtime rules
- WorldMapManager.PLAYABLE_HUB_IDS = [itubera, zambiapunga, camamu_manguezal].
- can_travel_to checks this whitelist and existing unlocked state and hub catalog.
- reset() never unlocks Salvador.
- load_from_dict sanitizes saved current_hub=salvador (or unsupported hub) to Ituberá, retains historical visited_hubs and travel_log, excludes old Salvador unlocks and syncs WorldState.current_hub.
- Travel charges, XP and progress remain the sole responsibility of WorldMapManager and ProgressionOS as before.
- Legacy hub data and map page 10 remain available as nonplayable reference. No deletion of saved historical records and no save schema bump.

## Tests
- tests/baixo_sul_travel_migration_smoke.gd: denied external travel, no charge/no travel event, hub recovery, retained travel history, and serialization roundtrip.
- tests/progression_os_smoke.gd: uses regional Zambiapunga in place of Salvador for first-visit XP and exploration discovery.

    godot --headless --editor --path . --import
    godot --headless --path . --script res://tests/baixo_sul_travel_migration_smoke.gd
    godot --headless --path . --script res://tests/progression_os_smoke.gd
    npm run quality

## Intentional exclusions / migration debt
- This does not promote new hubs, routes or invented roads from reference illustrations.
- Map UI is updated separately in PR #168; page 07 needs a geographically faithful separation of Maraú (playable region) and Itacaré (context).
- Saves loaded from external hubs re-enter Ituberá. The original history remains read-only; a future explicit full-save migration with version update may refine this.
- On rollback, restore the pre-change WorldMapManager and progression test, retaining save file bytes. No irreversible mutation or asset deletion.
