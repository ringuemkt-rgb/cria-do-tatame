# Gold Slice — transições candidatas

**Status:** AUTHORING ONLY · `shipping=false` · `qa_status=pending`.

Os 10 JSONs são projeções de `data/techniques.json` (fonte mestra, decisão D6).
`CombatManager`, `CombatStateMachine`, `TechniqueResolver` e `DataRegistry` existentes continuam as únicas autoridades de gameplay.
**Não existe carregamento automático destes JSONs.** Para consumi-los, primeiro propor um adapter não destrutivo, revisar compatibilidade com `data/techniques/technique_slice_ouro_v1.json`, integrar e testar separadamente. Este lote não modifica runtime.

Mapeamento: usar estados `PLAYER_*` do catálogo sem reinterpretá-los. Campos numéricos novos com zero são placeholders **sem efeito autorizado**; `denial_reward` espelha o exemplo de authoring solicitado, mas não é uma regra de pontuação ativa.
`legal_ibjjf`/`legal_adcc` são **flags preliminares**, não certificação por faixa, divisão, fase de combate ou ruleset; a regra versionada `data/combat/bjj_rulesets_verified_v1.json` decide legalidade e score. `score_event=none` significa revisão pendente, não ausência definitiva de pontuação.

O catálogo de `sprawl` declara saída `PLAYER_STANDING_NEUTRAL`, enquanto o overlay do slice declara `PLAYER_TOP_CLINCH`. Este lote preserva o catálogo; conflito de overlay requer revisão humana antes de integração.
Cada técnica animada futura exige dupla attacker/defender e `sync_map.json`; não há sprites neste lote.
