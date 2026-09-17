# Cria Visual Foundry v1

Pipeline oficial de fabricação visual do **Cria do Tatame** para transformar referências e masters 3D em assets 2D/pixel-art integráveis no Godot.

## Papel no repositório

Este módulo **não cria um segundo pipeline visual**. Ele complementa:

- `data/visual/production_manifest_v02.json` — fonte de verdade de escopo visual;
- `tools/ai_asset_pipeline/` — geração e filas existentes;
- `tools/art/` — sprite forge, identidade e QA;
- `tools/animation/` — pacotes de animação;
- `production/` — lotes e evidências de produção.

A Foundry v1 entra entre a referência/master e o Sprite Forge:

```text
referência/concept
  -> master 3D
  -> retopo + UV + material
  -> rig
  -> animação
  -> render ortográfico RGBA
  -> downscale/pixel pass
  -> Sprite Forge / QA
  -> Godot
```

## Objetivos

1. reduzir drift de personagem entre frames;
2. reaproveitar rig e animações;
3. produzir pares atacante/defensor com timing reproduzível;
4. manter pivô, escala e contato com chão estáveis;
5. gerar saídas auditáveis e versionadas;
6. preservar desempenho mobile.

## Ferramentas previstas

Ferramentas são adaptadores opcionais, não dependências do runtime:

- Blender — DCC, render, câmera, rig e automação;
- TripoSG / TripoSR — candidatos de image-to-3D;
- TRELLIS.2 — candidato para master/textura quando hardware permitir;
- UniRig — candidato de auto-rig;
- Instant Meshes / QuadriFlow — retopologia;
- Godot — destino final.

Nenhuma ferramenta externa é considerada instalada ou aprovada apenas por aparecer nesta lista. Cada adaptador precisa passar por licença, smoke test, custo, qualidade e exportação antes de entrar em produção.

## Padrão visual herdado

A Foundry respeita o manifesto visual existente:

- estilo: HD Pixel Art 2.5D Regional Premium;
- altura de combate: 72 px;
- grid: 16 px;
- filtro: nearest;
- outline final: 1 px;
- fundo: RGBA transparente quando aplicável;
- pivô e linha de contato documentados.

## Comandos

Planejar lotes:

```bash
python tools/visual_foundry/build_foundry_queue.py
```

Validar contratos:

```bash
python tools/visual_foundry/validate_visual_foundry_v1.py
```

Teste unitário:

```bash
python -m unittest discover -s tests -p 'test_visual_foundry_v1.py'
```

## Estrutura de saída por personagem

```text
production/visual_foundry/<character_id>/
  refs/
  master/
  rig/
  anim/
  renders/
  sprites/
  metadata.json
  provenance.json
  qa_report.md
```

Arquivos grandes (`.blend`, masters pesados, checkpoints) não devem ser versionados diretamente sem política de LFS aprovada.

## Definition of Done

Um personagem derivado pela Foundry só pode avançar para shipping quando:

- identidade canônica aprovada;
- master com proveniência/licença registrada;
- escala e pivô compatíveis com o perfil do jogo;
- animações obrigatórias produzidas;
- técnicas pareadas possuem atacante, defensor e `sync_map`;
- render bruto preservado como evidência;
- sprite final passa pelo Sprite Forge e QA visual;
- asset roda em cena real no Godot;
- desempenho e memória passam no gate mobile.
