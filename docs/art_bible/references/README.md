# Referências visuais aprovadas

Esta pasta registra as referências fornecidas e aprovadas pelo dono do projeto em 2026-07-24.

## Manifesto

`REFERENCE_MANIFEST_V1.json` contém:

- IDs das nove imagens-fonte analisadas;
- dimensões;
- hashes SHA-256 dos derivados locais aprovados;
- declaração da logo oficial;
- estado de importação dos binários.

## Status

```text
brand_status = official_reference
production_status = master_pending
runtime_status = not_runtime_asset
binary_import_status = pending_asset_pr
```

A direção da marca está congelada, mas os binários locais não foram enviados por este conector. Um PR de asset dedicado deverá incorporar:

- recorte de referência da logo;
- contato das pranchas;
- master vetorial;
- PNG transparente 4K;
- metadados de origem e direitos.

Nenhuma prancha densa deve ser importada como sprite, background ou tela final. Ela orienta a reconstrução técnica em assets separados, com manifest, licença, cena de teste e QA.
