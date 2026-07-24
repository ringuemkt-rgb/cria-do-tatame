# CRIA DO TATAME – PRESSÃO
## GDD‑SYSTEMS v4.1 — Camada Técnica de Gameplay

**Status:** authoritative partial intake from 2026-07-24  
**Target:** Godot 4.3+ / GDScript  
**Platforms:** Android ARM64 + Windows  
**Relation:** complements `GDD‑CDT v4.0`; narrative/canon rules remain superior in conflicts.

> This file records only the systems content actually received. The source message was truncated during Section 4.4 and must not be treated as a complete v4.1 specification.

---

## 0. Encaixe e convenções

- This document governs gameplay/runtime behavior.
- `GDD‑CDT v4.0` governs narrative, canon and production.
- Canon invariants remain mandatory, especially exactly three factions and the TUPA‑200 artistic-intent rules.
- Existing assumed autoloads: `WorldDirectorManager`, `FactionDirectorV3`, `CriaLiveFeed`, `SaveManager`, `CombatBus`, `DeckManager`, `NarrativeFlags`, `InformantSystem`, `Economy`, `Weather`.
- New systems introduced here: `PositionFSM`, `CombatResources`, `OverworldController`, `SkillTree`.
- No gacha or loot boxes. Cards and skill nodes unlock through training, mentors, progression and CRIAcoin.
- Molho currency may buy world shortcuts, never randomized combat power.

## 1. Three nested loops

### Macro — Weekly Career

Seven-day pressure cycle. Each day the player chooses one or two actions: train, fight, complete a mission, rest, investigate or publish. The World Director advances weather, factions and feed state. Belt Ceremony closes acts and progression routes toward five endings.

### Meso — Open world day

Top-down overworld inside municipalities plus a world map between municipalities. The player walks, talks to NPCs, accepts missions, enters arenas, dojos and stores, travels by land or river, encounters events, manages CRIAcoin/Molho, edits the deck and unlocks skill nodes.

### Micro — Positional combat

Shared positional state machine, combat resources, contextual hand and five principal action buttons. Victory by submission, positional control or surrender. Combat choices alter honor, corruption and root flags, feeding back into the meso and macro loops.

## 2. Positional combat system

### 2.1 Combat resources

| Resource | Meaning | Zero-state consequence |
|---|---|---|
| Integrity | Ability to endure before tapping | defeat/tap |
| Gas | Physical stamina | slower and weaker actions |
| Focus | Reading and concentration | hidden/shuffled cards and lost timing clarity |
| Grip | Gi control level, 0–3 | control/submission cards lock |
| Pressure | Offensive threat accumulation | finishing options do not open |
| Guard | Defensive positional integrity | vulnerable to passes and submissions |
| Moral tension | Dirty-fighting pressure and corruption | no direct defeat, but raises `roxo` and may fail ritual fights |

HUD contract:

- Opponent Integrity: large red bar.
- Player Integrity: large blue bar.
- Player Gas: thin energy bar beneath portrait.
- Four shield indicators: Guard, Focus, Pressure and Grip.
- Moral tension: purple aura/overlay.

### 2.2 Shared PositionFSM

Canonical position flow:

```text
STANDING
  -> CLINCH_NEUTRO
  -> CLINCH_DOMINANTE
  -> GUARD_TOP / GUARD_BOTTOM
  -> HALF_TOP / HALF_BOTTOM
  -> SIDE_CONTROL
  -> MOUNT / BACK_CONTROL
  -> SUBMISSION
```

Core rules:

- Position is shared, not duplicated per fighter.
- State stores relative ownership (`top_id`, `bottom_id`, or attacker/defender).
- Standing/clinch is grip and takedown play.
- Guard/half guard is pass versus sweep/recovery.
- Side/mount/back is submission versus escape.
- Every transition has resource prerequisites and may be driven by a card or generic move.
- Every position defines initiative and threat.

Proposed enum:

```gdscript
enum POS {
  STANDING,
  CLINCH_NEUTRO,
  CLINCH_DOMINANTE,
  GUARD_TOP,
  GUARD_BOTTOM,
  HALF_TOP,
  HALF_BOTTOM,
  SIDE_CONTROL,
  MOUNT,
  BACK_CONTROL,
  SUBMISSION
}
```

### 2.3 Victory paths

| Path | Rule |
|---|---|
| Submission | Reach `SUBMISSION` and win the submission mini-game |
| Positional control | Official points until round timer ends |
| Surrender | Opponent Integrity reaches zero through positional damage, fatigue and pressure |

Official points specified in this intake:

- takedown: 2
- guard pass: 3
- mount: 4
- back control: 4
- sweep: 2

Arena rulesets decide which paths are legal. Underground fights may disable points; ritual fights require symbolic yielding rather than destructive depletion.

### 2.4 Real-time decision windows

Combat is neither hard turn-based nor pure button-mashing. It uses real-time resolution with short decision windows and subtle slow-motion/hitstop when meaningful responses open.

Priority order:

```text
DEFESA / ENCERRAR
TRANSIÇÃO / CARD
PRESSÃO
GRIP
MOVEMENT
```

Resolution loop:

1. Read input.
2. Tick resources.
3. Opponent AI selects intention.
4. Resolve simultaneous actions by priority.
5. Successful transition updates PositionFSM, points and positional damage.
6. Enter Submission HUD when reaching submission state.
7. Check victory, moral tags and combat feel.
8. Emit CombatBus signals to HUD, Cria Live and World Director.

### 2.5 Damage model

- Positional damage: low Integrity damage plus Gas/Guard loss and official points.
- Submission damage: massive Integrity loss or direct tap.
- Extended zero Gas: passive Integrity loss.
- Damage presentation must communicate domination, leverage and exhaustion rather than striking.

### 2.6 Opponent AI profiles

| Profile | Behavior |
|---|---|
| Bruto / Oni | high pressure, low defense, dirty behavior, ignores points |
| Técnico / Davi | correct positional progression, strong windows, wins by points |
| Frio / Kenzo | mirrors style, punishes timing mistakes |
| Moral / Calebe | drains Focus through `manto_olhar`, wins through doubt |
| Espiritual / Jacaré | ritual test; evaluates clean behavior rather than ordinary victory |

Difficulty scales primarily through positional reading and timing accuracy, not raw damage inflation.

## 3. Combat controls

### 3.1 Input map

| Action | Keyboard | Gamepad | Touch |
|---|---|---|---|
| move | WASD/arrows | left stick | virtual d-pad |
| grip | Q | L1 | GRIP |
| pressao | E | R1 | PRESSÃO |
| transicao | Space | A | TRANSIÇÃO |
| defesa | Shift | B | DEFESA |
| encerrar | F | Y | ENCERRAR |
| carta_1/2/3 | 1/2/3 | d-pad/right bumper mapping | tap card |
| pausa | Esc | Start | menu |

### 3.2 Contextual action contract

- `GRIP`: establishes or improves grips appropriate to current position.
- `PRESSÃO`: closes distance, applies body pressure or advances passing control.
- `TRANSIÇÃO`: executes selected card; without a selected card, performs a weaker generic transition.
- `DEFESA`: contextual sprawl, frame, guard recovery, bridge or submission defense.
- `ENCERRAR`: disengages, yields position, releases a submission or ends a ritual exchange.

The transition button must relabel itself by context, such as PASSAR, RASPAR or FINALIZAR.

### 3.3 Movement

- Standing/clinch: angle and distance.
- Ground: hip micro-adjustment and positional leverage.
- Dash consumes Gas and creates a punishable window when mistimed.

## 4. Deck and cards

### 4.1 Card schema

Required fields:

```text
id
nome
tecnica
origem
destino
lado
custo { grip, gas, foco }
janela
vs_defesa
pontos
dano_pos
moral
requisito_flag
raridade
frames_anim
```

Rarity is progression classification (`base`, `avancada`, `mestre`) and never a gacha rarity.

### 4.2 Deck construction

- Deck size: 12 cards.
- Draw hand: 3 cards; maximum hand size 5.
- Deck capacity grows with level and Evolution skill nodes.
- Unlock sources: training, mentors, skill nodes and narrative flags.
- Supported archetypes include pressure, guard, back-control and hybrid/root.

### 4.3 Contextual hand

- On every position change, DeckManager filters cards by origin and compatible side.
- Low Focus may temporarily hide cards as `?`.
- Playing a card requires selecting it and pressing TRANSIÇÃO.
- Without a selected card, TRANSIÇÃO uses a weaker generic positional move.

### 4.4 Canonical cards received before truncation

| Card | Origin -> Destination | Side | Cost grip/gas/focus | Window | Defense | Points | Moral | Progression |
|---|---|---:|---:|---:|---|---:|---|---|
| Grip de Ferro | STANDING -> CLINCH_DOMINANTE | any | 0/10/5 | 0.3 | — | 0 | clean | base |
| Baiana | STANDING/CLINCH -> GUARD_TOP | top | 1/25/10 | 0.6 | sprawl | 2 | clean | base |
| Guarda Fechada | GUARD_BOTTOM -> fortified GUARD_BOTTOM | bottom | 0/5/15 | — | — | 0 | clean | base |
| Raspagem Tesoura | GUARD_BOTTOM -> GUARD_TOP | bottom | 1/20/15 | 0.6 | base/frame | 2 | clean | advanced |
| Knee Cut Pass | GUARD_TOP -> SIDE_CONTROL | top | 2/20/15 | 0.6 | frame/hip | 3 | clean | advanced |
| Cem Quilos | SIDE_CONTROL -> stronger SIDE_CONTROL | top | 1/10/10 | 0.4 | bridge | control | clean | base |
| Montada | SIDE_CONTROL -> MOUNT | top | 2/25/15 | 0.7 | elbow escape | 4 | clean | master |
| Kimura | GUARD_TOP/SIDE -> SUBMISSION | top | 3/15/20 | 0.8 | submission defense | — | clean | master |
| Triângulo | GUARD_BOTTOM -> SUBMISSION | bottom | 2/20/25 | 0.8 | submission defense | — | clean | master |
| Mata-Leão | BACK_CONTROL -> SUBMISSION | top | 3/10/20 | 0.9 | submission defense | — | clean | master |

## Intake truncation boundary

The received source stopped immediately after beginning the optional dirty-card subsection:

```text
Cartas "sujas" (opcionais, do underground): ex.: Cabeçada no Clinch ...
```

Sections 5–15, the remainder of Section 4.4, all consolidated tables and the final implementation instructions were not received in this message. They must be appended from an explicit reviewed source and must not be reconstructed silently.
