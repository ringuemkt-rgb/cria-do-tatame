# CriaLive v1

Rede diegética. Motor de carreira, purse e nemesis. Não é autoload novo.

Já existe `CriaLiveManager` + `CriaLiveFeedManager`. Este contrato **envolve** esses nós. Não inventa o terceiro.

## Autoridade

- Combate → CombatManager (clip_quality nasce do resultado)
- Tempo / payout → WorldDirectorManager (avanço de semana)
- Ledger → ProgressionOS
- Social → CriaLiveService (apresentação + regras de feed)

## 5 loops

1. Post → virality seeded → seguidores / hype / ads
2. Proposta de luta → missão ou expire com zoação
3. Patrocínio → obligação semanal + patch
4. Provocação → heat; clip da mesma técnica ≥2x ensina o rival
5. Decay −2% seguidores se semana sem post; hype −10%

Tom provocador sobe Cobertura só se infiltração estiver ativa.

## Slice de implementação

1 post + 1 proposta Davi + 1 payout de suplementos. UI phone já em `scenes/ui/CriaLiveUI.tscn`.
