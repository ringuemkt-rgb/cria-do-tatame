# Open Pixel Forge v1 — produção visual local do Cria do Tatame

Status: integração experimental, local-first e segura por padrão.

## Objetivo

Substituir dependência exclusiva de APIs pagas por uma forja local baseada em software livre e modelos de pesos abertos, mantendo o repositório oficial como fonte única de verdade.

`Sem limites` significa **sem cota por chamada de API**. Ainda existem limites reais de GPU, memória, armazenamento, tempo de processamento, energia, licença dos pesos e revisão humana.

## Arquitetura

```text
production_manifest_v02.json
        ↓
assets:queue
        ↓
production_queue_v02.jsonl
        ↓
open_pixel_forge.py
        ↓
ComfyUI local HTTP API
        ↓
raw candidates
        ↓
nearest downscale + palette reduction + optional rembg
        ↓
Pixelorama / LibreSprite cleanup
        ↓
build_sprite_atlas.py
        ↓
spritesheet.png + preview.gif + atlas_metadata.json
        ↓
manual QA + integrate_assets_godot.py
        ↓
Godot runtime + Android physical test
```

A geração nunca grava diretamente em `assets/graphics`. As saídas ficam em:

```text
tools/ai_asset_pipeline/generated_outputs/open_pixel_forge/
```

Cada pacote nasce com `status: candidate_only` e `promotion_blocked: true`.

## Pilha aprovada

| Camada | Ferramenta | Uso |
|---|---|---|
| Orquestração visual | ComfyUI | servidor local, workflows e API HTTP |
| Estilo pixel | Pixel Art XL / Pixel Party XL / Pixel Art Slider | LoRA ou checkpoint local, sem versionar pesos |
| Consistência | IP-Adapter | rosto, roupa, massa e paleta por referência |
| Pose e composição | ControlNet | esqueleto, contorno, profundidade e layout |
| Limpeza | Pixelorama | edição pixel, timeline, paleta, tiles e animação |
| Alternativa de limpeza | LibreSprite | sprites e animação frame a frame |
| Interpolação | Practical-RIFE | candidatos intermediários, nunca aprovação automática |
| Recorte | rembg | remoção de fundo opcional |
| Atlas | `build_sprite_atlas.py` | empacotamento determinístico para Godot |

O registro de licenças e restrições está em:

```text
data/production/open_pixel_forge_sources_v01.json
```

## Instalação recomendada

### 1. Dependências do repositório

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
npm install
```

Windows PowerShell:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
npm install
```

### 2. ComfyUI fora do repositório

Instale a versão fixada em `data/production/open_pixel_forge_sources_v01.json` em uma pasta externa, por exemplo:

```text
D:/AI/ComfyUI
```

Não copie ComfyUI, custom nodes ou pesos para `cria-do-tatame`.

Inicie o servidor local na porta padrão 8188. O Open Pixel Forge consulta:

```text
http://127.0.0.1:8188
```

### 3. Modelos

Coloque o checkpoint em:

```text
ComfyUI/models/checkpoints/
```

E o LoRA pixel em:

```text
ComfyUI/models/loras/
```

Os nomes precisam coincidir com:

```text
data/visual/open_pixel_forge_config_v01.json
```

Não versionar `.safetensors`, `.ckpt`, `.pt`, `.pth`, `.onnx` ou modelos similares.

### 4. Ambiente local

Copie `.env.example` para `.env` e configure:

```env
CRIA_FORGE_PROVIDER=comfyui
COMFYUI_URL=http://127.0.0.1:8188
COMFYUI_CHECKPOINT=sd_xl_base_1.0.safetensors
COMFYUI_PIXEL_LORA=pixel-art-xl.safetensors
COMFYUI_LORA_STRENGTH=0.9
CRIA_FORGE_SEED=437042
```

## Comandos

### Validar contratos sem GPU

```bash
npm run assets:local:validate
```

Esse comando recria a fila e valida IDs, tipos, dimensões, prompts e bloqueios de cânone.

### Planejar cinco tarefas

```bash
npm run assets:local:plan
```

### Gerar candidatos de Ruan

```bash
python tools/ai_asset_pipeline/open_pixel_forge.py \
  --target ruan_macacao \
  --kind character_animation \
  --limit 5 \
  --candidates 2
```

### Gerar keyframes de uma técnica pareada

```bash
python tools/ai_asset_pipeline/open_pixel_forge.py \
  --target baiana_single_leg \
  --kind paired_technique_animation \
  --candidates 4
```

Isso gera candidatos. Não gera uma técnica game-ready automaticamente.

### Construir atlas após limpeza

```bash
python tools/ai_asset_pipeline/build_sprite_atlas.py \
  caminho/frames_limpos \
  caminho/pacote_final \
  --columns 8 \
  --cell-width 128 \
  --cell-height 128 \
  --fps 12
```

Saídas:

```text
spritesheet.png
preview.gif
atlas_metadata.json
```

## Perfis de produção

### Hub 8 direções

- fonte: 512 ou 1024 px;
- redução nearest para célula de 64 px;
- oito direções produzidas em tarefas separadas;
- pivô padrão no centro inferior;
- limpeza manual de rosto, mãos, faixa e patches.

### Combate

- fonte: 1024 px por keyframe;
- alvo visual: atleta de 72 px na câmera final;
- canvas intermediário recomendado: 128 × 128 ou 192 × 128;
- atacante e defensor separados somente depois de o contato ser validado;
- `sync_map.json`, hitbox, hurtbox e grabbox são obrigatórios.

### Arenas

- geração de conceito em 1536 × 864;
- separação manual em cinco camadas;
- colisão, bounds de câmera, oclusão e orçamento Android não são inferidos pela IA;
- especificidade regional vale mais que decoração genérica.

### UI

- geração em 1280 × 720;
- nenhum texto longo deve ser incorporado à imagem;
- nove-patch, ícones e estados de controle precisam ser exportados separadamente;
- alvos touch continuam com mínimo de 48 dp.

## Vertical slice inicial

Ordem recomendada:

1. Ruan `idle_combat`, `walk_forward`, `guard_hold`, `hit_light`, `victory`;
2. Davi com o mesmo núcleo;
3. referências IP-Adapter aprovadas para ambos;
4. Arena do Dique em cinco camadas;
5. clinch entry e baiana single-leg como técnicas pareadas;
6. HUD mobile;
7. atlas, metadados e importação Godot;
8. Main Menu → Terreiro → Combate → Resultado → Save;
9. teste Android físico e profiling.

Somente depois esse padrão deve ser replicado para o restante do elenco.

## Limites obrigatórios

- ComfyUI e modelos não entram no runtime do jogo.
- Gameplay continua determinístico e offline.
- Nenhum asset gerado é final por existir em PNG.
- Nenhuma técnica de grappling é aprovada por interpolação automática.
- OpenPose oficial da CMU não deve ser usado no pipeline comercial sem licença comercial.
- Pesos OpenRAIL precisam ter revisão de uso e hash registrados.
- Pixel Party XL não deve ser espelhado ou hospedado pelo projeto.
- Conceitos com “Ruan Cria”, “Caio Ravel”, marcas ou ligas reais são bloqueados.

## Definition of Done da integração

- [ ] `npm run assets:local:validate` verde;
- [ ] dry-run gera plano determinístico;
- [ ] ComfyUI local responde ao health check;
- [ ] um candidato de Ruan é baixado e pós-processado;
- [ ] pacote contém metadata, import notes e QA;
- [ ] frames limpos geram atlas e GIF;
- [ ] atlas é importado com nearest no Godot;
- [ ] nenhum peso ou segredo aparece no Git;
- [ ] Ruan × Davi é testado em aparelho físico.
