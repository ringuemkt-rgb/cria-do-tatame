# Atlas regional — viagem transacional de toque único (27/10/2026)

**Status:** IMPLEMENTADO EM BRANCH; não integrado à main, não homologado em aparelho físico.

## Defeito reproduzível pelo código

`WorldMapScreen._on_travel_pressed()` chamava `WorldMapManager.travel_to()` imediatamente e aguardava 0,5 s antes de trocar a cena. Durante a espera, os botões continuavam ativos. Dois toques rápidos — ou a seleção de dois destinos — chamavam o manager duas vezes: dois débitos, duas entradas no histórico e potencial avanço duplicado de tempo. A supressão de mouse sintético no mapa (#179) não protegia os botões de viagem.

## Implementação e autoridade

- O consumidor real `scenes/world/WorldMapScreen.gd` trava a navegação **antes** de chamar a autoridade existente `WorldMapManager.travel_to()`, bloqueia botões de viagem/voltar durante a transição e ignora toques adicionais, inclusive reentrantes.
- Se a viagem for negada, o bloqueio é revertido e a mensagem de erro fica visível.
- A cena de destino é verificada via `ResourceLoader.exists` **antes** de debitar dinheiro, avançar o dia ou salvar. Caso a cena não exista, a tentativa é recusada sem efeitos colaterais.
- Se a mudança de cena falhar após uma viagem efetivada, o bloqueio permanece para evitar nova cobrança; o jogador recebe orientação para reabrir o save.
- `_perform_travel()` é apenas uma função delegadora, sobrescrita exclusivamente pelo teste isolado. Não cria manager, altera schema de save nem adiciona rotas ou coordenadas.
- Ituberá, Zambiapunga e Camamu/Manguezal são os únicos destinos UI aceitos. Salvador/Itacaré permanecem contexto externo, sem viagem jogável.

## Regressão

`tests/world_map_travel_ui_smoke.gd` instancia a **cena real** com um test double de `_perform_travel` em `tests/helpers/WorldMapTravelScreenStub.gd`, sem tocar no save do slot 1. Testa: rotas externas rejeitadas, recusa recuperável, cena inexistente rejeitada antes de commit, dois toques no mesmo destino, toque em destino diferente durante a transição, botões bloqueados e ausência de mutação de dinheiro/histórico pelo teste.

```bash
npm run quality
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/world_atlas_navigation_smoke.gd
godot --headless --path . --script res://tests/world_map_travel_ui_smoke.gd
godot --headless --path . --script res://tests/baixo_sul_travel_migration_smoke.gd
```

A workflow `world-atlas-navigation-v1.yml` passa a executar o novo smoke. **Os resultados devem ser lidos da CI; adicionar o teste não é evidência de aprovação.**

## Dependências e critérios de promoção

Base: #179 → #175, com conteúdo de #167, #168, #169, #157, #164, #165 e #166. Não fundir branches irmãs #176/#177/#178/#180/#181/#182 sem reconciliação de diffs e revisão.

Os mapas ilustrados são referências artísticas; continuam `shipping=false` até proveniência, licença, QA Sprite Forge e aprovação humana. Nenhuma imagem nova foi promovida.

**Android físico pendente:** instalar build ARM64 em aparelho, testar duplo toque rápido nos três destinos, toque em destinos diferentes antes da transição, erro por falta de dinheiro, retorno ao Terreiro, reinício e recuperação do save. Registrar modelo, Android, build SHA, vídeo de toques, logs, custo antes/depois e aprovação humana.

**Rollback:** reverter a mudança de `WorldMapScreen.gd`, o teste isolado, o passo CI e este documento. Nenhum save é migrado por este lote.
