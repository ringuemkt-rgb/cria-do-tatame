---
name: cria-visual-production-director
description: Audita, normaliza, especifica, produz e valida todo material visual do Cria do Tatame em pixel art 2D/2.5D, preservando cânone, BJJ posicional, GI/No-Gi, mobile-first, licenças e integração real no Godot.
version: 1.0.0
status: ACTIVE
project: ringuemkt-rgb/cria-do-tatame
language: pt-BR
---

# CRIA VISUAL PRODUCTION DIRECTOR — SKILL MESTRE

## 1. Missão

Transformar referências, concept arts, fichas, mapas, arenas, HUDs, personagens e animações do **Cria do Tatame** em um pipeline único, coerente e verificável, capaz de produzir assets finais para Godot sem deriva estética, narrativa, biomecânica, jurídica ou técnica.

Esta skill não existe para “fazer uma imagem bonita”. Ela existe para garantir que cada imagem:

1. pertença ao mesmo jogo;
2. respeite o cânone atual;
3. represente Jiu-Jitsu Brasileiro posicional;
4. seja legível em Android;
5. tenha função real no fluxo jogável;
6. possa ser reproduzida, auditada e integrada;
7. não use marcas, pessoas, ligas ou instituições reais sem licença;
8. não seja promovida de concept art para shipping sem QA humano e teste no Godot.

## 2. Ativação obrigatória

Ative esta skill quando a tarefa envolver qualquer um destes itens:

- personagem, retrato, model sheet ou expressão;
- sprite, spritesheet, animação, técnica pareada ou VFX;
- arena, cenário, hub, mapa, tile, prop ou iluminação;
- HUD, carta, menu, tela, ícone, emblema, estandarte ou logo;
- GI, No-Gi, faixa, rashguard, kimono, uniforme ou patch;
- concept art recebido do criador;
- prompt de geração de imagem;
- importação, normalização ou aprovação de asset;
- revisão visual, art bible, identidade regional ou material promocional.

## 3. Leitura obrigatória antes de agir

Leia nesta ordem:

1. `AGENTS.md`;
2. `docs/DECISIONS.md`;
3. `data/production/canon_contract_v4_1.json`;
4. `data/production/faction_migration_v4_2.json`;
5. `data/visual/visual_production_director_v1.json`;
6. `data/visual/production_manifest_v02.json`;
7. `docs/art_bible/VISUAL_RECONCILIATION_AND_PRODUCTION_STANDARD_V2.md`;
8. `data/techniques.json` para qualquer técnica;
9. `data/arenas.json` para qualquer local, arena ou texto geográfico;
10. contracts de GI/No-Gi presentes na branch ativa;
11. implementação consumidora real no Godot.

Concept art, mockup, prompt antigo e imagem isolada nunca superam contrato, dado ou runtime integrado.

## 4. Cânone visual congelado

### 4.1 Protagonista

- ID: `ruan_macacao`;
- nome: **Ruan “Macacão” Silva**;
- origem: Ituberá, Baixo Sul da Bahia;
- símbolo: Silverback;
- estilo: pressão pesada, pegada forte, domínio por cima;
- poder: Silverback Grip;
- frase: “Ser forte é ser gentil.”

É proibido publicar novo asset com `Ruan “Cria” Silva` como nome oficial. “Cria” pode aparecer apenas como tratamento comunitário ou marca do jogo quando o contexto deixar isso inequívoco.

### 4.2 Facções ativas

- `ALE`: **Os Aleluiados**;
- `LEM`: **Lá Ele Mil Vezes**;
- `NTM`: **Nós Tem Um Molho**.

IDs legados são aliases de migração e nunca criam facção adicional. Em estandartes, HUD, mapa, menu, cartas e concept art novo, use exatamente os nomes acima.

### 4.3 Núcleo de combate

- Jiu-Jitsu Brasileiro posicional;
- não é beat’em up;
- não é MMA;
- não é jogo de trocação;
- posição antes de submissão;
- finalizações terminam em tap, escape ou intervenção técnica;
- sem lesão celebrada, membro quebrado ou dor como recompensa;
- `instant_finish` permanece falso;
- técnicas vêm exclusivamente de `data/techniques.json`.

## 5. Doutrina gráfica oficial

### 5.1 Nome do estilo

**HD Painted Pixel Art 2D/2.5D Regional Premium**.

### 5.2 Aparência

- pixel clusters deliberados e legíveis;
- pintura rica sem perder a grade de pixel;
- contorno escuro firme;
- rim light seletivo de 1 px;
- volumes por blocos, não por blur;
- luz quente regional contrastada por azuis profundos;
- materiais reconhecíveis: madeira, palha, tatame, tecido, água, barro, metal e vegetação;
- atmosfera cinematográfica sem virar pintura digital lisa;
- perspectiva 2D com profundidade por camadas, parallax, escala e oclusão controlada;
- composição artesanal e regional, nunca “favela tropical” genérica.

### 5.3 Especificações runtime

- viewport de referência: `1280×720`;
- filtro: nearest;
- grid-base: 16 px;
- sprite de combate: aproximadamente 72 px de altura no frame lógico;
- célula de hub: 64 px;
- outline: 1 px na resolução lógica;
- rim light: 0–1 px;
- upscale apenas por escala inteira quando aplicável;
- sem anti-aliasing borrado;
- sem textura com ruído que destrua a leitura;
- ação principal legível a 25% do tamanho de apresentação.

Pranchas 1536×1536, posters e fichas densas são **art bible/marketing**, não resolução de sprite nem layout de HUD em tempo real.

## 6. Classificação obrigatória de referência

Cada imagem recebida deve ser classificada antes de ser usada:

1. `visual_north` — direção estética aprovada;
2. `canon_candidate` — ideia útil, ainda não canônica;
3. `production_brief` — descreve asset a produzir;
4. `runtime_mockup` — hipótese de tela, não implementação;
5. `art_bible_sheet` — ficha explicativa densa;
6. `asset_candidate` — arquivo candidato sujeito a normalização;
7. `shipping_asset` — somente após todos os gates.

Nunca trate uma ficha de personagem, mapa ilustrado ou HUD promocional como asset final apenas porque parece profissional.

## 7. Matriz de reconciliação do acervo recebido

### 7.1 Fichas de personagens

Usar como referência para:

- silhueta;
- paleta individual;
- roupa GI/No-Gi;
- expressão;
- papel narrativo;
- gesto de vitória;
- atmosfera de origem.

Não copiar automaticamente:

- nomes divergentes;
- faixas contraditórias;
- golpes de MMA;
- comandos X/Y/A/B;
- “dano” ou destruição de articulação;
- marcas, distintivos ou corporações reais;
- textos gerados com erros;
- técnicas ausentes de `data/techniques.json`.

### 7.2 Estandartes de facção

Aprovar a estrutura vertical, mosaico, tecido, moldura dourada e leitura por cor. Corrigir sempre:

- azul/branco/dourado: `OS ALELUIADOS`;
- vermelho/azul/dourado: `LÁ ELE MIL VEZES`;
- amarelo/azul/vermelho: `NÓS TEM UM MOLHO`.

Símbolos devem permanecer ficcionais e não reproduzir brasão, igreja, organização ou marca real.

### 7.3 Arenas e hubs

Usar como direção de:

- iluminação;
- camadas de profundidade;
- arquibancada e plateia;
- materiais;
- arquitetura;
- identidade local;
- props narrativos;
- variação manhã/tarde/noite/chuva.

Textos de município, estado, arena e evento só podem ser inseridos depois de conferidos em `data/arenas.json` e no contrato geográfico vigente. Se houver contradição, remova o texto da imagem e marque `pending_canon_location`.

### 7.4 Mapas

Aprovar como mapa regional de nós e rotas. Não interpretar como obrigação de mundo contínuo estilo GTA.

Modelo permitido:

- mapa regional ilustrado;
- hubs exploráveis;
- arenas instanciadas;
- rotas terrestres e fluviais;
- viagens e eventos representados por nós;
- zoom e filtros;
- sem simulação contínua de todas as cidades.

### 7.5 HUDs e combate

As imagens densas podem orientar tutorial, codex ou ficha técnica. O HUD runtime deve proteger a luta.

Persistentes recomendados:

- gás;
- controle posicional;
- fluxo/foco em forma compacta;
- tempo/pontos quando o ruleset exigir;
- mão de três cartas ou comandos contextuais do sistema ativo.

Vida, moral, guarda, foco, pegada, postura e vantagens não devem virar sete barras permanentes por atleta. Exiba apenas o que influencia a decisão imediata; o restante entra como ícone, estado contextual, painel temporário ou tela de pausa.

## 8. GI e No-Gi

GI e No-Gi não são simples troca de roupa.

### GI

- kimono com lapela, manga, tecido e faixa legíveis;
- pegadas de tecido somente quando a técnica permitir;
- deformação do tecido coerente com o contato;
- patch fictício e aprovado;
- sem logo de academia ou liga real.

### No-Gi

- rashguard e shorts sem tecido agarrável;
- grip de punho, cabeça, underhook, overhook, body lock e controle anatômico;
- silhueta mais limpa e leitura de membros reforçada;
- sem reutilizar animação de lapela/manga;
- sem transformar No-Gi em MMA.

Cada asset de técnica deve declarar `ruleset_compatibility` e variantes visuais necessárias.

## 9. Personagens — contrato de produção

Para cada personagem, produza nesta ordem:

1. ficha canônica textual aprovada;
2. seed frame em escala de jogo;
3. turnaround frontal, 3/4, lateral e costas;
4. paleta indexada;
5. expressões essenciais;
6. outfit GI;
7. outfit No-Gi quando aplicável;
8. idle aprovado;
9. strip completa por animação;
10. normalização de escala e âncora;
11. preview;
12. importação no Godot;
13. teste em cena real.

Não gere cada frame isoladamente. Gere a strip inteira a partir do seed aprovado, normalize com uma escala compartilhada e âncora bottom-center.

### Gate de personagem

- rosto reconhecível;
- massa corporal estável;
- altura e proporção constantes;
- mãos e pés legíveis;
- faixa correta por ato/ruleset;
- roupa sem mutação entre frames;
- nenhuma marca real;
- nenhuma arma;
- nenhum elemento de outro personagem;
- leitura clara no fundo escuro e claro.

## 10. Técnicas e animação pareada

Cada técnica visual é uma única unidade com atacante e defensor.

Arquivos mínimos:

```text
assets/techniques/<technique_id>/
  attacker/
  defender/
  reference/
  metadata.json
  sync_map.json
  hitbox.json
  preview.gif
  contact_sheet.png
  qa_report.md
```

Regras:

- mesmo frame count para atacante e defensor;
- pivô compartilhado;
- âncoras documentadas;
- contato visível antes de deslocamento;
- sem teleporte;
- sem clipping grave;
- direção da força legível;
- defesa reage no mesmo evento;
- posição visual final coincide com o estado lógico;
- setup, entrada, controle, estabilização e saída claramente marcados;
- tap, escape ou intervenção possuem animação própria;
- nenhum frame celebra lesão;
- câmera não esconde a pegada essencial.

GrappleMap, MediaPipe e vídeos licenciados são referência de pose e sequência, não autoridade automática de timing, biomecânica, Gi ou arte final.

## 11. Arenas — contrato de produção

Cada arena deve conter:

- `background_far`;
- `background_mid`;
- `playfield`;
- `foreground_occlusion`;
- `lighting_fx`;
- props interativos apenas se o runtime consumir;
- colisão;
- camera bounds;
- sombra de contato;
- pontos de áudio;
- orçamento móvel;
- variantes aprovadas.

### Regras de arena

- a área de luta deve permanecer clara;
- plateia e cenário não podem competir com os lutadores;
- elementos culturais devem ter contexto e respeito;
- fenômenos naturais não podem tornar BJJ biomecanicamente absurdo;
- piso escorregadio, água, barro ou pedra devem ser estilizados e controlados, nunca sugerir competição irresponsável;
- cards de arena alteram estratégia de forma moderada e nunca quebram clamp ou regra técnica;
- locais ritualísticos não são tratados como espetáculo exótico.

## 12. Mundo e hub

O Terreiro da Luta é o coração social e funcional.

O hub deve comunicar:

- treino;
- comunidade;
- mestre;
- origem;
- deck/progressão;
- missões;
- Cria Live;
- ligação com o mapa.

A câmera 2.5D deve usar parallax, oclusão e escala sem exigir navegação 3D. O mapa do Baixo Sul é uma interface regional por nós, não uma promessa de mundo contínuo integral.

## 13. UI/HUD mobile-first

- safe area mínima: 7%;
- touch target mínimo: 48 dp;
- centro e faixa inferior central do playfield protegidos;
- uma camada persistente principal e no máximo uma secundária compacta;
- lore, estatísticas longas e instruções extensas em drawer, codex, pausa ou tutorial;
- contraste mínimo forte sobre fundo em movimento;
- texto em português brasileiro revisado;
- não incorporar parágrafos dentro de sprites;
- reduced motion para efeitos não essenciais;
- feedback visual, sonoro e tátil para ação importante;
- HUD de combate não pode parecer dashboard administrativo.

## 14. Facções — linguagem visual

### ALE — Os Aleluiados

- azul profundo, branco e dourado;
- ordem, prestígio, fé ficcional e disciplina;
- pomba, halo e cruz abstrata somente em desenho original;
- evitar associação direta com igreja, denominação ou organização real.

### LEM — Lá Ele Mil Vezes

- vermelho, azul, roxo e dourado;
- observação, informação, provocação e psicologia;
- olho e mão abstratos;
- não usar simbologia religiosa/esotérica real de maneira literal.

### NTM — Nós Tem Um Molho

- amarelo, laranja, vermelho e azul;
- cultura popular, carisma, mídia e malícia;
- pilão, pimenta e molho ficcionais;
- sem marca de bebida ou alimento real.

## 15. Proibições visuais

Bloquear:

- `Ruan “Cria” Silva` como nome oficial;
- `Os Aleluia` ou `Os Aleluiado` em material novo;
- marcas Ray-Ban, IBJJF, CBJJ, Gracie, UFC, PF ou equivalentes sem licença;
- brasões de prefeitura, governo, polícia, federação ou academia real;
- pessoa real reconhecível;
- logos de patrocinadores reais;
- joelhada, soco, chute ou trocação como núcleo de carta;
- arma de fogo;
- gore;
- osso quebrado;
- submissão representada como mutilação;
- photorealismo;
- 3D genérico;
- cartoon infantil;
- anti-aliasing borrado;
- texto ilegível gerado por IA;
- cenário regional genérico sem pesquisa;
- UI console copiada sem adaptação touch;
- frames gerados isoladamente sem seed e normalização;
- promoção automática de saída de IA.

## 16. Modos operacionais

### `/auditar`

Classifica referências, identifica conflitos, risco legal, função provável e estado de produção.

### `/canonizar`

Transforma ideia aprovada em contrato textual/dado, sem gerar asset até resolver conflitos.

### `/personagem`

Produz brief, turnaround, seed, paleta, outfit e plano de animação.

### `/animacao`

Produz strip inteira, metadata, sync map, contatos, preview e QA.

### `/arena`

Produz composição por camadas, playfield, props, luz, áudio, câmera e orçamento mobile.

### `/mapa`

Produz mapa regional por nós/rotas, ícones e regras de navegação.

### `/hud`

Separa art bible, tutorial e runtime; reduz informação e protege o playfield.

### `/faccao`

Produz estandarte, emblema, paleta, aplicações e teste de leitura pequena.

### `/prompt`

Gera prompt autônomo com cânone, escala, seed, proibições, layout e critérios de QA.

### `/integrar`

Cria metadata, importa no Godot, liga consumidor real e atualiza catálogo.

### `/qa`

Executa os gates automáticos e produz relatório de aprovação/reprovação.

## 17. Fluxo de trabalho obrigatório

```text
pedido
→ leitura do cânone
→ classificação da referência
→ matriz de conflitos
→ função real no jogo
→ brief aprovado
→ seed aprovado
→ produção em lote
→ normalização
→ QA técnico
→ QA canônico/legal
→ import Godot
→ teste em cena
→ teste Android
→ aprovação humana
→ shipping
```

Não pule etapas. Quantidade de imagens não compensa falta de integração.

## 18. Quality score

Todo candidato recebe 0–100:

- cânone: 20;
- coerência técnica de BJJ: 15;
- silhueta/leitura: 15;
- consistência entre frames: 15;
- integração/metadata: 10;
- mobile/performance: 10;
- regionalidade respeitosa: 5;
- acessibilidade: 5;
- licença/origem: 5.

Regras:

- mínimo geral para candidato aprovado: 90;
- cânone, licença e biomecânica devem ter nota integral;
- qualquer blocker reprova independentemente da soma;
- shipping exige aprovação humana e teste em aparelho físico.

## 19. Status permitidos

- `reference_only`;
- `canon_pending`;
- `brief_approved`;
- `seed_approved`;
- `candidate_generated`;
- `normalized`;
- `qa_passed`;
- `integrated`;
- `device_tested`;
- `shipping_approved`;
- `rejected`;
- `archived`.

Nunca use “final” sem `shipping_approved`.

## 20. Saída obrigatória da skill

Cada execução deve informar:

1. **Fonte e classificação** — o que foi recebido e como será usado;
2. **Cânone aplicado** — nomes, IDs, ruleset, localização e técnica;
3. **Correções** — tudo que foi descartado ou adaptado;
4. **Brief de produção** — dimensões, camadas, frames, paleta e consumidor;
5. **Arquivos** — candidatos, metadata, previews e relatórios;
6. **Integração** — cena, script, catálogo ou UI consumidora;
7. **QA** — gates executados e evidências;
8. **Riscos** — licença, biomecânica, performance e pendências humanas;
9. **Próximo lote** — menor passo vertical de maior valor.

## 21. Condições de parada

Pare e registre bloqueio quando:

- nome, origem, faixa, facção ou localização estiverem conflitantes;
- a técnica não existir no catálogo;
- GI/No-Gi não estiver definido;
- não houver seed aprovado;
- a referência contiver marca/pessoa real sem licença;
- o asset depender de texto gerado ilegível;
- a animação pareada não tiver defensor;
- não houver consumidor real;
- a performance mobile não puder ser avaliada;
- o pedido exigir rebaixar o padrão abaixo do contrato visual.

Entregue apenas a parte segura. Nunca invente aprovação, integração, teste ou licença.
