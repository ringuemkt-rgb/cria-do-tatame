# Instalação modular CRIA Asset Factory v0.2 (apenas authoring)

**O que está instalado neste repositório:** manifesto de integrações, diagnóstico/instalador local do núcleo Python, criador de jobs canônicos, adaptador de submissão **somente localhost** para ComfyUI, tests e CI. Nenhum servidor/GPU/modelo externo é instalado automaticamente no computador do usuário. Godot continua único runtime.

## 1. Núcleo (CPU, sem serviços pagos)

Na raiz do repositório oficial, Python >= 3.10:

```sh
python tools/cria-asset-factory/scripts/bootstrap.py --check
python tools/cria-asset-factory/scripts/bootstrap.py --install-core
python tools/cria-asset-factory/scripts/quality_gate.py
python -m unittest discover -s tools/cria-asset-factory/tests -p 'test_*.py' -v
```

O instalador cria apenas `tools/cria-asset-factory/.venv` e instala o pacote Python local. Não toca no ambiente global nem altera cenas. FFmpeg é um binário do sistema, detectado por `--check`, não instalado pelo Python. A linha gratuita de CI instala/verifica esse mesmo núcleo em ambiente descartável.

## 2. Preparar um candidato (nenhuma imagem gerada)

```sh
python tools/cria-asset-factory/scripts/prepare_candidate_job.py \
  --id baiana --character ruan_macacao --outfit gi_white \
  --phase anticipation --kind character_combat_pose_concept \
  --out /tmp/cria-baiana-authoring.json
```

O job usa apenas IDs do Gold Slice e lê as revisões exatas do `data/ai/qwen_pixel_art_profile_v1.json`. O PNG 128x128 **não** é a resolução de inferência: gera-se um *conceito* em resolução maior e apenas depois de revisão usa-se Pixelorama/palette-snap/crop para o frame normalizado.

## 3. ComfyUI (opcional, fora do runtime)

- Repositório: <https://github.com/Comfy-Org/ComfyUI> (código GPL-3.0; usar como ferramenta externa, sem incorporar código ao Godot).
- Criar **ambiente Python separado**, instalar PyTorch correspondente à GPU e os requisitos conforme guia oficial; registrar SHA do upstream revisado. Não confundir instalação de ComfyUI com download de pesos.
- Fornecer um **workflow API JSON já configurado** com checkpoints/LoRA cujas licenças foram revisadas; o adapter não o cria nem faz upload implícito de imagem de referência.
- Rodar serviço apenas em `127.0.0.1`; não expor a porta para a internet.
- Primeiro executar `comfyui_adapter.py --job /tmp/cria-baiana-authoring.json --workflow /path/workflow_api.json --prompt-node 6` (dry-run). Somente em GPU próprio autorizado, acrescentar `--submit`. A ação inicia inferência e não produz asset final/autoriza shipping.

O Qwen-Image-2512 + Pixel-Art-LoRA **já está registrado e pinado** no projeto, mas pesos grandes, VRAM e direitos de treino permanecem gates externos. Não baixar pesos/modelos automaticamente nem consumir Hugging Face Jobs pagos.

## 4. Ferramentas externas opcionais

| Ferramenta | Uso | Ativação | Limite |
|---|---|---|---|
| FFmpeg | vídeo/áudio fornecido | instalar via gestor do sistema | fonte legal obrigatória |
| Pixelorama (MIT) | edição e correção de pixel art | instalar build desktop oficial | requer revisão humana |
| ComfyUI (GPL-3.0) | geração local de conceitos | GPU + workflow já aprovado | sem prometer consistência de 2 lutadores |
| Motion Factory existente | referência de movimento | `tools/motion_factory/run_mixamo_llm_mocap.py` | upstream/rigs/termos próprios |
| SAM 2 / MMPose | máscaras / keypoints | ambiente Torch/CUDA separado, manual | grande custo e limitação em membros oclusos |
| Áudio | transcodificação de WAV licenciado | FFmpeg + `build_audio_pack.py` | sem áudio sintetizado automaticamente |

## 5. Política de shipping e custo

Tudo é `shipping=false`, `qa_status=pending`. A fábrica nunca cria `CombatManager`, nem promove licença ou origem desconhecida. Cobrança de serviço externo, download de modelos enormes e GPU **não são autorizados** por este instalador; exigem intervenção manual explícita no ambiente de inferência. Sem hardware GPU, a produção por Qwen não pode ser validada.

Cada lote precisa de revisão de origem, identidade, anatomia, sincronização, paleta, `quality_gate.py`, testes Godot na cena real, `npm run quality` e aprovação humana.

Referências: `AGENTS.md`, `docs/DECISIONS.md`, `.agents/skills/cria-art-direction/SKILL.md`, `data/ai/model_registry_v02.json`, `data/production/external_tool_registry_v1.json`.
