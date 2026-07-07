# Cria Positional Grappling Engine

## Objetivo

Criar o motor de combate autoral do jogo: um sistema de Jiu-Jitsu posicional, mobile-first, tático, responsivo e visualmente forte.

Não é cópia de UFC, EA, THQ ou qualquer jogo licenciado. O objetivo é absorver princípios gerais de bons jogos de luta/carreira:

- carreira como tutorial vivo;
- stamina/fadiga impactando desempenho;
- transições conectadas;
- grappling fluido;
- opções simplificadas e profundas ao mesmo tempo;
- controle de posição como coração do combate.

---

## 1. Filosofia

```txt
Fácil de apertar. Difícil de dominar.
```

O jogador deve entender rápido os botões, mas dominar o sistema exige leitura, timing, gestão de gás, grip, foco e controle.

---

## 2. Estados oficiais

```txt
01_DISTANCIA_LONGA
02_DISTANCIA_MEDIA
03_GRIP_FIGHT
04_CLINCH_NEUTRO
05_CLINCH_DOMINANTE
06_QUEDA_ENTRADA
07_QUEDA_DISPUTA
08_GUARDA_FECHADA
09_GUARDA_ABERTA
10_MEIA_GUARDA
11_SIDE_CONTROL
12_MONTADA
13_COSTAS
14_FINALIZACAO_SETUP
15_FINALIZACAO_LOCK
16_TAP_OR_ESCAPE
17_RESET
```

---

## 3. Botões contextuais

O jogo usa cinco botões principais. O nome do botão muda conforme o estado.

### Distância média
| Botão | Ação |
|---|---|
| A | Pegada |
| B | Defesa |
| C | Finta |
| D | Clinch |
| E | Queda |

### Clinch neutro
| Botão | Ação |
|---|---|
| A | Pressão |
| B | Quebrar Pegada |
| C | Trocar Base |
| D | Defesa |
| E | Queda |

### Side Control
| Botão | Ação |
|---|---|
| A | Pressão |
| B | Crossface |
| C | Isolar |
| D | Joelho na Base |
| E | Montar |

### Costas
| Botão | Ação |
|---|---|
| A | Ganchos |
| B | Seatbelt |
| C | Arrastar |
| D | Defender Reversão |
| E | Finalizar |

---

## 4. Recursos

| Recurso | Função |
|---|---|
| HP | resistência geral |
| Gás | energia para entradas, defesa e scramble |
| Foco | timing, leitura e precisão |
| Moral | confiança e resistência mental |
| Controle | domínio posicional |
| Grip | qualidade da pegada |
| Guarda | defesa no chão |
| Vantagens | quase pontuação |
| Punições | erros oficiais/anti-jogo |

---

## 5. Pontuação autoral

Inspirada no espírito do grappling esportivo, mas ficcional e ajustada para gameplay.

```txt
Queda limpa: 2 pontos
Raspagem: 2 pontos
Passagem de guarda: 3 pontos
Montada: 4 pontos
Costas com ganchos: 4 pontos
Vantagem técnica: 1 marcador
Punição: perda de vantagem ou ponto do rival
Finalização: vitória imediata por tap/intervenção
```

Pontos só validam com controle mínimo estabilizado por tempo curto de jogo.

---

## 6. Fluxo de finalização

```txt
SETUP → LOCK → PRESSÃO TÉCNICA → TAP / ESCAPE / ÁRBITRO
```

Regras:

- Sem lesão explícita.
- Sem glamourizar dano articular.
- Tap é respeito.
- Árbitro protege.
- Finalização é técnica e disciplina.

---

## 7. Sistema de animação

Toda técnica deve ter fases:

```txt
idle
anticipation
entry
contact
control
resolution
recovery
branch
```

A animação só é aprovada se alterar recurso, posição, vantagem ou estado.

---

## 8. IA por plano de luta

### Davi Relâmpago
- Evita pressão.
- Reseta distância.
- Pune entrada atrasada.
- Usa scramble.
- Gasta gás rápido quando preso.

### Cássio Molho
- Provoca.
- Busca movimento plástico.
- Força hype.
- Arrisca crise no Cria Live.

### Jacaré do Mangue
- Forte no chão.
- Bom em arena irregular.
- Pouco refinado no circuito oficial.

### Kenzo Kuroi
- Foco alto.
- Defesa fria.
- Punição de erro.
- Pouco hype, muita técnica.

---

## 9. Arena altera luta

| Arena | Modificador |
|---|---|
| Terreiro da Luta | +foco, +moral, treino melhor |
| Arena do Dique | pontuação oficial, punição, sponsor visibility |
| Ponte do Saci | pouca lateral, vento, chuva, risco alto |
| Praia de Pratigi | areia reduz velocidade, crowd aumenta hype |
| Zambiapunga | ritmo dos tambores afeta timing/moral |
| Manguezal Profundo | lama, tração ruim, vantagem para pressão pesada |

---

## 10. Definition of Done do motor de combate

```txt
[ ] Botões mudam por estado.
[ ] HUD atualiza em tempo real.
[ ] Técnicas consomem gás/foco/grip.
[ ] Rival reage com plano próprio.
[ ] Arena altera tática.
[ ] Luta termina por pontos, controle ou tap.
[ ] Resultado muda reputação.
[ ] Animação dispara eventos mecânicos.
[ ] Jogador entende por que ganhou/perdeu.
```
