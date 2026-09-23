# CRIA DO TATAME — Combat Cards Visual Canon v2

Status: CANÔNICO
Data: 2026-08-10
Escopo: Hub de combate, cartas, árvores de habilidade, overlays técnicos e materiais promocionais do sistema de luta.

## 1. Regra permanente

Todo material visual do jogo deve seguir **2.5D Pixel Art Premium**. Referências externas de jiu-jitsu, judô, wrestling ou anatomia são usadas somente para engenharia reversa de biomecânica, posicionamento, alavancas e contatos. O estilo visual final nunca copia a estética da referência: ele é traduzido para o DNA visual do Cria do Tatame.

## 2. DNA visual

### Paleta principal

- Fundo carvão: `#0D0F12`
- Preto forjado: `#090B0D`
- Ivory de texto: `#F2E9D3`
- Ouro envelhecido: `#D4AF37`
- Laranja/ataque: `#FF8A00`
- Azul tático/controle: `#2EA7FF`
- Verde mangue/raiz: `#6DBF67`
- Roxo elite/foco: `#B16DFF`
- Vermelho perigo/finalização: `#FF4B4B`

### Ambiente

- Arena escura com luz dramática.
- Tatame com textura legível sem competir com os lutadores.
- Rim light quente/dourada e acentos de luz fria conforme categoria.
- Profundidade 2.5D por planos, sombras de contato e volumes pixelados.
- Silhuetas limpas em leitura mobile-first.

## 3. Tipografia e hierarquia

- Títulos: condensados, pesados, caixa alta, leitura imediata.
- Subtítulos: caixa alta, cor da categoria.
- Corpo: curto, funcional, alto contraste.
- Número da carta: grande e dominante.
- Custo e cooldown: sempre legíveis mesmo em miniatura.

## 4. Categorias cromáticas

- Entrada/Mobilidade: verde.
- Queda/Ataque: laranja.
- Passagem/Controle: azul/ciano.
- Controle superior: azul profundo.
- Finalização: vermelho.
- Defesa/Escape: azul/roxo conforme função.
- Leitura/Foco: roxo.
- Raiz/Moral: verde mangue.
- Elite/Lendária: ouro.

## 5. Estrutura obrigatória da carta

1. Categoria.
2. Número/raridade.
3. Nome técnico.
4. Ilustração principal biomecanicamente correta.
5. Custos: Gás, Foco, Grip e, quando aplicável, Moral/Adrenalina.
6. Efeito em texto curto.
7. Cooldown.
8. Três keyframes: entrada → controle → desfecho.
9. Barras/atributos quando a peça for didática ou de coleção.

## 6. Regra biomecânica

Nenhuma técnica é aprovada somente porque “parece luta”. Antes de entrar no jogo, a ilustração deve responder claramente:

- quem controla cabeça/pescoço;
- quem controla quadril;
- quem controla a linha do joelho/pé;
- onde estão os pontos de apoio;
- para onde o centro de massa se desloca;
- qual articulação/estrutura recebe a alavanca;
- qual é a direção principal da força;
- quais frames representam preparação, aplicação e saída.

### Proibido

- membros atravessando corpos;
- articulações em ângulos impossíveis;
- mãos sem função ou grips inexistentes;
- pés flutuando sem apoio;
- quedas sem desequilíbrio/entrada;
- finalizações sem isolamento prévio;
- transições por teleporte entre poses;
- anatomia chibi ou caricatural incompatível com o cânone.

## 7. Personagens do combate

A arte deve respeitar o cânone do repositório para idade, uniforme, graduação, proporções e identidade. Variações de roupa ou faixa precisam ser explicitamente associadas a progressão, arena ou modo de jogo.

## 8. Famílias da coleção

A coleção visual do Hub passa a ser organizada por famílias:

1. Entradas e leitura tática.
2. Pegadas, clinch e quebra de postura.
3. Quedas e projeções.
4. Passagens de guarda.
5. Controle superior.
6. Finalizações de braço e ombro.
7. Estrangulamentos.
8. Ataques de perna.
9. Defesa, escapes e contra-ataques.
10. Cartas elite, suporte e domínio.

## 9. Árvore de habilidades

A árvore usa três caminhos canônicos:

- **Pressão** — postura, base, grip, passagem, controle e domínio.
- **Leitura** — tempo, reação, contra-ataque, foco e transição.
- **Raiz do Mangue** — resistência, adaptação, moral, recuperação e identidade regional.

Graduação visual: branca → azul → roxa → marrom → preta. A faixa libera tiers, cartas, VFX e nós avançados; ela não substitui a progressão mecânica do DeckManager.

## 10. Padrão de nitidez

- Fonte de arte: trabalhar em resolução alta.
- Preservar bordas e pixels intencionais.
- Downscale somente com método nearest quando o destino for sprite.
- Evitar blur, antialiasing excessivo, compressão destrutiva e ruído que comprometa leitura.
- Cartas de documentação podem usar WebP de alta qualidade; sprites runtime devem seguir o contrato PNG/atlas do pipeline oficial.

## 11. QA final

Uma peça só pode ser marcada como APROVADA quando passar por quatro gates:

1. **Canon Gate** — personagem, uniforme, graduação e nomenclatura corretos.
2. **Biomechanics Gate** — posição, contatos, alavancas e direção de força plausíveis.
3. **Visual Gate** — 2.5D pixel art, paleta, tipografia, moldura e hierarquia consistentes.
4. **Game Gate** — legibilidade no tamanho real, atlas/metadados e teste no Godot quando for asset runtime.

Este documento substitui interpretações visuais fragmentadas anteriores para o sistema de cartas e Hub de combate.