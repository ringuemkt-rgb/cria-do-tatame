---
name: cria-art-direction
description: Direção de arte operacional de Cria do Tatame – Pressão. Use para gerar, editar, avaliar ou preparar qualquer asset visual do jogo. A skill aplica o cânone executável, o visual regional premium, o pipeline de assets e gates humanos/rights; nunca promove geração automaticamente.
version: 1.0.0
status: ACTIVE_AUTHORING_SKILL
---

# CRIA ART DIRECTION v1

## 0. Authority — ler antes de produzir

Esta skill é uma camada operacional de direção/QA. Ela **não** é segunda fonte de cânone, registry, runtime ou licença.

Ordem de autoridade:

1. `data/production/` — contratos executáveis e cânone mais recente;
2. `docs/DECISIONS.md` + cânone ativo;
3. dados/runtime realmente consumidos;
4. `data/visual/production_manifest_v02.json`, `data/visual/ui_theme_v2.json`, contratos do Asset Pipeline/Sprite Forge;
5. esta skill e suas referências;
6. concept art, prompts, mockups e imagens de sessão.

Regras invariáveis:

- Godot é o único runtime;
- asset gerado começa como candidato, com `shipping=false`;
- aprovação humana, direitos/proveniência, QA e integração real continuam obrigatórios;
- em conflito, a âncora visual só vence se também estiver aprovada pela hierarquia acima;
- nome canônico de ALE: **Os Aleluiado**; `Os Aleluiados` é forma superseded e não deve ser reintroduzida;
- ID/alias de facção nunca é renomeado por estética.

## 1. Identidade visual

**Nome operacional:** `HD Pixel Art 2.5D Regional Premium`.

O jogo deve parecer brasileiro, costeiro, regional e material — não fantasia genérica, anime genérico, render 3D ou vetor liso.

DNA recorrente:

- Baixo Sul da Bahia: rio, mangue, mar, cais, madeira, barro, telha, cacau, piaçava, feira, embarcação e vegetação tropical;
- preto/painel + dourado queimado + off-white + azul-rio + verde-mangue + terracota;
- contraste alto e silhueta legível em tela pequena;
- composição densa, mas hierarquia visual clara;
- mundo vivo: água, barcos, pássaros, bandeiras, folhagem, multidão, fogo, chuva e névoa como camadas animáveis;
- tese visual: força como cuidado e pertencimento, não violência glamorizada.

## 2. Paleta e tokens

Fonte executável de UI/facções: `data/visual/ui_theme_v2.json`.

### Base de autor

- `#0B0B0D` — painel/preto profundo;
- `#C9971C` — dourado/ornamento;
- `#EDE6D6` — off-white/gi/texto;
- `#1E3A5F` — azul-rio/sombra fria;
- `#2D5016` — verde-mangue;
- `#B85C38` — terracota;
- `#D4A574` — areia/madeira/tons claros;
- `#8B0000` — perigo/conflito;
- `#4B0082` — segredo/Avesso.

### Facções — tokens de gameplay

- ALE: `#FF9408`;
- LEM: `#4A6741`;
- NTM: `#3FE3F5`;
- LEI/institucional: `#1E3A5F`.

### Facções — variantes cerimoniais/mapa

Variantes de estandarte, brasão ou badge podem usar famílias auxiliares desde que o ID e o significado permaneçam inequívocos:

- ALE: azul-real + ouro + branco;
- LEM: roxo/vinho + ouro;
- NTM: vermelho/laranja + ouro, com azul secundário quando necessário.

Essas variantes **não substituem** os tokens de gameplay de `ui_theme_v2.json`.

### Orçamento de cor

Alvo autoral: sprite enxuto, cena controlada, sem arco-íris acidental. Limites quantitativos efetivos de promoção continuam pertencendo aos validadores do Asset Pipeline; não inventar aprovação apenas por contar cores.

## 3. Traço e raster

- pixel-art/pintura raster controlada; nunca vetor liso ou fotorealismo;
- frame normalizado de gameplay: `128x128` RGBA;
- pivô compartilhado: `[64,96]`;
- anchor: pés/linha de contato;
- nearest-neighbor e escala inteira no runtime;
- outline típico 1–2 px; a autoridade quantitativa final é o Asset Protocol;
- cel-shading/clusterização de pixels, sem blur;
- anti-aliasing manual apenas quando necessário; nunca filtro que destrua o pixel grid;
- FX desacoplado do corpo por padrão.

## 4. Personagens e identity lock

Proporção heroica e funcional: leitura atlética, mãos e base próprias para grappling, sem deformação anatômica gratuita.

Todo personagem deve possuir:

- rosto reconhecível e não reutilizado;
- cabelo/textura consistente;
- faixa/gi/rashguard coerentes com cena e ruleset;
- 1–2 âncoras de identidade versionadas;
- turnaround/pose aprovados antes de sheets densos;
- silhouette profile estável;
- mãos com anatomia plausível e cinco dedos;
- pés/joelhos/linha de contato coerentes com a ação.

### Ruan “Macacão” Silva

Âncoras obrigatórias quando aplicáveis:

- protagonista `ruan_macacao`;
- símbolo Silverback;
- top game/pressão/grip de ferro;
- GI branco/off-white ou configuração consumida pelo dado da cena;
- identidade forte e respeitosa, nunca caricatura.

### Davi Relâmpago

- rival técnico do vertical slice;
- silhueta mais ágil/leve que Ruan;
- leitura de reação, scramble e counters;
- identidade própria, nunca “Ruan mais magro”.

## 5. GI / NO-GI

GI e NO-GI são contratos de gameplay e animação, não simples recoloração.

GI:

- kimono e faixa coerentes com dado/cena;
- grips em gola/manga devem ter contato legível;
- tecido e dobras respeitam puxada/pressão.

NO-GI:

- rashguard/short sem marcas reais;
- cores e patches fictícios coerentes;
- grips não podem depender visualmente de lapela/manga inexistentes.

Nunca usar GI em técnica/cena declarada somente NO-GI ou vice-versa.

## 6. Linguagem das facções

### ALE — Os Aleluiado

Tema: ordem, fé, proteção, circuito e disciplina.
Símbolos fictícios permitidos: pomba, halo/auréola, cruz genérica, louros, estrelas.
Evitar símbolos/logos de igreja real.

### LEM — Lá Ele Mil Vezes

Tema: mangue, maré, memória, segredo, travessia.
Símbolos: olho, raízes, lua, água, névoa violeta.

### NTM — Nós Tem Um Molho

Tema: rua, comércio, hype, festa, oportunidade e risco.
Símbolos: pimenta/chama, pilão, palco, bandeirolas, estrelas.

### LEI

Institucional/ficcional: postura rígida, azul-marinho, documentos e sinalização fictícia. Nunca copiar brasão, uniforme, distintivo ou logotipo real.

## 7. Arenas

Arena é cenário jogável, não pôster.

Obrigatório:

- play area/tatame livre e legível;
- fundo em camadas separáveis;
- profundidade 2.5D por parallax/oclusão, não câmera 3D genérica;
- props de foreground sem bloquear ações críticas;
- NPCs nas bordas;
- clima/luz definidos por preset;
- collision/occlusion/camera bounds tratados fora do bitmap final;
- mundo vivo implicado em arte e animado em engine.

Para P1, `arena_do_dique` e `terreiro_da_luta` têm prioridade absoluta.

## 8. Mapas

Direção aprovada das referências de mapa:

- composição panorâmica densa, ilustrada, com leitura de RPG regional;
- hub dominante e municípios/POIs organizados por rotas;
- água com espuma/reflexo, cais, barcos, pontes, mangue, serras e cachoeiras;
- rotas terrestres claras, rotas marítimas ciano e bloqueios vermelhos com X;
- segredo por violeta/névoa/olho;
- badges circulares e locks dourados;
- placas e frases regionais como camada narrativa.

### Separação obrigatória de layers

A pintura-base não deve queimar estado mutável de gameplay.

1. `map_base_art`: terreno, água, vegetação, cidades, landmarks;
2. `world_overlay`: nodes, rotas, locks, facção, segredo, recursos/coletáveis;
3. `ui_overlay`: legenda, topbar, região, HUD, prompts;
4. `narrative_overlay`: frases/placas/eventos quando apropriado.

Texto, lock, facção e objetivo devem preferencialmente ser UI/overlay Godot, não texto irreversível no bitmap.

`Costa das Marés` permanece expansão/candidato enquanto não houver promoção canônica explícita.

## 9. Recursos e coletáveis no mapa

Overlay opcional pode representar recursos e coletáveis derivados de dados:

- cacau;
- piaçava;
- pesca/mariscos;
- plantas medicinais;
- fragmento de memória;
- dossiê de evidência;
- esconderijo CriaCoin.

Nenhum recurso/coletável concede existência canônica apenas por aparecer em concept art. A fonte de gameplay precisa estar em `data/` e ter consumidor.

## 10. UI

- fundo/painel `#0B0B0D`;
- borda/ornamento `#C9971C`;
- texto principal `#EDE6D6`;
- mobile-first, safe area e contraste alto;
- cantos trabalhados/ornamentais sem comprometer hit target;
- ícones legíveis a 24 px, base 48 px quando possível;
- status mutável nunca rasterizado em fundo permanente;
- map, combat HUD e submission HUD devem priorizar jogabilidade, não decoração.

## 11. Cartas

Card de técnica deve ter estrutura consistente, mas os stats sempre vêm do dado de gameplay.

Zonas recomendadas:

1. header/identidade;
2. badge de tipo;
3. raridade;
4. título;
5. posição/alvo/modalidade;
6. arte técnica pareada;
7. descrição;
8. stats;
9. footer/citação.

Não inventar `power`, stamina, legalidade, pontos ou raridade quando o dado não existir.

## 12. Ícones

- master 48 px quando aplicável;
- legível a 24 px;
- silhueta reconhecível;
- uma cor-base + acento quando suficiente;
- outline consistente;
- transparência limpa;
- sem marca real.

## 13. Tipografia

- títulos: brush/marcador/condensada forte, compatível com a marca;
- corpo: sans condensada legível;
- citação: tratamento secundário claro;
- não versionar fonte proprietária sem licença;
- texto final de UI deve ser renderizado pelo engine sempre que possível.

## 14. Luz e clima

Presets de direção:

- `golden_hour`: luz quente rasante + preenchimento frio;
- `day`: leitura clara, sombra curta;
- `night`: base azul profunda + pontos quentes;
- `rain`: frio, reflexos, névoa/partículas.

Uma fonte dominante por cena; não misturar três atmosferas concorrentes.

## 15. Motion / mundo vivo

Toda cena/mapa deve declarar ao menos uma camada animável quando o contexto permitir:

- água;
- barcos;
- pássaros/garças;
- bandeiras/fitas;
- multidão idle;
- fogueira/luzes;
- folhagem;
- chuva/névoa.

Arte estática deve sugerir movimento sem baking de blur.

## 16. COMMAND protocol

Formato obrigatório de authoring:

```text
#CMD <id> | <categoria> | lote <N>/<TOTAL>
STYLE: cria-art-direction@1.0.0
AUTH: <fontes de dado/cânone>
SPEC: <contrato visual e variáveis>
MOTION: <camadas vivas ou n/a>
MOBILE: <restrições de leitura/touch/safe area>
QA: <gates aplicáveis>
OUT: <caminho candidato> + metadata/sidecar · shipping=false
```

O `AUTH` é obrigatório para impedir que um prompt vire fonte de verdade.

## 17. Templates

### CHAR_TURNAROUND

`Turnaround de {character_id}, frente/3-4/costas, identidade derivada do canon spec, vestimenta {gi_or_nogi}, anchors {anchors}, fundo técnico neutro, pixel art HD 2.5D regional premium, pés/linha de contato consistentes.`

### CHAR_COMBAT_POSE

`Pose lateral de combate de {character_id}, modalidade {gi_or_nogi}, stance {style}, identity lock ativo, frame/readability compatível com 128x128, fundo transparente/candidato.`

### ACTION_SHEET

`Sheet da família {action_family} para {character_id}, frame 128x128, pivot (64,96), feet anchor, identidade travada, corpo separado de FX, ações derivadas do production manifest.`

### PAIRED_TECHNIQUE

`Técnica pareada {technique_id}: attacker {attacker_id} × defender {defender_id}, entry {from}, exit {to}, fases anticipation/entry/establish/stabilize/response/recovery, pivô compartilhado, contato biomecanicamente plausível, sync_map obrigatório, sem striking genérico.`

### ARENA_LAYER

`Camada {layer} de {arena_id}, bioma/local canônico, luz {lighting}, playfield protegido, paralaxe/oclusão prevista, mundo vivo {motion_layers}, sem HUD baked.`

### MAP_PAGE

`Mapa regional {region_id}: base art separada de world/ui/narrative overlays, hubs/nodes derivados de data, rotas terrestres/marítimas/bloqueadas, segredo violeta, densidade regional alta, nenhuma geografia inventada como canon.`

### CARD

`Carta de {technique_id}; identidade/raridade/stats estritamente derivados dos dados; arte central pareada; UI preta/dourada/off-white; nenhuma regra ou número inventado.`

## 18. QA gates

Antes de promover qualquer candidato:

- canon/ID/name match;
- provenance/license/rights;
- human visual approval;
- cultural review quando aplicável;
- identity lock;
- GI/NO-GI e biomecânica;
- escala/pivô/anchor;
- alpha/edge/empty-frame;
- paired sync para técnica;
- legibilidade mobile;
- UI/safe area quando aplicável;
- integração em cena real;
- `shipping=false` até todos os gates de release aplicáveis passarem.

Consultar `references/qa.md` e os validadores existentes para thresholds numéricos.

## 19. Stop conditions

Pare e marque `REVIEW_REQUIRED` quando houver:

- conflito com contrato executável;
- nome/ID divergente;
- referência visual sem proveniência ou sem caminho no repo;
- personagem/patch/facção inconsistente;
- anatomia/biomecânica duvidosa;
- marca/pessoa/IP de terceiro;
- mapa inventando geografia como fato;
- texto incorreto baked em imagem;
- tentativa de promover concept/generated output diretamente para shipping;
- falta de aprovação humana.

## 20. Âncoras e precedência

Leia `references/anchors.md` antes de produzir. Uma imagem só é âncora de produção quando existe referência rastreável e status aprovado no repositório. Imagens da conversa podem orientar concept/authoring, mas não recebem automaticamente status de shipping.

## 21. Validação da skill

```bash
python .agents/skills/cria-art-direction/scripts/validate_skill.py
npm run validate:art-direction
npm run test:art-direction
npm run quality
```

A skill deve falhar se reintroduzir nomes superseded, perder as autoridades, permitir `shipping=true` automático ou divergir dos tokens essenciais atuais.
