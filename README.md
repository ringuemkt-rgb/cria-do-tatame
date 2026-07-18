# 🦍🥋 Cria do Tatame – Pressão

Repositório oficial de produção do jogo **Cria do Tatame – Pressão**.

- **Gênero:** luta 2D + Action RPG de carreira + Jiu-Jitsu Brasileiro posicional
- **Engine:** Godot 4.3+; compatibilidade mínima atualmente auditada em Godot 4.2.2
- **Plataformas-alvo:** Android ARM64 e Windows x86_64
- **Visual:** HD Pixel Art 2.5D regional premium
- **Protagonista canônico:** Ruan “Macacão” Silva
- **Símbolo:** Gorila Silverback
- **Frase central:** Ser forte é ser gentil.
- **Slogan:** De cria pra cria. Luta. Disciplina. Evolução.

> Primeiro precisa abrir, rodar, salvar, lutar, avançar a semana e exportar. Depois vem o brilho.

O núcleo não é um beat’em up genérico. O Jiu-Jitsu é tratado como sistema: base, pegada, pressão, queda, passagem, controle, montada, costas, encerramento técnico e consequência moral.

## Fonte única de verdade

`ringuemkt-rgb/cria-do-tatame` é o único repositório oficial. Protótipos devem existir em branches deste repositório. Godot é o único runtime do produto; ferramentas Node e Python existem apenas para validação, produção de conteúdo e automação.

## Estrutura principal

```text
.
├── project.godot
├── export_presets.cfg
├── AGENTS.md
├── docs/
├── data/
├── src/
├── scenes/
├── assets/
├── tools/
│   ├── ai_asset_pipeline/
│   ├── build/
│   └── node/
├── production/
├── reports/
├── tests/
└── ai_lore_guardian/
```

## Abrir no Godot

1. Instale Godot 4.3+.
2. Clone o repositório.
3. Abra `project.godot`.
4. Aguarde a importação.
5. Rode a cena principal configurada.

```powershell
git clone https://github.com/ringuemkt-rgb/cria-do-tatame.git
cd cria-do-tatame
```

## Qualidade e contratos

Requer Node 20+ e Python 3.10+.

```powershell
npm run quality
```

O comando valida:

- sintaxe JSON;
- referências entre dados;
- estrutura obrigatória do jogo;
- contratos de runtime;
- prontidão de release;
- canon do protagonista;
- manifesto audiovisual;
- presets e scripts de build.

A CI também executa import/parser e smoke tests Godot headless.

O escopo final, os limites de autonomia, a cadeia audiovisual, as metas de conteúdo e os gates que impedem uma declaração prematura de conclusão estão definidos em [`docs/CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md`](docs/CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md). O equivalente validável por máquina está em [`data/production/supreme_build_contract_v01.json`](data/production/supreme_build_contract_v01.json).

## Fila audiovisual completa

O inventário técnico está em:

```text
data/visual/production_manifest_v02.json
```

Para gerar uma fila JSONL individualizada de personagens, animações sincronizadas, arenas, UI e áudio:

```powershell
npm run assets:queue
```

Saída:

```text
tools/ai_asset_pipeline/generated_queue/production_queue_v02.jsonl
```

Todo asset final exige preview, metadata, documentação de importação e QA. Concept art não entra diretamente na build.

## Deck de Combate — A Mente no Tatame

O Terreiro inclui um construtor de 5 técnicas ativas e 3 fundamentos passivos. Em combate, uma mão determinística de 3 cartas especializa técnicas existentes sem pausar a luta nem ignorar posição, recursos, timing ou tap/escape. O design e a integração estão documentados em [`docs/gameplay/COMBAT_DECK_SYSTEM_V01.md`](docs/gameplay/COMBAT_DECK_SYSTEM_V01.md).

## Gerar APK Android no Windows

Pré-requisitos:

- Godot 4.3+ e export templates da mesma versão;
- JDK 17 configurado no Godot;
- Android SDK configurado;
- `GODOT_BIN` opcionalmente apontando para o executável;
- aparelho ARM64 e `adb` para instalação automática.

Auditoria:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build\check_environment.ps1
```

Exportação debug:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build\build_android_debug.ps1
```

Exportar e instalar no aparelho conectado:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build\build_android_debug.ps1 -Install
```

Saída esperada:

```text
builds/android/CriaDoTatame-debug.apk
reports/build/android_build_report.json
builds/android/CriaDoTatame-debug.apk.sha256.txt
```

O projeto só pode declarar APK pronto quando o arquivo existir, possuir hash e tiver sido instalado e testado em aparelho físico.

## Build Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build\build_windows_debug.ps1
```

Saída esperada:

```text
builds/windows/CriaDoTatame.exe
reports/build/windows_build_report.json
```

## Vertical slice obrigatória

- Main Menu funcional.
- Terreiro da Luta navegável.
- Ruan jogável.
- Mestre Dendê disponível no hub.
- Davi Relâmpago como rival inicial.
- Arena do Dique funcional.
- Combate com vida, gás, foco, guarda, grip e controle.
- Ações contextuais mobile.
- Queda, passagem, montada e encerramento técnico.
- Resultado, progressão, Cria Live e retorno ao hub.
- Save/load.
- Uma semana de carreira.
- APK debug documentado e testado.

## Documentos prioritários

- `AGENTS.md` — regras para Codex, Manus e agentes.
- `docs/CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md` — especificação definitiva de construção e Definition of Done.
- `data/production/supreme_build_contract_v01.json` — metas e gates executáveis.
- `docs/qa/RUNTIME_AUDIT_V08.md` — auditoria do runtime.
- `docs/production/APK_VISUAL_COMPLETION_PLAN_V09.md` — gates de APK e audiovisual.
- `data/visual/production_manifest_v02.json` — inventário completo.
- `docs/09_MANUS_MASTER_PROMPT.md` — orientação de execução delegada.

## Canon obrigatório

O protagonista oficial é **Ruan “Macacão” Silva**. Referências antigas a Caio Ravel ou Ruan “Cria” são legado e não podem entrar em UI, dados finais ou campanha principal.

- Origem: Ituberá, Baixo Sul da Bahia.
- Idade: 19 anos no início, 28 no final.
- Símbolo: Gorila Silverback.
- Estilo: pressão pesada, grip de ferro e top game dominante.
- Poder mecânico: Silverback Grip.
- Frase eixo: Ser forte é ser gentil.

## Definition of Done da base

A base só é considerada pronta quando:

- abre no Godot sem erro fatal;
- Main Menu entra no Terreiro;
- Terreiro inicia combate;
- combate respeita estados e recursos;
- resultado retorna ao hub;
- save/load funciona;
- calendário avança;
- JSON e contratos passam na CI;
- APK debug é exportado e testado em aparelho.

## Status

O runtime central e os smoke tests foram fortalecidos. A branch de produção v0.9 adiciona presets oficiais na raiz, scripts Windows de exportação, validação de release e manifesto audiovisual completo. Assets finais, controles touch em aparelho, performance Android e build release assinada permanecem gates obrigatórios antes de chamar o jogo de concluído.
