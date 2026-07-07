# UFC-Style Grappling Research Adaptation — Cria do Tatame

## Status de pesquisa

Não há acesso público ao código-fonte de EA Sports UFC 6, nem permissão para copiar sistemas proprietários, assets, nomes licenciados, animações ou marcas. Este documento transforma apenas **princípios de design observáveis** em uma arquitetura original para **Cria do Tatame**.

Objetivo: absorver o que jogos modernos de MMA fazem bem — fluidez, leitura, responsividade, carreira, narrativa, modos offline, reação de IA e feedback — e adaptar para um jogo autoral de **Jiu-Jitsu posicional**.

---

## 1. O que aproveitar de jogos modernos de MMA

### 1.1 Grappling fluido

Princípio observado:
- Submissões e transições precisam ser rápidas de iniciar.
- O jogador não deve ficar preso em menu lento.
- A transição precisa comunicar causa e consequência.

Adaptação:
```txt
DISTANCIA → PEGADA → CLINCH → QUEDA → GUARDA → CONTROLE → FINALIZACAO
```

Cada botão contextual deve iniciar uma ação legível em no máximo 0.2–0.4 s de feedback visual.

---

### 1.2 Defesa com timing

Princípio observado:
- Bons jogos de grappling dão valor ao timing defensivo.
- Defesa bem feita pode gerar bloqueio, sprawl, escape ou reversão.

Adaptação:
```txt
DEFESA CEDO = gasta gás, evita dano, mas não ganha vantagem
DEFESA PERFEITA = bloqueio + pequena vantagem ou reversão
DEFESA TARDE = reduz dano/risco, mas perde posição
SEM DEFESA = posição ruim, ponto ou finalização setup
```

---

### 1.3 Carreira como tutorial vivo

Princípio observado:
- Modo carreira ensina mecânicas em contexto, não só em tutorial isolado.

Adaptação:
- Mestre Dendê ensina base, queda e respeito.
- Tinker Bell explica scouting e leitura de rival.
- Cria Live mostra consequência pública.
- Sponsors criam tradeoffs.
- Cada ato introduz uma camada nova do combate.

---

### 1.4 Identidade única de lutadores

Princípio observado:
- Lutadores precisam jogar diferente, não só trocar skin.

Adaptação:
- Ruan “Macacão”: pressão, grip, top game, controle.
- Davi Relâmpago: velocidade, scramble, reset.
- Cássio Molho: hype, risco, provocação.
- Jacaré do Mangue: força, ambiente irregular, domínio bruto.
- Kenzo Kuroi: foco, defesa fria, punição de erro.

---

### 1.5 Modos offline fortes

Princípio observado:
- Jogo de luta moderno precisa ter mais que luta rápida.

Adaptação:
- Carreira principal.
- Legacy do Baixo Sul: capítulos especiais.
- Terreiro Academy: treino e codex.
- Hall do Tatame: memória de mestres/rivais.
- Cria Live: social, crise, reputação.
- Mapa do Baixo Sul: campanha territorial.

---

## 2. O que NÃO copiar

- Código da EA.
- Animações proprietárias.
- Nome UFC.
- Nomes de lutadores reais.
- Logos de federações.
- Regras oficiais palavra por palavra.
- Sistema exato de controle.
- Microtransações predatórias.
- Dano visual extremo.

---

## 3. Melhorias para o nosso jogo

### 3.1 Combate de Jiu-Jitsu puro

Enquanto jogos de MMA equilibram boxe, chute, wrestling, clinch e chão, Cria do Tatame foca em:

```txt
posição
pegada
pressão
passagem
defesa
raspagem
montada
costas
finalização com tap
```

### 3.2 Menos dano, mais controle

Substituições de design:

| MMA tradicional | Cria do Tatame |
|---|---|
| dano facial | desgaste técnico |
| nocaute | domínio posicional |
| ground and pound | pressão de controle |
| médico | árbitro / segurança |
| finisher violento | tap respeitoso |
| hype vazio | reputação moral |

---

## 4. Flow State adaptado sem virar poderzinho barato

Alguns jogos recentes usam “estado de fluxo” ou bônus temporário. Para Cria do Tatame, isso só entra se for contextual, técnico e raro.

Nome: **Estado de Axé Técnico**

Ativa quando:
- jogador encadeia 3 ações corretas;
- mantém gás acima de 40%;
- usa técnica coerente com estilo;
- não comete falta;
- respeita o adversário.

Efeito:
- pequena janela de leitura;
- preview de transição provável;
- bônus leve de foco;
- animação de respiração/ritmo;
- nunca encerra luta sozinho.

---

## 5. Modelo de luta viciante e justo

### Loop de 15 segundos
```txt
ler estado → escolher ação → ver resposta → ajustar plano
```

### Loop de 60 segundos
```txt
ganhar pegada → desequilibrar → cair por cima → estabilizar → pontuar/finalizar
```

### Loop de luta
```txt
plano → execução → adaptação → consequência → reputação
```

---

## 6. Critérios de excelência

```txt
[ ] Luta nunca parece turno parado.
[ ] Toda posição tem opção ofensiva, defensiva e neutra.
[ ] Defesa boa muda o rumo da luta.
[ ] Rival tem plano reconhecível.
[ ] Arena altera decisão técnica.
[ ] Animação e mecânica disparam juntas.
[ ] Jogador entende por que perdeu.
[ ] Vitória limpa vale mais que humilhação.
```
