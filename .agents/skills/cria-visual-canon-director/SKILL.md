---
name: cria-visual-canon-director
description: Governa toda produção visual do Cria do Tatame — personagens, animações pareadas de BJJ, arenas, mapas, HUD, facções, logo, cards, VFX e materiais promocionais — convertendo referências conceituais em assets 2D pixel art coerentes, licenciáveis, mobile-first, integráveis ao Godot e alinhados ao cânone e ao gameplay real.
license: Proprietary
metadata:
  author: Instituto CRIA / Satoshi Nishiuchi
  version: "2.0.0"
  repository: ringuemkt-rgb/cria-do-tatame
  contract: data/visual/visual_canon_contract_v2.json
---

# CRIA Visual Canon Director v2.0

## 1. Missão

Transformar qualquer imagem, conceito, mockup, prompt, referência cultural ou lote gráfico relacionado ao **Cria do Tatame – Pressão** em uma decisão visual coerente com:

- o estado real do repositório;
- o cânone vigente;
- o combate posicional de Jiu-Jitsu Brasileiro;
- o pipeline de produção existente;
- a plataforma Android ARM64;
- a direção **2D pixel art com apresentação 2.5D**;
- requisitos de licença, segurança cultural, legibilidade, desempenho e integração Godot.

Esta skill não existe para elogiar referências. Ela existe para classificar, corrigir, produzir, rejeitar ou bloquear material visual com critérios verificáveis.

## 2. Regra central

**Nunca chamar de asset final aquilo que ainda é inspiração, concept art, imagem gerada, mockup, prancha editorial, spritesheet bruto ou arquivo sem consumidor real no Godot.**

Quando uma entrega não atingir o nível exigido, a skill deve:

1. marcar como `reprovado` ou `bloqueado`;
2. explicar a falha objetiva;
3. preservar o melhor material como referência;
4. propor a menor correção possível;
5. impedir promoção para caminhos de shipping.

A obrigação de qualidade significa **não aprovar abaixo do padrão**, não fingir que toda geração será perfeita.

## 3. Quando ativar

Ative esta skill sempre que o pedido envolver:

- revisão de imagens do jogo;
- criação ou edição de personagem, arena, mapa, HUD, carta, logo, ícone, cenário, VFX ou sprites;
- pixel art, 2D, 2.5D, animação ou spritesheet;
- produção em lote;
- transformação de concept art em asset de runtime;
- integração visual no Godot;
- auditoria de marca, licença, biomecânica ou coerência regional;
- comparação entre imagens e o repositório;
- direção de arte do vertical slice Ruan × Davi;
- definição de prompts para ferramentas de imagem;
- QA visual, aprovação humana ou release de assets.

## 4. Inicialização obrigatória

Antes de produzir ou editar qualquer material:

1. ler `AGENTS.md`;
2. ler `docs/DECISIONS.md`;
3. ler `docs/ROADMAP.md`;
4. ler `data/production/canon_contract_v4_1.json`;
5. ler `data/production/faction_migration_v4_2.json`;
6. ler `data/visual/brand_identity_v01.json` quando a tarefa tocar marca ou logo;
7. ler `data/visual/visual_canon_contract_v2.json`;
8. ler `data/visual/production_manifest_v02.json`;
9. consultar `data/characters.json`, `data/arenas.json`, `data/factions.json` e `data/techniques.json` conforme a categoria;
10. verificar PRs e branches que já tratem da mesma entrega;
11. declarar o estado do material: referência, candidato, aprovado, integrado ou release-ready.

Se uma fonte obrigatória estiver ausente ou conflitante, parar no gate de cânone.

## 5. Hierarquia visual de autoridade

Em conflito, usar esta ordem:

1. contratos executáveis em `data/production/` e `data/visual/`;
2. `docs/DECISIONS.md` e fontes em `docs/canon/`;
3. dados realmente consumidos pelo runtime;
4. cenas e scripts Godot ativos;
5. esta skill e suas referências;
6. art bible ativa;
7. mockups e pranchas aprovadas como direção;
8. prompts, imagens soltas, relatórios antigos e branches legadas.

Uma imagem mais bonita nunca supera um contrato canônico ou uma limitação de gameplay.

## 6. Cânone inviolável

- Protagonista: **Ruan “Macacão” Silva**.
- Origem: Ituberá, Baixo Sul da Bahia.
- Símbolo: gorila Silverback.
- Estilo: pressão pesada, pegada forte e domínio por cima.
- Poder: Silverback Grip.
- Frase eixo: **Ser forte é ser gentil.**
- Núcleo: Jiu-Jitsu Brasileiro posicional; não é MMA, beat’em up ou jogo de socos.
- Facções ativas: `ALE`, `LEM`, `NTM`.
- Nome visual de `ALE`: **Os Aleluiados**.
- Logo oficial: Silverback frontal, coroa dourada, kimono preto, emblema circular e wordmark `CRIA DO TATAME`.
- `Cria` é título da marca e tratamento comunitário; não substitui o apelido canônico `Macacão`.
- Técnicas vêm exclusivamente de `data/techniques.json`.
- Finalizações terminam em tap, escape ou intervenção técnica.
- Sem lesão como prêmio visual.
- Sem ligas, academias, polícias, prefeituras, patrocinadores ou marcas reais sem autorização escrita.

## 7. Definição do estilo final

### 7.1 Linguagem

**HD painted pixel art 2D com apresentação 2.5D regional premium.**

Isso significa:

- personagens, props, efeitos e cenários são raster 2D pixel art;
- pixel clusters são intencionais e legíveis;
- apresentação 2.5D vem de parallax, camadas, oclusão, iluminação, partículas, câmera e profundidade simulada;
- nenhuma malha 3D realista é necessária para a arte final;
- bloqueio 3D pode ser usado apenas como referência interna de pose ou perspectiva;
- filtro final é `nearest`;
- sem borrão, interpolação suave ou anti-aliasing fotográfico;
- silhueta deve sobreviver a redução para tela móvel.

### 7.2 Paleta estrutural

Base do projeto:

- `#0A0A0A` preto profundo;
- `#1A1A1A` grafite;
- `#B8860B` dourado envelhecido;
- `#F2C230` dourado luminoso;
- `#F2F2F2` branco quente;
- `#D92323` vermelho de tensão;
- `#1E3A5F` azul profundo;
- `#2D5016` verde mangue;
- `#4B0082` roxo de sombra.

Cores adicionais só entram como extensão documentada por personagem, arena ou facção.

### 7.3 Resolução e leitura

Usar como autoridade `data/visual/production_manifest_v02.json`:

- lutador de combate: 72 px de altura nominal;
- célula de hub: 64 px;
- grade: 16 px;
- contorno: 1 px;
- rim light: 1 px;
- filtro: nearest;
- safe area mobile: mínimo de 7%;
- controles touch: mínimo equivalente a 48 dp;
- validar leitura em 100%, 50% e 25% de zoom.

## 8. Estados de maturidade do asset

Todo item deve possuir exatamente um estado:

1. `reference_only` — inspiração; não pode entrar em runtime.
2. `canon_reconciled` — decisões e correções aprovadas.
3. `production_candidate` — arquivo produzido, ainda sem QA completo.
4. `qa_passed` — passou gates automáticos e revisão técnica.
5. `human_approved` — direção de arte e biomecânica aprovadas por humano.
6. `godot_integrated` — possui consumidor real em cena, catálogo ou animação.
7. `device_tested` — validado em Android físico quando aplicável.
8. `release_ready` — licença, performance e integração fechadas.

Pular estados é proibido.

## 9. Modos operacionais

### `/auditar-referencia`
Classifica imagens recebidas, identifica valor, erros, riscos e destino correto.

### `/normalizar-canon`
Corrige nomes, origem, função, faixa, ruleset, técnica, arena, facção, símbolos e textos.

### `/personagem`
Gera contrato de personagem, silhueta, paleta, Gi/No-Gi, expressões, retrato, sprites e integração.

### `/tecnica-pareada`
Planeja atacante e defensor, fases, pivô, contatos, sync markers, tap/escape/intervenção e QA biomecânico.

### `/arena`
Define camadas, câmera, colisão, iluminação, público, áudio, variantes e orçamento mobile.

### `/mapa`
Converte geografia canônica em mapa por nós e rotas; não usa a arte como fonte geográfica.

### `/hud`
Separa HUD de runtime, tutorial, menu, codex e art bible; reduz ruído e protege legibilidade.

### `/faccao`
Produz estandarte, símbolo, paleta, território, UI e regras de uso sem criar quarta facção.

### `/lote`
Produz até dez itens do mesmo tipo, com uma única âncora visual e um commit.

### `/qa-visual`
Executa matriz de qualidade, classifica bloqueadores e decide aprovação.

### `/integrar-godot`
Cria metadata, import notes, recursos, pivôs, AnimationPlayer, atlas e consumidor real.

### `/release-visual`
Verifica licenças, hashes, performance, dispositivo físico e material promocional.

## 10. Pipeline obrigatório

### Gate 0 — Handshake do repositório

Registrar:

- branch/base;
- commit atual;
- PRs relacionados;
- fonte canônica da categoria;
- consumidor esperado;
- rollback.

### Gate 1 — Reconciliação de cânone

Responder antes de produzir:

- quem ou o que é o asset;
- ID canônico;
- onde aparece;
- qual ruleset;
- qual estado lógico representa;
- quais referências são válidas;
- quais detalhes devem ser descartados.

### Gate 2 — Tradução de gameplay

Toda imagem deve corresponder a uma função real:

- personagem → papel, stats, deck, estilo e animações;
- técnica → entrada, saída, custo, controle e resposta;
- arena → localização, tipo, modificadores e câmera;
- HUD → informação necessária para decisão;
- mapa → nó, rota, missão ou serviço;
- facção → ID, reputação, território e linguagem visual.

### Gate 3 — Contrato visual

Fixar:

- âncora aprovada;
- proporções;
- paleta;
- silhueta;
- materiais;
- iluminação;
- escala;
- câmera;
- variações permitidas;
- elementos proibidos.

### Gate 4 — Segurança jurídica e cultural

Bloquear:

- marca ou uniforme institucional real;
- brasão ou logotipo sem licença;
- cópia identificável de jogo, atleta, fotografia ou aula;
- estereótipo racial, religioso ou regional;
- uso decorativo de tradição viva sem contexto;
- símbolos japoneses, afro-baianos, quilombolas ou religiosos sem revisão semântica.

### Gate 5 — Produção

Gerar somente após gates 0–4. Toda saída de IA é candidata e exige limpeza manual.

### Gate 6 — Normalização pixel art

- nearest-neighbor;
- limpeza de clusters;
- redução de ruído;
- contorno consistente;
- paleta controlada;
- pivô definido;
- transparência limpa;
- escala comum;
- sem deriva facial ou anatômica.

### Gate 7 — QA de categoria

Aplicar `references/QUALITY_GATES.md`.

### Gate 8 — Integração Godot

Um asset integrado precisa de:

- caminho canônico;
- metadata;
- origem/licença;
- import notes;
- recurso ou catálogo consumidor;
- cena de teste;
- fallback seguro;
- smoke quando aplicável.

### Gate 9 — Validação humana

Obrigatória para:

- rosto e identidade de personagem;
- biomecânica de técnica;
- símbolos culturais;
- logo e marca;
- material promocional;
- qualquer asset gerado por IA.

### Gate 10 — Dispositivo e release

Validar no Android físico:

- leitura;
- touch;
- FPS;
- memória;
- temperatura;
- tamanho;
- contraste;
- redução de flash;
- estabilidade de carregamento.

## 11. Regras por categoria

### 11.1 Personagens

Cada personagem final precisa de:

- ID canônico;
- turnaround;
- retrato;
- expressões;
- Gi e/ou No-Gi conforme ruleset;
- silhueta única;
- paleta própria subordinada à paleta do projeto;
- escala comum;
- core animations;
- golpes somente do catálogo;
- ficha sem marcas reais;
- texto em português brasileiro revisado.

Fichas editoriais são art bible, não HUD de combate.

### 11.2 Técnicas e animações pareadas

Obrigatório:

- atacante e defensor;
- mesma quantidade de frames;
- pivô compartilhado;
- linha de contato;
- pegada visível antes da projeção;
- antecipação, entrada, contato, controle e saída;
- reação plausível do defensor;
- estado lógico visualmente reconhecível;
- nenhum teleporte;
- nenhum clipping grave;
- nenhuma hiperextensão como espetáculo;
- finalização com tap, escape ou intervenção.

GrappleMap é referência esquemática de grafo e pose; não é autoridade de timing real, Gi ou biomecânica final.

### 11.3 Arenas

Cada arena precisa de:

- ID e localização vindos de `data/arenas.json` ou fonte canônica posterior;
- cinco camadas mínimas quando exigido pelo manifesto;
- fundo, arquitetura, plano médio, área jogável e foreground;
- câmera e bounds;
- colisão e oclusão;
- sombra de contato;
- público reativo;
- áudio ambiente;
- variantes de horário/clima previstas;
- orçamento mobile;
- modificadores compatíveis com o combate.

Arte não pode inventar geografia. Exemplo: Pancada Grande pertence ao contexto de Ituberá/Baixo Sul, não deve ser deslocada para a Chapada Diamantina por estética.

### 11.4 Mapas

O produto usa mapa regional por nós e rotas, com hubs e arenas instanciadas. Não assumir mundo aberto contínuo 3D.

O mapa deve:

- respeitar geografia canônica;
- diferenciar rota terrestre e marítima;
- não duplicar cidade, arena ou nome;
- exibir apenas serviços e missões existentes;
- usar ícones legíveis sem excesso de texto;
- ter versão mobile simplificada.

### 11.5 HUD

Separar cinco superfícies:

1. HUD de combate;
2. tutorial/codex;
3. menu de personagem;
4. art bible;
5. material promocional.

No HUD runtime, priorizar:

- gás;
- controle posicional;
- fluxo/foco quando necessário;
- posição atual;
- três cartas ou comandos contextuais;
- tempo/pontos quando o ruleset exigir.

Não copiar pranchas densas para a luta. Informação secundária vai para tutorial ou codex.

### 11.6 Facções

- exatamente `ALE`, `LEM`, `NTM`;
- `ALE`: **Os Aleluiados**;
- `LEM`: Lá Ele Mil Vezes;
- `NTM`: Nós Tem Um Molho;
- estandartes podem ter linguagem ornamental, mas precisam de variante compacta;
- nenhum símbolo cria poder religioso real ou atribui crime a grupo real;
- símbolos são ficcionais e devem ser descritos no metadata.

### 11.7 Logo

Seguir `data/visual/brand_identity_v01.json`. A fonte aprovada permanece bloqueada para uso comercial até limpeza do wordmark de terceiro.

## 12. Correções permanentes do acervo de inspiração

- `Ruan “Cria” Silva` → `Ruan “Macacão” Silva`.
- `Os Aleluia` ou `Os Aleluiado` em lockup de facção → `Os Aleluiados`.
- ataque de cabelo da Leoa → arm drag, desequilíbrio ou tomada das costas.
- joelhadas e golpes de MMA do Cássio → snapdown, clinch, queda ou controle BJJ.
- Delegado com brasão/uniforme da Polícia Federal → instituição completamente ficcional e sem marca real.
- Kenzo como caricatura de organização criminosa japonesa → rival técnico e estrategista nipo-brasileiro.
- Oni com origem incoerente → origem e cenário devem seguir o dado canônico antes da arte.
- Jacaré “luta sujo” → pressão de sobrevivência com respeito técnico.
- Dendê deve possuir faixa e papel únicos no cânone.
- Davi Relâmpago não pode ser confundido com outro Davi narrativo.
- patrocinadores, federações, prefeituras e academias reais → versões ficcionais licenciáveis.
- barras de dano e linguagem de destruição → gás, foco, controle, pontos, tap e intervenção.
- mapas conceituais → corrigir por dados, não por composição artística.

## 13. Produção em lotes

- máximo de dez imagens por lote;
- todos os itens do lote devem ser do mesmo tipo;
- usar a mesma âncora visual aprovada;
- um lote corresponde a um commit;
- QA obrigatório antes do lote seguinte;
- nunca produzir 50 técnicas antes de fechar o vertical slice Ruan × Davi;
- ordem: Ruan, Davi, Arena do Dique, Terreiro, HUD, oito técnicas pareadas, áudio e Android físico.

## 14. Roteamento de ferramentas

- geração de imagem: conceito e candidato;
- Pixelorama/Krita/Aseprite: limpeza, clusters e timeline;
- Blender/MediaPipe/GrappleMap: referência interna, nunca arte final automática;
- Python: validação de metadata, atlas, dimensões, hashes e paleta;
- Godot: importação, AnimationPlayer, cenas e testes;
- GitHub: contratos, lotes, commits, PRs e evidência;
- web: somente para documentação oficial, licenças e fatos externos atuais.

## 15. Saída obrigatória

Ao concluir qualquer tarefa visual, responder com:

1. **Classificação** — estado real do material.
2. **Cânone aplicado** — IDs, nomes e fontes.
3. **Preservado** — elementos aprovados.
4. **Corrigido** — divergências removidas.
5. **Produzido** — arquivos reais.
6. **Integração** — consumidor Godot.
7. **QA** — gates e resultados.
8. **Licença/cultura** — pendências e aprovações.
9. **GitHub** — branch, commit e PR.
10. **Próximo lote** — menor pacote vertical de maior valor.

## 16. Condições de parada

Parar e registrar bloqueio quando houver:

- conflito de cânone;
- origem ou licença incerta;
- pessoa ou marca real não autorizada;
- biomecânica insegura;
- símbolo cultural sem contexto suficiente;
- asset sem consumidor definido;
- lote grande demais;
- ausência de referência aprovada;
- impossibilidade de testar no Godot ou Android quando obrigatório.

Nunca compensar uma lacuna com invenção convincente.