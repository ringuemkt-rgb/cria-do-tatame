# 10 — Bíblia Visual 2D / HD Pixel Art 2.5D

Documento operacional para orientar Manus AI, artistas, geradores de imagem, Pixelorama/LibreSprite, Godot e revisão humana.

## 1. Objetivo

Garantir que **Cria do Tatame – Pressão** tenha uma identidade visual coerente, profissional e reconhecível em qualquer tela: celular Android, PC, Web, thumbnail, capa, trailer, HUD, sprites e arena.

O visual não deve parecer genérico. Deve parecer:

- Jogo brasileiro premium de luta.
- Jiu-Jitsu Brasileiro como cultura, não enfeite.
- Baixo Sul da Bahia como território vivo.
- Preto/dourado de marca forte.
- HD Pixel Art 2.5D com leitura mobile.
- Energia de tatame real, suor, madeira, lama, tecido de kimono, luz quente e disciplina.

## 2. Estilo oficial

Nome técnico interno:

**HD Painted Pixel Art 2.5D — Cria do Tatame Style**

Características:

- Base 2D lateral/isométrica leve.
- Sprites em pixel art de alta resolução, com pintura controlada.
- Contorno forte e seletivo.
- Sombreamento com blocos legíveis.
- Textura de tecido, madeira, lona, metal, lama e suor.
- Iluminação cinematográfica quente/fria conforme arena.
- Animação fluida, mas com silhueta clara.
- UI premium preto fosco + dourado queimado.
- Zero aspecto plástico barato.
- Zero cartoon infantil.

## 3. Paleta oficial

| Token | Hex | Função |
|---|---:|---|
| black_absolute | `#0A0A0A` | fundo, menus, sombras profundas |
| black_matte | `#1A1A1A` | painéis, cards, HUD |
| gold_burned | `#B8860B` | bordas, honra, molduras, faixa |
| gold_honor | `#F2C230` | CTA, seleção, vitória, ícones |
| dirty_white | `#F2F2F2` | texto principal, kimono, highlights |
| red_conflict | `#D92323` | dano, crise, perigo, sombra competitiva |
| blue_river | `#1E3A5F` | água, noite, circuito oficial, tatame oficial |
| green_mangrove | `#2D5016` | mangue, recuperação, raiz, natureza |
| purple_shadow | `#4B0082` | dualidade, Kenzo, submundo frio |

## 4. Regras de leitura mobile

- Nenhum texto crítico abaixo de 18 px em tela 1280x720.
- Botões de combate devem caber no polegar.
- HUD deve ser lido em 1 segundo.
- Não usar excesso de partículas na frente dos lutadores.
- A silhueta do lutador deve ser clara mesmo sem detalhes.
- O estado da luta precisa ser visual: distância, pegada, clinch, queda, chão, finalização.

## 5. Direção de personagens

### Ruan “Macacão” Silva

Silhueta:
- Tronco forte.
- Pescoço curto.
- Base baixa.
- Ombros largos.
- Passos pesados.
- Centro de massa visivelmente baixo.

Visual:
- Jovem de Ituberá.
- Kimono/shorts de treino com desgaste real.
- Faixa evolui ao longo da campanha.
- Emblema do Gorila Silverback.
- Expressão focada, não caricata.

Animação:
- Menos velocidade, mais peso.
- Pegadas longas.
- Pressão de cabeça.
- Transições com sensação de esmagamento técnico.

### Davi “Relâmpago”

Silhueta:
- Corpo mais leve.
- Postura alta.
- Passos rápidos.
- Muitas fintas e recuos.

Visual:
- Rival técnico.
- Linhas mais ágeis.
- Contraste com a massa corporal de Ruan.

Animação:
- Scramble rápido.
- Esquiva.
- Recuperação veloz quando não está preso.

### Mestre Dendê

Silhueta:
- Postura firme.
- Economia de movimento.
- Autoridade silenciosa.

Visual:
- Mentor raiz.
- Roupa simples.
- Aparência de quem venceu mais batalhas internas do que externas.

## 6. Direção de arenas

### Terreiro da Luta — Ituberá

Palavras-chave:
Madeira, mangue, rio, pôr do sol, ancestralidade, disciplina, treino raiz, respeito.

Elementos obrigatórios:
- Tatame azul/dourado gasto.
- Estrutura de madeira.
- Água/mangue no fundo.
- Luz quente lateral.
- Placas com valores: foco, disciplina, respeito, coragem, fé, humildade.
- Atmosfera de palácio de treino humilde, não ginásio rico.

### Arena do Dique — Salvador

Palavras-chave:
Oficial, campeonato, multidão, luz fria, telões, prefeitura, faixa, glória competitiva.

Elementos obrigatórios:
- Tatame azul com bordas douradas.
- Telões grandes.
- Público em arquibancada.
- Banner Cria do Tatame.
- Identidade Salvador/Bahia.
- Sensação de evento grande.

### Manguezal Profundo

Palavras-chave:
Lama, raiz, tração baixa, água, perigo, silêncio, natureza viva.

Gameplay visual:
- Lama e água devem comunicar perda de tração.
- Reflexos discretos.
- Partículas de lama controladas.

## 7. Spritesheets mínimos

Para cada lutador jogável/rival:

- idle
- walk_forward
- walk_back
- guard_stance
- grip_attempt
- grip_success
- grip_break
- clinch_enter
- takedown_attempt
- takedown_success
- sprawl_defense
- ground_guard
- half_guard
- side_control
- mount
- back_control
- submission_setup
- submission_lock
- tap
- escape
- win
- lose
- hurt
- stamina_break

## 8. Padrão técnico de exportação

Sprites:
- PNG transparente.
- Pivot na base dos pés/quadril conforme ação.
- Nomes em snake_case.
- Tamanho inicial recomendado: 256x256, 384x384 ou 512x512 por frame, conforme necessidade.
- Import no Godot com filtro desligado para manter pixel art.

Arenas:
- `bg_far.png`
- `bg_mid.png`
- `play_area.png`
- `foreground.png`
- `light_overlay.png`
- `particles.png` ou VFX separados.

UI:
- 9-slice panels.
- Bordas douradas.
- Ícones monocromáticos dourado/branco.
- Estados: normal, hover/focus, pressed, disabled.

## 9. Prompt base para assets

Use sempre esta estrutura:

```txt
HD painted pixel art 2.5D, Brazilian Jiu-Jitsu fighting game, Cria do Tatame visual identity, matte black and burned gold premium UI, Baixo Sul da Bahia atmosphere, strong readable silhouette, mobile game readability, cinematic lighting, detailed but clean pixel art, transparent background when character sprite, no plastic 3D, no childish cartoon, no copyrighted game style.
```

## 10. Negative prompt obrigatório

```txt
low quality, blurry, unreadable silhouette, cheap plastic 3D, childish cartoon, chibi, generic anime, copied commercial game style, excessive colors, messy UI, tiny text, distorted anatomy, extra limbs, broken hands, unreadable logo, fake watermark, photorealistic skin, AI artifacts
```

## 11. Checklist de aprovação visual

Um asset só entra no jogo se responder “sim” para:

- Está dentro da paleta?
- Lê bem em celular?
- Tem silhueta forte?
- Não parece genérico?
- Respeita Baixo Sul/Bahia/Jiu-Jitsu?
- Funciona em Godot sem ajuste absurdo?
- Não usa material protegido?
- Conversa com Ruan Macacão e o Gorila Silverback?

## 12. Regra final

Bonito não basta. O asset precisa servir gameplay, leitura, performance e identidade.
