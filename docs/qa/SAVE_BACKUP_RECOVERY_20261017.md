# Save backup recovery — 2026-10-17

**Status:** VALIDATED LOCALLY / PR #165 / NOT MERGED

A normal save may promote a new primary after corruption without rotating the corrupt bytes over `.bak`. Recovery preserves `.bak`; unsuccessful restoration leaves migration in memory. The schema, autoloads and slot naming remain unchanged.

The I/O smoke compares backup bytes directly and checks the promoted JSON fields explicitly, avoiding numeric-type differences introduced by JSON decoding. The failed-restore runtime smoke now runs in CI in addition to the structural migration guard.

## Evidence

Godot 4.3 stable official `77dcf97d8`, Linux headless:

- editor import: exit 0, no script/parser/resource errors;
- `save_backup_atomic_integrity_smoke.gd`: PASS;
- `save_backup_failed_restore_migration_smoke.gd`: PASS;
- `save_backup_failed_restore_runtime_smoke.gd`: PASS, directory fault injection preserved backup bytes and skipped migration persistence;
- `runtime_smoke.gd`: 126 checks, 0 failures.

`npm run quality` was executed and failed at the pre-existing Sprite Forge Phase 1 gate: `davi_relampago`, no QA profile for `counter_entry`. The same validator fails on unmodified main `099c060`. This change does not repair or waive that gate.

No Android/Windows durability claim, physical-device certification, merge, or human asset approval is implied. Revert this focused commit to roll back; do not delete player backups.
