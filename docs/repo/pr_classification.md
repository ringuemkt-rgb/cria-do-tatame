# Repository PR / Branch Classification — Phase 0.5

Status date: 2026-09-06  
Repository: `ringuemkt-rgb/cria-do-tatame`  
Baseline main: `2461a418a217a7f0803177798fa6d149be948741`

## Purpose

This document is the authoritative Phase 0.5 recognition ledger for open pull requests and remote branches. It does **not** promote any candidate asset, does not authorize a merge by itself, and does not reinterpret historical work as current canon.

Allowed classifications:

- `ACTIVE` — current implementation line; keep open.
- `SUPERSEDED` — replaced by newer canon/implementation; safe to close as an active PR while preserving history.
- `STACK_ORPHAN` — stacked branch/PR whose integration base was retired and that has no active merge path.
- `CLOSE_SAFE` — no unique active work / explicit no-op / external product; may be retired without losing current game implementation.
- `REFERENCE_ONLY` — useful art/spec/research source; never merge directly; requires human approval before closing its PR.
- `PORT_SELECTIVELY` — contains useful unique implementation or tests; human approval required before port/cherry-pick and before closing original PR.

`ACKNOWLEDGED_ZERO_DIFF` is a note, not a seventh classification. It means the ref is proven identical to `main` and is recognized so it is not an untracked orphan.

---

## A. Pull requests currently open

| PR | Head | Classification | Action / rationale |
|---:|---|---|---|
| #81 | `cmd/epic69-world-map-v4` | **ACTIVE** | EPIC 69 / `world_map_v4` + MAP_UI_v2. Reopened because current owner state declares it active. Keep draft until its own gates are green. |
| #71 | `lead-mcp/doctrine-v1` | **PORT_SELECTIVELY** | Unique doctrine/data/mobile/rollback work. Do not merge stacked branch directly. |
| #70 | `lead/calibracao-v1` | **PORT_SELECTIVELY** | Contains calibration, gate and migration material; PR itself explicitly says not to merge without human gates. |
| #69 | `feat/m4-sprite-forge-compat` | **PORT_SELECTIVELY** | Useful isolated sprite-forge compatibility tooling and tests. |
| #68 | `chore/prime-agent-pilot-v1` | **PORT_SELECTIVELY** | Optional tooling with unique commits; no runtime authority. Review before port/retirement. |
| #67 | `feat/bjj-dynamics-reference-v1` | **REFERENCE_ONLY** | Research-only BJJ atlas/spec layer; not runtime truth and not shipping evidence. |
| #66 | `feat/mocap-prototype-v1` | **REFERENCE_ONLY** | Prototype/research pipeline awaiting owned capture; retain only as reference pending human decision. |
| #65 | `feat/visual-qa-v2` | **PORT_SELECTIVELY** | Deterministic visual QA V2 is useful infrastructure; base is historical, so port tests/tools only after review. |
| #61 | `content/gpt-work-production-gate-v1` | **PORT_SELECTIVELY** | Asset-pack/cloud production infrastructure has unique implementation; canon decisions inside are stale and must not be merged wholesale. |
| #57 | `visual/combat-cards-hub-v2` | **REFERENCE_ONLY** | Dense visual boards/art direction and candidate manifests; not runtime assets. |
| #56 | `feat/combat-audiovisual-foundation` | **PORT_SELECTIVELY** | Contains useful combat/audio/visual infrastructure and tests; requires reconciliation with current reducer roadmap. |
| #55 | `feat/pratigi-festival-arena` | **PORT_SELECTIVELY** | Festival scene/mechanics useful for future EPIC 64, but old Dique/geography/heat assumptions forbid direct merge. |
| #52 | `visual/art-protocol-v1` | **REFERENCE_ONLY** | Art protocol contains useful constraints but obsolete map assumptions; use as reference only until reconciled. |
| #51 | `visual/visual-canon-skill-v2` | **REFERENCE_ONLY** | Visual-canon skill/reference material; later brand/map canon supersedes direct merge path. |
| #49 | `visual/visual-production-director-v1` | **REFERENCE_ONLY** | Older production-director standard; useful historical visual QA source only. |
| #48 | `visual/logo-oficial-canon` | **REFERENCE_ONLY** | Official logo provenance/reference remains useful, but historical third-party wordmark risk prevents direct commercial/shipping use. |
| #47 | `feat/v4-3-rulesets-gi-no-gi` | **PORT_SELECTIVELY** | GI/NO-GI contracts/filtering are relevant to current combat roadmap; port surgically. |
| #38 | `feat/cria-visual-forge-v1` | **PORT_SELECTIVELY** | Visual Forge tooling is a selective source, not a monolithic merge. |
| #37 | `build/epic-0-foundation-governance` | **PORT_SELECTIVELY** | Boot/gate work is partly represented in current main; compare and port only missing tests/contracts. |
| #35 | `docs/visual-quality-and-logo-v1` | **REFERENCE_ONLY** | Historical visual standard includes obsolete Arena do Dique=Salvador assumption; never merge directly. |
| #34 | `feature/combat-integration-contract` | **PORT_SELECTIVELY** | Useful bridges/bindings/contracts; old stacked base requires selective port only. |
| #33 | `docs/game-build-protocol-v1` | **PORT_SELECTIVELY** | Protocol-as-code/tests may still be useful, but current SKILL_OS and governance supersede direct authority. |
| #32 | `release/v4-integration` | **PORT_SELECTIVELY** | Explicit monolithic branch-source; never merge directly. Port small reviewed modules only. |
| #26 | `feat/open-pixel-forge-v1` | **PORT_SELECTIVELY** | Offline generation tooling can be reused after license/toolchain review; never promotes assets automatically. |
| #25 | `release/unify-and-feel` | **PORT_SELECTIVELY** | Input/game-feel/audio/telemetry modules useful; must preserve current `CombatManager`/reducer authority. |
| #24 | `agent/visual-audio-world-v10` | **PORT_SELECTIVELY** | Large audiovisual/world milestone; selectively port owned/licensed pieces and tests only. |

### Auto-closed in Phase 0.5

| PR | Classification | Result |
|---:|---|---|
| #63 | **SUPERSEDED** | Closed without merge. Old narrative/world V3 replaced by merged EPIC 58 narrative canon and EPIC 69 world-map line. |
| #54 | **SUPERSEDED** | Closed without merge. Old 7-municipality/15-arena P0 world contract replaced by current map/data backbone. |

### Already handled in Phase 0

| PR | Classification | Result |
|---:|---|---|
| #77 | **SUPERSEDED** | Closed without merge. |
| #78 | **STACK_ORPHAN** | Closed without merge after #77 base was retired. |

PRs not listed above are not open at the time of this Phase 0.5 ledger and therefore are outside the open-PR gate.

---

## B. Remote branch classification

Every remote ref returned by the GitHub branch inventory is recognized below. `main` is included as the permanent integration branch.

| Branch | Classification | Recognition / next action |
|---|---|---|
| `agent/repository-hardening-2026-07` | SUPERSEDED | Repository governance/hardening now represented by later main history. |
| `agent/visual-audio-world-v10` | PORT_SELECTIVELY | Source for PR #24; preserve until selective port decision. |
| `audit/full-game-hardening-2026-07` | SUPERSEDED | Historical audit branch; current workflows supersede it. |
| `build/drive-cloud-adapter-v1` | PORT_SELECTIVELY | Cloud adapter tooling may be reused after current architecture review. |
| `build/epic-0-foundation-governance` | PORT_SELECTIVELY | Source for PR #37; retain until missing boot/governance pieces are compared. |
| `build/p0-canon-baixo-sul-vertical-slice` | SUPERSEDED | PR #54 closed; old world contract no longer authoritative. |
| `chore/prime-agent-pilot-v1` | PORT_SELECTIVELY | Source for PR #68. |
| `chore/repository-professionalization-v1` | SUPERSEDED | Professionalization absorbed by later main governance. |
| `cmd/epic58-narrative-update` | SUPERSEDED | EPIC 58 merged via PR #79; branch history retained only. |
| `cmd/epic62-asset-ingestion-foundation` | CLOSE_SAFE | Empty/failed first EPIC62 branch; valid work landed through `-v2`. |
| `cmd/epic62-asset-ingestion-foundation-v2` | SUPERSEDED | Merged via PR #80 into current main. |
| `cmd/epic63-world-map-v3` | CLOSE_SAFE | **ACKNOWLEDGED_ZERO_DIFF**: proven identical to `main` (`ahead=0`, `behind=0`, zero files). Connector cannot delete remote refs; recognized intentionally. |
| `cmd/epic69-playable-map` | SUPERSEDED | Replaced by `cmd/epic69-world-map-v4`. |
| `cmd/epic69-world-map-v4` | ACTIVE | PR #81 / EPIC69 current map line. |
| `cmd/phase0-cleanup` | ACTIVE | Phase 0/0.5 cleanup branch. |
| `codex/build-visao-de-cria-system` | CLOSE_SAFE | External/non-game product per historical repo cleanup issue. |
| `codex/create-comprehensive-e-book-production-system` | CLOSE_SAFE | External/non-game product per historical repo cleanup issue. |
| `codex/vertical-slice-system` | PORT_SELECTIVELY | Historical slice tooling/content; compare before reuse. |
| `codex/visual-format-v10` | PORT_SELECTIVELY | Historical visual format implementation; selective reuse only. |
| `consolidation/supreme-repository-2026-07` | SUPERSEDED | Historical consolidation superseded by current main. |
| `content/gpt-work-production-gate-v1` | PORT_SELECTIVELY | Source for PR #61. |
| `content/narrativa-mundo-v3-proposta` | SUPERSEDED | PR #63 closed in Phase 0.5. |
| `delete-me-noop` | CLOSE_SAFE | Explicit no-op; no current implementation responsibility. |
| `docs/cps-standard-v43` | REFERENCE_ONLY | Historical standard/documentation reference. |
| `docs/fundacao-2026-08-13` | REFERENCE_ONLY | Historical foundation documentation. |
| `docs/game-build-protocol-v1` | PORT_SELECTIVELY | Source for PR #33; useful tests/protocol fragments may be ported. |
| `docs/gdd-cdt-v4-canon` | REFERENCE_ONLY | Historical GDD intake; current canon/data has higher precedence. |
| `docs/v4-1-canon-contracts` | REFERENCE_ONLY | Historical contracts; compare only. |
| `docs/visual-quality-and-logo-v1` | REFERENCE_ONLY | Source for PR #35; obsolete Dique geography blocks direct use. |
| `feat/bjj-dynamics-reference-v1` | REFERENCE_ONLY | Source for PR #67. |
| `feat/combat-audiovisual-foundation` | PORT_SELECTIVELY | Source for PR #56. |
| `feat/cria-visual-forge-v1` | PORT_SELECTIVELY | Source for PR #38. |
| `feat/m4-sprite-forge-compat` | PORT_SELECTIVELY | Source for PR #69. |
| `feat/mocap-prototype-v1` | REFERENCE_ONLY | Source for PR #66; research/non-shipping. |
| `feat/open-pixel-forge-v1` | PORT_SELECTIVELY | Source for PR #26. |
| `feat/positional-card-combat-v1` | PORT_SELECTIVELY | Historical combat prototype; selective algorithms/tests only. |
| `feat/pratigi-festival-arena` | PORT_SELECTIVELY | Source for PR #55; requires canon corrections. |
| `feat/v4-2-factions-save` | SUPERSEDED | Later main contains the active three-faction/save evolution. |
| `feat/v4-3-rulesets-gi-no-gi` | PORT_SELECTIVELY | Source for PR #47. |
| `feat/visual-qa-v2` | PORT_SELECTIVELY | Source for PR #65. |
| `feature/assets-pipeline` | SUPERSEDED | EPIC62 asset ingestion foundation v2 is the current pipeline baseline. |
| `feature/autoloads-foundation` | SUPERSEDED | Current `project.godot`/autoload graph supersedes this foundation. |
| `feature/combat-integration-contract` | PORT_SELECTIVELY | Source for PR #34. |
| `feature/faction-director-v2` | SUPERSEDED | Current three-faction/runtime contracts supersede v2. |
| `feature/functional-ai` | PORT_SELECTIVELY | Historical AI implementation; only algorithms/tests may be reused. |
| `feature/local-ai-dialogue` | PORT_SELECTIVELY | Historical local-dialogue implementation; no current authority. |
| `feature/world-director-ai-nft-v1` | SUPERSEDED | NFT/world AI direction is retired from current runtime authority. |
| `fix/p0-bugs` | SUPERSEDED | Historical fixes absorbed/superseded by later main. |
| `fix/runtime-smoke-main` | SUPERSEDED | Explicitly recorded as absorbed by later main runtime smoke fix. |
| `lead/calibracao-v1` | PORT_SELECTIVELY | Source for PR #70. |
| `lead/harmony-gates-v1` | REFERENCE_ONLY | Closed historical human-gate stack; retain evidence concepts only. |
| `lead/harmony-v1` | REFERENCE_ONLY | Closed harmony spec stack; reference for paired-motion QA only. |
| `lead/slice-core-v1` | REFERENCE_ONLY | Historical slice contract; not active runtime. |
| `lead/slice-final-v1` | REFERENCE_ONLY | Historical mobile acceptance evidence; no merge path. |
| `lead-mcp/doctrine-v1` | PORT_SELECTIVELY | Source for PR #71. |
| `lead-mcp/nishiuchi-fix` | SUPERSEDED | Nishiuchi naming is already represented in current narrative canon. |
| `main` | ACTIVE | Permanent integration branch; protected logically by phase gates. |
| `release/unify-and-feel` | PORT_SELECTIVELY | Source for PR #25. |
| `release/v4-integration` | PORT_SELECTIVELY | Source for PR #32; explicit branch-source, never direct monolithic merge. |
| `rescue/sprint-0-complete` | PORT_SELECTIVELY | Unknown historical rescue work; preserve until diff review before retirement. |
| `ringuemkt-rgb-patch-1` | PORT_SELECTIVELY | Generic historical patch branch; preserve until diff review. |
| `test-noop` | CLOSE_SAFE | Explicit no-op/test branch. |
| `upgrade/apk-visual-pipeline-v09` | SUPERSEDED | Later Android/asset pipeline work supersedes this upgrade branch. |
| `upgrade/runtime-audit-v08` | SUPERSEDED | Current runtime audit workflow supersedes v08. |
| `visual/art-protocol-v1` | REFERENCE_ONLY | Source for PR #52. |
| `visual/combat-cards-hub-v2` | REFERENCE_ONLY | Source for PR #57. |
| `visual/epic16-canon-layer` | SUPERSEDED | PR #77 closed as superseded. |
| `visual/epic16-runtime-v1` | STACK_ORPHAN | PR #78 closed after its base #77 was retired. |
| `visual/logo-oficial-canon` | REFERENCE_ONLY | Source for PR #48; legal cleanup still required before shipping. |
| `visual/visual-canon-skill-v2` | REFERENCE_ONLY | Source for PR #51. |
| `visual/visual-production-director-v1` | REFERENCE_ONLY | Source for PR #49. |
| `visual-pipeline-completo` | PORT_SELECTIVELY | Historical visual pipeline; compare before any reuse. |
| `visual-pipeline-full` | PORT_SELECTIVELY | Historical visual pipeline; compare before any reuse. |
| `visual-test-branch-safe` | CLOSE_SAFE | Explicit test/no-op branch recorded as removable in historical cleanup. |

Remote branch inventory count recorded by Phase 0.5: **74 refs including `main`**.

---

## C. Human-approval queue

### REFERENCE_ONLY — do not close yet

Open PRs awaiting owner approval before archival/closure:

`#67, #66, #57, #52, #51, #49, #48, #35`

### PORT_SELECTIVELY — do not close yet

Open PRs awaiting owner approval and a dedicated port branch before closure:

`#71, #70, #69, #68, #65, #61, #56, #55, #47, #38, #37, #34, #33, #32, #26, #25, #24`

No selective port or cherry-pick is authorized by this ledger alone.

---

## D. Phase 0.5 gate evidence

- Retro binary scan: `66` binaries discovered.
- Manifest indexed: `66 / 66` binaries.
- Coverage: `100.0%`.
- Retro provenance sidecars created: `66`.
- Retro license sidecars created: `66`.
- `shipping=true`: `0`.
- Missing manifest entries: `0`.
- Stale manifest entries: `0`.
- `cmd/epic63-world-map-v3`: `ACKNOWLEDGED_ZERO_DIFF`, compare status `identical`, `ahead_by=0`, `behind_by=0`.
- Every currently open PR has a classification in section A.
- Every currently enumerated remote branch has a classification in section B.

### Gate result

`PHASE_0_5_CLASSIFICATION_GATE = PASS_PENDING_REPOSITORY_CI`

This PASS means the recognition/coverage gate is satisfied. It does **not** waive normal Repository Quality / Runtime Audit / Validate Data / Full Game Hardening checks on the cleanup PR before merge.
