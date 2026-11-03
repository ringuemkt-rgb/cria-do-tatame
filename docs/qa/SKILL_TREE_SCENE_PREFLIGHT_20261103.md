# Skill tree scene preflight — 2026-11-03

Status: DRAFT / stacked on PR #191 (which is stacked on #189).

## Functional delta
The existing SkillTreeScreen checks the PackedScene resource before calling SaveManager.save_game(1) when navigating to the Terreiro or DeckBuilder. An absent scene now keeps the current screen interactive and displays the caller's error. This prevents an unnecessary save attempt on a known-bad navigation destination. The existing save-failure guard, transition lock, and current managers are unchanged.

## Test
`godot --headless --editor --path . --quit`
`godot --headless --path . --script res://tests/skill_tree_deck_smoke.gd`
`npm run quality`

Regression covers an intentionally missing PackedScene, reset of the transition lock, visible error, and no mutation of WorldState/DeckManager. The test does not prove that no disk write occurred; the preflight ordering in source establishes that property. Full runtime, Android export, physical touch, and human review remain required.

## Integration and rollback
Merge order: #189 → #191 → this PR, subject to required CI and human review. No independent cherry-pick into main until dependent changes are reconciled. Revert the focused preflight commit and test commit if the guard causes regressions. No save schema, autoload, world route, combat, or asset changes. Ituberá remains the hub; Salvador and Itacaré remain outside playable travel.
