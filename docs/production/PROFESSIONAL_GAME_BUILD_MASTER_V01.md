# Cria do Tatame — Contrato Mestre de Produção Profissional V01

**Status:** fundação executável em evolução; não declarar “jogo completo” antes dos gates de conteúdo, arte, áudio, Android e revisão humana.

## 1. Produto e tese

`Cria do Tatame` é um RPG de luta posicional em Jiu-Jitsu brasileiro, Android-first, com Ruan “Macacão” Silva como protagonista. A tese mecânica é **força com controle**: posição, leitura, stamina, foco, tap e consequência importam mais que violência gráfica.

Princípios não negociáveis:

- combate determinístico e funcional offline;
- tap, parada técnica e linguagem segura de finalização;
- deck amplia a técnica, mas não substitui estado, custo ou defesa;
- áudio, câmera e VFX nunca alteram o resultado da simulação;
- sem segundo runtime, managers concorrentes ou IA obrigatória no APK;
- nenhum asset entra em shipping sem origem, licença e revisão;
- acessibilidade sensorial é requisito, não polimento tardio.

## 2. Autoridades de runtime

| Domínio | Autoridade | Estado atual |
|---|---|---|
| Dados canônicos | `DataRegistry` | implementado |
| Estado persistente | `WorldState` + `SaveManager` | implementado |
| Combate | `CombatManager` | implementado |
| Deck | `DeckManager` | implementado |
| Sinais | `SignalBus` | implementado |
| Áudio | `AudioManager` | catálogo/fallback implementado; assets finais pendentes |
| Apresentação do combate | `CombatPresentationDirector` scene-local | implementado nesta fundação |
| Game feel | `GameFeelManager` + `CombatImpactOverlay` | implementado nesta fundação |
| Treino | `TrainingManager` | fundação existente; conteúdo/UX final pendente |
| Carreira | `CareerLoop` e módulos `src/career/` | fundação existente; campanha completa pendente |
| Mundo | `WorldMapManager` + `WorldDirectorManager` | mapa de hubs existente; mundo aberto locomovível ainda não implementado |

É proibido criar outro `CombatManager`, `AudioManager`, `ArenaManager` ou `EnvironmentManager` enquanto a autoridade acima puder ser estendida cirurgicamente.

## 3. Loop vertical obrigatório

```text
Menu → carregar/criar save → Terreiro
→ treino/deck → seleção de luta → combate posicional
→ resultado/consequência → Cria Live → avanço de semana
→ autosave → Terreiro
```

O fluxo adicional de Pratigi é:

```text
Terreiro → Mapa do Baixo Sul → destino de evento Pratigi
→ aposta opcional em moeda interna → luta + heat visível
→ aviso/interdição segura ou resultado → consequência/save
```

Não existe minigame de fuga de autoridade.

## 4. Arquitetura do combate

### 4.1 Simulação

1. `CombatStateMachine` valida a posição relativa.
2. `DeckManager` oferece mão determinística de três cartas, dentro do deck ativo de cinco.
3. `TechniqueClashResolver` compara especialização e defesa.
4. `TechniqueResolver` valida estado, recursos, chance e efeitos.
5. `CombatManager` aplica a transição e emite o resultado.
6. `FrameDataSystem` anexa dados de apresentação; não toca a lógica.

### 4.2 Apresentação audiovisual

`data/combat/combat_presentation_v01.json` traduz técnica, família e clash em:

- hit-stop limitado a 100 ms;
- shake limitado a 8 px e 140 ms;
- flash limitado a alpha 0,16 e sem strobe acima de 2 Hz;
- VFX procedural legível e limitado a cinco impactos concorrentes;
- háptico limitado a 45 ms;
- cue de áudio resolvido pelo catálogo central.

`CombatPresentationDirector` é o único consumidor de `technique_resolved` para efeitos. Isso elimina áudio e shake duplicados entre ação do jogador e resposta da IA.

Com `reduced_motion=true`, shake e flash são removidos, hit-stop é reduzido e o feedback permanece por som, cor estática e háptico curto.

## 5. Arquitetura de áudio

`data/audio/audio_cues_v01.json` é a fonte de verdade. Cada cue tem:

- caminho futuro de `.ogg` licenciado;
- ganho nominal;
- fallback procedural offline;
- alias para compatibilidade com IDs antigos.

O `AudioManager` mantém pool máximo de oito SFX, dois players de música para crossfade e fallback de oscilador a 22,05 kHz. O APK nunca depende de streaming ou serviço externo.

Entregas finais de áudio:

- impacto de tatame, tecido, pegada, transição, respiração e tap;
- crowd por arena com três intensidades;
- loops de Terreiro, Dique, Mangue, Pratigi e grandes eventos;
- stings de vitória, derrota, alerta e Cria Live;
- mix validado em alto-falante de celular, fone barato e fone estéreo;
- legendas/indicadores para informação crítica que não pode existir só no som.

## 6. Arte, mapa e biomas

O contrato `data/production/biome_tileset_contract_v01.json` define:

- master 128×64 e runtime 64×32, projeção isométrica 2:1;
- PNG RGBA real, sem fundo branco/xadrez gravado;
- camadas separadas de solo, água, vegetação, props e oclusão;
- luz superior esquerda consistente;
- atlas máximo de 2 MB por lote Android;
- oceano/baía/estuário/mangue animados em baixa frequência.

As duas folhas fornecidas em 10/08/2026 foram inventariadas por SHA-256. São referências úteis de paleta/bioma, mas estão bloqueadas para shipping porque são JPEGs 1536×857 com extensão `.png`, sem alfa, dimensões misturadas e licença ainda não confirmada. A folha terrestre também contém xadrez e seta gravados.

### Mundo regional — fases

| Fase | Entrega | Gate |
|---|---|---|
| M1 | mapa de hubs e destinos de evento | existente |
| M2 | TileSet canônica + POIs e rotas clicáveis | contrato pronto, runtime pendente |
| M3 | token de Ruan e interpolação de viagem | pendente |
| M4 | relógio regional e maré única | pendente; não criar autoload duplicado |
| M5 | NPCs por rotina e clima | dados existentes; cena/runtime pendentes |
| M6 | Taipu/rotas afetadas por maré | pendente após M4 |

## 7. Pipeline biomecânico de duas pessoas

O arquivo `data/production/motion_source_registry_v01.json` bloqueia uso comercial indevido e mantém IA fora do runtime.

Decisões atuais:

- **preferido:** captura própria com autorização dos dois atletas;
- **permitido como ferramenta externa:** Pose2Sim (BSD-3-Clause);
- **permitido externamente com conformidade copyleft:** FreeMoCap (AGPL-3.0);
- **avaliação apenas:** `grappling-pose-identification` (MIT, prova acadêmica pequena);
- **bloqueado até direitos/consentimento:** `carlosj934/BJJ_Positions_Submissions`; a página oficial verificada em 10/08/2026 contém 1 amostra e 1 classe (`closed_guard1`), não uma biblioteca de técnicas;
- **condicional a revisão jurídica/versionamento:** NVIDIA GEM-X;
- **bloqueados para saída comercial:** SpinePose, KungFu-Fiesta, MotionMillion e AI4Animation nas licenças publicadas.

Keypoints são dados derivados, mas não funcionam como apagador jurídico: a cadeia de direitos do vídeo, a licença do dataset/modelo e o consentimento dos dois atletas continuam obrigatórios. Classificação automática é apenas um sinal de triagem; não atesta verdade biomecânica nem calibra sozinha timing, dano, buffs ou janelas de defesa.

Fluxo:

```text
vídeo próprio autorizado
→ ferramenta externa de pose/mocap
→ export neutro de dois corpos
→ build_motion_package.py
→ ângulos + confiança + sync roots
→ revisão humana de BJJ, tap e segurança
→ key poses / sprite sheet / manifest
→ import Godot e teste no aparelho
```

Exemplo de construção de um pacote de rascunho:

```bash
python tools/animation/build_motion_package.py \
  --input tests/fixtures/motion_capture/raw_baiana_sample.json \
  --technique baiana \
  --output /tmp/baiana_motion_package.json
```

Sem `--human-reviewed` e um revisor identificado, o pacote permanece `needs_human_review` e `shipping_ready=false`.

## 8. Arenas e regras

Cada arena precisa declarar identidade, regra, áudio, modificador e consequência. Arena clandestina não significa ausência de ética do produto:

- luta oficial: juiz, pontuação/regras e parada técnica;
- evento paralelo: mediador, tap obrigatório, exposição/heat e consequência;
- aposta: somente moeda interna já existente, sem compra com dinheiro real;
- técnica ilegal jamais vira incentivo gratuito; deve ser bloqueada ou cobrada por honra/carreira;
- heat máximo encerra o evento, sem evasão.

Entregas prioritárias de arte final: Terreiro e Arena do Dique primeiro; Pratigi é a terceira arena-alvo. Expandir para quinze arenas só depois de essas três passarem Android físico.

## 9. UI e controles

- viewport de referência: 1280×720;
- alvos touch mínimos: 48 px, preferencialmente 56–64 px em combate;
- mão do deck: três cartas sempre legíveis sem cobrir os corpos;
- cores nunca são o único indicador de custo, estado ou sucesso;
- foco de teclado/gamepad e atalhos 1/2/3 preservados;
- texto PT-BR, fonte escalável e contraste alto;
- opções de movimento reduzido, shake, háptico, áudio e legendas persistentes.

## 10. Definition of Done de shipping

Um lote só está pronto quando:

- `npm run quality` passa;
- import/parser Godot 4.2.2+ passa;
- smoke do fluxo alterado passa;
- save/load e migração passam;
- 60 FPS alvo e memória são medidos em Android de referência;
- toque, safe area, legibilidade e áudio são testados no aparelho;
- assets têm licença/proveniência;
- técnicas de dois corpos têm revisão humana;
- rollback está documentado;
- nenhuma tela depende de placeholder silenciosamente.

## 11. Ordem de produção

1. estabilizar PR #55 de Pratigi;
2. integrar esta fundação audiovisual ao combate/deck;
3. produzir Ruan + Davi e Terreiro + Dique finais;
4. fechar loop completo com save/carreira/Cria Live;
5. produzir TileSet e viagem regional;
6. implementar relógio/maré/NPCs sem managers duplicados;
7. expandir arenas e campanha por lotes verificáveis;
8. substituir cada fallback de áudio com asset licenciado;
9. fechar Android físico, acessibilidade, performance e release.

Essa ordem protege escopo e transforma “jogo completo” em uma sequência de entregas auditáveis, sem confundir especificação extensa com conteúdo realmente implementado.

## 12. SOP-IA alinhado à arquitetura real

O contrato `data/production/ai_production_sop_v01.json` formaliza a produção assistida por IA sem criar uma segunda memória ou uma segunda árvore de especificações. A sessão começa pelas autoridades existentes (`AGENTS.md`, `docs/INDEX.md`, decisões, roadmap e contratos executáveis), escolhe um lote vertical pequeno, integra um consumidor real e publica evidência em PR rascunho.

Correções vinculantes ao estudo de ferramentas:

- arte binária continua permitida e necessária; texto, prompt e quantização não substituem origem, licença, alfa, QA de pixel nem aprovação humana;
- 640×360 e 480×270 são grades candidatas de autoria, não autorização para trocar o viewport atual 1280×720 sem lote de aparelho;
- Pixelorama (MIT) e Penpot (MPL-2.0) são ferramentas externas aprovadas de autoria/design;
- Tiled pode ser avaliado somente com export determinístico; não se presume importação TMX nativa no Godot 4;
- a integração GDScript oficial de Yarn Spinner está em alpha e requer Godot 4.6+, portanto não substitui os diálogos JSON atuais;
- os workflows existentes já fixam Godot 4.2.2 e executam import/smokes/export candidato; um container adicional é opcional e jamais elimina o teste físico;
- LMMS, sfxr e compiladores de tema só entram após versão, licença, execução headless reproduzível e comparação de saída serem validadas em lote próprio.

A IA pode especificar, implementar, validar e preparar PR; não pode fazer merge autônomo, promover concept art para shipping, aprovar biomecânica, declarar release ou substituir a decisão humana/aparelho.
