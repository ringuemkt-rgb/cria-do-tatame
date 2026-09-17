# MAP ATLAS RUNTIME v1

Status: `shipping=false`. Contrato de apresentação do mapa vivo. Não substitui CombatManager nem WorldMapManager.

## Quem manda

| Problema | Autoridade |
|---|---|
| Viajar / hubs desbloqueados | `WorldMapManager` |
| Bloco do dia, clima, economia, plano opcional de IA | `WorldDirectorManager` |
| Agenda de NPC (minutos, nó, atividade) | `NPCEcologyEngineV1` |
| Lua, maré, camadas, life cap, lock composto | `MapAtlasPresenter` |
| Luta | `CombatManager` |

IA remota (Hugging Face / proxy) só via `WorldDirectorManager.configure_ai_proxy`. Default OFF. Offline-first. LLM não muda frame, não pinta mapa, não luta.

## Camadas

L0 céu/água/espuma (shader) → L1 chão pintado sem HUD → L2 vida + névoa → L3 grafo (nós/rotas/pawn) → HUD Control.

Key-art oficial = âncora de look. `map_base` 1536×864 sem chrome. Amplitude de água ≤ 2 px.

## Tempo vivo

- Blocos: manhã / tarde / noite / madrugada (`WorldDirectorManager`)
- Clima por região: cadeia em `climate_regions_v01.json`
- Lua: `(week * 7 + day_index) % 8` em `moon_tide_v01.json`
- Maré deriva da fase + bloco. Rotas marítimas com `bloqueavel_por_mare` fecham em `mare_baixa`.
- Pratigi do Avesso: `ato4` + `lua_cheia` + `mare_baixa` (cânone `world_map_v4`)

## Vida / NPC

O atlas **não** simula agente. Tiers:

- L0_DORMANT / L1_STATISTICAL — calendário
- L2_ACTIVE_REGION — presença no plate (áx 3–4 atores)
- L3_FULL_RUNTIME — só cena de hub walkable

Cast nomeado em `npc_map_profiles_v01.json` + rotina densa em `npc_routines_v01.json`.

## Input

L navegar · R zoom 1.0–1.35 · A entrar · Y detalhe · B voltar.

## Quality

`python3 tools/data/validate_map_atlas_v1.py`
`python3 -m unittest tests.test_map_atlas_runtime_v1`
