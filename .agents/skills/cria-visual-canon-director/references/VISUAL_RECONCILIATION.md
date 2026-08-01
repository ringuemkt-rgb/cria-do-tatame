# Reconciliação Visual do Acervo — Cria do Tatame

**Status:** CANONICAL REFERENCE  
**Escopo:** imagens conceituais enviadas pelo criador até 2026-08-01.  
**Regra:** o acervo define direção e ambição; contratos e dados do repositório definem o conteúdo final.

## 1. Diagnóstico geral

O acervo possui qualidade alta de composição, identidade regional, silhueta e apresentação editorial. Ele mostra corretamente a ambição de um jogo premium de Jiu-Jitsu com personagens fortes, arenas memoráveis, facções, mapa regional e HUD expressivo.

O acervo não pode ser importado diretamente porque mistura:

- art bible;
- mockup promocional;
- HUD de console;
- tutorial;
- ficha de personagem;
- mapa conceitual;
- asset de arena;
- texto não revisado;
- marcas e instituições reais;
- técnicas de MMA ou violência incompatíveis com BJJ;
- geografias, nomes e faixas contraditórios.

A função desta reconciliação é preservar a direção artística e remover o que quebraria cânone, gameplay, licença, cultura, mobile ou runtime.

## 2. Decisão estrutural

### Preservar

- pixel art detalhada e expressiva;
- contraste preto/dourado;
- paletas próprias por personagem e arena;
- atmosfera regional do Baixo Sul;
- madeira, água, mangue, tatame e luz quente;
- pranchas editoriais como documentação e marketing;
- silhuetas fortes;
- cartões de técnica como linguagem de menu/codex;
- mapa regional ilustrado;
- arenas como personagens narrativos;
- facções com estandartes reconhecíveis.

### Converter

- profundidade 3D aparente → parallax e camadas 2D;
- HUD enciclopédico → HUD runtime reduzido + codex separado;
- combos de botões → cartas/comandos contextuais mobile;
- dano e destruição → gás, foco, controle, pontos e tap;
- mundo aberto contínuo → mapa por nós e hubs instanciados;
- técnica isolada → animação pareada atacante/defensor;
- marca real → marca ficcional;
- geografia estética → geografia canônica.

### Rejeitar

- fotografia ou render 3D como arte final;
- golpes de soco, joelhada ou cotovelada no núcleo de combate;
- técnica inventada não presente em `data/techniques.json`;
- pessoa real identificável;
- logotipo ou uniforme real sem licença;
- lesão celebrada;
- texto baked-in em sprite de runtime;
- estereótipo religioso, japonês, quilombola, policial ou regional;
- asset sem metadata, QA e consumidor Godot.

## 3. Logo oficial

### Valor do material

A logo do Silverback é memorável, possui leitura imediata e conecta força, disciplina, coroa, kimono e identidade do jogo.

### Preservar

- Silverback frontal;
- coroa dourada;
- kimono preto;
- anéis concêntricos;
- preto, branco e dourado;
- wordmark `CRIA DO TATAME`;
- linguagem esportiva premium.

### Corrigir

- remover/substituir o wordmark de terceiro nos óculos;
- produzir master transparente, monocromáticos, app icon, patch Gi, patch No-Gi e versão pixel small-size;
- não usar a logo de facção;
- manter `Ruan “Macacão” Silva` separado do título da marca.

### Fonte

`data/visual/brand_identity_v01.json`.

## 4. Fichas de personagem

As fichas de Leoa, Montenegro, Kenzo, Oni, Dendê, Jacaré, Ruan, Cássio, Davi e Guigo são excelentes como **Character Bible editorial**. Elas não são HUD de combate.

### Padrão aprovado

- retrato dominante;
- corpo inteiro;
- função narrativa;
- estilo de luta;
- atributos compactos;
- quatro técnicas e uma passiva apenas quando existentes no catálogo;
- linha de sprites;
- paleta individual;
- cenário de origem;
- frase curta;
- Gi/No-Gi explícito.

### Correções por personagem

#### Ruan

- nome obrigatório: **Ruan “Macacão” Silva**;
- origem: Ituberá;
- `Cria` pode aparecer como tratamento comunitário, nunca como apelido oficial no cabeçalho;
- aparência Gi/No-Gi muda por ruleset, não por inconsistência;
- faixa deve acompanhar o ato ou modo selecionado;
- estilo: pressão, pegada e top game;
- símbolo: Silverback.

#### Davi Relâmpago

- rival técnico do vertical slice;
- linguagem azul/elétrica aprovada;
- velocidade, antecipação e counter grappling;
- origem e faixa devem vir do dado canônico;
- não confundir com `davi_profeta_santos`.

#### Mestre Dendê

- mentor moral central;
- BJJ raiz, leitura, paciência e controle;
- definir uma única faixa/título no cânone;
- Capoeira Angola pode informar base, ginga e cultura, sem transformar o combate em capoeira;
- evitar sincretismo decorativo sem contexto.

#### Leoa Quilombola

- liderança, guarda, base e resistência aprovadas;
- cabelo e tranças são identidade visual e animação secundária, não arma;
- `Juba de Guerra` deve virar arm drag, quebra de postura ou tomada das costas;
- símbolos quilombolas exigem revisão cultural;
- evitar sexualização ou fantasia ancestral genérica.

#### Cássio “Molho”

- antagonista de hype e espetáculo;
- vermelho/laranja e energia de arena clandestina aprovados;
- remover joelhadas, socos ou dano contínuo;
- converter para snapdown, body lock, clinch, queda, pressão e controle;
- ameaça moral vem da transformação da luta em produto, não de violência ilegal.

#### Kenzo

- rival estrategista e finalizador;
- preto/vermelho, precisão e silêncio aprovados;
- remover linguagem de caricatura criminal japonesa;
- japonês deve ser semanticamente revisado;
- leg locks dependem de ruleset, faixa e catálogo;
- não copiar estética de organização real.

#### Oni

- rival pesado, defensivo e metódico;
- origem, nome e cenário precisam ser reconciliados antes da produção;
- não celebrar destruição articular;
- usar pressão, base e controle;
- visual demoníaco deve permanecer símbolo ficcional, não equivalência cultural.

#### Jacaré

- forte identidade de mangue e sobrevivência;
- pressão, arrasto, passagem e controle aprovados;
- remover a frase de que “não luta limpo”;
- lama e água podem afetar tração, nunca justificar golpe ilegal;
- frase recomendada: “Eu vim da lama, mas aprendi a lutar com respeito.”

#### Delegado Montenegro

- função narrativa de investigação/pressão institucional pode permanecer;
- remover `PF`, brasão, distintivo e uniforme reais;
- usar instituição inteiramente ficcional;
- não transformar contenção policial em espetáculo esportivo;
- como lutador, usar leitura, controle e defesa BJJ canônica.

#### Mestre Guigo

- treinador avançado de No-Gi/pressão no Ato 3;
- não substituir Dendê como mentor moral;
- leg locks somente conforme ruleset e progressão;
- escola e logotipo devem ser ficcionais.

## 5. Facções e estandartes

### Decisão final

- `ALE` — **Os Aleluiados**;
- `LEM` — Lá Ele Mil Vezes;
- `NTM` — Nós Tem Um Molho.

IDs e aliases não mudam.

### Estandarte ALE

Preservar pomba ficcional, halo, cruz abstrata, azul, branco e dourado. O texto visual deve ser `OS ALELUIADOS`.

A iconografia religiosa é ficcional. Não representar grupo religioso real como criminoso ou corrupto.

### Estandarte LEM

Preservar olho, mão, vermelho, roxo e dourado. O símbolo deve representar observação e informação, sem copiar ícone religioso ou esotérico real identificável.

### Estandarte NTM

Preservar pimenta, pilão, molho e paleta quente. A garrafa deve usar marca totalmente ficcional.

### Derivados obrigatórios

- estandarte completo;
- ícone 64 px;
- brasão 32 px;
- versão monocromática;
- banner de arena;
- badge de UI;
- variante de Cria Live.

## 6. Arenas

### Terreiro da Luta

**Aprovado como coração do jogo.**

Preservar madeira, rio, mangue, tatame azul/dourado, alunos, mestre, altar comunitário contextualizado e pôr do sol. Separar:

- hub navegável;
- cena de treino;
- arena de sparring;
- tela editorial da art bible.

Não sobrecarregar o runtime com todos os painéis vistos no mockup.

### Arena do Dique

Fonte canônica atual: `data/arenas.json` → Salvador, Bahia, circuito oficial.

Preservar ginásio, arquibancada, telão, mesas, árbitro e tatame azul/dourado. Corrigir:

- remover IBJJF/CBJJ e órgãos públicos reais;
- usar federação e patrocinadores ficcionais;
- não usar Prefeitura de Nilo Peçanha se a arena é Salvador;
- HUD oficial usa pontos, vantagens, punições e tempo de forma limpa;
- banners de facção são elementos de torcida, não patrocinadores institucionais.

### Budokan das Águas

Aprovado como arena de elite e precisão. Preservar água, madeira, silêncio, lanternas e geometria. Corrigir:

- localização deve vir do dado canônico, não da prancha;
- arquitetura é nipo-baiana ficcional, sem copiar templo real;
- água é atmosfera e risco controlado, não superfície absurda de lesão;
- japonês precisa de revisão humana.

### Zambiapunga

Aprovado como evento cultural de alto valor narrativo, condicionado a revisão cultural local. Preservar tambor, comunidade, fogo controlado e respeito. Proibir:

- caricatura ritual;
- máscara tratada como monstro genérico;
- uso da tradição como buff mágico sem contexto;
- mistura arbitrária com religiões ou entidades não relacionadas.

A arena deve comunicar festa, memória e comunidade, não “arena tribal”.

### Pancada Grande

A cachoeira pertence ao contexto de Ituberá/Baixo Sul. A prancha que a coloca na Chapada Diamantina está errada.

Como arena jogável, a superfície não deve ser uma cachoeira real perigosa. Usar uma plataforma ficcional segura, próxima à cachoeira, com água e respingos como atmosfera. Trava de gameplay:

- sem luta em rocha escorregadia letal;
- sem risco de queda real;
- modificadores sutis de foco/ambiente;
- segurança visual coerente com esporte.

### Manguezal Profundo, Pratigi e Ferro Velho

Manter como arenas distintas. Não duplicar nome ou localização. Cada uma precisa de ID, tipo, modificadores e layers vindos de dados.

## 7. HUD e combate

### O que as imagens acertam

- retratos fortes;
- barras com identidade;
- leitura de posição;
- contraste;
- tempo e pontos;
- destaque do atleta e da arena;
- sensação premium.

### O que deve ser separado

#### HUD runtime

Mostrar apenas informações necessárias para decidir:

- gás;
- controle posicional;
- foco/fluxo quando ativo;
- posição atual;
- tempo/pontos quando aplicável;
- mão de três cartas ou comandos contextuais;
- feedback curto de pegada/postura.

#### Tutorial/codex

Pode mostrar:

- vista superior;
- vista lateral;
- recompensas;
- riscos;
- explicação da posição;
- ícones e texto extenso.

#### Art bible

Pode manter pranchas densas, legendas, planta baixa, detalhes de arena e notas de design.

### Correções

- `HP` não é eixo principal de vitória;
- `moral` não deve ser uma barra permanente de luta sem contrato;
- comandos de controle físico não substituem cartas;
- `finalização` só habilita após posição e controle;
- nenhuma linguagem de “destruir joelho” ou “causar dano contínuo”;
- tocar/arrastar/segurar deve respeitar acessibilidade.

## 8. Mapas

Os mapas são aprovados como direção ilustrada. O runtime deve usar mapa regional por nós e rotas.

### Preservar

- hidrografia e costa como identidade;
- Ituberá como núcleo;
- rotas terrestres e marítimas;
- ícones de arena, treino, missão e serviço;
- sensação de Baixo Sul conectado.

### Corrigir

- não inventar pontes, ilhas ou distâncias como verdade geográfica;
- não deslocar Salvador para dentro do Baixo Sul;
- não duplicar Valença;
- não usar arte para decidir localização de arena;
- evitar mundo aberto contínuo 3D;
- o mapa do jogador deve refletir conteúdo realmente implementado.

## 9. Técnicas e pranchas de movimento

As pranchas de Silverback Grip, controle lateral, montada e demais sequências são úteis para:

- fases de animação;
- leitura de contato;
- pose-chave;
- explicação no codex;
- direção de câmera.

Elas não validam biomecânica por si só.

Toda técnica final deve:

- existir em `data/techniques.json`;
- ter estado de entrada e saída;
- usar atacante e defensor;
- possuir frame count igual;
- documentar pivô e sync markers;
- mostrar pegada antes de força;
- terminar em posição, tap, escape ou intervenção;
- passar revisão de praticante competente.

## 10. Gi e No-Gi

No-Gi não é apenas trocar kimono por rashguard.

A produção deve alterar:

- pegadas disponíveis;
- postura e pummeling;
- silhueta de roupa;
- atrito visual;
- efeitos sonoros;
- cartas válidas;
- animações que dependem de tecido.

O lote visual de No-Gi depende da integração funcional do ruleset. Não declarar jogável apenas porque a roupa existe.

## 11. Texto e linguagem

- português brasileiro revisado;
- nomes canônicos consistentes;
- evitar excesso de caixa alta em HUD;
- texto longo não entra em sprite;
- texto de marketing e art bible não deve ser confundido com runtime;
- japonês, símbolos religiosos e termos culturais exigem revisão específica;
- frases devem reforçar disciplina, leitura, respeito e comunidade.

## 12. Matriz de destino

| Material recebido | Destino correto | Pode entrar direto no runtime? |
|---|---|---|
| Logo Silverback | Fonte de marca + derivados limpos | Não, até limpeza jurídica e export final |
| Fichas de personagem | Character Bible | Não |
| Estandartes | Fonte para assets de facção | Não, produzir derivados |
| Fichas de arena | Arena Bible | Não |
| HUDs densos | Tutorial/codex/art bible | Não |
| Combates em tela | Direção de composição | Não |
| Mapas ilustrados | World Bible | Não |
| Terreiro explorável | Direção de hub | Não, exige cena e layers |
| Sequências de técnica | Storyboard/pose guide | Não, exige animação pareada |
| Sprites embutidos em prancha | Referência de escala/silhueta | Não, recortar não basta |

## 13. Ordem de produção coerente

1. logo comercialmente limpo e derivados;
2. Ruan Macacão — Gi e No-Gi;
3. Davi Relâmpago — Gi e No-Gi;
4. Arena do Dique;
5. Terreiro da Luta;
6. HUD de combate reduzido;
7. oito técnicas pareadas do vertical slice;
8. Submission HUD;
9. áudio e VFX;
10. APK em aparelho físico;
11. somente então outros personagens, arenas e mapa expandido.

## 14. Critério final

O material visual é coerente quando:

- a imagem reconhece o personagem, arena ou facção sem depender do texto;
- o estado visual corresponde ao estado lógico;
- o gameplay não foi inventado pela arte;
- o estilo é repetível por lote;
- o asset é legível no Android;
- a cultura é tratada com contexto e respeito;
- licenças estão claras;
- o Godot realmente consome o arquivo;
- o conjunto parece parte do mesmo jogo do começo ao fim.