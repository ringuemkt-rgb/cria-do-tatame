# Atlas do Baixo Sul — Navegação interativa v1

**Status:** FEATURE BRANCH / NOT SHIPPING / GEOGRAFIA A CONFERIR  
**Data:** 2026-10-11

## Escopo preservado

O atlas continua com dez páginas e quarenta nós oriundos de `data/world/world_map_v4.json`. O usuário forneceu imagens anteriores de mapas/telas com referência para o mapa ilustrado tropical, ruas/rotas e UI 2.5D. O inventário de origem (sem binários privados) está em `data/visual/baixo_sul_map_reference_ledger_v1.json`.

- Ituberá continua sendo o hub de origem.
- Nilo Peçanha/Zambiapunga, Taperoá, Valença, Camamu, Cairu, Igrapiúna, Maraú, Piraí do Norte, Ibirapitanga e localidades regionais permanecem nos dados.
- Ponte do Saicí, Pancada Grande, Pratigi, Terreiro da Luta e Arena do Dique são pontos associados a Ituberá no escopo regional aprovado.
- Não incluir Salvador e Itacaré como **novas** localidades jogáveis: são referências históricas/contextuais; páginas 07/10 e o manager legado ainda precisam de reconciliação e migração de saves em PR próprio.

## Alterações reais na interface

- Botões táteis **página anterior/próxima** percorrem dez páginas, com wrap e retorno ao panorama.
- Painéis que eram posicionados em coordenadas absolutas >1280 foram substituídos por âncoras proporcionais, para caber no viewport 1280×720 do Godot.
- Estado de página exibe nome, referência de arte carregada ou fallback, e aviso de cartografia pendente.
- O botão Salvador foi desabilitado e marcado CONTEXTO; a tela rejeita viagem fora dos atalhos regionais permitidos.
- A autoridade de viagem continua em `WorldMapManager`, não foi duplicada nem substituída.
- `WorldMapLifeLayer` apenas expõe consultas de página e proveniência (não determina distância, lat/long, disponibilidade de rota ou destino).

## Honestidade cartográfica

As imagens recuperadas são **direção de arte**, não camada vetorial do IBGE. As posições dos emblemas do `world_map_v4.json` ainda precisam ser verificadas contra limites municipais, hidrografia, infraestrutura viária/portuária e rotas locais verificadas. Não atribuir coordenadas GPS, duração de viagem ou distâncias inventadas.

Cinco bases candidatas existentes (01–05) estão disponíveis no runtime. As cinco restantes (06–10) continuam usando fallback procedural; nenhuma foi automaticamente elevada ao estado `shipping`.

O caminho para fidelidade final é:

1. obter geometria IBGE/arquivo de rotas com proveniência/licença;
2. georreferenciar regiões e pontos concretos do jogo, separando claramente lugares ficcionais;
3. pintar camadas raster 2.5D sem texto bakeado, baseadas nas referências do usuário e na malha validada;
4. normalizar atlas, pivôs, oclusão, rota, interações, hitboxes e controle de maré;
5. testar no Godot e em Android físico, revisar contraste e desempenho, aprovar cada página.

## Validação e dívida registrada

```bash
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/world_atlas_navigation_smoke.gd
godot --headless --path . --script res://tests/world_map_life_smoke.gd
npm run quality
```

Este PR não altera o schema de save. **Conflito conhecido:** `WorldMapManager` ainda contém Salvador como hub legado liberado e `tests/progression_os_smoke.gd` o usa; um port de escopo regional completo terá de migrar dados e testes em um lote separado, sem apagar o save anterior. O botão do atlas não deverá oferecer tal destino.

**Rollback:** reverter código/TS CN/testes/ledger deste PR, sem migração de dados.

## Regressão de layout — 2026-10-17

O teste antigo exigia controles à direita apesar da barra inferior. A validação de limites também revelou que o `GridContainer` superior crescia sobre o canvas: suas colunas não repartiam a largura disponível e o texto multilinha elevava a altura mínima. Os quatro campos da primeira linha agora expandem horizontalmente, preservando a faixa reservada.

O smoke ajusta o viewport real antes de instanciar a cena e testa as dez páginas em 1280×720, 1600×720 e 1280×800. Verifica limites, altura dos botões e ausência de sobreposição com o mapa. Os filtros da CI incluem o mapa JSON, o contrato visual e as imagens candidatas consumidos.

Godot 4.3 stable oficial `77dcf97d8`, Linux headless: importação sem erros; navegação **584 verificações, zero falhas**; `world_map_life_smoke.gd` **14 verificações aprovadas**. `npm run quality` executado: bloqueado no perfil ausente `counter_entry` de Davi em Sprite Forge Phase 1, também reproduzido na main sem alterações `099c060`. Esse gate não foi dispensado. Revisão visual humana, geografia, #169 e Android físico continuam pendentes. Rollback: reverter este commit focado.
