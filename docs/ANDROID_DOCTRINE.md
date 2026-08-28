# Android Doctrine — Mobile Baseline

Status: canonical operating doctrine under D75
CTX: CRIA-WORK-v2@cfbc572
Decision refs: D36, D43, D47, D55, D75, D85

## Baseline
- Android ARM64 is the required device target for the vertical slice.
- Touch targets: minimum 48 dp.
- Critical combat/UI text and silhouettes must remain readable at the 72 px review scale used by visual QA.
- Target presentation: 60 fps when device permits; acceptance floor for low-end profile: stable 30 fps without gameplay timing divergence.
- Input buffering must follow D85 and may not bypass invalid state locks.

## Per-stage hard budgets
Inherited from D47:
- atlases 2048²: max 2;
- draw calls: max 24;
- simultaneous particles: max 64;
- animated crowd actors: max 4; baked crowd is default.

## Runtime working budgets
These are engineering ceilings for profiling, not promises of hardware support:
- gameplay frame CPU budget at 60 fps: <= 16.67 ms total frame;
- low-end 30 fps ceiling: <= 33.33 ms total frame;
- avoid frame-time spikes > 50 ms during normal combat flow;
- texture/audio assets must be imported in mobile-appropriate compressed forms before device promotion;
- no synchronous large-file load inside an active combat exchange.

## Device gate
A build cannot become `device_validated` without: install, launch, 10-minute checklist, crash-free combat loop, save/load, result→hub, 48 dp touch check, 72 px readability check, and human GATE05.

## Fail-closed
If profiling evidence is absent, the state remains `device_candidate`. Desktop/web success never substitutes the Android gate.
