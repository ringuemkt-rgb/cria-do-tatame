# Cria do Tatame — Visual Target V10

## Status

Este documento transforma as referências visuais aprovadas em contrato de produção para Godot 4.3+, Android ARM64 e Windows x86_64.

A referência final não é uma imagem isolada. É um sistema coerente com seis famílias de tela:

1. mapa mundial interativo;
2. hub explorável 2.5D;
3. combate lateral tático;
4. Cria Live + facções + árvore de habilidades;
5. fichas técnicas de arenas/personagens;
6. marca Gorila Silverback preto/dourado.

## 1. Diagnóstico do material atual

### Pontos fortes aprovados

- Identidade imediatamente reconhecível: preto, dourado queimado, branco sujo, azul profundo e acentos de facção.
- Mapa do Baixo Sul funciona como tela de decisão, não apenas ilustração.
- Combate mostra posição, controle, pegada, gás, foco, moral e contexto de comandos.
- Hub de Ituberá comunica vida cotidiana, comércio, academia, missões e conexão com o mangue.
- Cria Live conecta reputação, patrocinadores, facções, crises e skill tree em uma camada social única.
- Arenas possuem modificadores visuais e mecânicos próprios.
- A marca do Gorila Silverback cria unidade entre HUD, roupas, logo, menus e progressão.

### Problemas a eliminar

- Textos pequenos demais para Android.
- Excesso de informação simultânea sem hierarquia.
- Mockups com marcas reais, nomes institucionais reais ou geografias inconsistentes.
- Alternância indevida entre “Ruan Cria”, “Ruan Macacão”, “Rafa do Tatame” e outros placeholders.
- Imagens conceituais tratadas como se já fossem sprites, tiles ou cenas jogáveis.
- Ilustrações muito pintadas sem grade, pivô e recorte técnico.
- Controles de console exibidos em telas mobile.

## 2. Canon visual obrigatório

| Item | Contrato |
|---|---|
| Protagonista | Ruan “Macacão” Silva |
| Símbolo | Gorila Silverback coroado |
| Frase | Ser forte é ser gentil. |
| Engine | Godot 4.3+ |
| Plataformas | Android ARM64 e Windows x86_64 |
| Estilo | HD Pixel Art 2.5D Regional Premium |
| Resolução-base | 1280×720, escala responsiva |
| Grade | 16 px |
| Sprite de combate | 72 px de altura-base |
| Sprite de hub | célula 64×64, oito direções |
| Filtro | nearest |
| Contorno | 1 px externo escuro |
| Rim light | 1 px interno colorido |

## 3. Linguagem visual

### Paleta central

- `#080A0D` — preto oceânico, fundo principal.
- `#11151B` — preto fosco, painéis.
- `#201B14` — carvão quente, madeira e cards.
- `#B8860B` — dourado queimado, molduras.
- `#F2C230` — amarelo honra, seleção e vitória.
- `#E8DFD0` — branco sujo, texto principal.
- `#1E3A5F` — azul rio profundo, água e circuito oficial.
- `#2D5016` — verde mangue, raiz e recuperação.
- `#D92323` — vermelho conflito, dano e crise.
- `#4B0082` — roxo sombra, dualidade e Kuroi Mizu.
- `#09A8C8` — ciano técnico, controle e UI de posição.

### Materiais

- metal escovado e ferrugem nas arenas clandestinas;
- madeira gasta e tecido de gi no Terreiro;
- água, lama e reflexos no mangue;
- concreto, cartazes e luz urbana nos hubs;
- moldura preta com filete dourado em todas as telas sistêmicas;
- ruído e pincel seco apenas como textura de apoio, nunca prejudicando leitura.

### Tipografia

- Títulos: condensada, pesada, esportiva.
- Dados e HUD: sans-serif estreita e altamente legível.
- Corpo: sans-serif simples.
- Em runtime, não embutir texto em imagens.
- Tamanho mínimo Android: 16 px para texto principal e 18–22 px para valores críticos.

## 4. Família 1 — Mapa mundial

### Estrutura

- mapa isométrico/top-down ocupa 65–72% da largura;
- painel de objetivo à esquerda;
- ficha do local selecionado à direita;
- barra superior com personagem, nível, XP, dinheiro, energia, fadiga e reputação;
- barra inferior com ações;
- rotas terrestres, marítimas e bloqueadas visualmente distintas;
- ícones de risco, torneio, missão, treino e boss.

### Regras de gameplay

- Ituberá permanece hub central.
- Cada viagem mostra custo em tempo, energia e risco antes da confirmação.
- Fog of war esconde locais sem quebrar a geografia.
- Facção dominante muda cor de borda, NPCs, eventos e recompensas.
- O mapa nunca usa cidades ou rios em posição falsa apenas para “ficar bonito”.

## 5. Família 2 — Hub explorável

### Câmera

- top-down/2.5D com personagens proporcionais;
- leitura clara dos caminhos;
- minimapa no canto superior direito;
- câmera acompanha o jogador com suavização curta;
- interiores podem aproximar a câmera sem mudar a escala do personagem.

### HUD

- retrato, nível e três recursos principais no topo esquerdo;
- missão ativa abaixo;
- localização, horário e clima no topo direito;
- botões touch no canto inferior direito;
- textos e marcadores nunca cobrem NPCs importantes.

### Ituberá

- academia, mercado, cais, bar, clínica/recuperação e quadro de missões;
- casas coloridas, vegetação tropical, drenagem, madeira, mangue e rio;
- moradores com rotinas;
- ciclos manhã/tarde/noite/chuva;
- o Terreiro evolui visualmente conforme o Legado.

## 6. Família 3 — Combate lateral tático

### Composição

- lutadores ocupam o centro e permanecem sem obstrução;
- HUD espelhado no topo;
- timer e round no centro;
- controle e grip nas laterais inferiores;
- comandos contextuais no rodapé;
- estado posicional sempre visível.

### Recursos visuais

- HP: verde/vermelho conforme risco;
- Gás: azul;
- Foco: amarelo/roxo;
- Moral: ícone + texto curto;
- Controle: ciano com escala percentual;
- Grip Integrity: branco/cinza com alerta dourado/vermelho;
- Guarda/Postura: escudo e segmentos.

### Contexto de comandos

O comando muda pela posição:

- em pé: medir, jab, defesa, clinch, queda;
- clinch: pummeling, quebra de postura, defesa de pegada, projeção;
- chão por cima: pressão, passagem, montada, costas, finalização;
- chão por baixo: guarda, raspagem, recomposição, escape, finalização;
- encerramento: setup, lock, finish, ajuste, soltar.

### Feedback

- hitstop curto apenas em quedas, defesas perfeitas e transições críticas;
- câmera aproxima em finalizações sem perder a leitura do corpo;
- partículas separadas por layer;
- vibração mobile configurável;
- instruções descrevem função de jogo, não dano real.

## 7. Família 4 — Cria Live, facções e skill tree

### Layout desktop/tablet

- coluna esquerda: feed e personagens;
- topo central: patrocinadores e contratos;
- topo direito: crises e mapa de influência;
- centro inferior: Ruan e quatro ramos da árvore;
- rodapé: navegação principal.

### Layout Android

A tela deve ser dividida em abas:

1. Feed;
2. Contratos;
3. Facções;
4. Habilidades;
5. Crises.

Nunca reproduzir todo o dashboard desktop em uma tela pequena.

### Ramos da árvore

- Técnica — azul.
- Pressão — vermelho.
- Frieza — verde/ciano.
- Legado — roxo/dourado.

Cada nó exibe ícone, custo, faixa requerida, efeito e conexão. Nós bloqueados ficam dessaturados, sem perder contraste.

## 8. Família 5 — Fichas técnicas de arena

As fichas ilustradas são documentos internos, não telas de runtime.

Cada arena deve possuir:

- vista principal;
- mockup de gameplay;
- detalhes de piso, props, luz e público;
- quatro variações de iluminação quando aplicável;
- grupos de NPC;
- modificadores;
- risco de lesão gamificado;
- paleta;
- mapa de colisão;
- limites de câmera;
- layers de parallax;
- pacote de áudio.

## 9. Família 6 — Marca Gorila Silverback

### Usos corretos

- tela inicial;
- ícone do aplicativo;
- patch do gi/rashguard;
- indicador de habilidade Silverback Grip;
- troféu e emblema de legado;
- elementos de moldura.

### Limites

- o gorila é símbolo, não personagem jogável;
- evitar aparência infantil ou de mascote cômico;
- não usar óculos/marca comercial real;
- criar design próprio de óculos dourados;
- não inserir kanji sem revisão cultural.

## 10. Arquitetura de assets

```text
assets/
├── brand/
├── characters/
│   └── <character_id>/
│       ├── concept/
│       ├── raw/
│       ├── clean/
│       ├── frames/
│       ├── sheets/
│       ├── previews/
│       └── metadata/
├── arenas/
│   └── <arena_id>/
│       ├── layers/
│       ├── props/
│       ├── tiles/
│       ├── collision/
│       ├── lighting/
│       └── previews/
├── ui/
│   ├── icons/
│   ├── panels/
│   ├── buttons/
│   ├── portraits/
│   └── themes/
├── vfx/
└── audio/
```

## 11. Quality gates

### Visual

- silhueta legível a 25% da escala;
- nenhuma borda borrada;
- nenhuma mudança de altura entre frames;
- pivô estável;
- cores dentro da paleta;
- sem texto gerado por IA em sprites;
- sem marcas reais;
- sem geografia inventada tratada como oficial.

### Runtime

- tela legível em 1280×720;
- safe area de 7% no Android;
- botões touch com 80 px mínimos na resolução-base;
- UI não cobre o corpo dos lutadores;
- 30 FPS mínimo em aparelho de entrada;
- 60 FPS alvo em aparelho intermediário/PC;
- queda de qualidade automática para partículas, luzes e parallax.

### Entrega por asset

Obrigatório:

- `raw_sheet.png`;
- `clean_sheet.png`;
- `spritesheet.png`;
- `frames/`;
- `preview.gif`;
- `contact_sheet.png`;
- `metadata.json`;
- `import_notes.md`;
- `qa_report.md`.

Técnica pareada também exige atacante, defensor, `sync_map.json` e `hitbox.json`.

## 12. Ordem de implementação

1. design tokens e temas;
2. Main Menu;
3. HUD de combate;
4. World Map;
5. Hub Ituberá/Terreiro;
6. Cria Live mobile;
7. Skill Tree;
8. Arena Dique final;
9. Ruan e Davi finalizados;
10. expansão para demais personagens e arenas.

## 13. Definition of Done visual V10

A direção V10 só está implantada quando:

- as cinco telas principais usam o mesmo design system;
- o protagonista aparece somente como Ruan “Macacão” Silva;
- o mapa é navegável e data-driven;
- o hub é explorável;
- o combate mostra recursos e comandos contextuais;
- o Cria Live funciona em abas no Android;
- ao menos Ruan, Davi, Terreiro e Arena do Dique possuem assets finais importados;
- todos os assets possuem metadata e QA;
- build Android foi testada em aparelho físico.
