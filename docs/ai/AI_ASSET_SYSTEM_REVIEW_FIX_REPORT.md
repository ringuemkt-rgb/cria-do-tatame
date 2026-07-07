# AI Asset System Review and Fix Report

## Revisao executada

Foi feita uma revisao da camada de producao visual do Cria do Tatame com foco em:

- canon visual;
- pipeline Hugging Face;
- seguranca de credenciais;
- organizacao de manifests;
- fila de geracao;
- QA antes de importar assets no Godot.

## Correcoes aplicadas

### 1. Credenciais

A chave do Hugging Face nao foi gravada no repositorio. O projeto agora usa variavel local `HF_TOKEN` via ambiente ou arquivo `.env` nao versionado.

Arquivos adicionados/alterados:

- `.env.example`
- `.gitignore`
- `tools/ai_asset_pipeline/auth_check.py`

### 2. Manifests de IA

Foram criados os manifests oficiais:

- `data/ai/asset_pipeline_models_v01.json`
- `data/ai/asset_manifest_v01.json`

Esses manifests definem modelos, saidas, regras de canon, naming convention, personagens, arenas, audio e cutscenes.

### 3. Prompts profissionais

Foram criados prompts oficiais para:

- personagens pixel art;
- acoes de Ruan;
- NPCs principais;
- arenas por camada;
- musicas;
- SFX;
- cutscenes.

Arquivos:

- `prompts/ai_asset_generation/PIXEL_ART_CHARACTER_PROMPTS.md`
- `prompts/ai_asset_generation/ARENA_AUDIO_VIDEO_PROMPTS.md`

### 4. Fila de producao

Criado script local:

- `tools/ai_asset_pipeline/build_generation_queue.py`

Ele gera tarefas JSONL para personagens, arenas, audio e cutscenes.

### 5. Gerador local de imagens

Criado script local:

- `tools/ai_asset_pipeline/generate_image_assets.py`

Ele tenta usar Diffusers localmente com `HF_TOKEN`. Se falhar, gera metadados para producao manual.

### 6. Validador

Criado script local:

- `tools/ai_asset_pipeline/validate_asset_pipeline.py`

Ele verifica se a camada de IA possui os arquivos obrigatorios e se o manifesto tem Ruan, arenas e SFX.

## Como ativar localmente

1. Copiar `.env.example` para `.env`.
2. Colocar a chave do Hugging Face no `.env` local.
3. Nao commitar `.env`.
4. Exportar a variavel de ambiente antes de rodar scripts.

Exemplo Linux/macOS:

```bash
export HF_TOKEN="sua_chave_local"
python tools/ai_asset_pipeline/auth_check.py
python tools/ai_asset_pipeline/build_generation_queue.py
python tools/ai_asset_pipeline/validate_asset_pipeline.py
python tools/ai_asset_pipeline/generate_image_assets.py --metadata-only --limit 5
```

## Ordem de producao recomendada

1. Ruan Macacao: idle, stance, grip, clinch, takedown.
2. Davi Relampago: idle, counter, defense.
3. Terreiro da Luta: 5 camadas.
4. Arena do Dique: 5 camadas.
5. SFX basicos: grip, queda, respiracao, UI click.
6. Cria Live UI e notificacao.
7. Cutscene primeira derrota.

## QA final antes de importar no Godot

- Silhueta legivel em celular.
- Sem texto aleatorio dentro da imagem.
- Sem marca real.
- Sem equipe real.
- Sem pessoa real identificavel.
- Pose esportiva segura e compreensivel.
- Ruan reconhecivel como Macacao.
- Arquivo no caminho certo.
- Nome seguindo manifest.

## Status

A camada de IA agora esta pronta para producao local controlada. Os assets finais ainda precisam ser gerados fora do repositorio e importados depois do QA.
