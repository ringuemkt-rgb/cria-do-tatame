# Asset Pipeline v2

Asset classes are deliberately separated.

- `assets/ref/`: reference candidates only; never loaded as gameplay sprites.
- `assets/chars/frames/`: normalized 128x128 gameplay-frame candidates.
- `assets/chars/portraits/`: HUD/CriaLive portraits under their own visual contract.
- `assets/cards/`, `assets/icons/`, `assets/brand/`, `assets/arenas/`, `assets/ui/`: presentation classes with independent size contracts.
- `assets/audio/`: `ambient/`, `sfx/`, `music/`; absence remains `audio_pending` and is not a PASS.

Promotion chain:

`reference_candidate -> provenance -> normalize -> frame package -> M3 QA -> Godot import -> candidate_integrated -> human shipping gates`

Every gameplay PNG requires `.license.json`, `.provenance.json` and `.qa.json` sidecars and an index entry in `assets/manifest_v2.json`. `shipping` defaults to `false`.
