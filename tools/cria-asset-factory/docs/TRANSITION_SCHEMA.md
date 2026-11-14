# Candidate transition contract

Each JSON is keyed by a canonical ID from `data/techniques.json`. `entry_state`, `exit_state`, `family`, `base_chance` and `cost` are exact catalogue projections. All other fields are authoring annotations, not an injected rules layer. Historic PT-BR values (`estado_entrada` and `custo.foco`) are compatibility aliases in the existing catalogue; these new JSONs use `entry_state` and `cost.focus` only.

Three alphabets: narrative PT-BR labels, historical catalogue identifiers and `CombatStateMachine` PLAYER_* runtime names. Existing `src/combat/SliceStateMapper.gd` maps them; this package does not create a fourth mapper.

Scoring and legality come from the versioned BJJ ruleset and contextual referee logic. Boolean `legal_ibjjf`/`legal_adcc` flags are **preliminary**; not an assertion for every belt/division/phase. Unknown contacts remain empty/UNKNOWN. Noncanonical gameplay effects default to zero until separately reviewed. `sprawl` has a known catalog-vs-slice-overlay exit-state disagreement: follow the catalogue for this candidate.
