# VISUAL RECONCILIATION AND PRODUCTION STANDARD V2

**Status:** ACTIVE  
**Atualizado:** 2026-08-01  
**Autoridade operacional:** `.agents/skills/cria-visual-production-director/SKILL.md`  
**Contrato executável:** `data/visual/visual_production_director_v1.json`

## 1. Objetivo

Este documento consolida a revisão do material visual fornecido pelo criador e define como cada referência deve ser adaptada para o jogo real. O propósito é impedir que concept arts excelentes gerem um produto incoerente, pesado, juridicamente arriscado ou desconectado do runtime Godot.

A qualidade-alvo é a mostrada nas melhores imagens recebidas: pixel art 2D de alto detalhe, iluminação rica, personagens legíveis, cenários regionais e UI premium. O jogo, porém, deve atingir esse padrão por meio de assets produzidos para escala de runtime, não por posters estáticos ou telas sobrecarregadas.

## 2. Diagnóstico do acervo

O material recebido pode ser dividido em sete grupos:

1. fichas de personagens;
2. estandartes de facção;
3. fichas de arenas;
4. cenas de combate;
5. Terreiro/hub;
6. mapas regionais;
7. guias de técnicas e animações.

### 2.1 Pontos fortes recorrentes

- direção de arte forte e reconhecível;
- paleta preto/dourado/azul com variações por personagem e facção;
- excelente sensação de mundo regional;
- boa leitura de silhuetas;
- arenas com identidade própria;
- riqueza de materiais e iluminação;
- personagens com função narrativa aparente;
- integração visual entre cenário, HUD e lore;
- potencial para marketing, art bible e pitch.

### 2.2 Problemas recorrentes

- uso de `Ruan “Cria” Silva` em vez de Ruan “Macacão” Silva;
- variações `Os Aleluia`, `Os Aleluiado` e `Os Aleluiados`;
- nomes de municípios e arenas conflitantes;
- mistura entre BJJ, MMA, wrestling de entretenimento e combate de rua;
- comandos X/Y/A/B incompatíveis com o sistema de cartas mobile;
- HUD com seis ou sete barras persistentes;
- marcas, brasões, polícias, ligas e academias reais;
- finalizações descritas como destruição física;
- fichas densas tratadas como se fossem telas runtime;
- mundo aberto contínuo sugerido por mapas que devem ser interfaces por nós;
- roupas GI/No-Gi usadas sem diferenças técnicas;
- texto incorporado à imagem com erros ou baixa legibilidade;
- animações representadas por poucos quadros sem contrato de sincronização.

## 3. Decisões consolidadas

### 3.1 Protagonista

Use sempre:

```text
Ruan “Macacão” Silva
```

“Cria” é marca, tratamento comunitário ou título do jogo. Não é o apelido oficial do protagonista.

### 3.2 Facções

Use exatamente:

```text
ALE — Os Aleluiados
LEM — Lá Ele Mil Vezes
NTM — Nós Tem Um Molho
```

O ID legado `os_aleluia` permanece somente como alias de migração.

### 3.3 Mapa

O mundo é regional e navegável, mas deve ser implementado como:

- mapa ilustrado do Baixo Sul;
- nós de localidade;
- hubs exploráveis;
- arenas instanciadas;
- rotas terrestres e fluviais;
- eventos e deslocamento entre nós.

As imagens não autorizam transformar o projeto em um mundo 3D contínuo.

### 3.4 Combate

O combate visual deve representar:

- clinch;
- queda;
- guarda;
- meia-guarda;
- passagem;
- controle lateral;
- joelho na barriga;
- montada;
- costas;
- tartaruga;
- 50/50 quando autorizado;
- finalização;
- escape;
- tap/intervenção.

Golpes de trocação, joelhadas e ataques de rua não entram como cartas canônicas.

## 4. Revisão por grupo de referência

## 4.1 Fichas de personagens

### Leoa Quilombola

**Preservar:**

- paleta vermelha, dourada e preta;
- presença de liderança;
- tranças como elemento de silhueta;
- No-Gi regional;
- força, base e ancestralidade.

**Corrigir:**

- cabelo não é arma;
- “Juba de Guerra” deve virar arm drag, entrada de costas ou finta visual;
- técnicas precisam existir no catálogo;
- evitar transformar ancestralidade em poder mágico literal.

### Delegado Montenegro

**Preservar:**

- leitura fria;
- postura de controle;
- papel investigativo e pressão institucional.

**Corrigir:**

- remover Polícia Federal, PF, brasão, distintivo e helicóptero identificáveis;
- criar agência totalmente ficcional;
- não usar algema como técnica esportiva;
- personagem deve atuar prioritariamente na narrativa, não como tutorial de contenção policial.

### Kenzo

**Preservar:**

- precisão silenciosa;
- preto, vermelho e dourado;
- elegância de movimento;
- ameaça técnica.

**Corrigir:**

- evitar caricatura de máfia japonesa;
- organização e símbolos devem ser ficcionais;
- finalizações devem terminar em tap/intervenção;
- nome completo e origem devem vir do cânone de personagens.

### Oni do Sul

**Preservar:**

- massa corporal;
- defesa;
- pressão fria;
- paleta azul/vermelha;
- presença de boss.

**Corrigir:**

- cenário de neve só entra se a origem justificar;
- “destruir joelhos” é proibido;
- kneebar deve ser técnica regulamentada por ruleset/faixa;
- evitar armadura que comprometa leitura anatômica.

### Mestre Milson Dendê

**Preservar:**

- mentor central;
- BJJ raiz;
- capoeira angola como influência corporal/cultural;
- verde, dourado, branco e madeira;
- serenidade e leitura.

**Corrigir:**

- faixa deve ser única e canônica;
- não transformar a capoeira em golpe de trocação no combate BJJ;
- ambiente ritual deve ser respeitoso e não genérico.

### Jacaré do Mangue

**Preservar:**

- silhueta pesada;
- identidade do mangue;
- humor e intimidação;
- verde, barro e água.

**Corrigir:**

- “não luto limpo” não pode ser eixo positivo;
- lama é atmosfera e terreno moderado, não desculpa para ilegalidade;
- reduzir linguagem de dano e aumentar controle/pressão.

### Ruan

**Preservar:**

- pele, cabelo, massa atlética e identidade baiana;
- Silverback;
- pressão e mobilidade controlada;
- GI e No-Gi;
- verde/preto/dourado quando No-Gi.

**Corrigir:**

- nome oficial para Macacão;
- faixa varia por ato, não de forma aleatória;
- heel hooks e leg locks dependem de faixa/ruleset;
- “explosão” não pode quebrar clamp ou posição.

### Cássio Molho

**Preservar:**

- vermelho/preto;
- showman;
- hype;
- provocação e carisma.

**Corrigir:**

- remover joelhada;
- “clinch sujo” vira snapdown, body lock ou quebra de base;
- fama não produz dano mágico;
- evitar marcas ou corrente como mecânica.

### Davi Relâmpago

**Preservar:**

- azul/branco;
- velocidade;
- leitura;
- contra-ataque técnico;
- rivalidade direta com Ruan.

**Corrigir:**

- manter separado de qualquer Davi Profeta;
- origem e faixa precisam ser fixadas por ato;
- eletricidade é linguagem de VFX, não poder sobrenatural literal.

### Mestre Guigo

**Preservar:**

- roxo/preto;
- pressão No-Gi;
- papel de técnico avançado;
- leg drag e over-under.

**Corrigir:**

- não competir com Dendê como mentor moral;
- marca da escola deve ser ficcional;
- leg locks dependem de ruleset e progressão.

## 4.2 Estandartes

A composição com três banners é aprovada como norte visual.

### Os Aleluiados

- fundo azul;
- branco e dourado;
- pomba ficcional;
- halo abstrato;
- cruz abstrata;
- texto exato `OS ALELUIADOS`.

### Lá Ele Mil Vezes

- vermelho, azul, roxo e dourado;
- olho e mão abstratos;
- leitura mística e psicológica;
- sem símbolo religioso real.

### Nós Tem Um Molho

- amarelo, laranja, vermelho e azul;
- pilão, pimenta e molho;
- sem marca de bebida, molho ou patrocinador real.

## 4.3 Arena do Dique

O material mostra versões incompatíveis: Nilo Peçanha, Salvador e arena comunitária.

Regra de produção:

- o asset não recebe texto de cidade até `data/arenas.json` confirmar;
- a arena oficial e a arena comunitária devem ter IDs diferentes se ambas existirem;
- patrocinadores, prefeitura, CBJJ, IBJJF e órgãos públicos são substituídos por entidades ficcionais;
- arbitragem e placar podem existir como sistemas originais;
- o playfield deve permanecer limpo.

## 4.4 Budokan das Águas

Aprovar:

- madeira escura;
- água ao redor;
- iluminação noturna;
- silêncio e precisão;
- 2.5D com reflexos controlados.

Corrigir:

- símbolos japoneses precisam ser verificados linguisticamente;
- evitar templo genérico ou exotização;
- água não invade o tatame;
- piso e regras devem permitir BJJ seguro.

## 4.5 Zambiapunga

Aprovar:

- fogo, tambor, máscaras, comunidade e energia noturna como atmosfera;
- sensação de evento cultural vivo;
- presença de público e musicalidade.

Corrigir:

- não usar o ritual como “arena selvagem”;
- consultar referências culturais confiáveis;
- separar apresentação cultural da luta;
- não inventar símbolo sagrado;
- evitar texto que reduza tradição a buff mágico.

## 4.6 Terreiro da Luta

Aprovar como hub principal.

Deve concentrar:

- Dendê;
- Tinker;
- treino;
- deck;
- mapa;
- missões;
- comunidade;
- progressão;
- história.

A versão runtime deve reduzir a quantidade de NPCs e efeitos conforme orçamento mobile, preservando profundidade por camadas.

## 4.7 Pancada Grande

A cachoeira é visualmente forte, mas a luta sobre rocha molhada não deve ser tratada como competição oficial realista.

Uso seguro:

- treino narrativo estilizado;
- desafio simbólico;
- playfield seco ou plataforma preparada;
- respingos e água em segundo plano;
- sem escorregões violentos como recompensa.

## 4.8 Combate na Arena do Dique

A imagem de Ruan × Davi é o melhor norte de enquadramento e qualidade.

Preservar:

- câmera lateral baixa;
- sprites grandes;
- plateia profunda;
- foco no contato;
- luz do ginásio;
- HUD compacto no topo e ações contextuais embaixo.

Corrigir:

- remover brasões e marcas reais;
- não usar seis barras persistentes;
- substituir comandos de controle por cartas/ações compatíveis com mobile;
- status de pegada e postura devem ser contextuais.

## 5. Separação entre art bible e runtime

| Tipo | Pode ser denso? | Pode conter texto longo? | Entra direto no jogo? |
|---|---:|---:|---:|
| Ficha de personagem | Sim | Sim | Não |
| Ficha de arena | Sim | Sim | Não |
| Poster promocional | Sim | Limitado | Não |
| HUD runtime | Não | Não | Sim |
| Sprite | Não | Não | Sim |
| Mapa regional | Moderado | Curto | Sim |
| Tutorial/codex | Sim | Sim | Sim, fora da luta |
| Spritesheet | Não | Não | Sim |

## 6. Padrão técnico de pixel art

### 6.1 Personagens

- frame lógico alinhado à grade;
- altura aproximada de 72 px em combate;
- outline de 1 px;
- sombras em clusters;
- rosto simplificado, mas reconhecível;
- mãos ampliadas somente o necessário para leitura de pegadas;
- pés com contato claro no chão;
- sem subpixel no sprite final.

### 6.2 Arenas

- cinco camadas principais;
- parallax moderado;
- oclusão frontal limitada;
- plateia animada por ciclos simples e variações;
- iluminação separada do background quando possível;
- colisão e camera bounds documentadas;
- props com atlas compartilhado.

### 6.3 UI

- safe area de 7%;
- touch target de 48 dp;
- fonte bitmap ou renderização nítida;
- contraste suficiente;
- não cobrir centro do combate;
- detalhes longos em pausa/tutorial;
- ícones testados em 24–32 px.

## 7. Pipeline de personagem

```text
canon textual
→ seed de escala real
→ turnaround
→ paleta
→ outfit GI/No-Gi
→ idle
→ strip completa
→ normalização
→ preview
→ import Godot
→ teste de cena
```

Frame-by-frame independente é rejeitado.

## 8. Pipeline de técnica pareada

```text
technique_id válido
→ entrada/saída lógica
→ referência biomecânica
→ key poses
→ strip atacante+defensor
→ sync_map
→ hitbox/contact map
→ preview
→ QA
→ AnimationPlayer
→ smoke visual
```

## 9. Pipeline de arena

```text
arena_id válido
→ localização confirmada
→ moodboard licenciado
→ layout do playfield
→ cinco camadas
→ props
→ luz
→ colisão/câmera
→ áudio
→ montagem Godot
→ perfil mobile
```

## 10. Quality gates

### Blockers automáticos

- nome canônico incorreto;
- facção incorreta;
- técnica ausente do catálogo;
- marca real;
- ruleset incompatível;
- defensor ausente;
- frame count divergente;
- textura filtrada;
- asset sem metadata;
- sem consumidor real;
- texto geográfico não autorizado;
- promoção automática de saída de IA.

### Aprovação humana

- rosto;
- silhueta;
- regionalidade;
- respeito cultural;
- biomecânica;
- sensação de peso;
- legibilidade mobile;
- qualidade de animação;
- ausência de estereótipos.

## 11. Prioridade de produção

### Lote 1 — Vertical slice ouro

- Ruan Macacão;
- Davi Relâmpago;
- Terreiro da Luta;
- Arena do Dique canônica;
- 8 técnicas pareadas;
- HUD mobile reduzido;
- tela de resultado;
- mapa mínimo;
- áudio representativo.

### Lote 2 — identidade do mundo

- Dendê;
- Tinker;
- estandartes das três facções;
- mapa regional;
- Cria Live;
- Zambiapunga;
- Budokan das Águas.

### Lote 3 — elenco expandido

- Leoa;
- Cássio;
- Kenzo;
- Jacaré;
- Oni;
- Guigo;
- Montenegro narrativo.

## 12. Definition of Done visual

Um asset só está pronto quando:

- o ID existe;
- o brief foi aprovado;
- origem/licença foram registradas;
- o arquivo foi normalizado;
- o preview foi revisado;
- metadata e hash existem;
- o validator passou;
- o Godot importou;
- uma cena consumidora foi testada;
- o Android físico foi avaliado quando aplicável;
- o criador aprovou o resultado.

Sem esses itens, o asset permanece candidato.
