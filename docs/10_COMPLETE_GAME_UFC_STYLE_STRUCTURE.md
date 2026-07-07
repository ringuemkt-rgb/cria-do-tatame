# 10 - Estrutura Completa do Jogo — Cria do Tatame

## Objetivo

Transformar **Cria do Tatame – Pressão** em um jogo com começo, meio e fim, inspirado na robustez estrutural dos grandes jogos de luta/carreira, mas com identidade própria: Jiu-Jitsu brasileiro, Baixo Sul da Bahia, Ruan “Macacão” Silva, honra, território, reputação e domínio posicional.

> Referência estrutural: jogos modernos de MMA usam carreira, evolução de atleta, contratos, rivais, gerenciamento de treino, modos de luta e progressão narrativa. O nosso jogo absorve a lógica de produto, não nomes, marcas, assets ou sistemas proprietários.

---

## 1. Frase de projeto

**Não aperte botão para bater. Construa posição para dominar. Finalize com respeito.**

---

## 2. Estrutura macro

```txt
Abertura → Ato 1 → Ato 2 → Ato 3 → Ato 4 → Ato 5 → Final → Pós-jogo
```

### Abertura
- Ruan “Macacão” Silva retorna ao Terreiro da Luta.
- Mestre Milson Dendê identifica força bruta sem direção.
- Primeiro tutorial: distância, pegada, defesa, gás e respeito.
- Primeira derrota ou quase derrota contra Davi Relâmpago.

### Ato 1 — O Chão
- Hub principal: Terreiro da Luta, Ituberá.
- Ensina movimentação, base, grip, queda e guarda.
- Tema: força sem base vira queda.
- Chefe/rival: Davi Relâmpago.

### Ato 2 — O Circuito
- Desbloqueia mapa regional.
- Entrada na Arena do Dique, Salvador.
- Introduz regras oficiais, pontuação, árbitro, punições e sponsors.
- Tema: disciplina pública.

### Ato 3 — O Nome
- Cria Live cresce.
- Patrocinadores aparecem.
- Cássio “Molho” Santos oferece atalhos.
- Arenas híbridas e clandestinas surgem.
- Tema: hype contra honra.

### Ato 4 — A Queda
- Lesão, fadiga, crise pública, perda de moral ou quebra de reputação.
- Ruan precisa reconstruir estilo e propósito.
- Tema: o campeão que não domina a si mesmo perde antes da luta.

### Ato 5 — O Legado
- Torneio final regional.
- Rival técnico, rival moral e rival sombrio convergem.
- Final depende de Honra, Hype, Sombra, Legado e Dupla Face.

### Pós-jogo
- Lutas livres.
- Torneios semanais.
- Desafios de arena.
- Cria Live infinito controlado por banco de eventos.
- New Game+ com heranças de reputação.

---

## 3. Modos de jogo

| Modo | Função |
|---|---|
| Carreira | campanha principal de Ruan |
| Luta Rápida | combate direto em arenas desbloqueadas |
| Treino do Terreiro | tutorial e domínio técnico |
| Cria Live | social, hype, crises, sponsors e reputação |
| Mapa do Baixo Sul | navegação, rotas e eventos |
| Codex do Tatame | técnicas, posições, regras e lore |
| Torneios | chaves oficiais com pontuação |
| Desafios de Arena | variações ambientais e objetivos |

---

## 4. Core loop viciante

### Micro loop: 30–90 segundos
1. Escolher ação.
2. Executar técnica.
3. Ver mudança de posição/recurso.
4. Receber feedback visual, sonoro e tático.

### Loop de sessão: 5–15 minutos
1. Entrar no hub.
2. Treinar ou aceitar luta.
3. Lutar.
4. Receber XP, dinheiro, reputação e post do Cria Live.
5. Desbloquear habilidade, arena ou rival.

### Loop semanal
1. Segunda a sexta: treino, missão, social, recuperação.
2. Sábado: luta/evento.
3. Domingo: recuperação, Cria Live, consequências.

### Loop de temporada
1. Subir reputação regional.
2. Vencer torneios.
3. Resolver crise moral.
4. Escolher legado.

---

## 5. Sistemas obrigatórios

- Jiu-Jitsu Positional Fighting Engine.
- Career Scheduler.
- Reputation Matrix.
- Cria Live System.
- Sponsors & Contracts.
- Faction Influence.
- Arena Modifiers.
- Referee & Rules System.
- Scoring System.
- Rival AI Gameplans.
- Training & Fatigue System.
- Injury/Risk System gamificado.
- Save/Load.
- New Game+.

---

## 6. Progressão tipo carreira completa

### Eixos de evolução
- Faixa.
- Nível.
- Técnicas.
- Estilo.
- Reputação.
- Dinheiro.
- Sponsors.
- Aliados.
- Rivais.
- Mapas desbloqueados.

### Faixas
```txt
Branca → Azul → Roxa → Marrom → Preta
```

### Caminhos de habilidade
- Técnica: timing, defesa, leitura.
- Pressão: grip, controle, top game.
- Raiz: moral, resistência, comunidade.
- Frieza: foco, contra-ataque, precisão.
- Legado: reputação, liderança, sponsors limpos.

---

## 7. Finais

| Final | Requisito dominante | Resultado |
|---|---|---|
| Honra | Honra + Legado altos | Ruan vira referência limpa do Baixo Sul |
| Hype | Hype alto e Honra média | famoso, rico, instável |
| Sombra | Sombra alta | campeão temido, isolado |
| Dupla Face | Hype + Sombra + Honra oscilante | imagem pública e bastidor em conflito |
| Raiz Eterna | Honra + Moral + Comunidade altos | Ruan reconstrói o Terreiro e forma novos crias |

---

## 8. Definition of Done do jogo completo

```txt
[ ] Campanha com 5 atos jogáveis.
[ ] Pelo menos 12 arenas funcionais.
[ ] Pelo menos 16 rivais/personagens relevantes.
[ ] Pelo menos 60 técnicas/variações de posição.
[ ] Carreira semanal funcional.
[ ] Reputação afeta diálogo, missões, sponsors e finais.
[ ] Cria Live reage a lutas e escolhas.
[ ] Mapa do Baixo Sul respeita geografia real como base.
[ ] Export Android funcional.
[ ] Save/load estável.
[ ] Finalizações sempre terminam em tap, escape ou árbitro.
[ ] O jogo comunica: ser forte é ser gentil.
```
