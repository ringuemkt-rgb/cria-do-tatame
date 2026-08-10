# Protocolo Visual, de Animação e Fluxo de Combate V01

**Status:** ACTIVE — contrato da vertical slice ouro; não significa arte final nem jogo completo.

**Runtime:** Godot 4.2.2 mínimo auditado, Godot 4.3+ de produção, 1280×720, Android-first.

**Fonte executável:** `data/visual/visual_gameplay_protocol_v01.json`.

## 1. Resultado da análise das dez pranchas

As dez imagens formam uma direção consistente, embora não sejam assets de produção. Todas foram detectadas como JPEG apesar da extensão `.png`, não possuem alfa e não têm licença/proveniência suficiente para shipping. Seus hashes e dimensões estão registrados no contrato executável.

| # | Superfície | O que deve ser preservado | O que deve ser corrigido no jogo |
|---|---|---|---|
| 1 | Mapa regional | mapa como protagonista, rotas legíveis, objetivo à esquerda e destino à direita | reduzir ruído sob marcadores; custo, risco e bloqueio precisam existir como dados reais |
| 2 | Arena oficial | corpos no centro, juiz e público contextualizando, recursos simétricos | evitar barras duplicadas e manter ações fora da silhueta dos lutadores |
| 3 | Terreiro | Ruan em corpo inteiro, academia viva, missão e rotina na mesma tela | hierarquia precisa privilegiar a próxima ação; nove botões iguais diluem prioridade |
| 4 | Menu | marca dominante, key art forte e menu vertical simples | dados de save não podem competir com Novo Jogo/Continuar; online é opcional |
| 5 | Zambiapunga | identidade cultural, plateia e cartas de mecânica antes da luta | retratar a tradição com pesquisa e consultoria; quadro vertical é briefing, não HUD de combate |
| 6 | Cria Live | feed, crise, patrocinador e progressão no mesmo ecossistema | densidade é alta; no mobile, cada coluna vira aba/painel e nunca uma miniatura ilegível |
| 7 | Fluxo tático | objetivo, pontuação, técnica atual e sequência de cinco passos | a sequência precisa refletir o estado real do `CombatManager`, não uma animação decorativa |
| 8 | Carreira social | consequência pública, reputação e território | remover qualquer quarta facção e toda dependência de progressão online obrigatória |
| 9 | Pancada Grande | ambiente como regra legível e cards de risco | separar briefing da luta; risco ambiental precisa de telegraph e saída segura |
| 10 | Progressão | quatro arquétipos, detalhe da habilidade e faixa como gate | árvore completa ainda é escopo posterior; o deck atual continua sendo a projeção jogável |

### Diagnóstico comum

O padrão visual é preto/carvão com moldura ouro envelhecido, painéis compactos, tipografia condensada, azul profundo de tatame, vermelho de conflito, violeta de foco e verde de respeito. O cenário recebe alta densidade; a área sob os lutadores recebe contraste e ruído reduzidos. Informação crítica mora nas bordas, preservando pelo menos 52% da largura como zona clara dos corpos.

As pranchas também revelam um risco: várias telas tentam mostrar tudo ao mesmo tempo. A produção adota **revelação por contexto**. O jogador vê primeiro a decisão do momento; detalhes vivem em inspeção, aba ou briefing.

## 2. Sistema visual único

`CriaVisualTheme.gd` é a fachada local de estilo. Ele lê o contrato sem criar autoload e fornece:

- cores semânticas e métricas comuns;
- painéis preto fosco com borda ouro/azul;
- botões com estados de foco, hover, pressionado e desabilitado;
- barras com rótulo textual, nunca apenas cor;
- alvos touch mínimos de 48 px, preferidos de 64 px;
- texto real do Godot, separado da imagem de fundo.

O logo em pincel, retratos, ícones e cenários continuam sendo assets aprovados em separado. Não devem ser simulados com texto, emoji ou formas de interface.

## 3. Fluxo jogável e leitura de combate

O runtime continua sendo o `CombatManager` existente. O HUD apenas observa os sinais e traduz a luta em cinco perguntas:

```text
PEGADA → BASE → QUEDA → CONTROLE → FINALIZAÇÃO
```

| Etapa visual | Estados de runtime | Pergunta para o jogador |
|---|---|---|
| Pegada | `PLAYER_STANDING_NEUTRAL` | Quem define o primeiro contato? |
| Base | clinch por cima/baixo | Quem quebra postura sem perder equilíbrio? |
| Queda | guarda por cima/baixo | Quem consolidou a chegada ao solo? |
| Controle | lateral, montada e costas | A posição está estabilizada ou ainda é scramble? |
| Finalização | ataque/defesa de submission | Existe controle técnico para setup, tap ou escape? |

### HUD integrado neste lote

`CombatTacticalHUD` adiciona três zonas sem alterar o resultado da simulação:

1. **Trilho esquerdo:** objetivo, posição, controle e moral/público.
2. **Trilho direito:** técnica em execução, fase e leitura defensiva.
3. **Faixa inferior:** as cinco etapas com progresso derivado do estado real.

A mão do deck permanece separada e mostra apenas três cartas. As cinco ações contextuais continuam sendo técnicas válidas do catálogo. Carta melhora a leitura/qualidade da técnica; não substitui posição, custo ou defesa.

### Defesa e finalização segura

As janelas **cedo / perfeito / tarde** são informação de timing. O resultado continua vindo do resolver determinístico. Uma finalização usa:

```text
setup → lock → pressão técnica → tap ou escape → árbitro/recuperação
```

Não existe evento de “quebrar membro”. Animação, texto, áudio e câmera terminam em tap, escape, tempo/pontos ou intervenção.

## 4. Protocolo de criação de imagem

Cada asset visual percorre nove gates, nesta ordem:

1. **Brief de cânone e licença:** ID, função, bioma, horário, origem, proibições e consumidor Godot.
2. **Composição em cinza:** silhuetas e massas; nada de detalhe antes de a leitura funcionar em 25% do tamanho.
3. **Chave de cor/luz:** paleta travada e uma direção de luz para todos os layers.
4. **Master ambiental em camadas:** céu, fundo distante, arquitetura, público, área jogável, foreground, clima/luz.
5. **Model sheet:** frente, 3/4, perfil, costas, proporção, traje e itens persistentes.
6. **Limpeza pixel:** clusters intencionais, contorno de 1 px, rim light de 1 px, sem anti-alias borrado.
7. **Crop de runtime:** 1280×720, safe area e espaço dos lutadores/controles medidos.
8. **Integração Godot:** import nearest, layers, pivôs, colisão, bounds, variantes e perfil mobile.
9. **Comparação lado a lado:** referência + captura do jogo no mesmo estado; revisão humana decide promoção.

### Prompt mestre de conceito

```text
[FUNÇÃO DO ASSET], Cria do Tatame, HD pixel art 2.5D regional premium,
Brazilian Jiu-Jitsu positional, Baixo Sul da Bahia, 16:9 composition,
deep charcoal and weathered gold UI-safe palette, crisp intentional pixel clusters,
single top-left lighting direction, calm readable playfield center,
separate background layers, culturally researched regional details,
no UI, no words, no logo, no real brand, no watermark, no extra limbs,
no graphic injury, no copied person, leave declared safe zones empty.
```

O prompt produz **candidato**, não asset final. Texto, logo, molduras e controles são compostos no Godot ou em assets vetoriais/pixel aprovados; nunca dependem da grafia de um gerador de imagem.

`tools/visual/build_asset_prompt.py <brief_id>` materializa esse prompt a partir de `vertical_slice_asset_briefs_v01.json`. O builder torna a direção repetível, mas não é “infalível”: resolução, hashes, alpha, metadados e arquivos do pack são verificáveis por máquina; fidelidade visual, cultura, consistência de personagem e biomecânica exigem comparação lado a lado e revisão humana.

O Bill of Materials executável está em `data/production/visual_asset_bom_v01.json`. Ele conta **packs aprovados**, não presume que cada arquivo interno tenha o mesmo peso e não transforma a estimativa informal de 920 ativos em promessa de release.

## 5. Protocolo de animação pareada

Toda técnica tem atacante e defensor no mesmo relógio. O pacote mínimo contém spritesheets separados, `sync_markers.json`, preview, metadata e QA.

### Fases canônicas

```text
anticipation → entry → establish → stabilize → response → recovery
```

Finalizações expandem `response` para `setup → lock → technical_pressure → tap_or_escape → referee_or_recovery`.

### Contrato de quadro

Cada quadro lógico declara:

- frame do atacante e frame do defensor;
- root compartilhado e pivôs individuais;
- facing e escala;
- âncora principal de contato;
- grip que nasce, persiste e solta;
- evento (`grip_contact`, `base_break`, `position_established`, `defense_window`, `tap_or_escape`, `respect_reset`);
- hitbox/hurtbox/grabbox quando necessária;
- possibilidade de cancel/intervenção.

### QA obrigatório

- mãos não teleportam e o grip não troca de membro sem transição;
- articulações não saltam nem atravessam o corpo;
- escala, pivô, volume do gi e direção de luz permanecem estáveis;
- silhueta é legível no tamanho de combate de 72 px;
- BJJ é revisado por praticante qualificado;
- tap/escape/intervenção são claros;
- Android real confirma leitura, memória e FPS.

Keypoints, mocap ou IA podem acelerar blockout. Eles não aprovam biomecânica, licença ou asset final.

### GrappleMap: quarentena técnica

O repositório oficial declara código e dados em domínio público, mas `GrappleMap.txt` usa uma codificação compacta própria. Ele não contém o formato textual `position/transition/player/frame/j` assumido pelo parser apresentado na diretiva 003. O README também caracteriza as animações como esquemáticas, com timing rudimentar e sem hand-fighting, e pede revisão por praticantes.

Portanto, `grapplemap_import.py` não foi adicionado. A fonte permanece `blocked_pending_parser_and_bjj_review` no registro de movimento. Uma futura ingestão precisa de fixture extraída do banco oficial, decoder compatível, teste de roundtrip, auditoria de licença e revisão humana de BJJ antes de produzir qualquer `motion.json`.

## 6. Protocolo audiovisual

`AudioManager` permanece a única autoridade. A sequência sonora de uma técnica é:

```text
tecido/antecipação → contato de pegada → quebra de base
→ impacto da superfície → assentamento do controle
→ tap/árbitro → resposta da plateia
```

Camadas de arena: ambiência, crowd por intensidade, música base, tensão, tecido/pegada, superfície, respiração e UI. O catálogo `audio_cues_v01.json` define asset/fallback; streaming nunca é requisito. Informação crítica possui par visual/legenda.

## 7. Rubrica de fidelidade

Uma captura só é candidata a aprovação com nota mínima 85/100:

| Critério | Peso |
|---|---:|
| composição e hierarquia | 20 |
| leitura de lutadores/estado | 20 |
| consistência de pixel, paleta e luz | 15 |
| fidelidade regional e canônica | 15 |
| clareza de interação/touch | 10 |
| animação pareada/contato | 10 |
| áudio e resposta audiovisual | 5 |
| acessibilidade/reduced motion | 5 |

Falha automática: texto ilegível, mão teleportando, asset sem licença, quarta facção, progressão online obrigatória, aposta com dinheiro real, ferimento gráfico ou UI cobrindo a ação principal.

## 8. Estado real após este lote

- **Integrado:** contrato visual consumido pelo theme, trilhos táticos, sequência de combate, deck reposicionado, compatibilidade Godot 4.2.2.
- **Fundação existente:** menu, Terreiro, mapa, Cria Live e deck builder.
- **Especificado, não integrado:** briefing universal de arena e árvore completa de habilidades.
- **Pendente de produção humana:** personagens finais Ruan/Davi, técnicas pareadas, layers finais do Terreiro/Dique, fontes licenciadas e áudio gravado.
- **Pendente de prova:** import/smoke CI, comparação visual no mesmo viewport e Android físico.

## 9. Rollback

Remover `CombatTacticalHUD` da `CombatArenaBase.tscn`, restaurar os anchors anteriores de `CombatDeckHUD`/painel de ações e retirar `validate:visual-gameplay` do `package.json`. O `CombatManager`, o deck, o save e os resultados não são alterados por este protocolo.
