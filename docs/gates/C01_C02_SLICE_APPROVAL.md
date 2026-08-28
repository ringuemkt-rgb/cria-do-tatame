# C01/C02 — Slice Visual Correction & Human Approval

**Status:** ACTIVE GATE DOSSIER  
**Promotion rule:** `raw_candidate → clean_candidate → human_approved`  
**Automatic promotion:** FORBIDDEN  
**Authorized signer:** Mestre Satoshi  
**Scope:** exactly three upstream visual candidates; no new candidate is created by this lot.

## 1. Candidate set

The three upstream candidates are retained by neutral IDs so this dossier does not invent filenames or binary provenance that are not present on the base branch.

| Candidate | Input state | C01 output | C02 output |
|---|---|---|---|
| `candidate_01` | `raw_candidate` | corrected + QA evidence | `clean_candidate` or reject |
| `candidate_02` | `raw_candidate` | corrected + QA evidence | `clean_candidate` or reject |
| `candidate_03` | `raw_candidate` | corrected + QA evidence | `clean_candidate` or reject |

No candidate may become `human_approved` until the applicable human gates below are signed. CI, generation tools and agents cannot sign.

## 2. Four mandatory correction flags

These four flags apply wherever the relevant character is visible. A flag marked FAIL blocks `clean_candidate`.

| Flag | Decision | Requirement | Evidence field |
|---|---|---|---|
| `F01_DAVI_BLUE_BELT` | D15 | Davi uses a blue belt in every visible view/animation | __________________ |
| `F02_RUAN_NO_BACK_PATCH` | D16 | Ruan has no rear gi patch | __________________ |
| `F03_RUAN_WEAR_MAX_30` | D17 | wear/dirt/speckle covers no more than 30% of useful uniform area and preserves silhouette/contact readability | __________________ |
| `F04_RUAN_NO_TATTOOS` | D44 | Ruan has no tattoos | __________________ |

### Candidate correction checklist

#### candidate_01
- F01: [ ] PASS [ ] FAIL [ ] N/A
- F02: [ ] PASS [ ] FAIL [ ] N/A
- F03: [ ] PASS [ ] FAIL [ ] N/A
- F04: [ ] PASS [ ] FAIL [ ] N/A
- C01 notes: ________________________________________________
- C02 state: [ ] `clean_candidate` [ ] rejected

#### candidate_02
- F01: [ ] PASS [ ] FAIL [ ] N/A
- F02: [ ] PASS [ ] FAIL [ ] N/A
- F03: [ ] PASS [ ] FAIL [ ] N/A
- F04: [ ] PASS [ ] FAIL [ ] N/A
- C01 notes: ________________________________________________
- C02 state: [ ] `clean_candidate` [ ] rejected

#### candidate_03
- F01: [ ] PASS [ ] FAIL [ ] N/A
- F02: [ ] PASS [ ] FAIL [ ] N/A
- F03: [ ] PASS [ ] FAIL [ ] N/A
- F04: [ ] PASS [ ] FAIL [ ] N/A
- C01 notes: ________________________________________________
- C02 state: [ ] `clean_candidate` [ ] rejected

## 3. Human gates 01–06

A signature is an explicit human act. Blank means **not approved**. `N/A` requires a written reason and signature; it is not an automatic bypass.

### Gate 01 — Canon / identity
Checks Ruan/Davi identity, belt, no tattoos, no rear patch, wear ceiling and approved fictional markings.

- Status: [ ] APPROVED [ ] REJECTED [ ] N/A
- Evidence/notes: ___________________________________________
- Signer: _________________________________________________
- Signature: ______________________________________________
- Date/time: ______________________________________________

### Gate 02 — Visual / style
Checks pixel-art style lock, stable silhouette/proportions, readable contacts and consistency with the slice art direction.

- Status: [ ] APPROVED [ ] REJECTED [ ] N/A
- Evidence/notes: ___________________________________________
- Signer: _________________________________________________
- Signature: ______________________________________________
- Date/time: ______________________________________________

### Gate 03 — Biomechanics / safety
Checks paired grappling plausibility, pivots, contact points, tap/escape safety and absence of impossible or unsafe final motion.

- Status: [ ] APPROVED [ ] REJECTED [ ] N/A
- Evidence/notes: ___________________________________________
- Signer: _________________________________________________
- Signature: ______________________________________________
- Date/time: ______________________________________________

### Gate 04 — Rights / provenance
Checks fictional originality, source provenance, license chain and absence of copied athlete, academy, brand, footage or protected insignia.

- Status: [ ] APPROVED [ ] REJECTED [ ] N/A
- Evidence/notes: ___________________________________________
- Signer: _________________________________________________
- Signature: ______________________________________________
- Date/time: ______________________________________________

### Gate 05 — Mobile / technical readability
Checks nearest-neighbor pixel integrity, representative ARM64 readability, no destructive scaling and consumer plan in Godot.

- Status: [ ] APPROVED [ ] REJECTED [ ] N/A
- Evidence/notes: ___________________________________________
- Signer: _________________________________________________
- Signature: ______________________________________________
- Date/time: ______________________________________________

### Gate 06 — Cultural / regional respect
Checks respectful regional representation and any sensitive cultural/devotional material before approval.

- Status: [ ] APPROVED [ ] REJECTED [ ] N/A
- Evidence/notes: ___________________________________________
- Signer: _________________________________________________
- Signature: ______________________________________________
- Date/time: ______________________________________________

## 4. State transition rule

A candidate may move from `raw_candidate` to `clean_candidate` only after all applicable four correction flags pass C01/C02. A candidate may move from `clean_candidate` to `human_approved` only after every gate applicable to that candidate has an explicit signed disposition. No unsigned gate can be treated as approval.

For the APK DoD in this slice, Gates 01–03 must be explicitly signed as approved. Gates 04–06 remain authoritative whenever their subject matter is present; `N/A` is acceptable only with reason + signature.

## 5. Prohibitions

- no agent signature;
- no CI-as-approval;
- no generated asset promoted directly to `human_approved`;
- no integration of a rejected or unsigned required candidate;
- no creation of fourth candidate in M-MASTER-SLICE;
- no merge from this dossier.
