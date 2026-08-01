# Migração V4.2 — Facções e Save

**Status:** ACTIVE  
**Escopo:** três facções canônicas, aliases legados e save v5.

## Objetivo

Migrar o runtime de sete organizações ativas para exatamente três facções canônicas, sem apagar dados de saves antigos e sem criar managers paralelos.

## Facções ativas

| ID canônico | Nome de exibição | ID legado aceito |
|---|---|---|
| `ALE` | Os Aleluiado | `os_aleluia` |
| `LEM` | Lá Ele Mil Vezes | `la_ele_mil_vezes` |
| `NTM` | Nós Tem Um Molho | `nos_tem_um_molho` |

Novos saves escrevem os IDs canônicos. Missões e dados antigos podem continuar emitindo IDs legados temporariamente; o mapper converte esses valores na borda do sistema.

## O que deixou de ser facção ativa

- `terreiro` e `raiz`: comunidade e instituições narrativas;
- `circuito_oficial` e `cria_live`: instituições;
- `atalhos`: eixo narrativo;
- `dragao_vermelho` e `fantasma`: lore aposentado.

Esses domínios continuam existindo no mundo e na narrativa, mas não executam operações políticas autônomas no `FactionDirectorManager`.

## Compatibilidade de save

A versão do save passa de 4 para 5.

Ao carregar um save antigo:

1. `os_aleluia`, `la_ele_mil_vezes` e `nos_tem_um_molho` são convertidos para `ALE`, `LEM` e `NTM`;
2. relações, heat e flags dos três aliases são preservados;
3. dados de Terreiro, Raiz, Dragão e Fantasma são movidos para `legacy_archive`;
4. territórios antigos desses domínios passam a neutros, mantendo `legacy_owner`;
5. conflitos e operações inválidos são arquivados;
6. o save migrado é regravado atomicamente como versão 5;
7. o backup continua disponível caso a promoção do arquivo falhe.

A migração é idempotente: carregar novamente um save já migrado não cria facções duplicadas.

## Arquivos principais

- `src/factions/FactionIdentityV4.gd` — mapper e migração estrutural;
- `src/autoloads/FactionManager.gd` — relações, heat, flags e aliases;
- `src/autoloads/FactionDirectorManager.gd` — simulação política existente;
- `src/autoloads/SaveManager.gd` — save v5 e persistência pós-migração;
- `data/factions/faction_director_v02.json` — três facções ativas;
- `data/world/faction_territories_v02.json` — territórios com IDs canônicos;
- `data/production/faction_migration_v4_2.json` — contrato executável;
- `tools/audit/validate_faction_migration_v4_2.py` — gate automático.

## O que não mudou

- `CombatManager`;
- `DeckManager`;
- `AudioManager`;
- `project.godot` e a lista de autoloads;
- cartas e posições de combate;
- arte e áudio;
- regras GI e No-Gi.

## Próximo lote

O V4.3 tratará cartas, posições e rulesets **GI + No-Gi**, acompanhado pelo EPIC #44.
