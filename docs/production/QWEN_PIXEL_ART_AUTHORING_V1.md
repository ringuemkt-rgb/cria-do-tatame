# Qwen Pixel Art Authoring v1

**Status:** ACTIVE CANDIDATE TOOLING  
**Runtime authority:** none  
**Shipping default:** false

## Purpose

Use `prithivMLmods/Qwen-Image-2512-Pixel-Art-LoRA` as a high-capacity **candidate generator** inside CRIA's visual production pipeline. It is not the art-direction authority and it does not replace Sprite Forge, identity lock, paired BJJ animation review, provenance, rights review or human approval.

The authoritative CRIA profile is:

`data/ai/qwen_pixel_art_profile_v1.json`

## Audited stack

- base: `Qwen/Qwen-Image-2512`;
- base revision: `ca98f15a127a0c732aec7e60ba6e783fb953d490`;
- adapter: `prithivMLmods/Qwen-Image-2512-Pixel-Art-LoRA`;
- adapter revision: `e14eea588e8e4a9c753439e52a203d06288769c5`;
- license metadata observed on both: Apache-2.0;
- LoRA trigger: `Pixel Art`;
- weight: `Qwen-Image-2512-Master-Pixel-Art-LoRA.safetensors`;
- weight SHA-256: `2a2775ac823b3704eba2f72f3be65d7b0fe3262f1822e971c16818d0c923a4b6`;
- Hub-displayed weight size: 1.18 GB;
- declared training images: 50;
- training dataset provenance: not disclosed in the model card.

The last item prevents any inference from model license -> dataset provenance -> shipping rights. Outputs remain candidate-only until reviewed.

## Metadata-only audit clone

Use the command supplied for lightweight inspection:

```bash
GIT_LFS_SKIP_SMUDGE=1 git clone https://huggingface.co/prithivMLmods/Qwen-Image-2512-Pixel-Art-LoRA
```

This intentionally avoids pulling the large LFS/Xet weight during metadata audit. It is not an inference install.

## Production download rule

Do not render from mutable `main`. Resolve/pin the audited revision and fetch only the required weight on the GPU worker/Colab session. One acceptable pattern is:

```bash
hf download prithivMLmods/Qwen-Image-2512-Pixel-Art-LoRA \
  Qwen-Image-2512-Master-Pixel-Art-LoRA.safetensors \
  --revision e14eea588e8e4a9c753439e52a203d06288769c5 \
  --local-dir /content/cria-models/qwen-pixel-art
```

Then verify SHA-256 before inference. Large base-model caches should remain ephemeral where possible.

## Routing

### High-value uses

- arena/environment concept passes;
- regional props;
- collectible concepts;
- icon concepts;
- story-scene concepts.

### Conditional uses

- character turnaround concepts;
- combat-pose concepts;
- portrait concepts.

Character output must still pass identity lock and cannot be treated as a faithful likeness merely because a prompt mentions a reference person.

### Not authoritative alone

- fighter core/clinch/ground spritesheets;
- paired BJJ techniques;
- identity from real-person references;
- UI containing baked text.

Those need the project-specific motion, identity, UI and biomechanical pipelines.

## Inference baseline

The upstream model card publishes:

- trigger `Pixel Art`;
- 45–50 inference steps;
- 1024×1024;
- 1280×832.

CRIA uses 48 steps as a middle baseline for candidate experiments. The upstream card labels 1280×832 as `3:1`; that label is mathematically inconsistent, so CRIA records the dimensions but not the ratio label.

## CRIA prompt prefix

Every request starts from the repository art-direction contract, not from a generic pixel-art prompt. The profile stores a baseline prefix that includes:

- `Pixel Art` trigger;
- CRIA Regional Premium 2D pixel art;
- Baixo Sul da Bahia;
- crisp square pixel clusters;
- cel shading;
- grounded anatomy;
- no smooth vector/photo/3D CGI;
- no unapproved brands/canon changes.

The rest of the prompt is derived from `.agents/skills/cria-art-direction/SKILL.md` and the COMMAND source data.

## Mandatory postprocess

```text
generated candidate
    -> human visual selection
    -> identity lock (characters)
    -> palette snap
    -> manual pixel cleanup
    -> nearest-neighbor normalization
    -> pivot normalization (sprites)
    -> Sprite Forge QA (sprites)
    -> paired sync + BJJ biomechanics (techniques)
    -> provenance + rights sidecars
    -> human approval
    -> Godot integration
    -> runtime evidence
    -> shipping gate
```

Generation never implies approval, rights clearance, integration or shipping.

## Validation

```bash
npm run validate:qwen-pixel-art
python -m unittest discover -s tests/cloud -p 'test_qwen_pixel_art_profile.py'
```
