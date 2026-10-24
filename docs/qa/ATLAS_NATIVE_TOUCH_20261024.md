# Atlas regional — toque Android e emblemas visíveis (24/10/2026)

**Escopo:** correção vertical da cena já consumida `WorldMapScreen.tscn`, empilhada sobre a integração #175. Não altera autoloads, saves, coordenadas ou contratos canônicos.

## Defeitos corrigidos

1. `WorldMapLifeLayer._gui_input()` aceitava somente `InputEventMouseButton`. Em Android, `InputEventScreenTouch` é um evento nativo e a emulação de mouse pode estar desativada; o toque no atlas precisava funcionar diretamente.
2. Quando o dispositivo gera um mouse sintético logo após um toque, o mesmo gesto poderia acionar duas vezes a seleção ou navegar para outra página. O atlas agora descarta apenas o mouse pressionado no mesmo ponto (24 px) nos 250 ms seguintes ao toque nativo. O clique de mouse independente continua suportado.
3. A placa opaca de título era desenhada **sobre** os nós do canto superior esquerdo, inclusive `pancada_grande` na página 02. O título da página já existe no `HUD/LeftPanel/PageIndex`, fora do canvas. Remover a placa duplicada mantém o emblema visível sem mudar posições dos dados.

## Consumidor e regressão

- Cena: `scenes/world/WorldMapScreen.tscn`.
- Runtime: `scenes/world/WorldMapLifeLayer.gd`.
- Teste ampliado: `tests/world_atlas_navigation_smoke.gd`.
- CI existente: `.github/workflows/world-atlas-navigation-v1.yml` executa Godot 4.2.2; o Full Game Hardening cobre também Godot 4.3 no PR de integração.

O smoke instancia a cena real, envia `InputEventScreenTouch` e um `InputEventMouseButton` sintético na mesma posição, confirma navegação única, foco único, título fora do canvas e ausência de débitos/viagens. Mantém as verificações anteriores de dez páginas, quarenta nós e proporção das artes candidatas.

## Testes e critérios de promoção

```bash
npm run quality
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/world_atlas_navigation_smoke.gd
godot --headless --path . --script res://tests/baixo_sul_travel_migration_smoke.gd
```

**Android físico (obrigatório antes de release):** instalar build de teste, desligar a emulação de mouse se possível, abrir o atlas, tocar em municípios e nós da página 02 (incluindo Pancada Grande), alternar dez páginas, verificar ausência de seleção dupla, confirmar que Salvador/Itacaré não podem ser destinos jogáveis, e reabrir save migrado. Registrar modelo, Android, build SHA, captura de tela, logs e aprovação humana.

**Não promovido:** as imagens de mapas já produzidas são referências artísticas, não arte final com proveniência/licença/QA Sprite Forge aprovados. Nenhuma rota ou coordenada geográfica nova foi criada. O jogo permanece não certificado para Android.

## Dependências e rollback

- Depende da branch de integração #175, que incorpora os consumidores de #167, #168, #169, #157, #164, #165 e #166.
- #176 (migração regional v5/v6) e #177 (defesa touch do combate) são PRs irmãos, não incorporados neste lote.
- Reverter os commits deste PR restaura a entrada anterior do atlas sem alterar save nem estado do mundo.
- Não mesclar antes de CI verde, revisão humana e reconciliação das discussões relevantes em #168.
