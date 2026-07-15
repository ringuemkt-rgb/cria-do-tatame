# AGENTS.md — Cria do Tatame

Este arquivo orienta Codex, Manus, agentes locais e qualquer assistente automatizado que trabalhe neste repositório.

## Missão

Construir **Cria do Tatame – Pressão**, jogo Godot 4.3+ para Android ARM64 e Windows x86_64, com combate tático de Jiu-Jitsu Brasileiro, carreira, reputação, mundo vivo do Baixo Sul da Bahia e identidade visual preto/dourado premium.

## Fonte única de verdade

`ringuemkt-rgb/cria-do-tatame` é o único repositório oficial do jogo.

- Não criar outro repositório para protótipo, APK, arte, lore ou versão alternativa.
- Protótipos devem viver em branches ou pastas explicitamente delimitadas.
- Documentos antigos não podem substituir dados e bíblias canônicas atuais.
- Antes de criar algo, procurar implementação equivalente neste repositório.

## Regra de ouro

Não transformar o projeto em galeria de arte. Primeiro deve abrir, rodar, salvar, lutar, avançar a semana e exportar.

## Canon inviolável

- Protagonista: Ruan “Macacão” Silva.
- Símbolo: Gorila Silverback.
- Origem: Ituberá, Baixo Sul da Bahia.
- Estilo: pressão pesada, grip de ferro, top game dominante.
- Poder: Silverback Grip.
- Frase eixo: Ser forte é ser gentil.

Qualquer referência antiga a Caio Ravel, Rafa do Tatame ou Ruan “Cria” é legado e não deve ir para UI, campanha principal ou dados finais.

## Contratos visuais obrigatórios

Antes de alterar UI, sprites, mapas, arenas ou VFX, ler:

- `docs/art/VISUAL_TARGET_V10.md`;
- `data/ui/ui_design_tokens_v01.json`;
- `data/visual/screen_contracts_v01.json`;
- `data/visual/production_manifest_v02.json`;
- `docs/production/VISUAL_IMPLEMENTATION_BACKLOG_V10.md`.

Regras:

- HD Pixel Art 2.5D Regional Premium.
- Resolução-base 1280×720.
- Grade 16 px.
- Sprite de combate com 72 px de altura-base.
- Sprite de hub em célula 64×64 e oito direções.
- Filtro nearest.
- Centro da luta sempre limpo.
- Botão Android com 80 px mínimos na resolução-base.
- Safe area Android de 7%.
- Cria Live e Skill Tree devem usar abas no Android; não reduzir dashboard desktop inteiro.
- Não incorporar texto longo em imagens de runtime.
- Não usar marcas, logos institucionais ou símbolos culturais sem autorização/revisão.
- Concept art, infográfico e ficha técnica não entram diretamente na build.

## Ordem técnica obrigatória

1. Executar `npm run quality`.
2. Garantir que `project.godot` abre no Godot 4.3+ e mantém compatibilidade auditada.
3. Ligar e validar autoloads.
4. Preservar o fluxo Main Menu → Terreiro → Combate → Resultado → Save.
5. Implementar combate por estados relativos de BJJ.
6. Integrar carreira semanal, reputação, Cria Live, facções e patrocinadores.
7. Aplicar os contratos visuais às telas principais.
8. Produzir sprites, arenas, áudio e VFX com metadata e QA.
9. Exportar e testar Android/Windows.

## Contratos de arquitetura

- Gameplay crítico deve ser determinístico e executável offline.
- IA pode criar, revisar e classificar conteúdo; não pode sustentar o loop principal em tempo real.
- Dados em `data/` precisam manter IDs estáveis e referências válidas.
- Sistemas novos devem possuir ponto de entrada claro, teste ou checklist de validação e documentação mínima.
- Código temporário deve conter prazo ou condição objetiva de remoção.
- UI reage a sinais e estado; não deve controlar regras centrais diretamente.
- Conteúdo de personagem, técnica, arena e missão deve ser data-driven.

## Pipeline de asset

Nenhum asset é aceito sem:

- `raw_sheet.png`;
- `clean_sheet.png`;
- `spritesheet.png`;
- `frames/`;
- `preview.gif`;
- `contact_sheet.png`;
- `metadata.json`;
- `import_notes.md`;
- `qa_report.md`.

Técnicas pareadas também exigem atacante, defensor, `sync_map.json` e `hitbox.json`.
Arenas exigem layers, props, `collision.json`, `camera_bounds.json` e `arena.tscn`.
Áudio exige master WAV, runtime OGG e metadata.

## Restrições

- Não usar assets comerciais sem licença.
- Não copiar jogos existentes.
- Não criar sistema de soco/chute genérico como núcleo.
- Não afirmar APK pronto sem build validado.
- Não apagar arquivos úteis sem relatório de migração.
- Não introduzir segunda engine, segundo canon ou segundo backend de conteúdo.
- Não versionar segredos, chaves, tokens, keystores ou credenciais.
- Não usar nomes de arquivo finais como `image1.png`, `final_final.png` ou equivalentes.

## Quality gates

Uma alteração só pode ser descrita como pronta se:

1. JSON e referências passam nos validadores;
2. parser/import headless passa;
3. smoke test passa;
4. a cena pode ser navegada no fluxo real;
5. a UI permanece legível em 1280×720 e Android;
6. assets possuem metadata e QA;
7. bugs e limitações são declarados.

## Saída esperada de cada agente

Todo agente deve entregar:

1. arquivos criados;
2. arquivos modificados;
3. testes executados;
4. erros encontrados;
5. riscos ou dívidas técnicas;
6. evidências de validação;
7. próximo passo recomendado.
