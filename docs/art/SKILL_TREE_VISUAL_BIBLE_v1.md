# SKILL TREE VISUAL BIBLE v1 — CRIA DO TATAME

Status: **VISUAL GROUND TRUTH / REFERENCE_CANDIDATE**  
Shipping: **false**  
Runtime authority: **none**  
Gameplay authority target: **data + reducer**

## 1. Purpose

The ten approved skill-tree boards define the official visual language for progression screens in CRIA DO TATAME. They are the art-direction reference for composition, hierarchy, icon density, typography scale, graph readability, path colors, preview panels and the relationship between progression, factions, arena perks and meta-progression.

They are **not screenshots to be loaded directly as interactive UI**. Runtime screens must be reconstructed in Godot from data, theme resources and UI components.

## 2. Visual language

- Premium pixel-art / illustrated game UI aligned with the official world-map quality bar.
- Dark charcoal/black chrome with gold borders and off-white text.
- Dense but clearly segmented information architecture.
- 16:9 wide layout.
- Strong contextual environment behind the UI, without reducing readability.
- Ruan remains the central visual anchor for the skill system.
- Path colors are stable: Pressão red, Técnica blue, Mobilidade green, Finalização purple, Resiliência gold.

## 3. Canonical screen anatomy

1. Top global navigation.
2. Player card with portrait and current progression state.
3. Path selector on the left.
4. Central graph with connected nodes and visible dependency direction.
5. Right contextual panel with selected technique preview, effects and requirements.
6. Bottom legend / belt requirements / page marker.

## 4. The five canonical paths

### Pressão
Identity: advance, dominate, exhaust, positional control.  
Signature visual capstone: **Silverback Pressure**.

### Técnica
Identity: clean mechanics, grip adjustment, kuzushi, timing, reading and countering.  
Signature visual capstone: **Zanshin Counter**.

### Mobilidade
Identity: movement, escapes, guard recovery, scramble and re-composition.  
Signature visual capstone: **Fantasma do Mangue**.

### Finalização
Identity: isolate, hunt, chain attacks and finish under control.  
Signature visual capstone: **Caçador de Finalizações**.

### Resiliência
Identity: conditioning, breath control, recovery, mental stability and consistency.  
Signature visual capstone: **Coração do Tatame**.

## 5. Cross-progression screens

The visual system also includes three cross-system families:

- Arena perks: environmental/territorial rewards linked to clandestine arenas.
- Faction reputation: ALE, LEM and NTM progression, with exclusive rewards and consequences.
- Meta progression: belt journey, Honra, Hype, Heat and Truth Fragments.

These screens must reuse the same chrome, typography and graph language instead of creating unrelated UI styles.

## 6. Authority boundary — mandatory

Generated text inside reference boards is **not canon by itself**. Examples of possible generation drift include faction spelling, player level, prices, percentage bonuses, belt labels or captions.

The authority order is:

1. `data/brand/canon_lock.json`
2. canonical gameplay/narrative data (`factions_v2`, `roster_v3`, progression contracts)
3. reducer/rules services
4. runtime UI presentation
5. visual reference boards

Therefore:

- Official faction names remain **Os Aleluiados**, **Lá Ele Mil Vezes**, **Nós Tem o Molho**.
- The canonical belt sequence remains white → blue → purple → brown → black unless a future explicit data migration changes it.
- Numbers printed into generated artwork do not establish balance.
- A visual node is not automatically unlocked or implemented because it exists in a board.

## 7. Runtime implementation rules

```text
DATA / REDUCER
      ↓
SkillTreeRules
      ↓
SkillTreeViewModel
      ↓
Godot Control Nodes
      ↓
Animation / Audio / VFX
```

The UI must never calculate unlock rules, costs, rewards or combat effects. It requests a decision and presents the result.

Interactive labels must be actual UI text, not baked into a PNG. Player-focused accessibility requires text scaling, reduced-motion mode, focus outlines and non-color-only node state signaling.

## 8. Asset lifecycle

```text
visual board
→ reference_candidate
→ human art QA
→ component extraction / recreation
→ runtime UI implementation
→ gameplay QA
→ shipping candidate
→ shipping
```

No reference board is shipping-ready merely because it looks final.

## 9. Source archive

The exact ten boards are preserved in the persistent ChatGPT Library folder:

`/CRIA DO TATAME/Visual Bible/Skill Tree v1/`

Hashes and stable Library file IDs are recorded in `data/visual/skill_tree_visual_manifest_v1.json`.

Binary copy into the repository is intentionally deferred to Phase 2 asset ingestion so the repository never claims a binary that was not actually ingested and sidecar-validated.
