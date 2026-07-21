# Marco v10 — visual, áudio, mundo e combate

Data: 20/07/2026
Estado: vertical slice integrado e aprovado no Godot 4.2.2; exportação Android aprovada em CI e homologação em aparelho físico pendente.

## Resultado entregue

O primeiro recorte audiovisual coerente foi fechado em torno do fluxo canônico **Menu → Terreiro da Luta → Arena do Dique → Ruan x Davi → Resultado**. Os novos arquivos complementam a base existente e preservam os placeholders anteriores como fallback até a homologação no motor.

Painel de revisão: `assets/graphics/review/world_combat_milestone_v10.jpg`.

### Personagens

- 8 model sheets canônicos.
- 8 retratos de diálogo.
- 8 pacotes de idle animado.
- 50 poses-chave de ação.
- 7 pacotes prioritários de ação, somando 34 quadros.
- 7 quadros de animatic pareado para grappling.
- Ruan e Davi usam primeiro a arte candidata em combate; se um manifesto ou atlas falhar, o runtime volta ao pacote placeholder existente.
- Dendê e Tinker aparecem animados no Terreiro. Davi, Cássio e Leoa podem aparecer como representantes animados de seus hubs.

### Mundo e arenas

- Arena do Dique: cenário 1920×1080, iluminação dinâmica, oclusão, colisão, perfil de ambiência, preview, hashes e documentação de fonte.
- Terreiro da Luta: cenário 1920×1080 com tatame navegável, rio/mangue, área de NPCs, mapa de colisão e âncoras de interação.
- Mapa do Baixo Sul: placa 1920×1080, quatro hubs canônicos, rotas normalizadas, custos e horas de viagem, destaque do hub atual e composição responsiva ao recorte de tela.
- Modelo de mundo preservado: **semiaberto com hubs densos**, não uma malha aberta vazia.

O pedido informal por “arenas do Rubi” não corresponde a nenhum ID canônico encontrado. A implementação tratou a expressão como referência às arenas de Ruan e priorizou `arena_do_dique`, sem inventar uma arena nova.

### NPCs

- Painel de presença por território conectado à API pública `WorldDirectorManager.get_npc_state()`.
- Estado disponível/ocupado, atividade atual, retrato e atualização por avanço de dia/clima.
- Alias controlado para Cássio evita duplicar personagem por divergência histórica de ID.
- Representante animado nos hubs regionais e Dendê/Tinker no Terreiro.

### Combate e game feel

- O combate da cena principal agora inicia com `arena_do_dique`; foi corrigida a divergência anterior que mostrava o Dique mas registrava `terreiro_da_luta` no motor.
- VFX de pulso com orçamento máximo de 12 instâncias para grip, queda, raspagem, defesa, controle, finalização e bloqueio.
- VFX e áudio próprios para os quatro resultados do Deck Clash: domínio, vantagem, disputa e contra-janela.
- Hit-stop com proteção contra chamadas concorrentes e shake determinístico do canvas quando não existe `Camera2D`.
- Davi possui o pacote candidato de sprawl/defesa; demais ações permanecem com fallback até terem animação aprovada.

### Áudio

Foram produzidos 28 eventos originais por síntese determinística, sem samples externos:

| Categoria | Eventos |
|---|---:|
| Combate e Deck Clash | 16 |
| Interface | 4 |
| Torcida | 2 |
| Ambiências | 5 |
| Música | 1 |

Cada evento possui WAV fonte, OGG Vorbis de runtime, metadados, relatório de nível, licença e SHA-256. Todos estão em 48 kHz estéreo. Loops recebem crossfade de emenda e validação contra estalo. O serial OGG é fixado por evento e o CRC é recalculado, garantindo exportação reprodutível byte a byte. O `AudioManager` usa pool de 24 vozes para SFX e players separados de música/ambiência.

Duas falas foram geradas apenas como **candidatos de casting** para Dendê e Davi. Elas não entram no runtime antes de exportação, revisão de licença, direção vocal e aprovação humana; os registros estão em `data/audio/voice_casting_candidates_v01.json`.

## Validação executada

- `npm run quality`: aprovado.
- 31 pacotes do catálogo de animação: aprovados.
- Validador de arte de personagens: 8 personagens, 50 poses, 7 ações prioritárias, sem erros.
- Validador de mundo: Arena do Dique, Terreiro e mapa aprovados; gates de candidato preservados.
- Validador de áudio: 28 eventos, hashes, formato, pico, duração, loop e licença aprovados.
- Lore Guardian: 7 testes aprovados.
- Auditor especializado `audit_cria_spec.py`: 0 erros de cânone.
- Godot 4.2.2: importação integral aprovada, sem erro de parser/recurso.
- Runtime smoke: 137/137 verificações aprovadas e nenhum erro oculto no log.
- Faction Director smoke: 26/26 verificações aprovadas.
- Full Game smoke: 146 verificações e 14 cenas carregadas.
- Android CI: APK debug exportado, assinado e validado estruturalmente.
- Pacote Android: `com.criadotatame.pressao`, versão `1.0.0`, minSdk 21 e targetSdk 34.
- APK: 193.868.415 bytes; SHA-256 `600712231371372de92236b0b9f128736a2fb32827e4156dc786de7d9d9e69c2`.
- GitHub Actions: Validate Cria Data, Repository Quality, Cria Runtime Audit e Full Game Hardening aprovados no commit `ed1582f`.

## Limites honestos deste marco

Existe um APK debug produzido pelo CI e validado quanto a assinatura, integridade ZIP, biblioteca ARM64 e manifesto. Esse artefato ainda não é um build homologado: faltam instalação em aparelho físico, medição de FPS/memória, teste tátil, escuta crítica e aprovação humana.

O contrato supremo também continua aberto:

| Frente | Atual verificável | Meta | Falta |
|---|---:|---:|---:|
| Personagens com conjunto visual | 8 | 18 | 10 |
| Arenas com cenário premium | 1 | 15 | 14 |
| Fluxos animados pareados | 7 | 50 | 43 |
| SFX | 22 | 100 | 78 |
| Música | 1 | 20 | 19 |
| Ambiências | 5 | 12 | 7 |

Esses números impedem uma declaração indevida de “jogo completo”. O marco v10 é a primeira fatia audiovisual integrada, auditável e pronta para passar pelos gates do motor.

## Próximo gate objetivo

1. Capturar vídeo real do fluxo Menu → Terreiro → Dique → Resultado usando a importação já aprovada.
2. Instalar o APK validado pelo CI em Android de referência, com meta de 60 FPS, orçamento de memória e simultaneidade de áudio.
3. Realizar escuta crítica, direção vocal e revisão humana de arte em dispositivo.
4. Depois da homologação do P1, produzir os próximos pares completos: Leoa, Kenzo, Oni e Cássio; em seguida expandir os ambientes dos três hubs regionais.
