# CRIA DO TATAME – PRESSÃO
## Padrão Visual Oficial v1 — marca, arte, HUD, arenas e produção

**Status:** CANÔNICO / VINCULANTE  
**Data:** 2026-07-24  
**Contrato executável:** `data/visual/official_visual_contract_v1.json`  
**Referências:** `docs/art_bible/references/`

> Este documento transforma o conjunto visual aprovado pelo dono do projeto em regras de produção verificáveis. As pranchas recebidas são direção de arte e produto; somente assets que passam pelos gates deste documento podem ser promovidos a runtime ou shipping.

---

## 1. Declaração da logo oficial

A **logo oficial completa do jogo** é o lockup composto por:

1. gorila **Silverback** frontal;
2. óculos aviador dourados;
3. halo circular com os valores **Disciplina · Foco · Respeito · Evolução**;
4. wordmark pincelado **CRIA DO TATAME**;
5. assinatura **JIU-JITSU É TUDO**.

Identificador canônico:

```text
cdt_primary_silverback_lockup_v1
```

Nome oficial do produto:

```text
Cria do Tatame – Pressão
```

A marca principal pode mostrar apenas `CRIA DO TATAME`; **Pressão** é o subtítulo do produto e deve aparecer em loja, metadata, telas legais e peças de campanha sem redesenhar o lockup mestre.

### Variantes permitidas

- principal colorida;
- monocromática clara;
- monocromática escura;
- wordmark horizontal;
- selo do Silverback.

### Usos proibidos

- deformar, esticar ou inclinar o wordmark;
- recolorir fora da paleta de marca;
- gerar novamente a logo por IA para uso final;
- retirar componentes da versão principal e continuar chamando-a de logo completa;
- inserir marcas de academias, federações, forças policiais ou empresas reais;
- aplicar sobre fundo complexo sem placa de proteção;
- usar a prancha de referência achatada como master de impressão.

O raster em `references/official_logo_reference_v1.png` é a **referência aprovada**. Um PR de asset deve produzir o master vetorial/4K transparente sem reinterpretar o desenho.

---

## 2. O que as imagens aprovam

O material consolida uma identidade reconhecível:

- preto e azul-noite como campo principal;
- dourado envelhecido para hierarquia, moldura e prestígio;
- branco quente para leitura;
- acentos funcionais vermelhos, azuis, verdes e roxos;
- pixel art 2D/2.5D de alto detalhe;
- iluminação cinematográfica quente, rim light dourado e sombras frias;
- composição editorial modular;
- Baixo Sul da Bahia tratado como território vivo, não cenário genérico;
- jiu-jitsu posicional como centro visual e mecânico;
- torcida, clima, piso e bioma influenciando a luta;
- personagens com silhueta, rosto e postura facilmente diferenciáveis.

### Distinção obrigatória

| Camada | Função | Pode entrar no runtime? |
|---|---|---|
| Prancha densa / pitch board | visão, linguagem e composição | não |
| Concept / key art | atmosfera e aprovação de direção | não diretamente |
| Sprite nativo | personagem jogável em 64/72 px | sim, após QA |
| UI Godot | informação, navegação e acessibilidade | sim |
| Arena modular | parallax, colisão, tags e áudio | sim |
| Arte de marketing | capa, trailer, mídia e loja | fora do gameplay |

A qualidade-alvo não significa colocar as pranchas inteiras dentro do jogo. Significa reproduzir sua **coerência, contraste, atmosfera e acabamento** com assets adequados ao runtime.

---

## 3. DNA visual mensurável

### 3.1 Personagens

- altura nativa: **72 px em combate** e **64 px em hub**;
- grid-base: **16 px**;
- filtro: `nearest`;
- escala inteira;
- contorno preto de 1 px na resolução nativa;
- highlight/rim light dourado de 1 px, sem apagar o volume;
- três massas de valor legíveis: sombra, base e luz;
- rosto, cabelo, massa corporal e kimono consistentes entre frames;
- pivô `bottom-center` e escala comum no roster;
- animação pareada com `sync_map` para atacante e defensor.

### 3.2 Arenas

Cada arena final deve possuir:

1. key art aprovada;
2. vista lateral jogável;
3. plano top-down;
4. 5–7 camadas de parallax;
5. tileset e props reutilizáveis;
6. mapa de colisão;
7. tags de terreno;
8. pontos de áudio e plateia;
9. variantes de horário/clima;
10. orçamento mobile e relatório de playtest.

O bioma precisa alterar leitura e mecânica. Exemplos canônicos: areia fofa, lama, vento, ritmo, torcida, baixa visibilidade e piso oficial.

### 3.3 HUD e UI

O HUD deve parecer parte da mesma marca sem cobrir o jiu-jitsu:

- recursos no topo;
- posição, lado e modificador destacados;
- comandos contextuais na faixa inferior;
- centro do tatame preservado;
- tipografia renderizada por `Label`, nunca gravada no cenário;
- alvos touch de no mínimo 48 dp;
- safe area, contraste e escalabilidade;
- feedback por forma + ícone + texto, nunca somente cor;
- opção de reduzir shake, strobo e flashes.

A moldura editorial dourada é adequada a menus, cards, telas de mapa, fichas e resultados. Em combate, deve ser simplificada para não competir com os corpos.

---

## 4. Sistema de telas

O padrão visual deve ser aplicado verticalmente ao fluxo:

```text
Main Menu
→ Terreiro da Luta
→ Hub de Habilidades / Deck
→ Mapa do Mundo
→ Pré-luta
→ Combate
→ Resultado
→ Cria Live
→ Save e avanço semanal
```

### Tela de hub

- cenário vivo com treino, NPCs e rio/mangue;
- missão principal e agenda legíveis;
- personagem central em escala de hub;
- atalhos e recursos sem cobrir o ambiente;
- sinalização regional coerente e sem marcas reais.

### Tela de mapa

- nós, rotas e clima em hierarquia clara;
- oficial, clandestino, hub e evento com iconografia distinta;
- painel contextual do destino;
- território real tratado com precisão geográfica.

### Tela de combate

- dois retratos, recursos e timer;
- posição visual igual ao estado lógico;
- cartas e comandos condicionados à posição;
- buffs/debuffs temporários fora da área de contato;
- placar e ruleset adequados à arena.

---

## 5. Leitura crítica do material enviado

### Aprovado como direção

- identidade preto/dourado/branco;
- acabamento de graphic novel/pixel art premium;
- composição editorial;
- diversidade visual dos biomas;
- HUD com recursos, posição e comandos;
- integração de NPC, missão, mapa, luta e progressão;
- arenas como sistemas e não apenas fundos;
- peso regional e atmosfera do Nordeste.

### Não aprovado automaticamente como cânone

- nomes, apelidos e roster mostrados nas pranchas;
- localizações divergentes;
- símbolos de academias, federações ou forças reais;
- técnicas de trocação que desviem do BJJ posicional;
- textos gerados dentro das imagens;
- quantidade de personagens ou arenas sem contrato de runtime;
- uniformes, marcas e emblemas de terceiros.

As correções detalhadas vivem em `VISUAL_RECONCILIATION_MATRIX_V1.md`.

---

## 6. Pacotes verticais de produção

### Personagem

```text
brief canônico
→ concept
→ turnaround
→ scale sheet
→ movesheet
→ key poses pareadas
→ sprite 72 px
→ sprite 64 px
→ atlas
→ animation manifest
→ cena de teste
→ QA visual/biomecânico/runtime
```

Um personagem só recebe `runtime_executable` quando todos os itens acima existem e rodam.

### Arena

```text
brief regional
→ key art
→ layout lateral/top-down
→ tileset/props
→ parallax
→ colisão
→ terrain tags
→ áudio/plateia
→ cena jogável
→ playtest/performance
```

### UI

```text
wireframe
→ token set
→ componentes
→ estados de interação
→ desktop/touch
→ localização
→ acessibilidade
→ cena real
→ teste de legibilidade
```

---

## 7. Gates de qualidade

### Gate visual

- paleta válida;
- silhueta legível a 25%;
- nenhum texto embutido em sprite de gameplay;
- escala, pivô e contorno consistentes;
- ausência de drift de rosto/roupa;
- nenhum logo real não autorizado;
- aprovação humana da direção de arte.

### Gate técnico

- import Godot sem erro;
- cena e manifest presentes;
- animações pareadas sem interpenetração crítica;
- posição visual igual ao FSM;
- atlas dentro do orçamento;
- HUD legível em mobile;
- 45 FPS mínimo sustentado no aparelho-alvo do vertical slice.

### Gate de conteúdo

- local e bioma canônicos;
- nome e função do personagem validados; protagonista: `Ruan “Macacão” Silva`;
- Praia de Pratigi situada em Ituberá – Bahia;
- exatamente três facções;
- sem `Caio Ravel` ou `Ruan “Cria” Silva` em shipping;
- sem pessoa real criminalizada;
- sem marca de terceiro incorporada ao produto.

---

## 8. Ordem estratégica para atingir esta qualidade

### M1 — congelar marca e tokens

- produzir master oficial transparente/vetorial;
- consolidar tipografia, ícones e paletas;
- criar componentes UI reutilizáveis;
- adicionar lint visual.

### M2 — vertical slice Ruan × Davi

- Ruan e Davi em 72 px com animações pareadas;
- Arena do Dique completa;
- HUD desktop e touch;
- áudio mínimo representativo;
- resultado, Cria Live e save.

### M3 — Terreiro e mapa

- hub funcional em 64 px;
- Dendê e Tinker como NPCs;
- mapa com destinos canônicos;
- progressão, deck e missões.

### M4 — expansão por pacote

Cada novo rival entra junto com:

- arena/arco correspondente;
- técnicas e animações;
- retratos e UI;
- áudio;
- missão;
- QA e performance.

### M5 — certificação

- revisão de licenças;
- teste Android físico;
- regressão visual e runtime;
- hash do build;
- aprovação humana final.

---

## 9. Definition of Done

> Só está pronto quando roda no jogo, possui dados, arte, cena, manifest, teste, licença e checklist verde.

Os termos **arte final**, **logo master**, **jogo completo**, **APK pronto** e **release ready** são proibidos sem a evidência correspondente.
