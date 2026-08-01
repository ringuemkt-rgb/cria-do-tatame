# ART_PROTOCOL — Cria do Tatame

> **status:** CANONICAL  
> **version:** 1.0.0  
> **last_reviewed:** 2026-08-02  
> **owner:** Direção de Arte — Cria do Tatame  
> **tokens:** `data/art_tokens.json`  
> **validator:** `tools/validate_art_protocol.py`

## Autoridade

Este documento é a fonte única de verdade para **execução visual**. Ele governa marca, mapa, arenas, HUD, iconografia, tipografia, pixel art, movimento e apresentação.

Quando houver conflito:

1. fatos de cânone, IDs, licença e origem permanecem nos contratos executáveis correspondentes;
2. para forma visual, composição, tokens, tipografia, proporção e QA, este protocolo vence documentação, mockup, prompt e concept art conflitantes;
3. mudanças neste protocolo exigem versão SemVer, changelog e justificativa.

**Certo:** corrigir um mockup bonito para obedecer ao protocolo.  
**Errado:** aprovar um mockup porque “parece profissional” mesmo quebrando tokens, HUD ou orçamento mobile.

## Changelog

| Data | Versão | O quê | Por quê |
|---|---:|---|---|
| 2026-08-02 | 1.0.0 | Criação do protocolo, tokens e gate de CI | Impedir deriva entre marca, mapas, arenas, HUD e assets futuros |

---

# BLOCO 1 — IDENTIDADE E MASCOTE

## 1.1 Silverback canônico

O Silverback representa o projeto inteiro. Não é personagem jogável nem facção.

Elementos obrigatórios:

- gi preto;
- óculos dourado **genérico**, sem logotipo;
- expressão estoica;
- patch de ombro com o ícone Silverback;
- `柔術` apenas como detalhe de ombro;
- anel fixo de valores: `DISCIPLINA · FOCO · RESPEITO · EVOLUÇÃO`.

**Certo:** `柔術` pequeno no ombro, subordinado ao símbolo principal.  
**Errado:** japonês como manchete, falsa caligrafia decorativa ou símbolo sem revisão semântica.

## 1.2 Variações obrigatórias

1. logo cheio;
2. cabeça com óculos;
3. cabeça monocromática em círculo;
4. triângulo-favicon.

Toda variação mantém reconhecimento em 25% do tamanho de apresentação.

## 1.3 Taglines oficiais

- `JIU-JITSU É TUDO`
- `DE CRIA PRA CRIA`

A frase narrativa `Ser forte é ser gentil.` continua canônica, mas não substitui automaticamente as taglines de marca.

## 1.4 Aplicações canônicas

- costas do kimono;
- peito da rashguard;
- patch de duffel;
- splash;
- ícone de aplicativo;
- canto de tela.

## 1.5 Anatomia congelada

Nunca mudar:

- silhueta larga dos ombros;
- direção frontal do olhar;
- paleta do gi;
- presença da coroa no logo cheio;
- óculos genérico sem marca;
- relação de escala entre cabeça, ombros e wordmark.

Pode variar:

- expressão sutil;
- faixa no cinto conforme progressão;
- tratamento monocromático autorizado;
- nível de detalhe conforme tamanho.

**Certo:** simplificar pelos clusters preservando a silhueta.  
**Errado:** afinar os ombros, transformar o gorila em cartoon infantil ou inserir marca nos óculos.

---

# BLOCO 2 — PALETA MESTRE

O nome do token é a verdade. O hexadecimal é a leitura calibrada atual.

| Token | Hex | Uso | Proibido | Contraste com `branco-giz` |
|---|---|---|---|---|
| `preto-tatame` | `#0B0B0C` | fundo, moldura, área negativa | apagar volume de pele; texto cinza sem contraste | AAA |
| `ouro-cria` | `#E8A317` | foco, borda ativa, título, marca | fundo contínuo; texto pequeno sobre claro | decorativo |
| `ouro-claro` | `#F2B705` | brilho curto, perfeito, raridade | corpo de texto; painel inteiro | decorativo |
| `branco-giz` | `#F4EFE6` | texto, número crítico, ícone neutro | fundo dominante; emissivo permanente | — |
| `cinza-grunge` | `#1A1A1C` | painel, separador, textura | substituir todos os biomas | AAA |
| `verde-mangue` | `#2F5D3A` | mangue, natureza, serviço regional | sucesso universal; pele | AA |
| `azul-agua` | `#1E6E7C` | rio, mar, rota marítima | perigo; facção sem metadata | AA |
| `vermelho-perigo` | `#C0392B` | risco, falha crítica, rota perigosa | recompensa; sangue-espetáculo | AA grande |
| `roxo-evento` | `#8E44AD` | evento e estado narrativo | gradiente neon; fundo dominante | AA grande |
| `ocre-terra` | `#8A5A2B` | madeira, barro, cais, roça | corpo de texto; substituir ouro | AA |

## 2.1 Regra 60/30/10

Toda tela usa:

- 60% `preto-tatame` ou área negativa equivalente;
- 30% neutros e bioma;
- 10% `ouro-cria` e destaques.

A regra vale para mapa, HUD, menus e Art Bible. Não é contagem pixel a pixel; é hierarquia perceptiva.

**Certo:** ouro conduz foco.  
**Errado:** tudo dourado, tudo saturado ou quatro cores competindo pela atenção.

## 2.2 Extensões

Uma cor nova exige:

1. token nomeado;
2. uso;
3. uso proibido;
4. contraste;
5. bump de versão;
6. changelog;
7. assets afetados.

Hex solto em cena é bloqueado.

---

# BLOCO 3 — TIPOGRAFIA

Existem quatro funções. Não existe quinta função sem bump de versão.

## 3.1 Logo

- `Cria Brush Custom`;
- é desenho, não fonte de sistema;
- não pode ser substituído por brush genérico.

## 3.2 Título e HUD

- `Saira Condensed` ou `Oswald`;
- peso 700;
- CAIXA ALTA;
- tracking `-2%`;
- skew visual `4°` quando o componente permitir.

## 3.3 Corpo

- `Hanken Grotesk` ou `Spline Sans`;
- pesos 400–500;
- mínimo mobile: 12 px.

## 3.4 Números

- `Saira` tabular ou `Space Mono`;
- números de barra: mínimo 14 px;
- alinhamento tabular obrigatório em placar, timer e recursos.

## 3.5 Regras

**Certo:** título condensado, corpo neutro, números estáveis.  
**Errado:** Inter, Roboto ou Arial como voz do jogo; serif para corpo; cinco famílias na mesma tela.

Fontes devem ser licenciadas e registradas no inventário. O protocolo não distribui arquivos de fonte.

---

# BLOCO 4 — ICONOGRAFIA

## 4.1 Glossário

| Ícone | Significado | Cor-base | Detalhe narrativo |
|---|---|---|---|
| losango | hub/seleção principal | `ouro-cria` | landmark municipal |
| coroa | torneio/chefão | `ouro-cria` | troféu, faixa, arquibancada |
| caveira | área perigosa | `vermelho-perigo` | sucata, ponte, mangue, mata |
| nota | evento cultural | `roxo-evento` | instrumento, bandeira, palco |
| punho | desafio | `ocre-terra` | pegada, faixa ou tatame; nunca soco |
| máscara | evento ritual revisado | `roxo-evento` | símbolo cultural validado |
| troféu | competição oficial | `ouro-claro` | placar ou medalha ficcional |
| cerejeira | treino nipo-baiano revisado | `roxo-evento` | árvore ou tecido |
| ferramentas | serviço/ferro-velho | `ocre-terra` | sucata ou ferramenta |
| cadeado | bloqueado | `cinza-grunge` | sem animação narrativa |

## 4.2 Estados

Todo nó declara:

- `completed`;
- `available`;
- `locked`;
- `boss`.

Estado não depende apenas de cor. Use forma, moldura e ícone.

## 4.3 Rotas

| Rota | Token | Tracejado | Significado |
|---|---|---|---|
| principal | `ouro-cria` | 8–4 | segura e principal |
| secundária/marítima | `azul-agua` | 6–4 | alternativa ou barco |
| perigosa | `vermelho-perigo` | 4–4 | risco narrativo |
| bloqueada | `cinza-grunge` | 2–6 | indisponível |

**Certo:** nó de Pancada Grande mostra cachoeira.  
**Errado:** nó genérico com caveira sem landmark.

---

# BLOCO 5 — COMPOSIÇÃO DE TELA

Toda tela de mundo usa grid de três trilhos e cinco zonas:

1. `Topbar`;
2. `LeftRail`;
3. `Center`;
4. `RightRail`;
5. `BottomBar`.

## 5.1 Função por zona

- **Topbar:** identidade, recursos, navegação global;
- **LeftRail:** objetivo, legenda ou filtros;
- **Center:** mundo, luta ou objeto principal;
- **RightRail:** detalhe do foco atual;
- **BottomBar:** comandos e ações contextuais.

O centro nunca desaparece.

## 5.2 Mobile

- rails colapsam para swipe horizontal;
- centro conserva pelo menos 50% da largura;
- máximo de três focos primários;
- uma ação principal por zona;
- touch target mínimo de 48 dp;
- safe area de 7%.

**Certo:** selecionar o nó abre detalhe sem cobrir o mapa.  
**Errado:** três cards iguais dominando o centro ou painel editorial cobrindo a luta.

---

# BLOCO 6 — HUD DE COMBATE

## 6.1 Quatro barras fixas

Sempre visíveis:

1. `GÁS`;
2. `CONTROLE`;
3. `PEGADA`;
4. `FLUXO`.

Contextuais ou condensados em ícone:

- vida;
- guarda;
- foco;
- moral;
- pontos;
- vantagens;
- penalidades.

A existência no sistema não obriga uma barra permanente.

## 6.2 Carta-botão

O botão **é** a carta. Não desenhar card e botão separados.

A carta contextual apresenta:

- ícone;
- família;
- custo;
- validade posicional;
- estado disponível/bloqueado;
- feedback de timing.

## 6.3 Arena card

Cada arena canônica possui quatro modificadores visuais. Eles descrevem regras já existentes nos dados; não criam mecânica por ilustração.

## 6.4 Timing

- `CEDO`;
- `PERFEITO`;
- `TARDE`.

## 6.5 Finalização

Fluxo:

```text
SETUP → LOCK → FINISH
```

O resultado lógico permanece:

- tap;
- escape;
- intervenção técnica.

`instant_finish` continua falso.

**Certo:** controle abre finalização e o HUD mostra progressão.  
**Errado:** barra de vida como condição central de vitória ou comandos de console no Android.

---

# BLOCO 7 — PIXEL ART E RENDER

## 7.1 Base

- canvas lógico: 640 × 360;
- referência de saída: 1280 × 720;
- filtro: `nearest`;
- escala inteira;
- pixel snap ligado;
- grade: 16 px;
- lutador de combate: 72 px de altura;
- contorno: 1 px;
- rim light: 1 px.

## 7.2 Profundidade 2.5D

Arte final continua 2D. Profundidade vem de:

- quatro paralaxes;
- cinco camadas lógicas;
- oclusão;
- sombra de contato;
- luz 2D;
- partículas;
- câmera.

## 7.3 Biomas

- mangue: `verde-mangue`, `azul-agua`, `ocre-terra`;
- rio: `azul-agua`, `verde-mangue`, `ocre-terra`;
- areia: `ocre-terra`, `ouro-claro`, `azul-agua`;
- mata: `verde-mangue`, `ocre-terra`, `cinza-grunge`;
- cais: `ocre-terra`, `cinza-grunge`, `azul-agua`;
- ginásio: `preto-tatame`, `cinza-grunge`, `ouro-cria`;
- roça: `ocre-terra`, `verde-mangue`, `ouro-claro`.

## 7.4 Luz

Três variantes:

- manhã: lateral limpa;
- tarde: quente, sombras longas;
- noite: contraste alto, fontes locais.

Luz só altera gameplay quando a arena declarar o efeito nos dados. A arte não inventa regra.

## 7.5 Orçamento mobile

- até 4 paralaxes;
- alvo ≤ 40 draw calls;
- ≤ 12 sprites animados de fundo;
- plateia em três estados: `idle`, `pressure`, `climax`;
- sombra de contato obrigatória;
- máscara de oclusão obrigatória.

**Certo:** plateia distante pré-renderizada e poucos loops próximos.  
**Errado:** 60 NPCs com animação individual ou blur para esconder pixel art inconsistente.

---

# BLOCO 8 — MOTION E FEEDBACK

| Evento | Duração | Ease | Resposta |
|---|---:|---|---|
| nó focado | 140 ms | out cubic | escala curta + ouro |
| rota disponível | 220 ms | in/out sine | pulso do tracejado |
| painel de detalhe | 180 ms | out quart | entrada lateral |
| fluxo cheio | 420 ms | in/out sine | pulso controlado |
| sucesso: hitstop | 70 ms | linear | pausa curta |
| sucesso: shake | 120 ms | out quad | deslocamento pequeno |
| sucesso: flash | 80 ms | out quad | branco-giz curto |
| falha | 90 ms | out expo | shake seco |
| troca de tela | 360 ms | in/out cubic | zoom do mapa |
| dia/noite/chuva | 900 ms | in/out sine | transição ambiental |

Feedback não pode:

- ocultar técnica;
- quebrar leitura;
- piscar sem perfil sensorial;
- ultrapassar o orçamento mobile;
- transformar falha em gore.

---

# BLOCO 9 — VOZ E TEXTO

## 9.1 Idioma

- português brasileiro revisado;
- oralidade baiana em NPCs quando coerente;
- “visse”, “oxente”, “bora”, “massa” e “tu é doido” são recursos, não caricatura;
- menus usam norma clara;
- fala preserva voz individual.

## 9.2 Nunca escrever

- marca real;
- pessoa real;
- liga real;
- facção real;
- “favela tropical genérica”;
- lesão como prêmio;
- violência como competência técnica;
- instituição pública real como patrocinadora;
- japonês sem significado validado.

**Certo:** “Bora, respira e firma a base, visse.”  
**Errado:** amontoar gíria em toda fala ou tratar tradição como magia genérica.

---

# BLOCO 10 — PROIBIÇÕES DURAS

Bloqueiam aprovação:

- gradiente índigo/violeta/rosa;
- glassmorphism de tela;
- Inter, Roboto ou Arial como voz;
- sistema creme + terracota + serif;
- fundo quase preto com um neon ácido dominante;
- três cards iguais em linha como layout principal;
- óculos com marca;
- japonês como manchete;
- controles de plataforma de console na HUD;
- Salvador, São Paulo ou Itacaré como nó jogável;
- arena desenhada como cidade;
- mulher sem função;
- arma como mecânica ou recompensa;
- fotografia ou 3D fotorrealista como arte final;
- MMA striking como núcleo;
- gore ou lesão celebrada.

---

# MANUTENÇÃO PERMANENTE

## M1 — Versionamento

Este documento abre sempre com:

- `version`;
- `last_reviewed`;
- `owner`;
- changelog.

Mudança em paleta, fonte, ícone, regra, proporção, HUD ou anatomia exige:

1. bump SemVer;
2. linha de changelog;
3. motivo;
4. lista de assets afetados;
5. atualização de `data/art_tokens.json`.

## M2 — Tokens

`data/art_tokens.json` é lido pelo validador e deve alimentar `Theme`, `ColorRect` e componentes futuros. Cena não inventa hex.

## M3 — CI

`tools/validate_art_protocol.py` valida o automatizável. O comando `npm run quality` fica vermelho em violação não excepcionada.

Legado só passa por exceção de migração:

- nomeada;
- justificada;
- limitada a caminho e regra;
- vinculada a marco de expiração.

## M4 — `/ARTE-CHECK <asset>`

Saída obrigatória:

```text
RESULTADO: PASS | FAIL
PROTOCOLO: 1.0.0
ASSET:
CLASSIFICAÇÃO:
VIOLAÇÕES:
CORREÇÕES:
CHECKS MANUAIS:
ESTADO MÁXIMO PERMITIDO:
```

Nunca aprovar por simpatia, esforço ou beleza isolada.

## M5 — `/ARTE-AMEND <mudança>`

Antes de aplicar:

- diff proposto;
- bump;
- changelog;
- justificativa;
- assets afetados;
- risco;
- rollback.

Só aplicar após confirmação explícita.

## M6 — Referências

README, Lore Guardian, contrato visual, contratos de arena e schema de HUD devem citar este protocolo. Contradição documental de execução visual é resolvida por este arquivo.

---

# CHECKLIST DE CONFORMIDADE POR ASSET

- [ ] Cores só via token nomeado (R1) e proporção 60/30/10 (R2)
- [ ] Fontes dentro das quatro funções (R3)
- [ ] Tela de mundo com cinco zonas (R4); HUD com quatro barras fixas (R5)
- [ ] Pixel art `nearest`, escala inteira, pixel snap e orçamento mobile (R6, R7)
- [ ] Nó com ícone, estado e detalhe narrativo (R8)
- [ ] Texto PT-BR; zero marca, pessoa, liga ou facção real (R9)
- [ ] Mascote dentro da anatomia congelada; óculos sem marca (R10)
- [ ] Nenhuma proibição do BLOCO 10 presente
- [ ] Mudança de regra acompanhada de version bump, changelog e motivo (M1)
- [ ] Origem, licença, metadata, QA e consumidor Godot registrados
- [ ] Aprovação humana e teste Android registrados quando aplicáveis
