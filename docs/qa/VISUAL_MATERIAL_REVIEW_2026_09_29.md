# Revisão do Material Visual — sessão 2026-09-29

**Status:** ACTIVE AUDIT / REFERENCE INTAKE  
**Issue:** #103  
**Related PRs:** #144, #147  
**Runtime:** unchanged  
**Shipping:** false

## Escopo

Esta revisão consolida o material visual construído e apresentado na sessão de produção de 2026-09-29 sem transformar concept art em runtime.

Inventário preservado no arquivo privado de produção:

- **43 assets construídos únicos**;
- **2 fotos reais de referência excluídas** do pack de arte do jogo;
- **1 duplicata exata removida**;
- arquivo privado: `cria_visual_master_pack_2026-09-29.zip`;
- SHA-256 do arquivo: `2de0f1cd6b5ea2756a57b4a561d185e98df62b500b6373d284938edad3431e05`.

O repositório público recebe somente este catálogo/auditoria. Nenhum PNG/JPEG da sessão é promovido por esta mudança.

## Veredito geral

O conjunto estabelece uma direção visual forte e relativamente coerente com o contrato atual:

- preto profundo + dourado queimado;
- pixel-art ilustrativo 2.5D de alto contraste;
- densidade regional do Baixo Sul;
- água, mangue, barcos, igreja, cais, estrada, cacau e piaçava;
- iconografia de facção memorável;
- mapas com boa legibilidade de rotas, locks e áreas secretas;
- cards de técnica com hierarquia visual clara.

O material, porém, continua predominantemente **reference/candidate art**. Ele não satisfaz automaticamente os contratos de runtime, Sprite Forge, rights, cards ou mapas data-driven.

## 1. Mapas — 19 imagens

### Core atlas

Foram preservadas referências para as dez páginas:

1. Baixo Sul overview;
2. Ituberá;
3. Nilo Peçanha;
4. Valença;
5. Camamu;
6. Cairu;
7. Itacaré & Maraú;
8. Interior Norte;
9. Interior Sul;
10. Salvador.

### Overlays

Cinco referências mostram recursos/coletáveis/facções. A ideia de exploração é forte, especialmente quando recursos regionais, fragmentos e dossiês passam a ter função econômica/narrativa.

### Expansão

Quatro imagens de **Costa das Marés** foram preservadas como `EXPANSION_REFERENCE_ONLY`. Elas não alteram as dez páginas core e não entram no cânone sem promoção explícita.

### Blocker de runtime

As imagens estão achatadas com elementos mutáveis baked-in: labels, rotas, cadeados, badges, coletáveis, estados e HUD. O runtime deve separar:

`base art -> routes -> nodes -> labels -> locks -> collectables -> faction overlay -> weather/tide`.

**Decisão:** os mapas são style anchors. O Godot deve reconstruir o mapa a partir de dados e layers, não usar a tela composta como texture final.

## 2. Facções — 6 estandartes

### LEM

Olho/raízes + roxo/vinho funciona bem como linguagem cerimonial.

### NTM

Pimenta/molho/fogo tem excelente reconhecimento e contraste.

### ALE

A estética azul/dourado/branco é forte, mas as duas imagens usam **“OS ALELUIADOS”**. O contrato canônico ativo exige **“Os Aleluiado”**.

**Decisão:**

- LEM/NTM: `STYLE_ANCHOR_REFERENCE`;
- ALE: `REFERENCE_REJECTED_CANON_TEXT` até regenerar texto ou remover texto baked.

## 3. Ruan e Davi

### Ruan

`ruan_turnaround_v2_beard_pixel` é o candidato de identidade mais forte desta sessão.

Próximos gates:

1. human identity review;
2. definição explícita de face/hair/body anchors;
3. views coerentes;
4. extração/normalização de frames;
5. 128×128 quando virar gameplay sprite;
6. pivô [64,96];
7. nearest-neighbor;
8. Sprite Forge QA;
9. rights/provenance;
10. Godot integration.

`ruan_combat_pose_alt_hair_v1` foi rejeitado como identity drift.

### Davi

`davi_identity_action_sheet_v1` é o candidato preferido para identity master, mas continua aguardando human review e normalização.

## 4. Adriano “Degodo”

Cinco peças derivadas de referência real foram preservadas somente no **arquivo privado**.

O roster atual declara `fictional_archetypes_only=true` e `no_real_person_likeness=true`. Logo:

- não publicar os binários no repositório público;
- não registrar como runtime asset;
- não integrar ao jogo;
- manter apenas como referência privada enquanto não houver mudança canônica + autorização explícita de likeness/rights.

As duas fotos reais originais foram excluídas do master pack de arte.

## 5. Cards de golpes — 5

Preservados:

- Tesoura;
- Joelho na Barriga;
- Mata-leão;
- Chave de Braço;
- Kimura.

### Pontos fortes

- shell visual forte da marca;
- boa leitura de tipo/posição/alvo;
- sequência 1–4 legível;
- composição central dramática;
- raridade e stats visualmente fáceis de ler.

### Blockers

- raster atual ~1044×1507, diferente do target 1080×1560;
- texto e stats estão baked;
- stamina/dificuldade/poder/raridade não têm autoridade enquanto a fonte de cards completa estiver ausente;
- apenas **Chave de Braço** possui correspondência direta com o fixture atual: `t057 Chave de Braço (Mount)`;
- Tesoura, Joelho na Barriga, Mata-leão e Kimura permanecem sem ID autoritativo no graph atualmente disponível;
- sequência biomecânica precisa de revisão técnica antes de uso instrucional ou animação.

**Decisão:** usar como `CARD_LAYOUT_REFERENCE_CANDIDATE`; preferir separar central art do shell e deixar Godot renderizar nome, regras, stats e localização.

## 6. Candidatos prioritários para o sistema

### P1

1. `ruan_turnaround_v2_beard_pixel`;
2. `davi_identity_action_sheet_v1`;
3. `map_core_02_itubera` como **style anchor** para reconstrução sem HUD baked;
4. LEM/NTM como referência de emblema/cerimonial;
5. ALE regenerado com **Os Aleluiado**.

### Técnica/card

`card_chave_de_braco_t057_v1` é o único card desta leva com ligação direta a uma técnica presente no fixture BJJ atual. Isso não o torna runtime-ready: ainda faltam cards authority, revisão biomecânica e separação de UI/data.

## 7. Não promover agora

- Costa das Marés;
- os cinco assets de likeness de Adriano;
- roster concept board;
- Irmão Caleb;
- Ruan alternate hair;
- valores/raridade baked dos cinco cards;
- qualquer mapa achatado como texture final.

## 8. Regra de promoção

A cadeia permanece:

`reference/candidate -> provenance/rights -> technical QA -> human approval -> normalization -> Godot integration -> runtime evidence -> coverage -> shipping`.

Esta auditoria **não** altera `assets/manifest_v2.json` e não cria coverage falso.

## 9. Handoff para PRs visuais existentes

- **#147** continua sendo a fila de fabricação P1;
- **#144** continua sendo o execution board de fight graphics;
- este intake serve apenas para indicar quais referências da sessão são preferidas ou bloqueadas;
- nenhuma referência da sessão substitui os contratos executáveis dos dois PRs.

A fonte machine-readable desta revisão é:

`data/visual/session_visual_intake_2026_09_29.json`.
