# Agent Sprite Forge — decisão e integração v1

**Status:** ACTIVE  
**Verificado em:** 2026-08-10  
**Escopo:** ferramenta externa opcional para pós-processar candidatos visuais.

## Veredito

O repositório [0x0funky/agent-sprite-forge](https://github.com/0x0funky/agent-sprite-forge) foi auditado no commit `64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2`.

- licença do código: MIT;
- dependências Python declaradas: Pillow e NumPy;
- testes upstream executados: 15, todos aprovados;
- chamadas de rede no pós-processador: nenhuma;
- subprocesso observado: somente `ffmpeg` no módulo opcional de vídeo, usando lista de argumentos e sem shell;
- runtime do jogo: não depende da ferramenta;
- instalação global de skill: não é feita automaticamente.

O processador de sprites é tecnicamente útil para remover fundo magenta, separar grid, preservar escala comum, alinhar âncora e exportar PNG/GIF/metadados. A adoção é limitada a **candidatos**.

## Matriz de adoção

| Capacidade | Decisão no Cria | Motivo |
|---|---|---|
| Limpeza magenta → alpha | Aprovada para candidato | Operação determinística e reversível |
| Separação de grid | Aprovada para candidato | Mantém frames e metadados verificáveis |
| Escala compartilhada e alinhamento | Aprovada para candidato | Reduz deriva entre quadros |
| Idle/walk individual | Aprovada para candidato | Não altera regras de combate |
| FX isolado | Aprovada para candidato | Ainda exige QA de pixel e acessibilidade |
| Preview composto de dois lutadores | Condicional | Serve apenas para leitura; não separa os papéis |
| Mapas/props | Avaliação por lote próprio | Não substitui o contrato atual de TileMap/camadas |
| `video2dsprite` | Pós-processamento condicional | A geração por vídeo não existe no Codex e a fonte exige direitos |
| Prompt builder upstream | Bloqueado | Prompts genéricos top-down/criatura conflitam com cânone e câmera do Cria |
| Arte pareada pronta para shipping | Bloqueada | Não produz atacante/defensor separados, pivô comum, `sync_map` ou eventos |
| Aprovação biomecânica | Bloqueada | Métricas de escala/âncora não validam técnica de BJJ |
| Promoção automática | Bloqueada | Candidato não é asset final |

## Integração adotada

O repositório externo não é copiado para dentro do jogo. O perfil fixado vive em:

```text
data/production/agent_sprite_forge_profile_v01.json
```

O adapter oficial do projeto vive em:

```text
tools/visual/agent_sprite_forge_adapter.py
```

Ele verifica commit e hashes do checkout, aplica parâmetros conservadores e limita as saídas a:

```text
production/candidates/agent_sprite_forge/<lote>/<asset>/
```

Todo lote recebe `cria-intake.json` com `artifact_state=candidate` e `promotion_allowed=false`.

## Instalação externa fixada

```bash
git clone https://github.com/0x0funky/agent-sprite-forge.git /caminho/agent-sprite-forge
git -C /caminho/agent-sprite-forge checkout 64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2
python3 -m pip install -r /caminho/agent-sprite-forge/requirements.txt
python3 tools/visual/agent_sprite_forge_adapter.py verify \
  --forge-root /caminho/agent-sprite-forge
```

Não copie automaticamente as skills para `~/.codex/skills`; uma atualização upstream só entra após nova auditoria e atualização dos hashes.

## Exemplo: idle candidato

O PNG bruto precisa ser uma folha 2×2 com fundo magenta sólido, direitos confirmados e personagem já aprovado como referência.

```bash
python3 tools/visual/agent_sprite_forge_adapter.py plan \
  --forge-root /caminho/agent-sprite-forge \
  --input /caminho/ruan_idle_raw.png \
  --batch-id vertical_slice_01 \
  --asset-id ruan_idle \
  --profile character_idle
```

Para executar:

```bash
python3 tools/visual/agent_sprite_forge_adapter.py run \
  --forge-root /caminho/agent-sprite-forge \
  --input /caminho/ruan_idle_raw.png \
  --batch-id vertical_slice_01 \
  --asset-id ruan_idle \
  --profile character_idle \
  --source-rights-confirmed \
  --acknowledge-candidate-only
```

## Grappling pareado

`paired_composite_preview` aceita uma folha 2×3 em que cada célula contém o par completo. Isso gera somente preview composto. Para entrar no jogo ainda são obrigatórios:

1. separar atacante e defensor sem perder contato;
2. manter a mesma escala e um pivô compartilhado;
3. criar `sync_map` e eventos mecânicos;
4. produzir manifestos compatíveis com o runtime;
5. revisar frame a frame com direção de arte e especialista humano de BJJ;
6. integrar ao estado real e testar a transição anterior e posterior.

Assim, Agent Sprite Forge complementa o pipeline existente; ele não substitui `build_motion_package.py`, o manifesto pareado, a FSM ou a revisão humana.

## Evidências e limitações

```text
PASS  python3 -m unittest discover -s tests -v  (15 testes upstream)
PASS  licença/hash/commit fixados
PASS  processador sem rede e sem shell
LIMIT preview pareado não é export pareado de shipping
LIMIT um ResourceWarning de arquivo PIL foi observado em teste upstream de mapa
```

## Rollback

Remover o perfil, o adapter, o validador e esta decisão. Como não há plugin Godot, autoload, asset promovido ou dependência de runtime, o rollback não afeta boot, combate ou save.
