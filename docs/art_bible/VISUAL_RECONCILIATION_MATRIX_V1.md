# Matriz de Reconciliação Visual v1

**Status:** vinculante para produção visual  
**Fonte de autoridade:** GDD-CDT v4.0, dados canônicos e `OFFICIAL_VISUAL_STANDARD_V1.md`

Esta matriz impede que uma prancha visual atraente seja tratada automaticamente como dado canônico ou asset executável.

## 1. Classificação das referências recebidas

| Grupo | Conteúdo observado | Uso aprovado | Uso proibido |
|---|---|---|---|
| Marca e aplicações | Silverback, wordmark, roupas, capas, ícones e HUD | logo, direção de marca e aplicações | copiar logos de plataforma ou marcas reais para shipping |
| Visão de produto | arenas, hubs, roster, Cria Live, árvore e moral | composição, escopo e atmosfera | declarar sistemas prontos por aparecerem na imagem |
| Roster | personagens em poses promocionais | silhueta, diversidade e hierarquia | assumir nomes, apelidos, função ou jogabilidade sem dados canônicos |
| Arenas e NPCs | galerias de biomas, diálogos e telas de luta | linguagem ambiental, fluxo e densidade | usar textos, locais ou emblemas inconsistentes sem correção |
| HUD de combate | recursos, timer, posição, cards e dicas | direção de informação e hierarquia | reproduzir texto dentro do background ou bloquear o centro do tatame |
| Pranchas densas | boards editoriais com muitos painéis | art bible e revisão | importar como sprite-sheet, menu ou cenário final |

## 2. Decisões canônicas obrigatórias

| Elemento nas imagens | Situação | Decisão para o projeto |
|---|---|---|
| `Ruan “Cria” Silva` | contradiz o cânone atual | usar **Ruan “Macacão” Silva**; bloquear o alias antigo em shipping |
| `Caio Ravel` | identificador legado proibido | não usar em UI, campanha, save novo ou marketing final |
| `Arena do Dique — Salvador` | consistente com `data/arenas.json` | **Salvador – Bahia** é a região canônica atual |
| Arena do Dique em Ituberá/Valença | aparece em outras pranchas | tratar como erro de concept e corrigir antes do asset final |
| `Praia de Pratigi / Itacaré` | erro geográfico recorrente | usar **Ituberá – Bahia** |
| `Zambiapunga — Una` | conflito entre pranchas | não promover; usar Nilo Peçanha somente após contrato de arena atualizado |
| Manguezal Profundo em Ituberá/Camamu/Cairu | conflito entre referências | manter `Baixo Sul da Bahia` até uma decisão canônica explícita de município |
| Ponte do Saici em Ituberá/Camamu | conflito não resolvido | marcar `location_pending_canon`; não gravar município no asset final |
| Pancada Grande em Itacaré/Nilo Peçanha/Ituberá | conflito não resolvido no material | realizar auditoria geográfica e atualizar dados antes da arte final |
| símbolos `Gracie`, `Atos`, `IBJJF`, `PF`, plataformas | marcas/instituições reais | substituir por instituições ficcionais ou licença comprovada |
| golpe em pé com estética de beat’em up | pode desviar o núcleo | luta em pé deve representar grip, clinch, queda, base e distância de BJJ |
| armas/equipamentos policiais | risco de tom e marca real | não usar em gameplay; instituições e operações permanecem ficcionais |
| textos gerados nas imagens | erros e baixa acessibilidade | recriar com `Label`, localização e tipografia oficial no Godot |
| 23 lutadores / 12 arenas | visão de escala | não equivale a roster ou conteúdo executável confirmado |

## 3. Logo oficial — resolução

### Oficial

- Silverback frontal;
- óculos aviador dourados;
- halo circular de valores;
- wordmark `CRIA DO TATAME`;
- assinatura `JIU-JITSU É TUDO`.

### Nome do produto

```text
Cria do Tatame – Pressão
```

### Estado do arquivo recebido

```text
brand_status = official_reference
production_status = master_pending
```

A decisão artística está congelada. O que falta é reconstrução técnica fiel em vetor/PNG transparente 4K, sem redesenhar a marca.

## 4. Paleta e tipografia

### Marca

`#F2C230 #F2F2F2 #0A0A0A #D92323 #1E5BFF`

### Arte pixel

`#0A0A0A #1A1A1A #B8860B #F2C230 #F2F2F2 #D92323 #1E3A5F #2D5016 #4B0082`

### Tipografia

- títulos: Bebas Neue Bold ou equivalente licenciado aprovado;
- corpo/UI: Barlow Condensed ou equivalente licenciado aprovado;
- lettering pincelado: reservado ao wordmark e chamadas de marketing;
- UI de runtime: texto nativo, escalável e localizável.

## 5. Matriz de promoção

| Estado | Evidência mínima | Pode aparecer onde? |
|---|---|---|
| `reference_only` | imagem e nota de origem | docs e revisão |
| `design_approved` | ficha visual + aprovação humana | docs, pitch e produção |
| `runtime_candidate` | sprite/arena/UI + metadados | branch de asset e cena de teste |
| `runtime_executable` | import, manifest, cena e smoke | vertical slice |
| `shipping_approved` | QA humano, licença, performance e regressão | build público |

## 6. Ações prioritárias

1. reconstruir a logo oficial em master transparente e vetor;
2. congelar tokens visuais e componentes UI;
3. produzir Ruan e Davi em 72 px com animação pareada;
4. produzir Arena do Dique com parallax, colisão, tags, som e crowd;
5. implementar HUD sem textos rasterizados;
6. produzir Terreiro em 64 px com Dendê e Tinker;
7. auditar geografia e nomes de todas as arenas antes da expansão;
8. usar as demais pranchas como metas de composição, nunca como evidência de runtime.
