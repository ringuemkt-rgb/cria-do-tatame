# Atlas — confirmação explícita de viagem regional (2026-11-20)

## Implementação
A tela existente `scenes/world/WorldMapScreen.gd` agora consulta `WorldMapManager.preview_travel_to()` antes de oferecer um diálogo de confirmação. O jogador vê o nome, custo, duração e eventual avanço do dia. Cancelar ou selecionar o hub atual não cobra, não grava save e não avança calendário.

Na confirmação, a tela consulta novamente disponibilidade e saldo, valida a cena de destino e somente então chama o comando mutável existente `travel_to()`. Toques repetidos não substituem a seleção pendente. Salvador e Itacaré não são destinos jogáveis; não há rotas, coordenadas ou mapas georreferenciados novos.

## Dependência e gates
Este PR está **empilhado no PR #213** (prévia de viagem), não na main. A integração exige revisão conjunta com #212 (validação de custos) e #211 (reset de hub); #167, #168, #169 já estão mesclados, mas a regressão de atlas/saves precisa continuar verde. O fluxo de combate/arte de #164 e #166 não é alterado.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/world_atlas_travel_confirmation_smoke.gd
godot --headless --path . --script res://tests/world_atlas_navigation_smoke.gd
godot --headless --path . --script res://tests/regional_travel_preview_smoke.gd
npm run quality
```

Nenhuma execução física Android ou aprovação humana é presumida. Sem novo manager, sem schema de save e sem promoção de arte. Reverter os commits deste PR restaura a navegação anterior.
