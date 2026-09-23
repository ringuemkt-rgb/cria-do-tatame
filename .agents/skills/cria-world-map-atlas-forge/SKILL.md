---
name: cria-world-map-atlas-forge
description: Skill especializada para criar, editar, revisar e integrar mapas regionais, hubs e overlays do CRIA DO TATAME seguindo o padrão visual consolidado dos mapas 01–10. Subordinada ao cria-art-direction e aos dados canônicos; nunca transforma concept art em verdade de gameplay.
version: 1.0.0
status: ACTIVE_AUTHORING_SKILL
parent_skill: cria-art-direction
---

# CRIA WORLD MAP ATLAS FORGE v1

## 0. Propósito

Esta skill domina a produção visual do mapa-mundo de **CRIA DO TATAME – Pressão**: páginas regionais, hubs, rotas, nós, facções, locks, segredos, recursos, coletáveis, placas narrativas, HUD, legendas, efeitos ambientais e handoff para Godot.

Ela existe para preservar o padrão dos mapas aprovados de **Baixo Sul, Ituberá, Nilo Peçanha, Valença, Camamu, Cairu, Itacaré & Maraú, Interior Norte, Interior Sul e Salvador**, eliminando drift de estilo, infográficos acidentais, estados baked e inconsistência de UI.

### Regra-mãe

> O mapa deve parecer uma ilustração regional viva, rica e memorável; o gameplay deve continuar data-driven, mutável e auditável.

Logo:

```text
MAP ART != WORLD STATE
MAP ART + WORLD OVERLAY + UI + NARRATIVE OVERLAY = MAP SCREEN
```

Nunca queimar no bitmap-base um estado que o jogo precise mudar em runtime.

---

## 1. Hierarquia de autoridade

Antes de produzir qualquer peça, aplicar a seguinte ordem:

1. `data/production/canon_contract_v4_1.json` e build contract ativo;
2. mapa semântico realmente consumido em `data/world/`;
3. decisões registradas em `docs/DECISIONS.md` e dados de narrativa/progressão;
4. `data/visual/ui_theme_v2.json` e contratos de Asset Pipeline;
5. `cria-art-direction`;
6. esta skill;
7. imagens de referência, concepts, mockups e prompts.

Se uma imagem contradiz o dado, o dado vence.

Se o mapa novo ainda não foi integrado ao runtime, tratá-lo como **target_semantic_snapshot**, nunca fingir que já é shipping.

### Estado atual que esta skill deve conhecer

- `main` ainda consome o mapa runtime de 10 páginas / 40 nós;
- o mapa expandido definido posteriormente contém 11 páginas e precisa de migração/normalização;
- `Costa das Marés` é expansão/NG+ e deve permanecer `candidate` até promoção explícita;
- LEI é controlador institucional, não quarta facção cultural equivalente a ALE/LEM/NTM;
- `ROTA 101` é terrestre; rota marítima não pode dispará-la.

---

## 2. Assinatura visual consolidada

**Nome do estilo:** `Regional Illustrated Atlas / HD Pixel Art 2.5D Premium`.

O padrão aprovado combina:

- panorama cartográfico oblíquo em 3/4;
- densidade alta de microdetalhes;
- leitura de RPG regional;
- pintura raster com bordas/clusterização inspiradas em pixel art;
- água extremamente viva e saturada;
- vegetação tropical abundante;
- arquitetura e infraestrutura local reconhecíveis;
- UI preta/dourada/off-white de alto contraste;
- badges circulares grandes para POIs;
- rotas pontilhadas/dash visualmente distintas;
- áreas secretas violeta com névoa e olho;
- placas físicas e frases de identidade regional;
- mapa vivo, mas com hierarquia visual rígida.

### Não é

- mapa GIS;
- satélite;
- vetor flat;
- cartoon infantil;
- anime;
- render 3D genérico;
- matte painting fotorealista;
- collage/infográfico de múltiplos painéis;
- mapa medieval genérico.

---

## 3. Canvas e composição de referência

As 10 referências consolidadas usam **1536×864, 16:9**. Este é o grid visual de referência.

### Zonas principais

Em 1536×864:

- `TOP_NAV`: y ≈ 0–70 px (~8% da altura);
- `MAP_VIEWPORT`: y ≈ 70–790 px;
- `BOTTOM_CONTROL_STRIP`: y ≈ 790–864 px;
- `LEGEND_SAFE`: x ≈ 12–180 px, y ≈ 75–330 px;
- `PLAYER_HUD_SAFE`: x ≈ 12–300 px, y ≈ 735–850 px;
- `REGION_PLATE_SAFE`: x ≈ 1150–1530 px, y ≈ 705–855 px.

Essas zonas são referência de composição, não pixels hardcoded de runtime.

### Centro protegido

Manter o miolo do viewport livre de painéis grandes. O mapa deve poder mostrar:

- hub principal;
- ao menos 2–4 rotas simultâneas;
- 3–7 POIs;
- leitura de costa/rios/estradas;
- profundidade do ambiente.

A UI periférica nunca pode esmagar o território.

---

## 4. Câmera cartográfica e profundidade 2.5D

Usar câmera ilustrada oblíqua de aproximadamente **30–45° acima do horizonte**, sem perspectiva aérea extrema.

A cena deve ter leitura em camadas:

```text
L0 sky / distant sea / far mountains
L1 major terrain masses
L2 rivers / coast / roads / beaches
L3 towns / villages / bridges / ports
L4 landmarks / POI architecture
L5 vegetation / props / boats / crowds
L6 ambient FX
L7 gameplay overlays
L8 UI
```

### Regra de escala

POIs relevantes podem receber **exagero cartográfico controlado**. Igreja, porto, arena, cachoeira ou dojo podem ser 1.2–2× maiores que a escala natural para leitura.

Nunca exagerar tudo ao mesmo tempo.

---

## 5. Densidade e ritmo visual

A densidade aprovada é alta, mas organizada.

### Macro

Cada página precisa possuir:

- 1 landmark dominante;
- 2–4 landmarks secundários;
- 1 eixo visual de circulação;
- 1 assinatura natural forte;
- 1 assinatura humana/cultural forte.

### Micro

Usar pequenos elementos para dar vida:

- barcos;
- caminhões/ônibus;
- pessoas;
- feiras;
- caixas;
- tendas;
- mastros;
- pássaros;
- coqueiros;
- placas;
- trapiches;
- cacau/piaçava;
- água correndo;
- bandeiras;
- iluminação local.

Evitar ruído aleatório. Todo microelemento deve reforçar região, função ou atmosfera.

---

## 6. Paleta estrutural

A UI segue `ui_theme_v2.json`:

- painel/preto: `#0B0B0D`;
- dourado/borda: `#C9971C`;
- texto/off-white: `#EDE6D6`.

### Mapa base

Famílias preferidas:

- água profunda: azul-marinho/azul petróleo;
- água rasa: ciano/turquesa vivo;
- mata: verdes médios/profundos;
- mangue: verde oliva + sombras azuladas;
- barro/estrada: ocres/terracotas;
- telhados: terracota/laranja queimado;
- arquitetura histórica: off-white/amarelo suave;
- madeira: castanho quente;
- pôr do sol: âmbar, rosa, púrpura controlados.

### Gameplay semântico

- rota terrestre: off-white/creme;
- rota marítima: ciano;
- rota bloqueada: vermelho;
- segredo/Avesso: violeta/magenta profundo;
- lock: dourado;
- player/current position: verde vivo;
- concluído: check verde ou tratamento definido pelos dados.

### Facções cerimoniais

- ALE: azul-real + branco + ouro;
- LEM: roxo/vinho + ouro;
- NTM: vermelho/laranja + ouro;
- LEI: navy + ouro/off-white institucional.

Não substituir os tokens de gameplay por essas variantes cerimoniais.

---

## 7. Linguagem dos nodes

Node aprovado = **badge circular + imagem/emblema + anel semântico + label escuro**.

### Estrutura

1. círculo principal;
2. conteúdo visual;
3. anel de estado/facção;
4. lock/check quando necessário;
5. painel de nome;
6. subtítulo curto;
7. ato/requisito quando necessário.

### Tamanhos de referência no composite 1536×864

- badge major: ~70–110 px;
- badge minor: ~48–80 px;
- label: 120–260 px de largura;
- lock: 20–36 px.

### Hierarquia

- hub/região: maior;
- arena/porto/dojo: médio;
- POI secundário: menor;
- segredo: forte contraste violeta, mas não maior que o hub.

### Conteúdo

Badge pode usar:

- miniatura do landmark;
- emblema de facção;
- pictograma de função;
- arte ambiental simplificada.

Não misturar 3 linguagens dentro da mesma página sem motivo.

---

## 8. Estados visuais padronizados

Estados do node devem ser derivados de dados.

### `current`

- ring verde;
- pulso sutil;
- opcional pequena seta/halo.

### `available`

- anel dourado/off-white;
- sem lock.

### `blocked`

- cadeado dourado;
- redução leve de saturação no label;
- requisito curto no painel;
- rota associada pode ficar vermelha/segmentada.

### `secret_known`

- badge violeta;
- olho/ícone secreto;
- névoa local;
- nome pode ser parcial conforme dado.

### `secret_unknown`

- não mostrar nome verdadeiro;
- usar `???` ou label definido pelo runtime;
- presença deve depender de descoberta.

### `completed`

- check ou halo definido por UI;
- não alterar a pintura-base.

---

## 9. Rotas

Rotas precisam ser lidas sem olhar a legenda.

### Terrestre

- branco/off-white;
- dashed curto;
- segue estradas/vales/terreno plausível;
- largura uniforme.

### Marítima

- ciano;
- dashed mais fluido;
- curva suave em baías/canais;
- não atravessar ilhas absurdamente.

### Bloqueada

- vermelho;
- dashed forte;
- X em pontos-chave;
- nunca usar só cor: X/padrão é obrigatório para acessibilidade.

### Secreta

- normalmente não aparece antes da descoberta;
- após descoberta pode usar violeta, linha descontínua e baixa opacidade.

### Ponte

Tratar semanticamente como `terrestrial + subtype bridge` quando esta for a normalização ativa.

### Conexão

Usar linguagem neutra de transição quando não for uma rota navegável tradicional.

---

## 10. Território de facção

Não pintar regiões como grandes blocos chapados.

Território deve ser sugerido por:

- badges;
- banners;
- cores locais;
- arquitetura/props;
- iluminação;
- sinalização;
- eventos;
- névoa/FX;
- iconografia.

O terreno continua reconhecível.

### ALE

Disciplina, circuito, ordem, proteção; azul/white/gold; pomba/halo/cruz genérica fictícia.

### LEM

Mistério, mangue, maré, memória; purple/gold; olho, névoa, raiz, lua.

### NTM

Comércio, rua, palco, hype, risco; red/orange/gold; pimenta/chama, bandeirolas.

### LEI

Institucional, navy/off-white/gold; documentos, checkpoints, prédios, veículos fictícios. Nunca brasão real.

---

## 11. Áreas secretas

O padrão aprovado é muito forte e deve ser preservado.

Uma área secreta usa:

- purple fog;
- queda de luminância;
- luz magenta seletiva;
- node olho/???;
- rotas quebradas/bloqueadas próximas;
- arquitetura parcialmente oculta;
- bordas naturais ou rochosas.

### Regra

Segredo deve parecer **presença**, não neon sci-fi.

Não inundar metade do mapa de roxo.

---

## 12. Água, costa e rios

Água é assinatura central do atlas.

Obrigatório quando aplicável:

- pelo menos 3 tons de profundidade;
- espuma em costa/rocha;
- reflexos/linhas de fluxo;
- barcos em escalas distintas;
- píeres/trapiches;
- canais navegáveis claros;
- borda entre mangue e água legível.

### Animação prevista

Separar/mascarar quando possível:

- espuma;
- ripple;
- corrente;
- ondas;
- barcos;
- reflexo;
- waterfall.

---

## 13. Vegetação e biomas

A vegetação deve contar onde estamos.

### Costa/ilhas

- coqueiros;
- restinga;
- vegetação baixa;
- rocha escura;
- areia clara.

### Mangue

- raízes expostas;
- copas densas;
- canais sinuosos;
- madeira/trapiche;
- aves brancas.

### Cacau/interior

- cacauais;
- mata úmida;
- estradas estreitas;
- morros;
- galpões/fazendas.

### Serra/cachoeira

- paredões;
- mata fechada;
- névoa;
- rios frios;
- pontes/trilhas.

Não usar vegetação tropical genérica idêntica em todas as páginas.

---

## 14. Arquitetura e infraestrutura

Misturar com coerência regional:

- igreja/casario histórico;
- casas simples;
- mercados;
- cais;
- trapiches;
- galpões;
- postos;
- pontes;
- estradas;
- arenas;
- ginásios;
- prédios institucionais fictícios;
- estruturas de turismo/litoral.

### Landmark rule

O landmark que dá nome/função ao node precisa ser identificável sem label quando ampliado.

---

## 15. Placas, frases e narrativa ambiental

As referências usam placas físicas e frases manuscritas para reforçar identidade.

Exemplos de função:

- ethos local;
- provérbio;
- advertência;
- cultura/trabalho;
- comentário do território.

### O que pode ser baked

Somente texto imutável de ambientação aprovado pelo cânone.

### O que NÃO pode ser baked

- nome de missão dinâmica;
- lock;
- moeda;
- nível;
- reputação;
- status;
- objetivo;
- contagem;
- ato;
- requisito variável;
- nome de node mutável.

Preferir engine text para localização e acessibilidade.

---

## 16. Top navigation

As referências variam de ordem; a produção final deve usar uma ordem canônica única.

### Ordem recomendada

```text
MAPA | PERSONAGEM | MISSÕES | FACÇÕES | INVENTÁRIO | DIÁRIO | CONFIGURAÇÕES
```

Badges ALE/LEM/NTM podem ocupar bloco central/adjacente conforme layout final, mas devem manter posição consistente em todas as páginas.

### Active state

- aba ativa: fundo preto elevado + borda dourada + ícone dourado;
- abas inativas: off-white/cinza;
- hover/focus: brilho dourado discreto.

### Não colocar

- currency/level em posição que varie página a página sem contrato;
- novos botões inventados por arte.

---

## 17. Legenda

A legenda precisa ser idêntica entre páginas.

### Vocabulário recomendado

- Sua posição;
- Disponível;
- Bloqueado;
- Área secreta;
- Rota terrestre;
- Rota marítima;
- Rota bloqueada;
- Cidade / Ponto.

Territórios/facções só entram se o mapa realmente usar overlay territorial naquele modo.

Evitar inconsistências vistas em concepts como “Não disponível”, “Não bloqueado” ou “Nó de Local”.

---

## 18. Region plate

Toda página regional usa uma placa grande no canto inferior direito.

Conteúdo:

```text
<INDEX>/<TOTAL>
<REGION NAME>
<TAGLINE>
<mini silhouette/compass/BA mark>
```

### Regra de migração

Se o atlas oficial passar a 11 páginas, **nunca manter `x/10` baked**. O total deve vir do runtime/dados.

A placa deve preferencialmente ser UI componível, não parte da pintura-base.

---

## 19. Player HUD no mapa

Canto inferior esquerdo:

- retrato;
- nível;
- barras relevantes;
- frase opcional.

Tudo dinâmico.

Nunca rasterizar `NV 4`, `NV 12`, HP ou energia no background.

---

## 20. Bottom control strip

Faixa inferior preta, baixa altura, com prompts de controle.

Exemplo:

```text
L NAVEGAR | R ZOOM | A SELECIONAR | Y VER DETALHES | B VOLTAR
```

Input glyphs precisam vir do runtime para suportar:

- Xbox;
- PlayStation;
- teclado;
- touch.

A arte-base só define o container e spacing.

---

## 21. Páginas regionais — assinatura visual

### 01 — Baixo Sul

Função: overview macro.

- Ituberá visualmente central;
- municípios distribuídos em rede;
- maior presença de rotas intermunicipais;
- leitura clara de costa, ilhas, rios e serras;
- densidade menor de labels locais;
- foco em orientação.

### 02 — Ituberá

- rio + mar + cais;
- Terreiro;
- Feira;
- Arena do Dique;
- Pratigi;
- ponte/estrada;
- comunidade compacta;
- água e circulação urbana como eixos.

### 03 — Nilo Peçanha

- cultura comunitária;
- porto/mangue;
- Zambiapunga;
- quilombo;
- barragem/rios;
- festividade e tradição.

### 04 — Valença

- porto mais urbano;
- centro histórico;
- ferry;
- ponte/infraestrutura;
- ginásio/circuito;
- comércio ativo.

### 05 — Camamu

- baía ampla;
- mangue;
- cais;
- mercado de peixe;
- trilhas/cachoeira;
- dojo;
- ilhas próximas.

### 06 — Cairu

- arquipélago;
- rotas marítimas dominantes;
- fortes/faróis;
- vilas insulares;
- turismo/festa;
- segredo submerso.

### 07 — Itacaré & Maraú

- litoral/surf;
- falésias;
- cachoeiras;
- praias;
- píeres;
- turismo + tensão territorial;
- mar aberto mais presente.

### 08 — Interior Norte

- cacau;
- BR/estrada;
- caminhões/posto;
- fazendas;
- serra/cachoeiras;
- sensação de circulação econômica.

### 09 — Interior Sul

- mangue + colônia + piaçava;
- passagens por água;
- marisqueira;
- Galpão Piaçava;
- Colônia Nishiuchi;
- contraste entre tradição local e memória histórica.

### 10 — Salvador

- densidade urbana;
- baía;
- skyline;
- porto;
- Pelourinho;
- arena grande;
- infraestrutura institucional;
- Lapa/industrial;
- escala metropolitana.

### 11 — Costa das Marés / NG+

Enquanto candidate:

- geografia mais aberta e misteriosa;
- mangues/ilhas/praias;
- ruínas;
- maré como linguagem estrutural;
- relíquias;
- bosses/segredos;
- visual não deve parecer “outro jogo”.

---

## 22. Layer contract para Godot

Toda página final deve ser pensada como composição de runtime.

### A. `map_base_art`

Pode conter:

- terreno;
- água;
- vegetação;
- arquitetura;
- landmarks estáticos;
- estradas físicas;
- pontes;
- praias;
- píeres;
- props imutáveis.

Não pode conter:

- node badge;
- lock;
- route state;
- objetivos;
- faction ownership mutável;
- currency;
- level;
- dynamic text.

### B. `ambient_layers`

- water foam;
- waterfall;
- boats;
- birds;
- flags;
- smoke;
- fog;
- light flicker;
- crowd idle;
- foliage.

### C. `world_overlay`

- nodes;
- routes;
- locks;
- current position;
- faction/controller;
- resource icons;
- collectibles;
- secret state.

### D. `ui_overlay`

- top nav;
- legend;
- region plate;
- player HUD;
- prompts;
- details panel.

### E. `narrative_overlay`

- event sign;
- temporary warning;
- story callout;
- temporary hand-written line.

---

## 23. Layout data

Separar semântica de posicionamento.

Forma-alvo:

```text
world_map_semantic.json
  nodes / routes / gates / resources / minigames

world_map_layout_v2.json
  page_id
  node_position_norm
  route_control_points
  label_anchor
  badge_scale
  visual_priority
  occlusion_hint
```

### Coordenadas

Preferir normalizadas `0..1` para páginas responsivas.

Não enterrar `pos` dentro do cânone semântico se a arquitetura migrada já separa layout.

---

## 24. Animação e mundo vivo

Cada página deve declarar de 3 a 8 elementos animáveis.

Categorias:

- `water_flow`;
- `sea_wave`;
- `boat_idle`;
- `boat_route`;
- `bird_flock`;
- `flag_flutter`;
- `crowd_idle`;
- `waterfall`;
- `fog_secret`;
- `fire_light`;
- `street_light`;
- `vehicle_loop`;
- `foliage_wind`.

### Movimento

Baixa amplitude.

O mapa deve parecer vivo, não um GIF caótico.

---

## 25. Pipeline de geração com IA

### Passo 0 — Scope lock

Definir:

- page ID;
- região;
- nós canônicos;
- rotas;
- bioma;
- landmarks;
- hora/clima;
- facções/controladores;
- segredos;
- layers necessários.

### Passo 1 — Base art primeiro

Gerar **uma única ilustração de mapa**, sem HUD, sem textos, sem badges.

### Passo 2 — QA estrutural

Verificar:

- geografia plausível;
- espaço para overlays;
- landmark placement;
- rotas físicas possíveis;
- leitura mobile.

### Passo 3 — Overlays separados

Gerar/produzir nodes, badges, labels, routes, locks e FX em arquivos separados ou engine UI.

### Passo 4 — Composite preview

Montar mockup completo somente para validar estilo e hierarquia.

### Passo 5 — Runtime handoff

Exportar layers e sidecars; nunca usar composite como mapa final se ele contiver estado mutável.

---

## 26. Anti-drift prompt lock

Todo prompt de página deve conter explicitamente:

```text
ONE SINGLE REGIONAL MAP SCENE
16:9
no infographic board
no multi-panel layout
no sprite sheet
no character sheet
no multiple alternate versions
no baked HUD
no baked mutable labels
no photorealism
no 3D render
regional Bahia visual language
illustrated 2.5D atlas
```

Isso existe porque modelos generativos tendem a transformar pedidos complexos em concept boards.

---

## 27. Templates de prompt

### MAP_BASE_ART

```text
Single 16:9 illustrated regional game-map background for CRIA DO TATAME, page {page_id} — {region_name}. Oblique 2.5D cartographic panorama, dense but readable Bahia regional environment, {biomes}, {landmarks}, {architecture}, {roads_and_waterways}. Preserve clear corridors for runtime routes and POI overlays. Strong water/vegetation/material detail. HD pixel-art-inspired raster painting, black/ochre regional premium identity. NO HUD, NO legend, NO node badges, NO route lines, NO labels, NO text, NO locks, NO infographic board, NO multiple panels.
```

### MAP_COMPOSITE_PREVIEW

```text
Create one complete gameplay mockup of CRIA DO TATAME map page {page_id}/{total}: base art {region_name}, black/gold top navigation, left legend, circular POI badges, gold locks, terrestrial off-white dashed routes, maritime cyan routes, blocked red dashed routes with X markers, violet secret-zone fog, bottom-left player HUD, bottom controller strip, bottom-right region plate. Maintain 16:9 and exact visual grammar of the approved atlas references. This is a COMPOSITE PREVIEW only; do not use as shipping base art.
```

### NODE_BADGE

```text
Single circular CRIA DO TATAME world-map node badge for {node_id}, role {node_type}, controller {controller}, state {state}. Black/gold frame, readable at 48–96px, center icon/landmark {visual_anchor}, transparent background, no text baked unless explicitly requested.
```

### SECRET_ZONE_FX

```text
Transparent violet secret-area overlay for CRIA DO TATAME: irregular fog, low-opacity purple haze, subtle magenta light pockets, organic edges, no sci-fi neon, readable over tropical terrain, seamless fade, alpha-ready.
```

### ROUTE_OVERLAY

```text
Transparent world-map route overlay, route {route_id}, type {route_type}, smooth control points from layout data, off-white terrestrial / cyan maritime / red blocked + X / violet discovered-secret treatment, consistent dash cadence, no terrain baked.
```

### REGION_PLATE

```text
CRIA DO TATAME region plate UI component: black charcoal panel, worn gold angular border, off-white condensed title, page counter from runtime, regional silhouette/compass, transparent background, no baked page number in master source.
```

---

## 28. Lote de produção

Padrão do usuário: **10 assets individuais por lote**.

Regras:

- nunca devolver uma colagem quando o lote pede assets individuais;
- cada arquivo recebe ID e função;
- QA item a item;
- falha não entra no registry;
- manter `shipping=false`;
- só avançar para lote seguinte após registrar rejeições/reparos importantes.

Exemplo de lote de página:

1. base art;
2. water FX;
3. ambient boats;
4. vegetation foreground;
5. secret fog;
6. node badge family;
7. route overlay;
8. legend panel;
9. region plate;
10. composite preview.

---

## 29. QA visual obrigatório

### Gate M1 — Canvas

- 16:9;
- safe zones livres;
- nenhum cropping de UI.

### Gate M2 — Regionalidade

- região reconhecível;
- bioma correto;
- materiais locais plausíveis.

### Gate M3 — Landmark hierarchy

- landmark principal domina;
- POIs não competem todos pelo mesmo peso.

### Gate M4 — Route readability

- terrestre/marítima/bloqueada distinguíveis sem legenda;
- X de bloqueio visível;
- rotas não atravessam absurdamente geografia.

### Gate M5 — Node readability

- badge reconhecível em 48–96 px;
- labels não colidem;
- locks não cobrem ícone principal.

### Gate M6 — Secret language

- violeta presente;
- não domina a página inteira;
- mistério legível sem virar sci-fi.

### Gate M7 — UI consistency

- top nav igual entre páginas;
- legend igual;
- region plate igual;
- controls iguais;
- tipografia coerente.

### Gate M8 — Runtime separability

- nenhum estado mutável preso no base art;
- overlays identificáveis;
- texto dinâmico engine-renderable.

### Gate M9 — Mobile readability

Avaliar downscale para ~6 polegadas:

- nome de região legível;
- node major distinguível;
- rota principal distinguível;
- segredo distinguível;
- legend funcional.

### Gate M10 — Color blindness

Bloqueio não depende só de vermelho; usar X/padrão.

### Gate M11 — Canon

- IDs corretos;
- facção/controlador correto;
- nomes corretos;
- nenhuma região inventada como fato.

### Gate M12 — Rights

- sem logos reais;
- sem brasões oficiais;
- sem arte de terceiros incorporada sem direito.

### Gate M13 — Engine proof

Só promover depois de:

- composição em Godot;
- captura de runtime;
- safe-area QA;
- input focus;
- performance;
- Android físico quando aplicável.

---

## 30. Taxonomia de erros e reparo

### `E_BOARD_DRIFT`

Sintoma: saiu uma prancha/infográfico.

Reparo: repetir “ONE SINGLE MAP SCENE”, remover termos como sheet/overview/board, gerar base sem UI.

### `E_BAKED_STATE`

Sintoma: lock, level ou node label entrou no background.

Reparo: inpaint/remove; mover para overlay.

### `E_UI_DRIFT`

Sintoma: abas mudam de ordem ou estilo.

Reparo: usar topbar template fixo.

### `E_REGION_GENERIC`

Sintoma: qualquer praia tropical serviria.

Reparo: reforçar landmarks, materialidade e bioma da página.

### `E_PURPLE_OVERLOAD`

Sintoma: secret zone domina a composição.

Reparo: reduzir área e saturação; usar purple como foco localizado.

### `E_ROUTE_CHAOS`

Sintoma: demasiadas linhas ou curvas sem lógica.

Reparo: routes vêm do grafo/layout; simplificar curvas e priorizar ligações jogáveis.

### `E_LABEL_COLLISION`

Sintoma: texto cobre terreno/node.

Reparo: resolver por anchor/priority no layout data.

### `E_FACTION_CONFUSION`

Sintoma: ALE/LEM/NTM/LEI ficam visualmente indistinguíveis.

Reparo: corrigir badge, paleta cerimonial e símbolos.

### `E_TEXT_ARTIFACT`

Sintoma: texto de IA ilegível.

Reparo: remover texto do bitmap; engine text.

---

## 31. Checklist por página antes de gerar

```text
[ ] page_id confirmado
[ ] region_name confirmado
[ ] semantic source confirmado
[ ] layout source confirmado
[ ] nodes da página listados
[ ] routes da página listadas
[ ] locks/gates listados
[ ] faction/controller listados
[ ] main landmark definido
[ ] secondary landmarks definidos
[ ] bioma definido
[ ] water/road axis definido
[ ] motion layers definidos
[ ] secret zones definidas
[ ] dynamic text separado
[ ] output paths definidos
```

---

## 32. Sidecar mínimo

Cada asset candidato deve registrar:

```json
{
  "asset_id": "map_02_itubera_base_v01",
  "category": "world_map",
  "page_id": "02",
  "region": "itubera",
  "layer": "map_base_art",
  "style": "cria-world-map-atlas-forge@1.0.0",
  "source_authority": ["data/world/..."],
  "generated": true,
  "shipping": false,
  "contains_dynamic_state": false,
  "rights_status": "pending_review",
  "qa": {
    "canon": "PENDING",
    "visual": "PENDING",
    "runtime": "PENDING",
    "mobile": "PENDING"
  }
}
```

---

## 33. Composite reference vs shipping asset

Classificar sempre:

### `concept_reference`

Imagem completa com UI/textos usada para direção.

### `candidate_layer`

Elemento isolado pronto para QA.

### `runtime_candidate`

Layer integrado ao Godot, ainda sem gates finais.

### `shipping`

Somente quando QA, rights, human approval e runtime evidence passarem.

Nenhuma imagem desta skill vira `shipping` por qualidade estética isolada.

---

## 34. Regras para revisão das 10 referências aprovadas

Ao comparar nova produção com o set 01–10, verificar:

- mesma moldura preta/dourada;
- mesma linguagem dos badges;
- mesma hierarquia do topo;
- mesma espessura visual das rotas;
- água com energia semelhante;
- densidade regional compatível;
- região plate consistente;
- secret zones localizadas;
- narrativa ambiental presente, não excessiva;
- mapa ainda legível em miniatura.

Não copiar erros dos concepts, especialmente:

- `x/10` hardcoded;
- labels inconsistentes;
- ordem variável do top nav;
- textos de IA imperfeitos;
- facção/controller baked;
- brasões institucionais parecidos com marcas reais.

---

## 35. Definition of Done — página regional

Uma página só está pronta quando:

```text
semantic data valid
+ layout data valid
+ base art approved
+ overlays approved
+ UI consistent
+ dynamic states engine-driven
+ route graph aligns visually
+ mobile readability passes
+ Godot runtime capture reviewed
+ rights/provenance passes
+ human approval
= page promotable
```

Antes disso:

```text
shipping=false
```

---

## 36. Definition of Done — atlas completo

O atlas completo exige:

- todas as páginas canônicas integradas;
- page count derivado do dado;
- no orphan node;
- no orphan route;
- todas as rotas têm visual geometry;
- todos os locks têm consumidor;
- todas as secret zones obedecem discovery state;
- current position funciona;
- legenda única;
- top nav único;
- gamepad/keyboard/touch prompts funcionam;
- zoom/pan funcionam;
- transição para hubs funciona;
- TravelDetailPanel funciona;
- ROTA 101 só em rota terrestre compatível;
- maré afeta rotas marítimas quando o sistema estiver ativo;
- save/load preserva discovery/mastery;
- Android físico mantém legibilidade/performance.

---

## 37. Comando operacional padrão

Quando solicitado “faça o mapa/hub/material seguindo o padrão”, responder internamente com:

```text
ROUTE: cria-art-direction → cria-world-map-atlas-forge
AUTH: canon + runtime data + layout data
MODE: candidate authoring
BATCH: 10 individual assets unless user specifies otherwise
BASE FIRST: yes
BAKED DYNAMIC STATE: forbidden
RUNTIME: Godot only
SHIPPING: false by default
QA: M1–M13
```

Esta é a regra de produção permanente desta skill.
