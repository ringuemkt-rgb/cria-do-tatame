# Release Gate Status Reconciliado — 13/08/2026

## Estado congelado

- `main`: `d99780ffb42aff4f66e71a62f9e24f6f8f8d0a2e`
- origem do HEAD: merge do PR #59 (`feat(forge): integrar Drive, Colab e provenance Hugging Face`)
- decisão desta fotografia: **FREEZE / NO MERGE**
- proteção de `main`: **ausente** no momento da consulta
- PRs abertos: **23**

## Regra de reconciliação

O ledger existente (`data/production/release_gate_status_v01.json`) permanece como evidência histórica. Seus gates `passed` apontam para 01/08/2026 e para o commit `246201e6319915652476b27da7334229b26d67fd`; eles não são silenciosamente rebased para o HEAD atual.

Um gate só é considerado certificado para release em `d99780f` quando existe evidência ligada ao HEAD (ou descendente explicitamente auditado) e ao mesmo escopo do gate.

## Gates históricos preservados

| Gate | Estado histórico | HEAD atual |
|---|---|---|
| `npm_run_quality` | passed em `246201e` | revalidação de release pendente |
| `godot_headless_import` | passed em `246201e` | revalidação de release pendente |
| `godot_parser_check` | passed em `246201e` | revalidação de release pendente |
| `save_load_roundtrip` | passed em `246201e` | revalidação de release pendente |
| `android_arm64_export` | passed em `246201e` | export histórico válido; release atual ainda requer smoke/device |

## Pendências de release

- vertical slice ouro com touch e assets finais;
- Android em aparelho físico;
- Windows export smoke;
- Web export/PWA smoke;
- auditoria final de licenças de assets;
- auditoria de loudness/áudio;
- revisão de acessibilidade;
- revisão canônica v5;
- matriz PC + Web + Android certificada;
- proteção da `main`.

## CI do HEAD

Foram observadas execuções de GitHub Actions associadas ao SHA `d99780f`; `Validate Cria Data` concluiu com sucesso. Esta fotografia não converte esse fato isolado em certificação de todos os gates de release.

## Topologia crítica dos PRs

```text
main @ d99780f
│
├─ #61 production stack / GPT WORK / packs / GATE-L1      [DRAFT]
│  ├─ #63 narrativa Mundo V3                              [DRAFT]
│  └─ #65 Visual QA V2                                    [DRAFT]
│
├─ #66 mocap paired-motion prototype                      [DRAFT lateral]
└─ #67 BJJ dynamics atlas + authoring specs               [DRAFT lateral]
```

#63 e #65 são **irmãos sobre #61**, não uma cadeia #61→#63→#65.

A cadeia visual histórica permanece:

```text
#48 logo/brand
  ↓
#51 visual canon skill v2
  ↓
#52 ART_PROTOCOL v1
```

## Bloqueadores P0

1. proteger `main` e exigir checks/review sem criar deadlock;
2. reconciliar cânone v5 antes de absorver narrativa/arte incompatível;
3. fechar a governança do #61, especialmente L1/L2/L3/L4 e human promotion;
4. rebasear #65 após decisão do #61;
5. reescrever/portar #63 sobre o cânone final;
6. formalizar 480×270 + PC/Web/APK no runtime existente;
7. fechar vertical slice Ruan×Davi antes de escala de conteúdo.

## Invariantes do congelamento

- nenhum merge autorizado por este documento;
- nenhum asset promovido para `assets/aprovados`;
- GATE-L4 permanece humano;
- `SaveManager`, `AudioManager` e `CombatManager` existentes continuam autoridades únicas;
- pesquisa BJJ/mocap não vira shipping sem provenance, QA e revisão humana;
- evidência histórica não é reclassificada como teste atual.
