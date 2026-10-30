# Identidade visual do elenco — atlas v1

**Status:** CANDIDATE AUTHORING / NÃO SHIPPING  
**Data:** 2026-10-17  
**Escopo:** 39 personagens corpóreos, incluindo todos os 17 lutadores do roster, em 117 vistas estáticas.

## Resultado utilizável

Dez PNGs RGBA em `assets/candidates/characters/identity_v1/` contêm frente, perfil direito e costas. As regiões absolutas de cada figura, dimensões e hashes ficam em `production/character_art_v1/atlas_manifest.json`. Não é necessário adivinhar células ou cortar manualmente as pranchas para compará-las no Godot.

O visualizador `tools/art/CharacterAtlasReview.tscn` é um consumidor real no Godot do mesmo projeto: seleção por personagem, três vistas, filtro nearest, apoio dos pés em `[64,96]` e enquadramento lógico de 128×128, com alturas menores para crianças. Não há novo singleton, engine, regra de combate, save ou backend. A prévia normaliza a exibição; os PNGs originais não foram reamostrados ou promovidos para sprites finais.

## Elenco e precedência

Fontes: `data/narrative/canon_v3.json`, `character_bible_v1.json`, `narrative_v3_fixes_characters.json` e `data/combat/roster_v3.json`. Os overrides vigentes são aplicados antes de gerar os metadados. Os IDs de runtime permanecem intactos; aliases visuais resolvem Jacaré, Montenegro, Leoa e os três arquétipos sem renomear saves.

| Atlas | Personagens |
|---|---|
| 01 | Ruan, Davi, Leoa, Oni da Lapa |
| 02 | Mestre Dendê, Joaquim Tinker Bell, Cássio Molho, Kenzo Kuroi |
| 03 | Jacaré, Oni do Sul, Mateus Predador, Verão Velho |
| 04 | Byaku, Ubirá, Montenegro, Ruan do Avesso |
| 05 | Viera, Miyao, Galvão, Adriano Degodo |
| 06 | Biel, Dandara, Pedro Bala, Pipoca |
| 07 | Foguete, Tiago Bomfim, Vera Salles, Raimundo |
| 08 | Dona Chie, Dona Zefa, Mestre Quirino, Seu Neco |
| 09 | Iara, Mãe Santinha, Nego Maré, Caique |
| 10 | Zé de Barro, Dr. Sombra, George Chupeta |

Teruko permanece nos fragmentos de memória; não se inventou retrato físico. O Coro permanece sem corpo fixo. Viera, Miyao e Galvão são desenhos ficcionais, sem referência a atletas reais. As idades aparentes não definidas numericamente no roteiro são propostas autorais, não fatos novos de gameplay.

Correções em relação às referências iniciais: Davi usa faixa azul no slice; Oni da Lapa usa NO-GI. As pranchas iniciais permanecem em `references/` como histórico, com ressalvas explícitas no source ledger. Tinker é civil, conforme o override vigente. Ruan do Avesso é um espelho humano, não demônio, e este estudo representa somente a variante inicial; o loadout por save ainda não foi produzido.

## Como abrir e validar

```bash
python -m pip install -r tools/art/requirements-character-review.txt
python tools/art/character_identity_atlases.py
godot --headless --editor --path . --quit
godot --path . res://tools/art/CharacterAtlasReview.tscn
godot --headless --path . --script res://tests/character_identity_atlas_smoke.gd
```

Para reconstruir medidas e sidecars a partir dos PNGs existentes: `python tools/art/character_identity_atlases.py --write`. A ferramenta mede pixels sem alterar os arquivos. Ela rejeita atlas sem exatamente três corpos isolados por personagem; dois candidatos com contato entre linhas foram regenerados. O recorte é determinado pelos componentes opacos reais, não por uma grade supostamente perfeita. A IA não determina colisão, pegada, pontuação ou animação.

Cada identidade usa o schema existente `character_identity_master_v2.schema.json`. O source ledger registra ferramenta, referência, revisão, captura de prompt e estado de direitos. Os prompts completos de 04–10 e as duas revisões de espaçamento estão versionados; os prompts originais 01–03 permanecem apenas no histórico da sessão, limitação explicitamente registrada. A revisão do modelo do gerador não foi exposta pela ferramenta e não foi inventada.

## Limites reais

Os 117 corpos foram identificados e têm regiões não vazias; não há contato das figuras com a borda das imagens no lote selecionado. Ainda existem pixels de alpha parcial/contorno nas fontes. Precisam de limpeza por pixel, aprovação da identidade, revisão de acessórios/assimetria e direitos antes do handoff de sprites. As paletas são amostras propostas, não uma quantização aplicada à imagem.

Não foram fabricadas animações de caminhada, idle em loop ou técnicas pareadas, nem variantes GI/NO-GI ausentes. Um turnaround estático não conta como uma animação funcional. O mestre de identidade continua `PENDING`, `human_reviewer=null`, `rights_status=PENDING`, `shipping=false`; nenhuma aprovação foi inferida para os novos desenhos.

Os presets Android e Windows excluem este pacote e o visualizador de autoria da exportação. Não houve exportação, instalação ou certificação em aparelho neste lote. A promoção deve usar o Asset Pipeline/Sprite Forge já existente após os gates, substituindo os placeholders em lote próprio com teste de fluxo.

Rollback: reverter o commit deste pacote e suas exclusões de exportação; nenhum save foi migrado e nenhum placeholder foi sobrescrito.

## Evidência local

Godot 4.3 stable oficial `77dcf97d8`: importação sem erros de script/recurso; smoke de autoria **989 verificações, zero falhas**, incluindo todas as 117 vistas, aliases e limites visíveis; smoke central **115 verificações, zero falhas**. Validação de 39 mestres de identidade contra o schema existente: aprovada. External Tools: 7 testes; Sprite Forge v2: 8 testes, aprovados. O validador de Sprite Forge v2 continua informando que o grafo BJJ completo está incompleto; este pacote não muda essa condição.

`npm run quality` foi executado antes/depois e encontra a mesma falha preexistente da base `099c060`: falta perfil `counter_entry` de Davi em Sprite Forge Phase 1. O workflow Repository Quality executa um subconjunto diferente e não substitui esse comando. O gate de autoria deste PR testa integridade/consumo, não aprovação humana ou shipping.
