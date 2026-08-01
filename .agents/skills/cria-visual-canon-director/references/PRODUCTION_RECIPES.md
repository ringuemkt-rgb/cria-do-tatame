# Production Recipes — CRIA Visual Canon Director

## 1. Estrutura comum de qualquer lote

```text
assets/visual/<categoria>/<asset_id>/
  source/
  reference/
  candidates/
  approved/
  runtime/
  preview/
  metadata.json
  import_notes.md
  qa_report.md
```

Somente `approved/` pode alimentar `runtime/`, e somente após aprovação humana.

## 2. Metadata mínima

```json
{
  "asset_id": "...",
  "category": "character|technique|arena|map|hud|faction|brand|vfx",
  "canon_id": "...",
  "status": "reference_only",
  "source_files": [],
  "source_hashes": {},
  "license": "proprietary|public_domain|other",
  "human_approval": false,
  "ruleset": ["GI", "NO_GI"],
  "palette_ref": "data/visual/visual_canon_contract_v2.json",
  "consumer": "",
  "godot_paths": [],
  "qa": {
    "score": 0,
    "blockers": [],
    "reviewer": "",
    "reviewed_at": ""
  }
}
```

## 3. Receita de personagem

### Entradas

- registro canônico do personagem;
- função narrativa;
- perfil de animação no manifesto;
- rulesets;
- âncora visual aprovada;
- paleta e símbolos;
- lista de técnicas existentes.

### Saídas editoriais

- retrato 1:1;
- corpo inteiro 3:4;
- turnaround frontal, lateral, costas e 3/4;
- cinco expressões;
- ficha de Gi;
- ficha de No-Gi quando aplicável;
- line-up de silhueta com o elenco.

### Saídas runtime

- sprite de combate com altura nominal de 72 px;
- sprite de hub em célula de 64 px;
- idle;
- walk forward/backward;
- clinch;
- estados ground necessários;
- victory/defeat;
- atlas e pivôs;
- portrait mobile.

### Prompt-base de conceito

```text
Crie uma prancha de direção visual para [NOME CANÔNICO], personagem de Cria do Tatame. HD painted pixel art 2D com apresentação 2.5D, grid visível, nearest-neighbor, contorno preto de 1 px na escala nativa, rim light dourado controlado. Preserve [SILHUETA], [PALETA], [ORIGEM], [FUNÇÃO], [RULESET] e [SÍMBOLO]. Mostre retrato, corpo inteiro, turnaround e expressões. Não use fotografia, render 3D, marca real, pessoa real, texto longo, golpe de MMA ou técnica inexistente. A ficha é referência editorial; sprites devem manter escala e rosto consistentes.
```

### Prompt-base de sprite

```text
Produza sprite pixel art 2D de [PERSONAGEM], altura visual nominal 72 px, vista lateral de combate, fundo transparente, mesma proporção e paleta da âncora aprovada. Pose [ESTADO]. Sem texto, sombra baked-in excessiva, blur, anti-aliasing ou variação facial. Preserve mãos e pés legíveis para grappling.
```

## 4. Receita de técnica pareada

### Entradas obrigatórias

- `technique_id` existente;
- estado de entrada;
- estado de saída;
- ruleset;
- atacante;
- defensor;
- frame target;
- pivô;
- revisão técnica.

### Fases

1. antecipação;
2. entrada;
3. estabelecimento de pegada/controle;
4. desequilíbrio;
5. contato ou transição;
6. estabilização;
7. resposta do defensor;
8. saída lógica.

### Estrutura

```text
assets/techniques/<technique_id>/
  attacker/frames/
  defender/frames/
  reference/
  spritesheet_attacker.png
  spritesheet_defender.png
  preview.gif
  sync_map.json
  hitbox.json
  metadata.json
  qa_report.md
```

### `sync_map.json`

```json
{
  "technique_id": "...",
  "shared_pivot": [0, 0],
  "frame_count": 0,
  "markers": [
    {"frame": 0, "event": "anticipation"},
    {"frame": 0, "event": "grip_established"},
    {"frame": 0, "event": "balance_broken"},
    {"frame": 0, "event": "position_changed"}
  ],
  "finish_resolution": "position|tap|escape|technical_intervention"
}
```

### Prompt-base

```text
Crie storyboard pixel art 2D pareado para a técnica canônica [TECHNIQUE_ID], com atacante [A] e defensor [B]. Entrada lógica: [ENTRY]. Saída lógica: [EXIT]. Ruleset: [RULESET]. Mesma escala, pivô compartilhado e contagem de frames. A pegada deve aparecer antes da aplicação de força; o defensor reage de forma biomecanicamente plausível. Sem teleporte, clipping, hiperextensão celebrada, golpe de MMA ou finalização automática. Finalizações terminam em tap, escape ou intervenção técnica. Fundo transparente e sem texto.
```

## 5. Receita de arena

### Entradas

- `arena_id` em `data/arenas.json` ou contrato posterior;
- localização;
- tipo;
- modificadores;
- variantes;
- público;
- câmera;
- orçamento mobile.

### Camadas

1. céu/horizonte;
2. paisagem/arquitetura distante;
3. plano médio e público;
4. área jogável;
5. foreground e oclusão.

### Saídas

- master 16:9;
- layers transparentes;
- props;
- collision map;
- camera bounds;
- light mask;
- low-density crowd;
- preview sem HUD;
- preview com HUD;
- cena Godot de teste.

### Prompt-base

```text
Crie arena de Cria do Tatame para [ARENA_ID], localizada em [LOCAL CANÔNICO]. Pixel art 2D detalhada com apresentação 2.5D por cinco camadas, parallax, oclusão e luz. O centro do tatame deve permanecer limpo e legível para dois lutadores de 72 px. Preserve [IDENTIDADE REGIONAL], [HORÁRIO], [MATERIAIS] e [TIPO]. Não inclua marca, brasão, prefeitura, federação, academia ou patrocinador real. Não invente geografia. Entregue composição sem HUD e indique separação de layers.
```

## 6. Receita de HUD

### Classificação inicial

Escolher uma:

- `combat_runtime`;
- `submission_runtime`;
- `tutorial_codex`;
- `character_menu`;
- `art_bible`;
- `marketing_mockup`.

### Combat runtime

Prioridade:

1. posição;
2. gás;
3. controle;
4. foco/fluxo;
5. tempo/pontos quando necessário;
6. três cartas/comandos contextuais.

### Regras

- safe area 7%;
- touch 48 dp;
- nada essencial sobre a ação central;
- cores com redundância de ícone/texto;
- modo foco reduz detalhes;
- texto em pt-BR;
- sem painel editorial durante a luta.

### Prompt-base

```text
Desenhe HUD mobile de combate para Cria do Tatame, superfície [TIPO], 16:9, safe area de 7%, touch targets de 48 dp, pixel art UI preta/dourada. Mostre somente [INFORMAÇÕES]. Preserve o centro da luta. Use ícones e texto curto em português brasileiro. Não reproduza a densidade de uma prancha de art bible. Sem marcas reais, sem comandos incompatíveis com o sistema de cartas e sem barras não contratadas.
```

## 7. Receita de mapa

### Modelo de produto

Mapa regional por nós e rotas, não mundo contínuo 3D.

### Saídas

- mapa editorial do Baixo Sul;
- mapa runtime simplificado;
- ícones 64/32/16 px;
- rotas terrestre e marítima;
- nós com estado bloqueado/desbloqueado;
- tooltip curto;
- legenda;
- versão sem texto para localização.

### Prompt-base

```text
Crie mapa regional ilustrado em pixel art 2D para Cria do Tatame. Use somente os nós e localizações fornecidos no contrato. Ituberá é o núcleo narrativo. Diferencie rotas terrestres e marítimas; mostre arenas e hubs como nós, não como mundo aberto contínuo. Preserve hidrografia e costa como linguagem visual sem declarar precisão cartográfica. Não duplicar cidades, deslocar arenas ou inventar pontes. Interface mobile legível, preto/dourado com azul e verde regional.
```

## 8. Receita de facção

### Saídas

- estandarte completo;
- emblema quadrado;
- badge circular;
- ícone 32 px;
- banner de arena;
- patch Gi/No-Gi;
- reação de Cria Live;
- variante monocromática.

### Prompt ALE

```text
Estandarte ficcional da facção ALE — OS ALELUIADOS. Pixel art mosaico azul, branco e dourado. Pomba ficcional, halo, ramo e cruz abstrata; composição respeitosa, sem copiar igreja, denominação ou brasão real. Texto exato: OS ALELUIADOS. Entregar também variante compacta sem texto.
```

### Prompt LEM

```text
Estandarte ficcional da facção LEM — LÁ ELE MIL VEZES. Pixel art vermelho, roxo, azul e dourado. Olho e mão abstratos representam observação, leitura e informação. Não copiar símbolo religioso ou esotérico real. Texto exato: LÁ ELE MIL VEZES.
```

### Prompt NTM

```text
Estandarte ficcional da facção NTM — NÓS TEM UM MOLHO. Pixel art amarelo, laranja, vermelho e azul. Pilão, pimentas e garrafa de molho com rótulo inteiramente original. Texto exato: NÓS TEM UM MOLHO. Sem marca comercial.
```

## 9. Receita de logo derivado

Usar somente a composição aprovada e o contrato de marca.

Derivados:

- master transparente;
- dourado monocromático;
- branco monocromático;
- horizontal;
- emblema compacto;
- app icon;
- pixel small-size;
- patch Gi;
- patch No-Gi.

Nunca gerar novo mascote ou remover coroa/Silverback.

## 10. Lote visual

### Manifesto do lote

```json
{
  "batch_id": "visual_<tipo>_<numero>",
  "type": "character|arena|technique|hud|map|faction",
  "anchor_asset": "...",
  "items": [],
  "max_items": 10,
  "branch": "visual/...",
  "consumer": "...",
  "qa_required": true,
  "human_approval_required": true
}
```

### Ordem

1. contrato;
2. referência;
3. geração;
4. seleção;
5. limpeza;
6. normalização;
7. QA;
8. aprovação;
9. integração;
10. commit.

Não iniciar lote seguinte antes do QA.

## 11. Relatório de integração

```text
ASSET ID:
CATEGORIA:
ESTADO:
FONTE CANÔNICA:
ARQUIVOS:
CONSUMIDOR GODOT:
CENA DE TESTE:
LICENÇA:
QA SCORE:
BLOQUEADORES:
APROVAÇÃO HUMANA:
ANDROID FÍSICO:
COMMIT/PR:
```