# Cria do Tatame — Guia do Pipeline IA

## Objetivo

Rodar localmente a producao de assets do jogo com geracao visual, audio, vozes e integracao Godot.

Canon: Ruan Macacao Silva, Gorila Silverback, Itubera, Baixo Sul da Bahia e HD Pixel Art 2.5D Regional Premium.

## Ambiente Python

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Windows PowerShell:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

## Execucao segura de teste

```bash
python tools/generate_all_assets.py --dry-run --limit 5
python tools/cria_forge.py --dry-run --limit 3
python tools/integrate_assets_godot.py
```

## Execucao real

```bash
python tools/generate_all_assets.py --limit 10 --delay 1
python tools/cria_forge.py --limit 5
python tools/integrate_assets_godot.py
```

## Importacao no Godot 4.2+

1. Abrir o projeto no Godot.
2. Esperar a importacao automatica dos assets.
3. Conferir `assets/generated_metadata/godot_import_manifest.json`.
4. Abrir cenas em `scenes/generated_characters/`.
5. Ajustar pivots, AnimationPlayer e spritesheets no editor.

## QA obrigatorio

- Proibido Caio Ravel como asset novo.
- Proibido marca real.
- Proibido equipe real.
- Silhueta precisa funcionar em celular.
- Ruan precisa ser reconhecivel como Macacao.
- Audio deve ter volume limpo e loop sem estalo.

## Saidas

- `assets/sprites/`
- `assets/backgrounds/`
- `assets/ui/`
- `assets/audio/dialogues/`
- `assets/audio/music/`
- `assets/generated_metadata/`
- `scenes/generated_characters/`
