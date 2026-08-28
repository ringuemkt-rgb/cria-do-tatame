# CAP_0001 — contrato de captura física do slice

**Status:** REQUIRED BEFORE COMBAT ART SCALE-UP  
**Decision:** D148  
**Timezone:** America/Bahia  
**Target window this week:** 2026-08-28 through 2026-08-30  
**Merge/publication:** forbidden by this lot.

## 1. Objective

Produce the first physical source-of-truth capture for the six slice techniques, with paired performer timing that can be converted into keypoints, motion blocking and synchronization evidence. This capture is evidence for animation construction; it is not final art and it does not by itself approve biomechanics or canon.

## 2. Minimum crew and equipment

- 2 adult performers with explicit consent;
- 2 smartphones capable of recording 60 fps;
- 1 safe grappling mat area with adequate clearance;
- stable supports/tripods or fixed operators for both camera angles;
- one capture lead responsible for slate, take IDs, safety stop and ledger.

No extra performer, camera or sensor is required for CAP_0001 acceptance.

## 3. Safety contract

- no strikes;
- no ballistic or uncontrolled finishes;
- every submission is demonstrated under controlled technical pressure only;
- TAP means immediate release, without completing pressure after the signal;
- either performer may stop a take at any time;
- pain, dizziness, unusual joint stress, loss of control or unsafe landing ends the take immediately;
- warm-up and technique rehearsal happen before recording;
- no take is repeated merely to obtain a prettier image when control or safety deteriorates.

## 4. Consent

Before recording, both performers confirm:

- participation is voluntary;
- recording is for the Cria do Tatame animation/reference pipeline;
- footage may be processed into keypoints, motion traces and derived fictional animation;
- raw capture is not automatically public or final game content;
- approval of derived game art remains a separate human gate.

Performer A name: ______________________________  
Consent/signature: _____________________________  
Date/time: ____________________________________

Performer B name: ______________________________  
Consent/signature: _____________________________  
Date/time: ____________________________________

Capture lead: __________________________________  
Signature: _____________________________________  
Date/time: ____________________________________

## 5. Camera setup

### Camera A
- 60 fps;
- full bodies visible throughout the technique;
- primary angle: lateral/three-quarter sufficient to read base, level change, hip line and landing;
- no digital zoom during the take.

### Camera B
- 60 fps;
- full bodies visible throughout the technique;
- complementary angle sufficient to read grips/hand fighting, limb position and contact geometry;
- no digital zoom during the take.

Both cameras record the same slate and synchronization cue before each take.

## 6. Six-technique capture matrix

The canonical six technique IDs/names must be resolved from the active slice technique catalog before the session. This contract does **not** invent replacement technique names.

For each of the six techniques capture, at minimum:

1. clean cooperative demonstration;
2. normal-speed paired execution;
3. defense branch;
4. escape or safe reset branch when applicable;
5. failure/denied-entry branch when the gameplay technique requires it;
6. explicit TAP/release demonstration for submissions.

| Slot | Canon technique ID | Clean | Normal | Defense | Escape/reset | Failure branch | TAP if applicable |
|---:|---|---|---|---|---|---|---|
| 01 | __________________ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 02 | __________________ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 03 | __________________ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 04 | __________________ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 05 | __________________ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 06 | __________________ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

## 7. Take naming

Use deterministic IDs:

`CAP0001_<technique_id>_<branch>_T###_CAM_A`  
`CAP0001_<technique_id>_<branch>_T###_CAM_B`

A take is invalid if the two camera files cannot be paired unambiguously.

## 8. Required outputs

CAP_0001 exits with these logical outputs, whether produced immediately or by the next processing step:

- paired raw-video take inventory;
- consent record;
- take ledger;
- keypoint sequence per accepted take;
- motion representation (`.mot` or project-equivalent deterministic motion file);
- attacker/defender synchronization markers;
- plausibility notes for base, pivots, contacts, landing and release;
- rejection reason for unusable takes.

No output may be labeled `human_approved` from capture alone.

## 9. Plausibility checklist per accepted take

- [ ] both bases are physically readable;
- [ ] entry direction matches the demonstrated technique;
- [ ] attacker/defender contact occurs in the correct order;
- [ ] center-of-mass shift is plausible;
- [ ] landing/reset is controlled;
- [ ] defender response is not visually impossible;
- [ ] submission pressure, if present, stops on TAP;
- [ ] no body intersection or timing artifact is accepted as motion truth.

## 10. Session ledger — maximum 20 lines

1. Session ID: CAP_0001
2. Date: __________________
3. Location: __________________
4. Performer A: __________________
5. Performer B: __________________
6. Camera A device: __________________
7. Camera B device: __________________
8. Both cameras 60 fps: [ ]
9. Consent A: [ ]
10. Consent B: [ ]
11. Safety briefing: [ ]
12. Technique slots resolved: [ ] 6/6
13. Paired slate sync verified: [ ]
14. Clean demonstrations captured: ____/6
15. Defense branches captured: ____/6
16. Escape/reset branches captured: ____/6
17. TAP/release branches applicable/captured: ____/____
18. Rejected takes logged: [ ]
19. Data backed up and hashes recorded: [ ]
20. Capture lead sign-off: __________________

## 11. Acceptance

CAP_0001 is complete only when both performers consented, both cameras recorded at 60 fps, all six canonical technique slots have the required applicable branches, unsafe takes are rejected, and the output can be traced from paired video to keypoints/motion/sync/plausibility ledger.
