# Dynamic Grapple Flow Spec

## Objetivo

Definir o fluxo dinâmico de combate do **Cria Positional Grappling Engine**, garantindo luta viva, responsiva, fiel ao Jiu-Jitsu e jogável no Android.

---

## 1. Arquitetura de decisão

```txt
Input do jogador
→ CombatInputRouter
→ CurrentCombatState
→ TechniqueResolver
→ DefenseWindow
→ AnimationEventTimeline
→ ResourceDelta
→ PositionResult
→ Score/Reputation/Crowd Feedback
```

---

## 2. Camadas de cada técnica

Toda técnica precisa ter seis camadas:

1. **Condição de entrada** — estado, distância, grip, gás, foco.
2. **Janela de execução** — tempo, direção, botão e comprometimento.
3. **Defesa do rival** — reação, timing, atributo, plano de IA.
4. **Resultado posicional** — sucesso, falha, bloqueio, reversão ou scramble.
5. **Consequência de recurso** — gás, foco, controle, grip, moral.
6. **Feedback audiovisual** — animação, câmera, som, crowd, UI.

---

## 3. Tipos de resultado

| Resultado | Significado |
|---|---|
| clean_success | técnica limpa, pontua ou avança posição |
| messy_success | avança posição com custo alto |
| blocked | rival bloqueia, mantém estado |
| scramble | disputa aberta, ambos podem reagir |
| countered | rival ganha posição ou vantagem |
| illegal_or_risky | árbitro/punição ou perda de honra |

---

## 4. Defesa por timing

```txt
0–25% da janela: defesa cedo — reduz risco, gasta gás
26–60%: defesa perfeita — bloqueia ou reverte
61–85%: defesa tarde — reduz dano posicional, mas perde vantagem
86–100%: falha — técnica entra
```

A janela muda por:
- foco do defensor;
- gás restante;
- estilo do rival;
- pressão da torcida;
- arena;
- fadiga acumulada;
- moral.

---

## 5. Técnicas prioritárias da vertical slice

```txt
pegada_lapela
quebrar_pegada
clinch_neutro
single_leg
sprawl_defense
queda_para_guarda
postura_na_guarda
knee_cut
side_control_pressure
montada
back_take
seatbelt
rear_choke_setup
rear_choke_tap
escape_reset
```

---

## 6. Grappling Momentum

Momentum é ganho por sequência técnica coerente, não por violência.

Ganha momentum:
- defender no timing perfeito;
- passar guarda;
- estabilizar posição;
- recuperar gás com calma;
- ouvir corner/Tinker Bell;
- respeitar o árbitro.

Perde momentum:
- spammar técnica;
- entrar sem gás;
- fugir da luta;
- forçar finalização sem controle;
- agir contra regra.

---

## 7. Estado de Axé Técnico

Bônus curto e contextual. Nunca é botão de vitória.

Ativa se:
```txt
3 ações coerentes seguidas
foco >= 60
gás >= 40
moral >= 50
sem punição recente
```

Efeito:
```txt
+10% leitura de defesa
+5% controle
UI mostra respiração/ritmo
Tinker Bell dá dica curta
```

---

## 8. Pontuação e estabilização

Ponto só entra após estabilização.

```txt
queda limpa: precisa 1.2s de controle
raspagem: precisa 1.0s de controle
passagem: precisa 1.5s sem guarda recuperada
montada: precisa 1.5s
costas: precisa seatbelt + ganchos por 1.5s
```

---

## 9. Anti-spam

Cada técnica repetida em sequência aumenta:
- custo de gás;
- previsibilidade para IA;
- chance de counter;
- perda de moral se falhar feio.

---

## 10. Critério de implementação

```txt
[ ] Toda técnica tem estado inicial/final.
[ ] Toda técnica tem custo.
[ ] Toda técnica tem defesa.
[ ] Toda técnica tem pelo menos 3 resultados.
[ ] Toda técnica tem animação de sucesso e falha.
[ ] Toda técnica emite evento de frame.
[ ] Toda técnica comunica feedback ao HUD.
```
