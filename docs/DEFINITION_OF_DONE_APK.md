# Definition of Done — APK do Vertical Slice

**Status:** BINDING ACCEPTANCE GATE  
**Decision:** D233  
**Target:** physical Android ARM64 device  
**Rule:** no new feature enters until every required item below is green.

## Governing question

Can Ruan, on a real ARM64 Android device, enter the Terreiro, start a drill and a fight, use the six canonical techniques through eligibility, defend using millisecond timing, use sovereign TAP at any time during a suffered submission, reach the result screen with metrics, save, close the game, reopen at the same point, and continue for ten minutes without a crash?

Only **YES with evidence** closes the slice gate.

## Required evidence header

- APK/build identifier: ______________________________
- Git commit SHA: ___________________________________
- Device model: _____________________________________
- Android version: __________________________________
- Architecture confirmed ARM64: [ ] YES
- Test date/time: ___________________________________
- Tester: ___________________________________________

## 1. Boot and Terreiro

- [ ] APK installs on the physical ARM64 device.
- [ ] Game boots without fatal error.
- [ ] Ruan reaches/enters the Terreiro through the shipping slice flow.
- [ ] No placeholder flow bypass is required.

Evidence/notes: ______________________________________________

## 2. Onboarding / drill

- [ ] At least one canonical onboarding drill starts from the Terreiro.
- [ ] Input feedback is visible and no required input is dead.
- [ ] Drill can complete and return a result/progression state.

Evidence/notes: ______________________________________________

## 3. Fight start and six-technique eligibility

- [ ] A slice fight can be started from the approved flow.
- [ ] All six canonical techniques can become eligible in their valid state/context.
- [ ] Ineligible techniques do not execute silently.
- [ ] Every blocked/ineligible action has visible reason or is unavailable before input.

Technique 01 ID: __________________ [ ] PASS  
Technique 02 ID: __________________ [ ] PASS  
Technique 03 ID: __________________ [ ] PASS  
Technique 04 ID: __________________ [ ] PASS  
Technique 05 ID: __________________ [ ] PASS  
Technique 06 ID: __________________ [ ] PASS

## 4. Timing defense in milliseconds

- [ ] Runtime consumes timing windows expressed in milliseconds.
- [ ] Early feedback is distinguishable.
- [ ] Perfect feedback is distinguishable.
- [ ] Late feedback is distinguishable.
- [ ] Input buffer behavior matches `data/ux/controls_slice_v1.json`.
- [ ] Refresh/frame rate does not redefine the canonical window values.

Evidence/notes: ______________________________________________

## 5. Sovereign TAP

- [ ] During a suffered submission, TAP is always reachable.
- [ ] Hold TAP causes immediate safe release/reset.
- [ ] TAP works while another contextual action would otherwise use the same physical button.
- [ ] TAP is not blocked by animation lock.
- [ ] TAP is not blocked by input buffer.
- [ ] TAP is not blocked by combo state.
- [ ] TAP is not blocked by interrupt lock.

Evidence/notes: ______________________________________________

## 6. Result screen and metrics

- [ ] Fight reaches a deterministic result screen.
- [ ] Result shows the slice metrics required by the active runtime.
- [ ] Result state is consistent with what happened in the fight.
- [ ] Returning from result does not corrupt navigation or progression state.

Evidence/notes: ______________________________________________

## 7. Save / close / reopen / same point

- [ ] Save is produced through the normal slice flow.
- [ ] App is fully closed after save.
- [ ] App is reopened from the installed APK.
- [ ] Continue/load restores the same logical point required by the slice.
- [ ] Required combat/progression state survives roundtrip.
- [ ] No manual save-file edit or debug teleport is used.

Evidence/notes: ______________________________________________

## 8. Ten-minute stability run

Start time: __________  End time: __________  

During ten continuous minutes on the same physical ARM64 device:

- [ ] no crash;
- [ ] no soft-lock;
- [ ] no unrecoverable input loss;
- [ ] no corrupted save;
- [ ] no submission state that hides/disables sovereign TAP;
- [ ] no blocker requiring editor/debug console intervention.

Evidence/notes: ______________________________________________

## 9. CI and human gates

- [ ] `validate_data` / repository data validation green.
- [ ] `npm run quality` green.
- [ ] required GitHub CI workflows green for the tested commit.
- [ ] Human Gate 01 signed APPROVED.
- [ ] Human Gate 02 signed APPROVED.
- [ ] Human Gate 03 signed APPROVED.

Gate dossier: `docs/gates/C01_C02_SLICE_APPROVAL.md`

## 10. Final DoD decision

All required checks above must be green. Partial pass is **NOT DONE**.

- [ ] APK SLICE DoD = GREEN
- [ ] APK SLICE DoD = NOT GREEN

Tester/signature: ____________________________________________  
Date/time: __________________________________________________

## Scope lock after test

If DoD is not green, the next work item must fix a failed requirement, produce missing evidence, complete C01/C02, complete CAP_0001, or rerun validation. It may not add a new feature.

If DoD becomes green, D232's moratorium may be reconsidered only through a new explicit lot; it does not auto-unfreeze future scope.
