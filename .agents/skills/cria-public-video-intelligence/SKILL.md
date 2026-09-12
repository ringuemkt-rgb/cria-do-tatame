---
name: cria-public-video-intelligence
description: Autonomous evidence-first discovery and analysis of public combat videos, classes and championships for CRIA DO TATAME. Uses platform-authorized discovery/metadata and lawful audiovisual access, preserves rights boundaries, timestamps observations, quantifies uncertainty, cross-checks rules and combat authorities, and never turns public footage into training or shipping assets without separate rights.
---

# CRIA Public Video Intelligence V1

## Mission

Continuously turn lawful public combat-video observations into useful project intelligence without requiring the user to manually choose every source, timestamp or next step.

The system may discover fights, technique classes, tournament footage, interviews and official rules material; classify source value; inspect the audiovisual material only through an authorized access path; extract timestamped observations; compare those observations with CRIA combat/rules authorities; and produce project-impact reports.

It must never pretend that a URL equals permission, that metadata equals visual evidence, or that a model prediction equals BJJ truth.

## Authority order

1. `data/combat/bjj_rulesets_verified_v1.json` — legality/scoring.
2. authoritative BJJ graph + `BJJGraphReducerV2` — combat state.
3. `data/research/public_video_analysis_director_v1.json` — autonomous routing policy.
4. `data/research/grappling_video_corpus_contract_v1.json` — rights-aware corpus policy.
5. `data/research/grappling_motion_lab_contract_v1.json` — biomechanical/motion evidence policy.
6. `data/production/motion_factory_v1.json` — offline retarget authoring only.
7. reviewed public-video observations.
8. captions/transcripts/metadata.
9. model-generated candidate labels.

Never invert this order.

## Autonomous loop

For every research cycle:

1. derive gaps from the golden chain, completion gates, combat telemetry contracts and open production obligations;
2. generate source queries automatically by technique, position, ruleset, athlete, tournament and failure/counter branch;
3. discover candidates through authorized search surfaces or official APIs;
4. de-duplicate by platform/video id, title, event and temporal overlap;
5. classify source class and access mode before analysis;
6. select the highest expected-information-gain candidates;
7. collect metadata and provenance;
8. acquire transcript only through a permitted route;
9. inspect audiovisual content only if a compliant viewing/media path is available;
10. segment observations into timestamped exchanges and the six CRIA motion phases when observable;
11. annotate uncertainty, occlusion and source limitations;
12. cross-check technique/rules claims against CRIA authorities and independent sources;
13. calculate project impact;
14. update research queues/ledgers and return a concise status report.

The system chooses the next query and source autonomously. Human confirmation is required only for rights-sensitive promotion, canon changes, or asset shipping.

## Capability truth table

### Autonomous and normally allowed

- discover public videos by query/event/athlete/technique;
- use official/public metadata such as title, channel, publication date, duration and identifiers;
- record URLs, timestamps, notes and transformed observations;
- compare several public sources;
- identify candidate positions, tactics, transitions, scoring events and teaching cues with confidence labels;
- find contradictions between commentary, video observations and official rules;
- identify missing motion references or gameplay states;
- produce evidence matrices and project-impact reports.

### Conditional

Transcript/captions:
- use when exposed through an authorized platform feature, user-owned source, supplied transcript, compatible open license, or other lawful access path;
- never assume the YouTube Data API can download third-party captions: official caption download requires edit permission on the video.

Visual/frame-level analysis:
- use when the environment provides authorized audiovisual access (for example user-supplied media, CRIA-owned capture, separately licensed media, compliant browser/player access, or a source whose license/access explicitly supports the intended analysis);
- if only metadata is available, mark `VISUAL_ACCESS_UNAVAILABLE` and do not infer motion from title/description.

Motion Factory / Sprite Forge derivation:
- public standard-license broadcast or instruction footage is reference evidence only by default;
- commercial training, frame extraction, retarget source use or shipping-asset derivation requires separate rights clearance.

### Forbidden by default

- automatic scraping/downloading of YouTube video or audio outside an authorized platform/API path;
- treating public availability as permission;
- redistributing third-party footage or extracted frames;
- face harvesting or identity datasets from public athletes;
- using public broadcast/instructional video as commercial model-training data without rights;
- auto-promoting a technique, score, rule or animation to canon/shipping.

## Source classes

`OWNED_CAPTURE` — full research/derivation subject to releases and session QA.

`OPEN_LICENSE_VERIFIED` — use only within verified license scope and platform terms.

`OFFICIAL_RULE_EDUCATION` — high-value rules/teaching reference; no automatic asset derivation.

`PUBLIC_COMPETITION_REFERENCE` — tournament/broadcast analysis for tactics, timing, scoring and failure patterns; no redistribution/training by default.

`PUBLIC_INSTRUCTION_REFERENCE` — technique/class reference; extract teaching claims and timestamps, not copyrighted lesson reproduction.

`UNKNOWN_RIGHTS` — metadata-only until resolved.

## Observation schema

Every nontrivial observation stores:

- source/video id;
- timestamp or time window;
- observation type;
- athlete/role labels when justified;
- position candidate;
- technique candidate;
- phase candidate;
- success/failure/counter state;
- score/rules candidate when relevant;
- pose/contact/occlusion notes;
- confidence dimensions;
- direct observation vs commentary/transcript distinction;
- contradiction flags;
- CRIA authority cross-check;
- project impact;
- review status.

## Evidence language

Use explicit statuses:

- `OBSERVED_HIGH_CONFIDENCE`
- `OBSERVED_MODERATE_CONFIDENCE`
- `CANDIDATE_LOW_CONFIDENCE`
- `TRANSCRIPT_ONLY`
- `METADATA_ONLY`
- `UNKNOWN_OCCLUDED`
- `CONTRADICTED`
- `NOT_ACCESSIBLE`

Never silently convert unknown into negative evidence.

## Analysis lanes

### Competition lane

Extract:
- opening position;
- initiative changes;
- takedown/guard-pull entries;
- pass/sweep/control attempts;
- stabilization windows;
- escapes/counters;
- boundary/referee effects;
- scoring moments;
- fatigue/readability cues;
- failure patterns and repeated branches.

### Technique-class lane

Extract:
- stated prerequisites;
- grips/ties;
- base/head/hip positioning;
- sequence of mechanical cues;
- common error/counter claims;
- GI/No-Gi specificity;
- safety warnings;
- contradictions with competition evidence or rules.

Do not reproduce long instruction transcripts. Store concise transformed claims with timestamps.

### Championship lane

Extract:
- event/ruleset/division;
- match graph coverage;
- recurring positions/techniques;
- scoring distribution;
- representative athlete styles;
- transitions worth adding to gameplay;
- gaps between current CRIA graph and observed competition behavior.

## Cross-source synthesis

One video is never enough to define a gameplay mechanic.

Prefer triangulation:

```text
official rules
+ multiple competition examples
+ instruction/expert explanation when lawful
+ CRIA-owned controlled capture for biomechanical/animation claims
```

Public competition footage can establish that a transition occurs and contextual patterns around it. It cannot by itself provide gold 3D biomechanics under the Motion Lab contract.

## Information-gain prioritization

Rank candidates higher when they:

- fill a missing golden-chain transition;
- show a counter/failure not represented in the graph;
- resolve a disputed scoring/rules interpretation;
- expose high-frequency competition behavior;
- contain a rare but game-important position;
- show the same technique from complementary views/sources;
- have strong official provenance;
- have captions/chapters or clear timestamps;
- reduce an existing uncertainty flag.

Rank lower when they are duplicates, edits with missing context, reaction videos, short highlights that remove setup/stabilization, or rights/access status is unclear.

## Autonomy stop conditions

Stop a specific source, not the whole research cycle, when:

- audiovisual access is unavailable;
- rights classification forbids the intended operation;
- the content is paywalled or login-restricted beyond authorized access;
- identity/position confidence collapses under occlusion;
- the source is a highlight that cannot support the target claim;
- a caption/transcript route would require unauthorized extraction;
- the source contradicts itself and no corroboration is found.

Then automatically choose the next ranked source.

## Reporting to the user

The default user-facing output is project status, not operational chatter.

Report:

1. what changed in the evidence base;
2. which techniques/positions gained or lost confidence;
3. what this changes in gameplay/motion/sprite priorities;
4. blockers that genuinely require rights, physical capture or a product-mode capability not available in the current environment;
5. next autonomous research target.

Do not ask the user to paste videos, choose timestamps, run scripts or select the next query when the system can proceed independently.

## Definition of done

Public Video Intelligence V1 infrastructure is complete when the director contract, observation ledger, validator, tests and CI are green.

A public-video claim is complete only when its access mode and provenance are explicit, the observation is timestamped, uncertainty is represented, relevant rules/graph authorities are cross-checked, and the claim is kept separate from rights-sensitive motion/asset promotion.
