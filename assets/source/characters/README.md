# Fontes visuais canônicas dos personagens — v01

Este diretório guarda as fontes de identidade do elenco principal de `data/characters.json`.
O lote v01 cobre os oito personagens canônicos atuais com uma folha-modelo, uma fonte
cromática de retrato, uma fonte cromática de seed e uma tira idle de quatro quadros para
cada identidade. O lote também contém uma folha de poses funcionais por personagem,
extraída em 50 key poses RGBA 512×512, e uma sequência pareada Ruan × Davi com sete chaves.
O lote v02 acrescenta sete folhas brutas de animação, processadas em 34 quadros RGBA,
sete spritesheets/GIFs candidatos e um animatic pareado de sete quadros.

## Método e origem

- Geração: ferramenta de imagem integrada da OpenAI, com referências internas geradas no próprio lote.
- Referências externas: nenhuma fotografia, atleta, academia, marca ou asset de outro jogo.
- Direção: `data/lore/visual_production_manifest_v01.json` e `data/visual/graphic_asset_catalog_v01.json`.
- Estilo: HD Pixel Art 2.5D Regional Premium, leitura mobile e patches ficcionais.
- Limpeza: chroma verde; Leoa usa chroma ciano para preservar o kimono verde.
- Normalização: retratos em 512×512; seeds em 256×256; nearest-neighbor; alpha real.
- Direitos: geração original para o projeto, sujeita aos termos aplicáveis da conta e à revisão jurídica de release.

## Processo aplicado

1. Folha-modelo com frente, perfil, costas, pose funcional e expressões.
2. Retrato derivado usando a folha-modelo como trava de identidade.
3. Seed de corpo inteiro derivado usando folha-modelo e retrato aprovados.
4. Remoção determinística de chroma com `tools/visual/chroma_key_asset.py`.
5. Tiras geradas de uma vez, curadas por componente alfa e normalizadas pela altura,
   linha de chão e pivô do seed aprovado.
6. Folhas de ação extraídas por grade, limpas por componente alfa e normalizadas para
   512×512 pelo `tools/visual/build_character_pose_library.py`.
7. Ações prioritárias recortadas, limpas e alinhadas por sequência pelo
   `tools/visual/build_action_animation_batch.py`, preservando pivô e linha de chão.

O teste inicial de transparência de Ruan incorporou um xadrez visual e foi rejeitado;
ele permanece em `ruan_macacao/rejected/` apenas para rastreabilidade e não aparece no manifesto.

Folhas-modelo e fontes cromáticas não são sprites finais. Os PNGs limpos em
`assets/graphics/characters/` passaram por QA de arquivo, mas só recebem status de runtime
após importação e inspeção no Godot. As poses de ação são fontes de animação e não podem
ser promovidas diretamente como se fossem movimentos completos.
Os packs v02 permanecem `candidate_only`; os que usam manequim são fontes e exigem a
substituição por oponente canônico antes da promoção.
