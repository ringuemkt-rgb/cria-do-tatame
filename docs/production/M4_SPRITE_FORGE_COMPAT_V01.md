# M4 — Compatibilidade do Sprite Forge

**Status:** DRAFT operacional  
**Branch de trabalho:** `feat/m4-sprite-forge-compat`  
**Objetivo:** desbloquear a preparação determinística de candidatos do M4 sem alterar o runtime Godot, sem promover assets e sem depender de um projeto externo não verificado.

## Decisão

O bloqueio não deve ser resolvido procurando um binário mágico chamado `agent-sprite-forge`. A `main` já possui `tools/cria_forge/cria_forge.py`, o pipeline de fila `tools/ai_asset_pipeline/build_production_queue_v02.py` e dependências suficientes para operações locais de imagem, mas não possui `tools/sprite_forge/`, `generate2dsprite`, `map`, um builder de props/VFX ou um gate visual integrado ao quality gate.[1] [2]

A solução adotada nesta branch é uma **camada fina de compatibilidade determinística**:

| Camada | Responsabilidade | Pode promover asset? |
|---|---|---:|
| Geração de conceito/candidato | Ambiente de geração autorizado ou produção manual; saída bruta imutável | Não |
| `tools/sprite_forge/cli.py` | Chroma key/despill conservador, fatiamento, contact sheet, metadata, licença-templated e validação estrutural | Não |
| `tools/sprite_forge/generate2dsprite` | Launcher compatível para empacotamento de uma folha PNG | Não |
| `tools/sprite_forge/map` | Launcher compatível para gerar mapa de regiões, pivôs e SHA-256 | Não |
| `tools/sprite_forge/build_m4_queue.py` | Subfila segura para ícones, arenas e UI usando IDs existentes | Não |
| QA humano e integração Godot | Aprovação de cânone, licença, biomecânica, legibilidade e consumidor real | Sim, manualmente |

Essa camada não tenta substituir o `Visual QA V2` proposto no PR [#65](https://github.com/ringuemkt-rgb/cria-do-tatame/pull/65), nem o gerador de fila visual proposto no PR [#38](https://github.com/ringuemkt-rgb/cria-do-tatame/pull/38). O plano correto é portar ou rebasear esses PRs depois da revisão da base, usando este compatibilizador apenas para fechar a lacuna de comandos e empacotamento.

## Por que não vendorizar imediatamente um forge externo

O contrato do projeto exige que ferramentas externas sejam opcionais, licenciadas, reproduzíveis e separadas do runtime. Também exige que fontes, revisões imutáveis, datasets, adapters e cadeia de licença sejam registrados antes da adoção.[3] A busca no GitHub encontrou projetos de pixel-art pipeline, porém a maioria dos resultados relevantes tem poucos sinais de maturidade ou não declara compatibilidade com este contrato; o repositório do projeto já lista Pixelorama e Material Maker como ferramentas de pesquisa/aprovação, mas não como um CLI `generate2dsprite/map` pronto para esta base.[4]

Consequentemente, a regra é: **reaproveitar a arquitetura existente e fixar uma interface local estável; somente depois avaliar um backend externo atrás dessa interface**. Um backend futuro poderá produzir ou normalizar imagens, mas deverá continuar entregando o mesmo pacote e passar pelos mesmos gates. O M4 não deve ficar bloqueado por uma dependência cujo código, licença, versão ou comportamento não foram verificados.

## Contrato dos comandos

### Empacotamento de um spritesheet

```bash
python tools/sprite_forge/generate2dsprite \
  --input /path/to/candidate.png \
  --output-dir /path/to/candidate-package \
  --asset-id m4_item_id \
  --frame-width 256 \
  --frame-height 256 \
  --fps 12 \
  --grid-px 16 \
  --chroma-key '#FF00FF' \
  --key-threshold 24
```

O comando preserva `raw_sheet.png`, produz `clean_sheet.png` e `spritesheet.png`, fatia `frames/frame_###.png`, cria `preview.gif` e `contact_sheet.png`, grava `metadata.json`, `import_notes.md`, `qa_report.md` e um `license.json` inicial com estado `pending_human_review`. O `license.json` é um formulário de proveniência, não uma licença concedida.

O cleanup é deliberadamente limitado. Ele remove a chave magenta próxima da cor declarada, reduz fringe em pixels de borda e não faz redimensionamento, inferência de anatomia, geração de poses, pintura de textura ou promoção de resultado. A ausência de redimensionamento evita transformar uma auditoria em uma alteração silenciosa do asset.

### Mapa de regiões

```bash
python tools/sprite_forge/map \
  --input /path/to/clean_sheet.png \
  --output /path/to/regions.json \
  --frame-width 256 \
  --frame-height 256 \
  --labels anticipation,entry,contact,stabilize,response,recovery
```

O `map` calcula regiões retangulares, pivô `bottom_center`, quantidade de frames e SHA-256 da folha de entrada. Ele **não** é um `sync_map.json` biomecânico de atacante e defensor. Técnicas pareadas continuam exigindo atacante, defensor, estados de entrada/saída, contato, timing, interrupção, custos e aprovação BJJ conforme o contrato de produção.[5]

### Subfila M4

```bash
python tools/sprite_forge/build_m4_queue.py \
  --output /tmp/m4_queue_v01.jsonl
```

A subfila atual é conservadora e emite 14 linhas:

| Tipo | Quantidade | Estado inicial |
|---|---:|---|
| Ícones/cards de técnica | 6 | `queued` |
| Ícones de UI | 4 | `queued` |
| Props do Terreiro/Dique | 2 | `needs_item_specification` |
| Partículas do Terreiro/Dique | 2 | `needs_item_specification` |

Os seis IDs de técnica são `grip_de_ferro`, `baiana`, `knee_cut`, `cem_quilos`, `montada` e `mata_leao`, todos presentes no catálogo gráfico atual. Os quatro alvos de UI são `combat_hud_mobile`, `submission_hud`, `result_screen` e `cria_live_feed`, todos presentes no manifesto audiovisual v02. Os pacotes de arena ficam em nível de variante: `terreiro_da_luta/afternoon` e `arena_do_dique/event_day`. O builder não inventa IDs de props, partículas ou materiais; exige uma especificação de item antes de gerar.

## Pacote e armazenamento

Os candidatos grandes devem ir para a árvore privada `CriaDoTatame/assets/candidatos/<BATCH_ID>/`. Git deve receber somente o código do compatibilizador, subfila, metadata, relatórios, hashes e documentação permitidos pelo contrato vigente. O fluxo privado recomendado é candidato → revisão humana de arte, biomecânica, licença e cânone → aprovado → cache local → integração explícita em cena Godot.[6]

O pacote de cada item deve manter, quando aplicável, `raw_sheet.png`, `clean_sheet.png`, `spritesheet.png`, `frames/`, `preview.gif`, `contact_sheet.png`, `metadata.json`, `import_notes.md`, `qa_report.md` e sidecar de licença. O `metadata.json` deve declarar fonte, SHA, frame size, FPS, pivot, grid, estado e parâmetros de cleanup. Nenhum arquivo recebe o estado `approved` por este CLI.

## Critérios de desbloqueio

O M4 pode sair de `BLOCKED` para `READY_FOR_CANDIDATE_GENERATION` quando os seguintes itens estiverem verdes:

1. `tools/sprite_forge/` existe na branch e possui licença/documentação próprias;
2. `generate2dsprite`, `map` e `validate` executam de forma reproduzível;
3. a subfila M4 é gerada somente a partir de manifests versionados;
4. os testes cobrem cleanup, fatiamento, regiões, contagem e estado de promoção;
5. `license.json` é obrigatório e começa como pendente de revisão humana;
6. o PR não toca `project.godot`, autoloads, `CombatManager`, `DeckManager`, `AudioManager`, save migration ou segundo runtime;
7. o Visual QA V2, quando portado/rebaseado, é usado como gate adicional e não como aprovação humana;
8. cada item gerado tem consumidor real planejado ou permanece apenas especificado.

## Validação local

```bash
python -m unittest discover -s tests/sprite_forge -p 'test_*.py'
python tools/sprite_forge/build_m4_queue.py --output /tmp/m4_queue_v01.jsonl
python tools/cria_forge/cria_forge.py validate
npm run quality
```

A execução completa de `npm run quality` continua sendo obrigatória para a branch, mas o resultado deve ser atribuído aos arquivos realmente modificados. Um teste verde do compatibilizador não prova licença, cânone, biomecânica, legibilidade mobile ou integração Godot.

## Rollback

Se a camada não for aceita, fechar o PR sem merge, remover a branch temporária e manter o M4 como intake bloqueado. O rollback não exige alterar o runtime, apagar dados canônicos ou remover candidatos privados; basta descartar a camada compatível e preservar o ledger de decisão.

## Próximo passo após este PR

O próximo PR deve ser separado e pequeno: adicionar o comando do builder ao CI, integrar o Visual QA V2 portado/rebaseado e validar um único item de ícone ou partícula em candidato privado. Só depois deve-se criar uma ficha de prop individual e permitir que M4 avance de `needs_item_specification` para `queued`.

## Referências

[1]: https://github.com/ringuemkt-rgb/cria-do-tatame/blob/main/tools/cria_forge/cria_forge.py "Cria Forge local — comandos atuais"

[2]: https://github.com/ringuemkt-rgb/cria-do-tatame/blob/main/tools/ai_asset_pipeline/build_production_queue_v02.py "Fila de produção audiovisual v02"

[3]: https://github.com/ringuemkt-rgb/cria-do-tatame/blob/main/data/production/canon_contract_v4_1.json "Contrato canônico v4.1 — proibições e autoridades"

[4]: https://github.com/Orama-Interactive/Pixelorama "Pixelorama — ferramenta aprovada no catálogo do projeto"

[5]: https://github.com/ringuemkt-rgb/cria-do-tatame/blob/main/data/visual/production_manifest_v02.json "Manifesto visual v02 — técnicas pareadas e quality gate"

[6]: https://github.com/ringuemkt-rgb/cria-do-tatame/blob/main/docs/production/DRIVE_CLOUD_V1.md "Drive Cloud v1 — proveniência e promoção manual"
