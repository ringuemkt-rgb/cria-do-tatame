# Open Source Combat Tooling — Cria do Tatame

## Objetivo

Listar ferramentas/repositórios úteis para construir o combate dinâmico de Cria do Tatame sem copiar sistemas proprietários.

---

## 1. Rollback / luta responsiva

### blast-harbour/Godot-Rollback-Fighter-Demo
Uso sugerido:
- estudar estrutura de luta com rollback;
- entender sincronização de input;
- futura base para versus online.

### maximkulkin/godot-rollback-netcode
Uso sugerido:
- estudar arquitetura rollback;
- adaptar conceitos apenas se compatível com Godot 4 e licença.

### JonChauG/RollbackNetcodeGodot
Uso sugerido:
- referência educacional para rollback;
- não integrar sem auditoria.

Prioridade atual:
- Vertical Slice offline primeiro.
- Rollback só depois do combate local estar sólido.

---

## 2. Templates de fighting game

### FoxFX87/Godot-FightingGameTemplate
Uso sugerido:
- estudar estrutura de projeto;
- HUD, personagens, input, troca de estado;
- adaptar apenas padrões, não copiar direto.

### DanySnowyman/Godot_Fighting_Project
Uso sugerido:
- referência de projeto 2D de luta;
- estudar organização de cena e personagem.

---

## 3. State Machine

### ninstar/Godot-StateMachineNodes
Uso sugerido:
- estudar node-based FSM;
- avaliar para PositionStateMachine.

### GreenCrowDev/neuron-fsm-godot
Uso sugerido:
- base conceitual para estados hierárquicos.

### ignaciomilesi/FSM-addon-godot
Uso sugerido:
- referência de addon simples.

Recomendação:
- implementar FSM própria e enxuta no projeto, inspirada por padrões públicos.
- Não depender cedo de addon externo.

---

## 4. IA / Behavior Tree

### bitbrain/beehave
Uso sugerido:
- árvore de comportamento para rivais;
- gameplans por estilo: pressão, scramble, defesa, hype.

### limbonaut/limboai
Uso sugerido:
- behavior tree + state machine mais robusta;
- avaliar peso e compatibilidade.

### godot-addons/godot-behavior-tree-plugin
Uso sugerido:
- referência educacional.

Recomendação:
- Vertical Slice: IA simples por utility score.
- Alpha: Behavior Tree para rivais principais.

---

## 5. Hitbox / Hurtbox / caixas técnicas

### coelhucas/hitbox-editor
Uso sugerido:
- estudar fluxo de edição de hitboxes;
- adaptar para áreas de contato: pegada, quadril, tronco, ombro, pescoço, base.

No Cria do Tatame, hitbox não é só dano:
- grip zone;
- base zone;
- control zone;
- escape zone;
- submission danger zone.

---

## 6. Stack recomendado

### Vertical Slice
```txt
Godot 4.2+
FSM própria
CombatInputRouter
TechniqueResolver
TransitionResolver
SubmissionEngine
JSON data-driven
AnimatedSprite2D + AnimationPlayer
```

### Alpha
```txt
Behavior Tree para IA
Hitbox/zone editor interno
ArenaModifierSystem
ScoringSystem
CriaLive feedback
```

### Beta / Online
```txt
Rollback research
input prediction
replay system
training dummy recorder
```

---

## 7. Regra de segurança técnica

Antes de importar qualquer repositório:

```txt
[ ] Verificar licença.
[ ] Verificar versão Godot.
[ ] Testar em projeto limpo.
[ ] Não misturar código sem entender.
[ ] Preferir adaptar arquitetura, não copiar arquivos.
[ ] Documentar tudo em THIRD_PARTY.md.
```
