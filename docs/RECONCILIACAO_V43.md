<!-- PATH: docs/RECONCILIACAO_V43.md -->

# CRIA DO TATAME – PRESSÃO — RECONCILIAÇÃO DE CÂNONE V4.3

**Status:** decisão autoritativa de cânone.  
**Escopo:** este documento resolve divergências entre os GDDs v4.0/v4.1, o brand book v1/v2 — imagens 30 e 32 —, o HUD — imagens 29 e 34 — e as fichas CPS — imagens 33, 34 e 35.  
**Regra de precedência:** em caso de conflito entre versões anteriores, documentos históricos, referências visuais, dados, prompts ou instruções de agentes, **ESTE DOCUMENTO VENCE**.

---

# 1. Tabela de reconciliação v4.3

| # | Divergência | Antes | Nas refs | DECISÃO v4.3 |
|---:|---|---|---|---|
| 1 | Idade Ruan | 20-22 | 28 (1,78m/82kg/preta/12 anos/Ituberá) | TRAVO 28. |
| 2 | Tinker jogável | narrador/só versus | lutador tático (faixa azul, “CÉREBRO DO TATAME”) | LUTÁVEL; estilo JIU-JITSU TÁTICO; mantém arco de narrador na campanha. |
| 3 | Mestre das dicas | só Dendê | Dendê (Ruan) e Mestre Pedrinho (Tinker) | mentor POR PERSONAGEM; +Mestre Pedrinho no elenco. |
| 4 | Slots de ação | 6 fixos | Ruan=6; Tinker=5 (c/ ÂNGULOS) | slots POR arquétipo. |
| 5 | Moral no HUD | roxo=VFX/flag | indicador MORAL ALTO verde | moral BIPOLAR verde ALTO ↔ roxo BAIXO. |
| 6 | Tags vs atributos | 1 conjunto | estilo=DISCIPLINA·FOCO·RESPEITO; combate=PRESSÃO·CONTROLE·EVOLUÇÃO | 2 conjuntos. |
| 7 | Paleta de marca | 6 cores | 5 cores (verde saiu) | marca=5; verde só em arte/HUD. |
| 8 | Tipografia texto | Oswald | Barlow Condensed | v2 vence: Bebas Neue Bold (títulos) + Barlow Condensed (textos). |
| 9 | Azul de marca | #2366FF | #1E5BFF | travo #1E5BFF na camada MARCA. |
| 10 | Nome Oni no HUD | Oni da Lapa | ONI DO SUL | lore/bio="Oni da Lapa"; display HUD="ONI DO SUL". |
| 11 | Classificação | 14+ | 18 nas caps | DECISÃO EM ABERTO (afeta tom do Ato II-C). |
| 12 | Cidades de marca | 11 municípios | +GANDU | incorporo Gandu como nó. |
| 13 | Plataformas | Android+Windows | +Switch | aspiracional; build real=Android+Windows. |
| 14 | Identidade no gi | patch genérico | por personagem (Ruan=gorila, Tinker=coroa/CORDA TÁTICA) | sistema de equipment/patch por personagem. |

---

# 2. Logo oficial travada

A logo oficial do jogo fica travada com os seguintes componentes inseparáveis:

- gorila silverback;
- óculos dourados;
- gi preto;
- coroa;
- anel com **DISCIPLINA × FOCO / RESPEITO × EVOLUÇÃO**;
- ideogramas **柔術**;
- lettering brush **CRIA DO TATAME**;
- faixa com graus;
- tagline **JIU-JITSU É TUDO**.

A composição oficial não pode ser redesenhada por preferência de agente, adaptada livremente para outro mascote, simplificada sem aprovação ou reconstruída com lettering diferente.

## 2.1. Variações canônicas

Existem exatamente três variações canônicas:

1. **Logo principal com óculos:** composição completa, gorila silverback com óculos dourados, gi preto, coroa, anel, ideogramas, lettering, faixa com graus e tagline;
2. **Variação P&B sem óculos:** composição monocromática aprovada, sem os óculos, preservando proporção, silhueta, elementos e hierarquia;
3. **Variação somente lettering dourado:** lettering brush dourado aprovado, usado quando a composição completa não couber, sem reconstrução tipográfica improvisada.

## 2.2. Usos incorretos — regra de QA

Os seguintes usos são proibidos:

- **NÃO DISTORCER**;
- **NÃO ALTERAR CORES**;
- **NÃO REMOVER ELEMENTOS**;
- **NÃO USAR FUNDOS COMPLEXOS**.

A aprovação de UI, material promocional, menu, capa, merchandising ou marketing exige verificar essas quatro proibições. Qualquer aplicação que prejudique contraste, leitura ou integridade da marca deve ser refeita.

---

# 3. HUD canônico v2

O HUD canônico v2 é dividido em zonas obrigatórias. Nenhuma tela de combate pode omitir essas zonas sem contrato específico de modo, tutorial ou acessibilidade.

## 3.1. Topo central

O topo deve apresentar:

- arena;
- round;
- timer;
- placar de rounds.

Esses elementos devem permanecer legíveis em desktop, controle e touch, respeitando safe area e escala de interface.

## 3.2. Painéis dos dois personagens

Cada lado do HUD deve possuir um painel com:

- retrato;
- nome;
- 3 tags de estilo;
- 5 barras: **VIDA, GÁS, FOCO, GRIP e CONTROLE**;
- 2 status contextuais.

As tags de estilo e os atributos de combate são conjuntos diferentes e não podem ser fundidos em uma única lista.

## 3.3. Buffs e debuffs

O HUD deve apresentar:

- painel de **BUFFS**;
- painel de **DEBUFFS**;
- ícone;
- nome localizado;
- efeito resumido;
- countdown quando houver duração temporária.

Buffs e debuffs não podem ser incorporados como texto fixo na imagem de fundo.

## 3.4. Posição atual

O painel **POSIÇÃO ATUAL** deve apresentar:

- miniatura da posição;
- nome localizado;
- percentual de estabilidade.

A informação exibida deve corresponder ao estado lógico do sistema posicional. A miniatura não pode mostrar posição diferente da posição registrada pelo runtime.

## 3.5. Dicas do mestre

O painel **DICAS DO MESTRE** deve apresentar:

- retrato do mentor associado ao personagem;
- dica específica da posição atual;
- linguagem coerente com o mentor;
- atualização por personagem e posição.

As dicas são fornecidas por um sistema chaveado por personagem e posição, e não por uma imagem fixa do HUD.

## 3.6. Barra inferior

A barra inferior apresenta os **slots de ação por estilo**. A quantidade e os nomes dos slots dependem do arquétipo do personagem. Eles não são seis botões globais obrigatórios para todos.

As cartas do deck especializam os slots válidos da posição atual, sem pausar a luta e sem ignorar posição, timing, tap ou escape.

## 3.7. Moral

O HUD inclui o indicador **MORAL bipolar**:

- verde **ALTO**;
- roxo **BAIXO**.

Moral não é uma sexta barra de recurso. É um medidor de estado moral conectado ao mundo e às consequências narrativas.

---

# 4. O padrão visual vira schema de dados

Cada prancha CPS espelha **1:1** uma estrutura de dados. A prancha não é apenas apresentação: sua numeração, categorias, campos e ordem devem corresponder ao JSON associado. Nenhum movimento, técnica ou equipamento pode existir somente na imagem sem registro nos dados, e nenhum dado pode apontar para frame inexistente.

## 4.1. CPS-A → moveset

Pseudocódigo:

```text
moveset_<id> = {
  id: "<id>",
  bio: {
    idade: <numero>,
    altura_m: <numero>,
    peso_kg: <numero>,
    faixa: "<faixa>",
    anos_treino: <numero>,
    origem: "<origem>"
  },
  estilo: "<estilo>",
  citacao: "<citacao>",
  atributos_combate: ["<atributo_1>", "<atributo_2>", "<atributo_3>"],
  moves: [
    {
      n: 1,
      id: "idle",
      categoria: "neutro",
      frames: ["anim_01_01", "anim_01_02", "anim_01_03"],
      frame_range: "01-03",
      loop: true,
      estado_entrada: "<estado>",
      estado_saida: "<estado>"
    }
  ]
}
```

A numeração da prancha, o ID do movimento, o frame-range e os caminhos dos arquivos devem ser idênticos aos dados.

## 4.2. CPS-B → techniques

Pseudocódigo:

```text
techniques_<id> = {
  id: "<id>",
  estilo: "<estilo>",
  mentor: "<mentor_id>",
  slots_estilo: ["<slot_1>", "<slot_2>", "<slot_3>"],
  leituras: ["FOCO", "LEITURA", "ESSÊNCIA"],
  tecnicas: [
    {
      n: 1,
      id: "<tecnica_id>",
      categoria: "<categoria>",
      posicao_entrada: "<posicao>",
      posicao_saida: "<posicao>",
      passos: [
        "<passo_1>",
        "<passo_2>",
        "<passo_3>",
        "<passo_4>"
      ],
      frames: [
        "tech_<id>_01_01",
        "tech_<id>_01_02",
        "tech_<id>_01_03",
        "tech_<id>_01_04"
      ],
      especializa_slot: "<slot>"
    }
  ]
}
```

Os quatro frames e os passos da técnica devem corresponder visual e semanticamente à mesma progressão.

## 4.3. CPS-C → equipment

Pseudocódigo:

```text
equipment_<id> = {
  id: "<id>",
  patch_identidade: "<patch>",
  paleta_propria: ["<hex_1>", "<hex_2>", "<hex_3>"],
  vistas_kimono: ["front", "back", "left", "right"],
  detalhes: [
    "lapela",
    "patch_ombro",
    "punho",
    "no_faixa",
    "barra_calca",
    "patch_costas",
    "costura"
  ],
  visuais_alternativos: [
    "branco_oficial",
    "preto_treino",
    "rashguard",
    "street"
  ],
  acessorios: ["<item_1>", "<item_2>", "<item_3>", "<item_4>", "<item_5>", "<item_6>"],
  caracteristicas_identidade: ["<traco_1>", "<traco_2>", "<traco_3>", "<traco_4>", "<traco_5>", "<traco_6>"],
  leituras_campo: ["<leitura_1>", "<leitura_2>", "<leitura_3>", "<leitura_4>", "<leitura_5>"]
}
```

As quatro vistas, os detalhes ampliados, os visuais alternativos e os acessórios devem existir como assets rastreáveis e não apenas como ilustração editorial.

---

# 5. Perguntas abertas

As decisões abaixo permanecem explicitamente abertas e não podem ser encerradas por inferência de agente:

1. **Classificação indicativa — DECISÃO EM ABERTO:** definir entre 14+, 16+ ou 18, considerando o tom do Ato II-C, intensidade visual, marketing e plataformas;
2. **Mestre Pedrinho — DECISÃO EM ABERTO:** definir se permanece NPC de hub e mentor ou se entra no roster;
3. **Tinker lutável — DECISÃO EM ABERTO:** definir se o acesso como personagem lutável ocorre dentro da campanha principal, em lutas opcionais ou somente no modo versus; sua identidade de lutador tático permanece estabelecida;
4. **Arquétipos de slots — DECISÃO EM ABERTO:** definir quantos arquétipos de slots existirão no produto final e quais personagens pertencem a cada um;
5. **Oni display vs lore — DECISÃO EM ABERTO:** confirmar até onde se estende a separação entre lore/bio “Oni da Lapa” e display “ONI DO SUL”, incluindo seleção, cards, diálogos e marketing.

Nenhum agente pode preencher essas decisões por preferência própria. A resolução exige atualização explícita deste documento ou criação de decisão posterior com autoridade superior declarada.
