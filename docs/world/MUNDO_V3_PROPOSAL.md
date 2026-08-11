# Mundo V3 — proposta geográfica e sistêmica

**Status:** DRAFT — PENDING HUMAN CANON MIGRATION

**Dados:** mapa, 12 arenas, elenco de 23 combatentes e árvore de cinco arquétipos

**Runtime:** inativo; nenhum manager, autoload ou save foi substituído.

## Recorte geográfico

O mapa usa municípios e referências reais como base cultural, mas rotas, custos, arenas, NPCs e facções são ficção de gameplay. Os valores de Criacoin e horas não afirmam tarifas ou tempos reais.

Correções verificadas:

- a [APA do Pratigi](https://www.ba.gov.br/inema/gestao-2/unidades-de-conservacao/apa/apa-do-pratigi) abrange Igrapiúna, Ituberá, Nilo Peçanha, Ibirapitanga e Piraí do Norte;
- a [Prefeitura de Ituberá](https://www.itubera.ba.gov.br/site/dadosmunicipais) lista Praia do Pratigi, Pancada Grande e Ponte da Saici entre seus referenciais; a Ponte da Saici foi, portanto, movida de Camamu para Ituberá;
- o [IPAC](https://www.ba.gov.br/ipac/zambiapunga) descreve a Zambiapunga como manifestação cultural de matriz banto; o conteúdo exige consultoria cultural e nunca oculta telegraphs;
- mapas oficiais da SEI situam [Itacaré](https://ftp.sei.ba.gov.br/Geoinformacao/mapas/munic/vigente/mapa_com_descritivo_atual_2914901.pdf) e [Maraú](https://ftp.sei.ba.gov.br/Geoinformacao/mapas/munic/vigente/mapa_com_descritivo_atual_2920700.pdf) no Território de Identidade Litoral Sul. Eles aparecem como expansão regional, não como núcleo estrito do Baixo Sul.

## Grafo

`data/world/mapa_v3.json` contém 10 nós e 10 arestas. Todos os destinos são resolvidos, inclusive `ferro_velho_lapa`, ausente no rascunho original. O grafo é conectado quando lido como rede de viagem bidirecional.

| Nó | Papel | Arenas |
|---|---|---|
| Ituberá | hub LEM | Terreiro, Pancada Grande, Ponte da Saici, Pratigi |
| Valença | trânsito oficial | Arena do Dique — filial |
| Cairu | mangue/ilhas | Manguezal Profundo, Mirante da Gamboa |
| Taperoá | festival ALE | Budokan das Águas |
| Nilo Peçanha | piaçava e memória | Roda da Zambiapunga |
| Camamu | baía e conexão | atividades de hub |
| Maraú | expansão pós-jogo | expedição futura |
| Itacaré | expansão costeira | Itacaré Noturna |
| Salvador | institucional neutro | Sede do Circuito Final |
| Ferro Velho da Lapa | sublocal ficcional NTM | Ferro Velho da Lapa |

## Arenas e segurança

As 12 arenas vivem em `data/arenas/arenas_12_v3.json`. Marcas de federações reais foram retiradas dos dados: os IDs são `training_controlled`, `gi_official_points`, `nogi_clandestine_submission_only` e `festival_exhibition`.

Todo cenário exige tatame nivelado, limite protegido e telegraphs preservados. Lama, areia, maré, cachoeira, sucata, ponte e água são atmosfera fora da superfície de combate. A arena Zambiapunga exige revisão cultural humana.

## Elenco

`data/characters/elenco_23_v3.json` contém 23 combatentes únicos:

- 18 jogáveis propostos;
- 5 treinadores/oponentes não jogáveis;
- NPCs de serviço em catálogo separado.

O ID `oni_da_lapa` é preservado; `oni_do_sul` aparece apenas como alias proposto. Tinker jogável, Nado, Helena e os demais IDs novos continuam bloqueados para revisão. Termos culturais usados em nomes também carregam gate humano.

## Árvore V3

`data/skill_tree/skill_tree_v3.json` modela Pressão, Tático, Guarda/Raspagem, Condicionamento e Mentalidade. Cada nó possui três ranks e cada ramo uma suprema que respeita tap/escape. “Dano de finalização” foi substituído por eficiência de controle técnico.

A árvore está inativa porque substitui a direção 4×4 anterior e requer:

- decisão canônica;
- balanceamento;
- mapper de nós antigos;
- versão e migração de save;
- testes de regressão do deck, progressão e Ground Stamina.

## Integração correta no Godot

O rascunho de “ativação total” sugeria novos `MissionSystem`, `WorldMapV3` e `CoverSystem`. Isso duplicaria managers canônicos. A integração aprovada deverá reutilizar:

| Proposta | Consumidor correto após aprovação |
|---|---|
| 40 missões | `DataRegistry` + `MissionManager` |
| mapa e viagem | `WorldMapManager`/estado de mundo existentes |
| exposição da capa | `WorldState` + `SaveManager` com migração |
| reputação e finais | matriz/fluxo existentes, por adapter |
| interação de NPC | cena/controlador existente ou adapter, sem autoload novo |

## Produção visual futura

O BOM proposto cobre seis famílias de tileset, 12 arenas, retratos/sheets do elenco, sete crowds e ícones de rota. Nada entra em `assets/aprovados` antes de licença, QA, aprovação humana e integração em cena. O mapa do Baixo Sul é item reservado; nenhuma promoção automática é permitida.
