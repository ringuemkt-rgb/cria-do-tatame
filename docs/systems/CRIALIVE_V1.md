# CriaLive V1 — Social Career Engine

## Papel

CriaLive é a camada diegética que converte acontecimentos do jogo em carreira social: posts, propostas, patrocínio, provocações, crescimento e dinheiro.

O V1 começa com um slice vertical executável:

1. publicar um clip;
2. calcular viralidade determinística;
3. gerar ads;
4. registrar exposição de técnica;
5. gerar e aceitar uma proposta de Davi;
6. assinar Luiz Henrique Suplementos;
7. processar um payout semanal.

## Firewall de autoridade

CriaLive não decide luta, tempo ou economia por conta própria.

| Domínio | Autoridade |
|---|---|
| Resultado da luta | CombatManager |
| Ledger | ProgressionOS |
| Semana/dia | WorldDirectorManager / WorldState |
| Dinheiro e reputação | WorldState |
| Persistência | SaveManager v6 |
| Estado social persistente | CriaLiveInteractionManager |
| Regras sociais | CriaLiveService |
| Feed legado/visual | CriaLiveManager |

CriaLiveService não é autoload. Ele é um motor determinístico instanciado pelo manager persistente.

## Fluxo do slice

    fight/training event
      -> candidate post
      -> PostComposer
      -> ViralityEngine(seed, week, clip, tone)
      -> followers / hype projection / ads
      -> ProgressionOS social events
      -> technique exposure
      -> nemesis signal at second exposure
      -> proposal
      -> sponsor
      -> week_completed
      -> payout

## Determinismo

A rolagem de viralidade usa um hash estável próprio + RandomNumberGenerator com seed derivado de:

- seed do mundo;
- semana;
- ID do post.

A mesma entrada produz o mesmo score e likes.

## Infiltração

coverage_risk só cresce quando:

- infiltracao_ativa == true; e
- o tipo do post está na lista de risco.

O serviço apenas calcula risco e emite recomendação de lay low. Ele não encerra a infiltração sozinho.

## Nemesis

O V1 registra technique_exposure. Na segunda publicação de uma mesma técnica, emite crialive_nemesis_exposure.

O sistema de rivalidade pode consumir o signal; CriaLive não altera o resultado da próxima luta diretamente.

## Save

O estado V1 mora dentro de CriaLiveInteractionManager.to_dict() em v1_state, portanto já viaja pelo campo existente cria_live_interaction_state do save v6.

## Próximos lotes

- composer visual no PhoneOverlay;
- provocações com personas;
- decline/expire completo com notificação;
- sponsor negotiation de Tinker;
- adapters explícitos para MissionManager e NemesisSystem;
- tendências por WorldDirector;
- analytics de tuning separados de telemetria autoritativa.
