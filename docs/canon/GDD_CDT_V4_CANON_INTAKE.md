# CRIA DO TATAME – PRESSÃO
## GDD‑CDT v4.0 — Canon Intake

**Status:** authoritative from 2026-07-24  
**Target:** Godot 4.3+  
**Supersedes:** GDD and world-bible versions v1.0 through v3.1

> This repository must resolve future canon conflicts in favor of GDD‑CDT v4.0.

## Non-negotiable canon

### Exactly three factions

Only these IDs may exist as factions in runtime data, UI, dialogue, saves, tests, or the Faction Director:

| Runtime ID | Display name | Color |
|---|---|---|
| `lem` | LÁ ELE MIL VEZES | `#D92323` |
| `ntm` | NÓS TEM UM MOLHO | `#2D5016` |
| `ale` | OS ALELUIADOS | `#4B0082` |

Operational nuclei are tags owned by one of the three factions and must never be promoted to faction status:

- `bonde_do_dique` → `lem`
- `patrulha_da_br` → `lem`
- `travessia` → `ntm`
- `ponta_de_areia` → `ntm`
- `lavanderia_do_festival` → `ntm`
- `obra_nova` → `ale`
- `congregacao_de_rua` → `ale`

Required runtime contract:

```gdscript
enum FACCAO { LEM, NTM, ALE }
```

A data-validation gate must fail when a fourth faction ID is introduced.

### TUPA‑200 artistic intent

TUPA‑200 is fictional social criticism about the commodification of common territory, capture of access by corrupt or criminal power, decontextualized outrage, land grabbing, and environmental degradation.

It is not a report, accusation, or portrayal of any real person, community, ethnic group, police officer, politician, festival owner, DJ, or criminal organization.

Required credits and README disclosure:

> A taxa TUPA‑200 é uma obra de ficção e crítica artística sobre a mercantilização do território e a captura do acesso pelo poder. Personagens, comunidades, facções e operações são fictícios; a geografia, a cultura e os fatos ambientais do Baixo Sul da Bahia são reais e tratados com respeito.

### Safety and platform rules

- Never name, symbolize, or imitate real criminal factions.
- Never portray identifiable real people as criminals or corrupt actors.
- No playable gunfights, gore, or operational crime instruction.
- Playable conflict is jiu-jitsu, restraint, escape, evidence gathering, and consequence.
- PF and PM are internally plural: lawful and corrupt characters coexist.
- Target rating remains 14+.

## Core design pillars

The official logo defines the progression model:

- DISCIPLINA — base, defense, routine, fatigue recovery.
- FOCO — reading, timing, grips, BPM, resistance to noise and manipulation.
- RESPEITO — clean endings, ritual, community legitimacy, lower corruption.
- EVOLUÇÃO — transitions, deck growth, adaptation.

The crown represents title and public power. 柔術 represents the soul of the practice. A crown without 柔術 routes toward `campeao_oco`; 柔術 without the crown may still route toward `cria_de_verdade`.

## Economy contract

- `criacoin` (`₵`, `#F2C230`) is clean, traceable community currency.
- `molho` (`💵`, `#2D5016`) is gray, untraceable influence currency.
- Parallel Pratigi may convert Molho into CRIAcoin as a money-laundering narrative hook.
- Carrying or spending Molho increases faction marking and moral corruption.

## Required world systems

- Faction Director with exactly three factions.
- Operational nuclei represented as owned tags.
- World-map nodes, road and river travel, blocked areas, and APA rules.
- Terrain modifiers: `areia_fofa`, `mobilidade_instavel`, `plateia`, `por_do_sol`, `strobo`, `lama`, `entulho`, `estreito_vento`, `batida_bpm`, `silencio_eco`, `manto_olhar`.
- Parallel Pratigi as a cyclical festival event combining exhibition combat, infiltration, environmental choice, and non-lethal escape.
- TUPA‑200 as a branching social-criticism arc with community dignity, evidence, law, and consequence.

## Repository audit at intake

The current repository does not yet satisfy this canon:

1. `src/autoloads/FactionManager.gd` currently registers seven faction-like IDs.
2. `data/factions.json` mixes institutions, community axes, media systems, and retired groups into the faction catalog.
3. `tests/test_faction_director_data.py` explicitly requires seven active factions.
4. `project.godot` still identifies the project as a Godot 4.2+ base while v4.0 targets Godot 4.3+.

These conflicts require a save-aware migration, not a blind search-and-replace.

## Exact legacy-ID disposition

The seven current IDs and their required v4 destinations are now known:

| Legacy ID | v4 disposition | Runtime domain |
|---|---|---|
| `la_ele_mil_vezes` | map to `lem` | faction |
| `nos_tem_um_molho` | map to `ntm` | faction |
| `os_aleluia` | map to `ale` and normalize display name to Os Aleluiados | faction |
| `terreiro` | reclassify as Ituberá hub/local | world node |
| `raiz` | reclassify as narrative axis/flag | NarrativeFlags |
| `dragao_vermelho` | retire from active runtime; optional lore flag during migration | retired lore |
| `fantasma` | retire from active runtime; optional lore flag during migration | retired lore |

`cria_live` and `circuito_oficial`, although present in the broader legacy data catalog, are systems/institutions and must never become v4 faction IDs.

## Migration policy

1. Preserve boot and the canonical main scene.
2. Introduce a compatibility mapper for old save IDs.
3. Reclassify `terreiro`, `raiz`, `cria_live`, and `circuito_oficial` as systems or reputation axes.
4. Retire `dragao_vermelho` and `fantasma` from the faction domain; preserve legacy save migration only where required.
5. Rebuild faction JSON, territory ownership, director operations, and tests around `lem`, `ntm`, and `ale`.
6. Add a lint test that fails on any fourth faction ID.
7. Do not merge implementation changes until boot audit and automated tests pass.
8. Upgrade Godot 4.2 → 4.3 in a separate pull request.

## Canon continuation

The approved material for Sections 9–17 is stored in:

- `docs/canon/GDD_CDT_V4_SECTIONS_09_17.md`

It defines the beat sheet, systems, five endings, target autoload contracts, art/audio direction, QA, accessibility, milestones and the approved seven-phase implementation approach.

## Completeness note

This intake is no longer missing the material content of Sections 9–15 and 17. Three documentary gaps remain explicit:

1. The original full Section 16 text containing the exact branch/commit/PR-template sequence was referenced but not reproduced verbatim; Issue #28 remains the executable source until that text arrives.
2. Appendix B was truncated again after the opening source list and must be resent and audited before being treated as factual canon.
3. Appendix C, the master list of flags, was not included in the received message.

No missing text may be silently invented and labeled as user-approved canon.
