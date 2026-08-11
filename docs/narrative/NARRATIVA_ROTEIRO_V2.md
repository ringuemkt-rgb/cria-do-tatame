# Roteiro de campanha v2 — proposta de cânone v5

**Status:** DRAFT — PENDING HUMAN CANON MIGRATION

**Diretivas:** `/ctt.narrativa.missoes.v1` e `/ctt.narrativa.dialogos.v1`

**Dados:** `data/missions/campaign_missions_v1.json`

**Runtime:** inativo; `MissionManager` e o save atual não foram alterados.

Rastreamento: issue #62. O PR deste pacote é empilhado sobre o PR #61.

## Resultado deste lote

A campanha foi estruturada como 40 missões sequenciais, divididas em cinco atos de oito missões. Cada entrada possui objetivo público, objetivo oculto opcional, briefing, escolhas, efeitos, recompensas e gates. O ledger conecta o incêndio do Terreiro, a dívida de Dendê, a ascensão de Oni e a operação acompanhada por Helena.

O conteúdo é uma proposta validada, não uma campanha jogável integrada. O contrato canônico v4.1 proíbe novos personagens e atos no lote atual; ativação exige revisão humana, migração de IDs e save, adapter para o runtime existente e smoke test em Godot.

## Estrutura dos atos

| Ato | Missões | Movimento dramático |
|---|---|---|
| 1 — Raiz | M01–M08 | tutorial, primeira queda, Valença, fogo de 2019 e contato de Helena |
| 2 — Maré | M09–M16 | festival, circuito, contrato, rivalidade e bilhete de entrada |
| 3 — Mangue | M17–M24 | NTM, Fichas de Ferro, lesão, Tinker mission-control e cofre localizado |
| 4 — Dique | M25–M32 | mídia, rivais, escândalo, verdade de Dendê e credencial final |
| 5 — Pressão | M33–M40 | semana final, chave/rota documental, final, ledger e epílogo |

## Sistemas narrativos

- `cover_exposure`: escala oculta de 0–100; menor é mais seguro. O nome elimina a ambiguidade do rascunho em que “capa” às vezes significava proteção e às vezes exposição.
- `double_briefing`: Tinker apresenta a leitura pública da luta; Helena oferece objetivo oculto opcional.
- `ledger`: estados explícitos de desconhecido até entregue, destruído ou submetido à responsabilização comunitária.
- `ferro_tokens`: moeda estritamente ficcional do NTM, sem conversão para dinheiro real.
- apostas: somente em lutas de terceiros, em Criacoin e com teto de 200.

M36 nunca bloqueia a campanha. Se a exposição da capa impedir a janela da chave, Tinker abre uma rota documental que ainda leva a M39.

## Fios e colheitas

| Fio | Planta | Colheita |
|---|---|---|
| Passado de Dendê | M06 | M19, M31 |
| Emboscada de Valença | M04 | M08 |
| Bilhete | M16 | M17 |
| Dívida e ledger | M06, M11 | M24, M36, M39 |
| Segredo de Tinker | M11 | M21, M23 |
| Rivalidade de Davi | M05 | M13, M30, M37 |
| Primeira faixa | M29 | M34, M38, M40 |
| Gentileza | M01 | M40 |

O gate automático verifica que toda colheita ocorre depois de pelo menos uma planta e que nenhuma referência aponta para missão inexistente.

## Finais propostos

| ID | Chave principal | Eixos de avaliação |
|---|---|---|
| `root` | entrega com depoimento | Honra, Legado, vínculo Tinker |
| `idol` | entrega/proteção de nomes | Hype, vínculo Tinker |
| `shadow` | destruição do ledger | Sombra |
| `double_face` | proteção dos nomes das crias | Honra, Sombra, exposição |
| `cria` | responsabilização comunitária | Honra, Legado, Comunidade, vínculo Tinker |

Nenhum final é promovido automaticamente. M39 define a família de consequência; M40 avalia os eixos e executa o epílogo após a integração humana.

## Segurança e tom

- Tap e escape são soberanos e nunca retiram Honra. M05 foi corrigida para premiar decisão segura.
- Treinar lesionado agrava a lesão e não concede recompensa.
- Finalizações não causam “dano” e não são automáticas.
- Objetivos ocultos não substituem a simulação biomecânica.
- A operação observa a emboscada; ela não cria uma agressão para “testar” Ruan.
- A escrita não fornece instruções operacionais de crime ou investigação.

## Diálogos-fonte

Seis nós Yarn foram normalizados em `data/dialogues/yarn_drafts/`: M06, M08, M23, M31, M36 e M39. Eles usam comandos `<<set $variavel ...>>` separados e permanecem fontes de escrita. O projeto não possui consumidor Yarn aprovado; por isso os arquivos não são carregados pelo runtime.

## Gates de integração

1. Aprovar Helena, o papel de Tinker e a história Dendê/Oni no cânone.
2. Resolver a identidade estável de Oni e os demais IDs novos.
3. Definir schema de missão e migração de save.
4. Fazer `DataRegistry` adaptar a proposta para o `MissionManager` existente.
5. Implementar exposição da capa em `WorldState`/save, sem criar singleton concorrente.
6. Compilar os diálogos com ferramenta licenciada e consumer aprovado.
7. Executar parser/import Godot, smoke de missão e roundtrip de save.

Validação offline:

```bash
python tools/audit/validate_world_narrative_v3.py
python -m unittest discover -s tests/narrative -p 'test_*.py'
```
