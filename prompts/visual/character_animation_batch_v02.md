# Prompts de produção — animação de personagens v02

## Contrato comum

As gerações usaram folha-modelo, seed e key pose do próprio projeto como referências
obrigatórias. O pedido comum fixou HD Painted Pixel Art 2D, câmera ortográfica 3/4,
escala e luz constantes, corpo inteiro, leitura mobile, chroma plano, ordem cronológica,
identidade/roupa/faixa imutáveis e jiu-jitsu esportivo gamificado. Foram proibidos texto,
marcas reais, pessoas extras, troca de papéis, membros extras, armas, golpes, sangue,
lesão, instrução real de violência, fotorealismo e cenário.

## Planos de quadros usados

- Davi × Ruan, 3×2/6 quadros: leitura da entrada, quadril para trás, contato, sprawl,
  clinch frontal neutro e reset. Davi sempre defende de gi azul; Ruan sempre ataca de
  gi branco. Ambos são referências canônicas.
- Leoa + manequim, 3×2/6: guarda fechada, conexão, desequilíbrio, raspagem tesoura,
  inversão e estabilização por cima. Chroma ciano preserva o gi verde.
- Oni + manequim, 5×1: entrada lateral, contato, assentamento da pressão, controle e
  microvariação respiratória para loop.
- Mestre Dendê, 4×1: seed, palma aberta, ênfase didática e retorno ao seed.
- Tinker Bell, 4×1: seed com telefone, elevação horizontal, reenquadramento e retorno.
- Cássio, 4×1: seed, convite gestual, provocação carismática sem ataque e retorno.
- Kenzo + manequim, 5×1: leitura, interceptação, mudança de ângulo, estabilização do
  contra-ataque e soltura controlada.

## Pós-processamento

`build_action_animation_batch.py` remove o chroma com tolerância fixa, separa a grade,
retém um corpo ou o par significativo, normaliza toda a sequência pela mesma escala e
pivô, trava seed inicial/final quando exigido e produz frames, atlas, GIF, prancha,
manifesto e hashes. O manequim é explicitamente temporário e não representa personagem
canônico.
