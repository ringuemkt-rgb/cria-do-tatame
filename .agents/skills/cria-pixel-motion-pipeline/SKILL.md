---
name: cria-pixel-motion-pipeline
version: 0.1.0
parent: cria-bjj-fight-intelligence@1.0.0
fail_closed: true
shipping_default: false
generative: auxiliary_only
frame_spec: 128x128 | pivot [64,96] | 12fps | nearest | no-AA
---

# CRIA PIXEL MOTION PIPELINE

Converte movimento BJJ pareado validado em apresentação pixel-art. Não cria biomecânica.

## Pipeline

`validated paired motion → key poses → Blender/orthographic reference → pixel candidate → deterministic cleanup → attacker/defender split → sync_map → hitbox/contact metadata → preview → QA`.

## Regras

- nunca gerar atacante e defensor como movimentos independentes e tentar encaixar depois;
- shared origin e sync map são obrigatórios;
- identidade do personagem deve permanecer estável entre frames;
- zero AA, nearest-neighbor, alpha/paleta conforme gate de asset vigente;
- contact points não podem flutuar ou trocar membro;
- submission animation encerra em tap + release, sem espetáculo de hiperextensão;
- outputs brutos/generated permanecem `shipping=false`.

## QA mínimo

Estrutural: dimensões, pivot, alpha, palette, sidecars.
Temporal: drift, flicker, limb swap, duplicate frame, loop.
BJJ: posição, grip, base, kuzushi, transição, estabilização.
Biomecânica: ROM plausível, pelvis/base, contact geometry, queda segura.
Humano: gate obrigatório antes de qualquer promoção.
