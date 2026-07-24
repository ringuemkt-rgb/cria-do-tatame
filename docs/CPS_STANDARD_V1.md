<!-- PATH: docs/CPS_STANDARD_V1.md -->

# CRIA DO TATAME – PRESSÃO — CPS STANDARD V1
## Character Production Sheet — padrão de produção de personagem v2

**Status:** cânone de produção obrigatório.  
**Aplicação:** personagens lutáveis, mentores, NPCs de história, artistas humanos e agentes de produção visual ou técnica.  
**Regra de autoridade:** nenhum asset, ficha, JSON, spritesheet, retrato, equipamento ou animação de personagem pode ser aprovado abaixo deste padrão.

---

# 1. Regra de ouro

Produzir um personagem lutável não significa entregar um sprite isolado. Produzir um personagem lutável significa entregar quatro pranchas canônicas e complementares — **CPS-A, CPS-B, CPS-C e CPS-D** — acompanhadas pelos dados espelho e pelos frames isolados necessários ao runtime. As quatro pranchas formam a bíblia visual e técnica do personagem; nenhuma delas substitui os assets finais de jogo, e nenhuma pode contradizer as demais.

## 1.1. CPS-A — Identidade + Movesheet

A **CPS-A — Identidade + Movesheet**, cuja referência visual é a imagem 35, estabelece a identidade corporal, biomecânica e animada do personagem. A prancha deve conter bio numérica completa — idade, altura, peso, faixa, anos de treino e origem —, estilo de luta, citação, símbolo de identidade, legenda de ícones de categoria e três atributos de combate. Também deve conter **33 movimentos numerados**, cada um representado por uma sequência legível de **3 a 5 frames**, preservando rosto, massa corporal, roupa, escala, pivô e direção de luz.

A lista mínima de 33 movimentos é:

1. IDLE;
2. ANDAR;
3. CORRER;
4. AGACHAR;
5. PULO;
6. GUARDA;
7. CLINCH;
8. PEGADA;
9. SINGLE LEG;
10. DOUBLE LEG;
11. ARM DRAG;
12. SPRAWL;
13. GUARDA FECHADA;
14. PASSAGEM PRESSÃO;
15. KNEE CUT;
16. SIDE CONTROL;
17. MONTADA;
18. COSTAS;
19. RASPAGEM;
20. TRANSIÇÃO;
21. TRIÂNGULO;
22. ARMBAR;
23. KIMURA;
24. MATA-LEÃO;
25. PASSAGEM AVANÇADA — LEG DRAG;
26. HIT LEVE;
27. HIT MÉDIO;
28. HIT PESADO;
29. QUEDA — THROWN;
30. QUEDA DE COSTAS — TAKEDOWN;
31. LEVANTAR;
32. TAUNT;
33. VITÓRIA.

Cada movimento deve declarar no JSON espelho: número, ID, categoria, frame-range, duração, loop ou execução única, estado de entrada, estado de saída e vínculo com o sistema posicional quando aplicável.

**O que vira no repositório:**

- `moveset_<id>.json`;
- `assets/sprites/characters/<id>/anim_*.png`;
- atlas, preview e metadados derivados dos frames aprovados.

## 1.2. CPS-B — Técnicas Centrais

A **CPS-B — Técnicas Centrais**, cuja referência visual é a imagem 34, define a linguagem técnica e tática do personagem. A prancha deve apresentar **10 técnicas**, cada uma com **4 frames numerados** e **3 a 4 passos em bullet**, descrevendo a progressão mecânica real da técnica. Também deve conter perfil tático, demonstração em combate, mestre diegético, slots de ação do estilo e três leituras funcionais: **FOCO, LEITURA e ESSÊNCIA**. A execução visual deve respeitar entrada, controle, transição, resposta do oponente e estado final, sem salto entre poses e sem contradizer o sistema posicional.

Cada técnica deve declarar no JSON espelho: número, ID, nome localizado, categoria, posição de entrada, posição de saída, lado relativo, custo, janela, resposta defensiva, passos, frames, eventos de sincronização e slot especializado.

**O que vira no repositório:**

- `techniques_<id>.json`;
- frames `tech_<id>_<n>_<frame>.png`;
- pacotes pareados de atacante e defensor quando a técnica exigir dois corpos sincronizados.

## 1.3. CPS-C — Kimonos, Visuais & Equipamentos

A **CPS-C — Kimonos, Visuais & Equipamentos**, cuja referência visual é a imagem 33, define a construção material e identitária do personagem. A prancha deve apresentar o kimono oficial em **4 vistas** — frontal, traseira, lateral esquerda e lateral direita —, além de detalhes ampliados de lapela, patch do ombro, punho, nó da faixa, barra da calça, patch das costas e costura. Deve apresentar **4 visuais alternativos** — branco oficial, preto de treino, rashguard e street —, **6 acessórios**, paleta própria, texturas e materiais, **6 características de identidade** e **5 leituras de campo**. Todas as vistas devem preservar exatamente o mesmo rosto, corpo, proporção, cabelo, patch, faixa e construção do uniforme.

Cada item deve declarar no JSON espelho: ID, categoria, vistas disponíveis, materiais, paleta, compatibilidade, função visual, função de gameplay quando existir, regras de sujeira e dano, e caminhos dos assets.

**O que vira no repositório:**

- `equipment_<id>.json`;
- `assets/sprites/equipment/<id>/`;
- variantes de roupa, patches, acessórios e materiais aprovados.

## 1.4. CPS-D — Perfil & Retratos

A **CPS-D — Perfil & Retratos** define a leitura emocional e narrativa do personagem. A entrega mínima inclui retrato em **3 expressões** — `calm`, `tense` e `happy` —, perfil tático, citação e mestre associado. As três expressões devem preservar o mesmo rosto, cabelo, idade aparente, tom de pele, roupa, proporção e iluminação-base, alterando somente a expressão e a tensão corporal necessárias ao diálogo.

O perfil tático deve registrar estilo, postura, jogo preferido, ponto forte, ponto-chave, mentalidade, tags de valor, atributos de combate e relação com o mentor. A citação não pode contradizer o arco narrativo ou a conduta canônica do personagem.

**O que vira no repositório:**

- `portraits/<id>_calm.png`;
- `portraits/<id>_tense.png`;
- `portraits/<id>_happy.png`;
- `characters/<id>.json`.

---

# 2. Protocolo de 2 passes

A produção de cada CPS ocorre obrigatoriamente em dois passes separados. Misturar os dois passes gera pranchas visualmente bonitas, porém inadequadas ao runtime.

## PASSO 1 — Prancha densa

Gerar uma **PRANCHA DENSA** por CPS, no estilo das imagens 33, 34 e 35. A prancha densa funciona como overview, bíblia visual, folha de aprovação, fonte de dados e referência de consistência. Ela pode conter cabeçalhos, molduras, rótulos, tabelas, explicações, setas, numeração e layouts editoriais. Ela **NÃO entra no Godot** como spritesheet, atlas, frame de animação, retrato de runtime ou tela final.

A prancha densa deve:

- consolidar proporções e identidade;
- numerar movimentos, técnicas, vistas e itens;
- permitir revisão humana antes da produção em escala;
- servir como referência anexada para o segundo passe;
- espelhar a estrutura dos JSONs canônicos;
- registrar claramente o que será isolado e produzido depois.

## PASSO 2 — Frames isolados

A partir da prancha densa aprovada, anexada como referência, gerar os **FRAMES ISOLADOS recortáveis**. Esses frames devem possuir fundo transparente, mesma escala, mesma linha de contato, pivô documentado, numeração determinística e consistência absoluta de rosto, corpo, roupa e luz. **Esses frames entram no Godot.**

Os frames isolados devem:

- ser exportados individualmente;
- usar nomes determinísticos;
- preservar o mesmo canvas lógico por família;
- evitar moldura, rótulo, número ou texto incorporado;
- declarar frame-range no JSON espelho;
- ser testados na escala real do jogo;
- gerar atlas, preview e relatório de QA antes da promoção.

## Ferramenta certa por job

| Job | Ferramenta principal | Regra de uso |
|---|---|---|
| Animações e movesheet | SpriteCook | Usa a CPS-A aprovada como referência; produz sequências consistentes, frames isolados e famílias de movimento. |
| Técnicas pareadas | SpriteCook com revisão técnica | Usa CPS-A e CPS-B como referência; atacante e defensor devem compartilhar timeline, pivô e eventos de sincronização. |
| Equipamentos e vistas estáticas | GPT/Gemini | Produz conceitos e key art estática a partir da CPS-C; cada vista aprovada deve ser isolada e limpa antes de entrar no runtime. |
| Retratos | GPT/Gemini | Produz as expressões da CPS-D preservando identidade; o resultado final deve ser exportado sem texto incorporado. |
| Key de técnica | GPT/Gemini | Produz pose-chave ou referência visual; não substitui a sequência técnica nem a revisão biomecânica. |

Nenhuma ferramenta promove automaticamente um resultado para a build. Toda saída é candidata até passar por revisão humana, integração, teste no Godot e QA.

---

# 3. Regra de texto

sprites e frames de jogo = SEM texto/letras/números; a LOGO = COM lettering (é a marca); rótulos de UI (VIDA 92/100, Meia Guarda, PEGADA, dica do mestre) = NUNCA imagem, sempre Label no Godot com as fontes oficiais.

---

# 4. As 3 camadas de cor

| Camada | Aplicação | Allow-list |
|---|---|---|
| ① MARCA | logo/menu/merch/marketing | `#F2C230 #F2F2F2 #0A0A0A #D92323 #1E5BFF` |
| ② ARTE PIXEL | sprites/arena/props/cards-arte | `#0A0A0A #1A1A1A #B8860B #F2C230 #F2F2F2 #D92323 #1E3A5F #2D5016 #4B0082` |
| ③ HUD FUNCIONAL | barras/slots/buffs | `VIDA=verde GÁS=azul FOCO=dourado GRIP=magenta CONTROLE=ciano buff=verde debuff=vermelho` |

**Regra de lint:** o lint de paleta valida a camada ② nos sprites de arte; NÃO reprova o HUD (③) nem a logo (①). Três allow-lists.

A camada deve ser declarada no manifesto do asset. Um mesmo arquivo não pode misturar paleta de marca, paleta de arte e cores funcionais sem contrato explícito. A logo é validada pela allow-list ①; sprites, arenas, props e arte de cards são validados pela allow-list ②; barras, slots, buffs, debuffs e indicadores de recurso são validados pela allow-list ③.

---

# 5. Slots de ação por arquétipo

Os slots de ação **NÃO são fixos globais**.

| Arquétipo | Quantidade | Slots |
|---|---:|---|
| PRESSÃO | 6 | `PEGADA, GUARDA, TRANSIÇÃO, PASSAGEM, MONTADA, FINALIZAÇÃO` |
| TÁTICO | 5 | `PEGADA, GUARDA, TRANSIÇÃO, ÂNGULOS, FINALIZAÇÃO` |
| GUARDA/RASPAGEM — sugerido para Leoa | DECISÃO EM ABERTO | Proposta não canônica: `PEGADA, GUARDA, RASPAGEM, TRANSIÇÃO, FINALIZAÇÃO`. Quantidade, ordem e nomes finais dependem de validação de design e combate. |

**Slot** é a ação posicional base, sempre visível, que move o `PositionFSM` de acordo com o estado atual. O slot comunica ao jogador quais famílias de ação são estruturalmente possíveis naquela posição.

**Carta do deck** especializa o slot da posição atual com janela, custo e efeito melhores, **SEM pausar a luta, SEM ignorar posição, timing, tap ou escape**. A carta não cria uma técnica fora do catálogo, não teleporta entre posições e não substitui o sistema posicional.

---

# 6. Moral bipolar no HUD

O indicador **MORAL é verde ALTO ↔ roxo BAIXO**. Ele **NÃO é uma 6ª barra de recurso**; é um medidor de estado moral ligado à flag roxo e ao World Director.

A Moral não deve ser tratada como custo de técnica, energia, vida, gás, foco, pegada ou controle. Seu papel é expressar o estado moral acumulado do personagem e permitir que o mundo, a narrativa, as reações e os eventos respondam a esse estado.

---

# 7. Mentor por personagem

O sistema canônico é um **MentorSystem** com:

```text
mentor_por_personagem = {ruan:dende, tinker:pedrinho, ...}
```

O arquivo `dicas_do_mestre.json` deve ser chaveado por **(personagem, posição)**. Cada dica precisa considerar o personagem ativo, o mentor associado, a posição atual, o lado relativo, o estado de estabilidade e a linguagem própria daquele mentor.

**Mestre Pedrinho = NPC de hub + mentor diegético do Tinker, sem movesheet por ora.**

**DECISÃO EM ABERTO:** Mestre Pedrinho vira membro do roster ou permanece exclusivamente como NPC de hub e mentor.

---

# 8. Tabela de volume real

| Asset por personagem lutável | Volume aproximado por personagem | Volume aproximado para 8 lutáveis |
|---|---:|---:|
| Frames de movesheet | 120–160 | 960–1.280 |
| Frames de técnicas | 40 | 320 |
| Equipamento | 14 | 112 |
| Retratos | 3 | 24 |
| Total aproximado | 180–220 imagens | 1.500–1.800 imagens |

Por personagem lutável, o volume real é aproximadamente **120–160 frames de movesheet + 40 frames de técnicas + 14 de equipamento + 3 retratos ≈ 180–220 imagens**. Para os **8 lutáveis da seleção**, o volume estimado é aproximadamente **1.500–1.800 imagens**.

**Conclusão:** 1 personagem = 1 lote grande, composto por 4 pranchas e seus frames. Lotes de “10 sprites soltos” ficam somente para props, ícones e retratos avulsos.

O lote grande pode ser dividido em commits técnicos menores para permitir revisão, rollback e QA, mas permanece uma unidade de produção do personagem.

---

# 9. Checklist de QA por CPS

Uma CPS só pode ser aprovada quando todos os itens abaixo estiverem confirmados:

- [ ] **(a)** 4 vistas do kimono com rosto e proporção idênticos;
- [ ] **(b)** oponente em técnicas de chão SEMPRE adulto de gi neutro, nunca criança;
- [ ] **(c)** sem texto nos sprites;
- [ ] **(d)** paleta da camada certa;
- [ ] **(e)** pivot nos pés e escala idênticos em todos os frames;
- [ ] **(f)** cada movimento numerado tem frame-range no JSON espelho;
- [ ] **(g)** silhueta legível a 64px.

A reprovação de qualquer item impede promoção do asset para o atlas final ou para cenas de shipping.
