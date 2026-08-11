# Visual QA V2

`tools/audit/visual_qa_v2.py` é o gate determinístico para candidatos pixel art. Ele valida o arquivo original; nunca redimensiona a entrada para fazê-la caber no contrato.

## O que o gate mede

- resolução exata, por padrão `480×270`;
- orçamento de cores visíveis;
- distância de paleta por CIEDE2000, com média e percentil 95;
- pixels candidatos a anti-aliasing por alfa parcial ou interpolação linear entre vizinhos;
- padrões checkerboard de dithering fora das regiões explicitamente autorizadas;
- cobertura e espessura do outline de 1 px quando a spec fornece uma máscara binária;
- SHA-256 da entrada e métricas reproduzíveis no relatório JSON.

A detecção de anti-aliasing é uma heurística auditável, não um classificador semântico. A medição de outline não é declarada sem máscara: o relatório emite `outline_not_measured_without_mask`. Aprovação biomecânica, licença GATE-L1 e promoção humana continuam sendo gates separados.

## Auditar um candidato

Exemplo de spec:

```json
{
  "biome": "terreiro",
  "expected_size": [480, 270],
  "dithering_regions": [[0, 180, 480, 90]],
  "outline": {
    "required": true,
    "mask_path": "ruan_foreground_mask.png"
  }
}
```

Execução:

```bash
python tools/audit/visual_qa_v2.py audit \
  assets/candidatos/ruan.png spec.json \
  --report qa/relatorios/ruan.visual_qa.json
```

O processo termina com código `0` somente quando `pass` é verdadeiro, `1` quando o candidato reprova e `2` quando a entrada ou a spec é inválida.

## Injetar rótulos determinísticos

O pipeline não inclui nem pressupõe uma fonte. A fonte, sua licença e, opcionalmente, seu hash precisam ser informados:

```bash
python tools/audit/visual_qa_v2.py inject \
  mapa_sem_texto.png rotulos.json mapa_rotulado.png \
  --font caminho/fonte_pixel.ttf \
  --font-license caminho/OFL.txt \
  --font-sha256 HASH_FIXADO
```

Os textos são normalizados, convertidos para caixa alta e rasterizados em máscara binária. Rótulos fora do canvas, fonte sem licença ou hash divergente interrompem a operação.

## Verificação do contrato

```bash
npm run validate:visual-qa-v2
npm run test:visual-qa-v2
```

A workflow dedicada instala uma versão limitada do Pillow e executa os fixtures de resolução, CIEDE2000, AA, dithering, outline e rótulos.
