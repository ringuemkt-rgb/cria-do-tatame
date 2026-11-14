#!/usr/bin/env bash
set -euo pipefail
# Run from OFFICIAL repository root. This checks DATA ONLY; no image generation.
python tools/cria-asset-factory/scripts/quality_gate.py
# Optional after supplying LICENSED, matched 128x128 attacker/defender frames:
# python tools/cria-asset-factory/scripts/build_paired_technique.py --id baiana \
#   --attacker-id leoa --defender-id jacare_do_mangue \
#   --attacker /work/input/attacker --defender /work/input/defender \
#   --counts 2,2,2,3,2,2 --commit-frame 8 --out /work/candidates/baiana
# python tools/cria-asset-factory/scripts/quality_gate.py --candidate /work/candidates/baiana
# npm run quality  # only after integration into actual Godot scene
