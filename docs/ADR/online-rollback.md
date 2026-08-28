# ADR — Online Rollback

Status: DEFERRED / RESEARCH_ONLY
CTX: CRIA-WORK-v2@cfbc572
Decision refs: D72, D75, D79

## Context
The vertical slice does not require online rollback netcode. Any rollback architecture would add determinism, synchronization, device-budget, test and operational complexity before the local combat loop is proven.

## Decision
Rollback remains outside the slice. `dsnopek`, `Klotho` and equivalent approaches are research candidates only; none is adopted, vendored or permitted as a runtime dependency by this ADR.

## Entry criteria for a future ADR
A later proposal must include:
1. deterministic-state feasibility evidence for the active CombatManager;
2. isolated prototype with no save/runtime regression;
3. Android CPU/memory/network budget measurements;
4. latency/jitter test matrix;
5. desync detection and recovery plan;
6. dependency pin + license/provenance record;
7. rollback/removal plan;
8. CI and human gameplay gate.

## Consequence
Current shipping code remains local/offline. No placeholder networking API may become a second combat source of truth.
