# CRIA DO TATAME – PRESSÃO
## GDD‑CDT v4.0 — Seções 9–17

**Fonte:** conteúdo aprovado pelo Mestre em 24/07/2026.  
**Autoridade:** complementa `GDD_CDT_V4_CANON_INTAKE.md` e substitui versões anteriores quando houver conflito.

> Nota de integridade: as Seções 9–15 e 17 foram recebidas com conteúdo material. A Seção 16 veio como referência ao plano de migração em sete fases, não como o texto integral original de branches/commits/template. O Apêndice B voltou a ser truncado e o Apêndice C não chegou nesta mensagem; portanto, esses itens permanecem pendentes e não serão inventados.

# 9. Estrutura narrativa e beat sheet

```text
PRÓLOGO  "O Peso do Macacão"        Terreiro                         Escolha 1
ATO I    "Raiz"                     Terreiro→Pancada→Manguezal       Escolhas 2,3
ATO II-A "O Circuito"               Dique→Budokan                    Escolha 4; Kenzo
ATO II-B "O Submundo + TUPA-200"    Ferro Velho→Ponte→Trilha         Escolha 5; T1,T2; Oni
ATO II-C "O Fio" — reviravolta      Verena/Reis/Montenegro/CriaLive  Escolha 6
ATO III  "A Maré"                   Zambiapunga→Mirante→Itacaré      Escolha 7; Belt Ceremony
CLÍMAX   "Sede Circuito Final"      final + escolha "O Código"
EPÍLOGO  ramificado                  cinco finais
```

Diálogos literais do Prólogo e Ato I pertencem a `docs/narrative/dialogos_ato1.md`. Diálogos TUPA‑200 pertencem a `docs/narrative/dialogos_tupa200.md`. Os demais atos obedecem ao beat sheet e às flags canônicas.

# 10. Sistemas

| Sistema | Contrato |
|---|---|
| World Director | Clima, NPCs, arenas, mangue e trilha reagem às flags. |
| Faction Director v3 | Exatamente `LEM`, `NTM`, `ALE`; leis não são facções. |
| Cria Live Feed | Coro grego, reputação pública e arco de Joaquim; posts podem mentir ou acertar. |
| InformantSystem | Missões PF/PMBA e escolhas de infiltração. |
| Economia | CRIAcoin limpa × Molho cinza; lavagem no festival. |
| Terrain/CombatBus | Modificadores por arena e corrupção por movimento sujo. |
| Clima | Dia/noite/chuva e evento sazonal de alagamento. |
| Eventos cíclicos | Zambiapunga, Paralelo Pratigi, São João e chuvas. |
| Belt Ceremony | Quem entrega a faixa expressa o estado moral da jornada. |
| Deck / Skill Tree | Quatro ramos correspondem aos quatro pilares do logo. |
| Weekly Career | Ato II estruturado em semanas de pressão crescente. |

# 11. Cinco finais

| Final | Condições canônicas | Resultado |
|---|---|---|
| Cria de Verdade | `honra>=8`, `raiz>=8`, mangue vivo, TUPA formalizada/comunitária, informante não queimado | Dendê entrega a chave do Terreiro; Ruan vira mestre. |
| Campeão Oco | circuito/ego altos, honra negativa, uso de Molho/festival | Ruan vira garoto-propaganda; Terreiro fecha; Joaquim é apagado. |
| Mártir do Tatame | honra alta, informante ativo, `provas>=3`, ajuda à comunidade | Ruan perde a final de propósito; dossiê vaza; Montenegro cai; Ruan é banido. |
| Sombra | roxo alto, underground cedo, informante queimado | Ruan vira o novo executor/aliciador; tela roxa. |
| Ponte | honra e raiz altas, vínculo forte com Leoa, TUPA comunitária | Ruan e Leoa fundam Terreiro na trilha reconhecida; Joaquim assina o próprio nome. |

Boss moral adicional: Irmão Calebe. A vitória ocorre recusando o discurso, não apenas reduzindo vida.

# 12. Spec técnica Godot

## Autoloads-alvo

- `WorldDirectorManager`
- `FactionDirectorV3`
- `CriaLiveFeed`
- `SaveManager`
- `CombatBus`
- `DeckManager`
- `NarrativeFlags`
- `InformantSystem`
- `Economy`
- `Weather`

## NarrativeFlags — contrato mínimo

```gdscript
extends Node
signal flag_changed(key: String, value)

var honra: int = 0
var roxo: int = 0
var raiz: int = 0
var circuito: int = 0
var ego: int = 0
var foco: int = 0
var dende_confianca: int = 0
var leoa_vinculo: int = 0
var joaquim_confianca: int = 0
var cassio_relacao: int = 0
var verena_confianca: int = 0
var reis_confianca: int = 0
var underground_acesso: String = "nenhum"
var bencao_mare: bool = false
var informant_status: String = "nenhum"
var mangue_estado: String = "vivo"
var tupa200_resolucao: String = "pendente"
var provas_joaquim: int = 0
var beats: Array[String] = []

func set_flag(key: String, value: Variant) -> void:
    set(key, value)
    flag_changed.emit(key, value)
    SaveManager.mark_dirty()
```

## Faction Director v3 — invariante

```gdscript
extends Node

enum FACCAO { LEM, NTM, ALE }

const NUCLEOS := {
    "bonde_dique": FACCAO.LEM,
    "patrulha_br": FACCAO.LEM,
    "travessia": FACCAO.NTM,
    "ponta_de_areia": FACCAO.NTM,
    "lavanderia_festival": FACCAO.NTM,
    "obra_nova": FACCAO.ALE,
    "congregacao_rua": FACCAO.ALE,
}

var rep: Dictionary = {
    FACCAO.LEM: 0,
    FACCAO.NTM: 0,
    FACCAO.ALE: 0,
}
```

A seleção de boss deve considerar informante, reputação ALE/LEM, circuito, honra, roxo, foco e raiz, sem criar quarta facção.

## Dados obrigatórios

- `res://data/factions/factions_v3.json`
- `res://data/economy/economy.json`
- `res://data/world/world_map_nodes.json`
- `res://data/world/seasonal_events.json`
- `res://scripts/combat/terrain_modifiers.gd`

`factions_v3.json` deve conter somente `LEM`, `NTM`, `ALE`; núcleos devem ter `faccao_pai` implícita ou explícita. PF limpa, PM honesta e PM suja são lei/instituição, não facções.

A economia contém `CRIACOIN` limpa e rastreável, `MOLHO` cinza e não rastreável, e a lavagem narrativa no Paralelo Pratigi.

Sinais obrigatórios do `CombatBus`:

```gdscript
signal moral_tension_changed(value: float)
signal dirty_move_attempted(id: String)
signal code_break_in_final(broken: bool)
```

# 13. Direção de arte e áudio

## Paleta oficial fechada

`#0A0A0A #1A1A1A #B8860B #F2C230 #F2F2F2 #D92323 #1E3A5F #2D5016 #4B0082`

## Regras visuais

- HD Pixel Art 2.5D regional premium.
- Contorno preto grosso.
- Cel shading de 3–4 tons.
- Rim light dourado.
- Nenhum texto incorporado em sprite.
- Silhueta legível a 64 px.
- Pivot nos pés.
- Ícone CRIAcoin: coroa + 柔術, sem efígie real.
- Ícone Molho: nota verde + gota, sem efígie real.

## Trilha por ato

- Prólogo: berimbau + maré.
- Ato I: atabaque + viola.
- Ato II-A: cordas tensas.
- Ato II-B: grave + percussão de ferro.
- Ato II-C: silêncio + drones roxos.
- Ato III: coral regional.
- Clímax: orquestra + atabaque.
- Epílogo: reprise do berimbau.
- Festival: eletrônica com amostra original de atabaque.

# 14. QA, acessibilidade e classificação

## Gate canônico

O CI falha quando:

1. `FACCAO` não possui exatamente três valores.
2. Um JSON declara facção fora de `LEM`, `NTM`, `ALE`.
3. Terreiro, Raiz, Cria Live, Dragão Vermelho ou Fantasma aparecem como facção.
4. Asset aprovado contém texto rasterizado indevido.
5. Áreas-chave usam cor fora da paleta oficial.

## QA de asset

- Paleta validada.
- Sem texto em sprite.
- Personagem com fundo off-white e contorno preto na folha de produção.
- Arena em pixel art.
- Card com moldura dourada e faixa textual vazia.
- Silhueta legível a 64 px.
- Pivot nos pés.
- Nome conforme convenção.

## Acessibilidade

- UI escalável.
- Modo daltônico com ícones além de cor.
- Vibração opcional.
- Legendas.
- Remapeamento de toque.
- Redução de flashes para strobo e `manto_olhar`.
- O sistema BPM não pode depender apenas de áudio.

Classificação-alvo: 14+. Aumento para 18+ altera apenas a intensidade do Ato II-C.

# 15. Plano de produção

| Milestone | Semanas | Entrega |
|---|---:|---|
| M1 Fundação jogável | 1–2 | Input, CombatArena, HUD, touch, Ruan base, core anims, Terreiro em cinco camadas. |
| M2 Mundo aberto v1 | 3–4 | Mapa, viagens, clima, três arenas, Cria Live. |
| M3 Elenco + facções | 5–6 | Personagens base, Faction Director v3, núcleos, economia. |
| M4 II-A/II-B + TUPA | 7–8 | Kenzo, Oni, T1/T2, Paralelo Pratigi, recrutamento como informante. |
| M5 Reviravolta + finais | 9–10 | Ato II-C, cinco finais, Belt Ceremony. |
| M6 Polimento + APK | 11–12 | QA, acessibilidade, áudio, Android ARM64 e Windows. |

# 16. Instruções de implementação

A execução do runtime segue a Issue #28 e o plano em sete fases aprovado:

1. Schema novo em paralelo ao legado.
2. Reclassificação dos IDs antigos.
3. Dados v3 mantendo legado por uma release.
4. Migração de saves para `save_version = 3`.
5. Reescrita dos testes.
6. Gate/lint canônico.
7. Upgrade Godot 4.2 → 4.3 em PR separado.

A sequência detalhada original de branches, arquivos, commits, template de PR, changelog e validação não foi recebida integralmente nesta mensagem. A Issue #28 é o plano executável vigente até o texto integral ser incorporado.

# 17. Honestidade final e perguntas abertas

## Fixado como cânone

- Três facções e seus núcleos.
- CRIAcoin × Molho.
- TUPA‑200 como crítica artística.
- Montenegro ligado aos Aleluiados.
- Dendê como ex-informante.
- Joaquim/Tinker como testemunha e prova.
- Ruan como informante possível.
- Geografia real tratada com respeito.
- Cinco finais.
- Quatro pilares na Skill Tree.
- Invariante de lint.

## Perguntas abertas

1. Existe câmbio livre CRIAcoin↔Molho com corrupção variável, ou moedas separadas até o festival?
2. A isenção tributária municipal inspiradora vira missão ou apenas lore?
3. O nome TUPA‑200 permanece ou recebe nome totalmente inventado?
4. Aleluiados usam somente coerção/discurso ou violência sempre off-screen?
5. Dendê conta seu passado antes ou depois da abordagem da PF?
6. Reis sobrevive ao clímax?
7. NG+ mostra o histórico do Cria Live da primeira jornada?

# Apêndice A — Glossário

- **Cria:** filho do lugar e do Terreiro.
- **Macacão:** apelido de Ruan, associado à força bruta.
- **Molho:** moeda viva e nome-símbolo da facção da água.
- **CRIAcoin:** moeda limpa do comum.
- **TUPA‑200:** arco de crítica artística sobre mercantilização do acesso.
- **Pressão:** antagonista invisível; cinco mãos puxando a faixa.
- **Rito:** luta feita para pedir licença, não simplesmente vencer.
- **Fio:** informante.
- **Manto/Olhar:** modificador dos Aleluiados; ser julgado pela fé alheia.

# Pendências documentais

- **Apêndice B:** a lista de fontes foi interrompida após o início dos portais; precisa ser reenviada integralmente e auditada antes de entrar no cânone factual.
- **Apêndice C:** master list de flags não foi recebida nesta mensagem.
- **Seção 16 original completa:** não foi recebida; o plano aprovado da Issue #28 permanece como substituto operacional provisório.
