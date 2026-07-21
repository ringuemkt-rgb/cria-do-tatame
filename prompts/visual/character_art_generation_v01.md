# Prompts de produção — personagens v01

## Contrato comum

Todos os pedidos fixaram: identidade idêntica à folha-modelo, HD Painted Pixel Art 2.5D,
silhueta legível em 256 px, anatomia humana plausível, Jiu-Jitsu esportivo sem trocação,
patches ficcionais, ausência de texto/marcas reais e fundo cromático plano. Retratos usam
enquadramento 1:1 de cintura para cima. Seeds usam corpo inteiro, margem de animação e
pivô inferior central. As negativas incluem membros extras, deriva facial, armas, sangue,
fotorealismo, anime e transformação fantástica.

## Âncoras por personagem

- `ruan_macacao`: jovem baiano compacto; gi branco gasto; faixa branca; patches inspirados no Silverback; pressão gentil e determinada.
- `davi_relampago`: rival seco e veloz; gi azul-marinho; faixa branca; base móvel e leitura fria.
- `mestre_dende`: mentor negro maduro; cabelo/barba grisalhos; gi reparado; faixa preta; emblema sol/raiz; gesto didático.
- `tinker_bell`: aliado jovem e urbano; sobrecamisa grafite, camiseta azul, mochila e telefone ficcional; atenção de bastidor.
- `cassio_molho`: atleta/promotor carismático; no-gi preto, laranja e vermelho; provocação controlada sem golpe.
- `kenzo_kuroi`: rival nipo-brasileiro preciso; gi carvão/índigo; faixa marrom; sem clichê ninja ou samurai.
- `leoa_quilombola`: lutadora negra forte e digna; tranças em coque; gi verde e faixa roxa; raiz, resistência e base baixa.
- `oni_da_lapa`: rival humano pesado; gi grafite e costura ferrugem; faixa marrom; pressão intimidante sem traço demoníaco.

## Tiras idle v01

Quatro quadros por personagem foram solicitados em uma única edição: seed exato,
inspiração sutil, microação coerente com o papel e expiração/retorno. Lutadores fazem apenas
transferência mínima de peso e mãos de pegada, sem deslizar os pés. Dendê mantém gesto
didático; Tinker mantém o telefone na mesma mão e altura. Cada quadro 01 é travado ao seed
aprovado durante a normalização.

## Folhas de ação v01

Cada personagem recebeu uma única folha multipose derivada de sua folha-modelo e seed.
Os prompts fixaram ordem de leitura, câmera 3/4, escala, linha de chão, vestuário e ações do
`graphic_asset_catalog_v01.json`. Posições que exigem contato usam manequim carvão sem
identidade; Leoa usa chroma ciano para preservar o kimono verde. O conteúdo foi separado
em 50 key poses RGBA 512×512 com pivô inferior central.

Ordem final das folhas:

- Ruan, 4×3: `stance`, `grip`, `clinch`, `takedown`, `top_guard`, `side_control`,
  `mount`, `back_control`, `technical_finish`, `win`, `loss`; célula 12 vazia.
- Davi, 3×2: `walk`, `sprawl`, `counter`, `scramble`, `loss`, `respect`.
- Dendê, 3×1: `teaching`, `arms_crossed`, `dialogue`.
- Tinker, 3×2: `phone`, `filming`, `concerned`, `celebrating`, `leaving`, `dialogue`.
- Cássio, 3×2: `stage`, `stance`, `offer`, `provocation`, `contract`, `stage_composed`.
- Kenzo, 3×2: `walk`, `stance`, `reading`, `punish_error`, `counter`, `silent_bow`.
- Leoa, 3×2: `walk`, `base`, `sweep_setup`, `sweep`, `root_pressure`, `victory`.
- Oni, 3×2: `walk`, `stance`, `burst`, `pressure`, `underground_win`, `loss`.

Contrato negativo comum: sem texto, marcas, atleta real, golpes, sangue, lesão, armas,
membros extras, deriva facial, mudança de faixa, anime, fotorealismo, brilho 3D ou cenário.

## Sequência pareada Ruan × Davi

A geração conjunta travou os dois modelos e sete estados oficiais: distância, pegada,
entrada de baiana, disputa da queda, cem quilos, tap/release e reset respeitoso. Foram
proibidos golpes, slam, lesão, sangue, teleporte de pegada e troca de identidade. A saída é
uma referência biomecânica; frames intermediários e integração Godot ainda são gates.
