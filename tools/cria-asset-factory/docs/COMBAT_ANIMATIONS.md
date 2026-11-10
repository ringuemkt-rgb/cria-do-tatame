# Combat animation profiles

Combat actions: idle_combat, walk, dash, guard, hit_light, hit_medium, hit_heavy, clinch, ground_top, ground_bottom, victory, defeat; all **side view**. World idle is an independent 3/4 profile. Body and detached FX remain separate. User-supplied frames must share 128×128 grid, [64,96] pivot and 12 fps. Technique phases in strict order: anticipation → entry → establish → stabilize → response → recovery. Equal frame-count timeline for attacker/defender; commit frame index zero-based. Timing is **visual only** and does not adjudicate the fight.
