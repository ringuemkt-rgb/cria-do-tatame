# AGENTS.md — Cria do Tatame

Este arquivo orienta Codex, Manus, agentes locais e qualquer assistente automatizado que trabalhe neste repositório.

## Missão

Construir **Cria do Tatame – Pressão**, jogo Godot 4.2+ para Android, PC e Web, com combate tático de Jiu-Jitsu Brasileiro, carreira, reputação, mundo vivo do Baixo Sul da Bahia e identidade visual preto/dourado premium.

## Fonte única de verdade

`ringuemkt-rgb/cria-do-tatame` é o único repositório oficial do jogo.

- Não criar outro repositório para protótipo, APK, arte, lore ou versão alternativa.
- Protótipos devem viver em branches ou pastas explicitamente delimitadas.
- Documentos antigos não podem substituir dados e bíblias canônicas atuais.
- Antes de criar algo, procure implementação equivalente neste repositório.

## Regra de ouro

Não transformar o projeto em galeria de arte. Primeiro deve abrir, rodar, salvar, lutar, avançar a semana e exportar.

## Canon inviolável

- Protagonista: Ruan “Macacão” Silva.
- Símbolo: Gorila Silverback.
- Origem: Ituberá, Baixo Sul da Bahia.
- Estilo: pressão pesada, grip de ferro, top game dominante.
- Poder: Silverback Grip.
- Frase eixo: Ser forte é ser gentil.

Qualquer identidade descartada de rascunhos antigos é legado e não deve ir para UI, campanha principal ou dados finais.

## Ordem técnica obrigatória

1. Executar `npm run quality`.
2. Garantir que `project.godot` abre no Godot 4.2+.
3. Ligar e validar autoloads.
4. Preservar o fluxo Main Menu → Terreiro → Combate → Resultado → Save.
5. Implementar combate por estados relativos de BJJ.
6. Integrar carreira semanal, reputação, Cria Live, facções e patrocinadores.
7. Só depois polir sprites, áudio, VFX e cutscenes.

O escopo completo e os gates de produção vivem em `docs/CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md` e `data/production/supreme_build_contract_v01.json`. Um agente não pode reduzir essas metas nem declarar conclusão ignorando o contrato executável.

## Contratos de arquitetura

- Gameplay crítico deve ser determinístico e executável offline.
- IA pode criar, revisar e classificar conteúdo; não pode sustentar o loop principal em tempo real.
- Dados em `data/` precisam manter IDs estáveis e referências válidas.
- Sistemas novos devem possuir ponto de entrada claro, teste ou checklist de validação e documentação mínima.
- Código temporário deve conter prazo ou condição objetiva de remoção.

## Restrições

- Não usar assets comerciais sem licença.
- Não copiar jogos existentes.
- Não criar sistema de soco/chute genérico como núcleo.
- Não afirmar APK pronto sem build validado.
- Não apagar arquivos úteis sem relatório de migração.
- Não introduzir segunda engine, segundo canon ou segundo backend de conteúdo.
- Não versionar segredos, chaves, tokens, keystores ou credenciais.

## Saída esperada de cada agente

Todo agente deve entregar:

1. arquivos criados;
2. arquivos modificados;
3. testes executados;
4. erros encontrados;
5. riscos ou dívidas técnicas;
6. próximo passo recomendado.

## Protocolo de autonomia

- Trabalhar em lotes verticais jogáveis e commits focados.
- Executar `npm run quality` antes e depois de cada lote.
- Usar GitHub, geração de imagem, Hugging Face e Sites apenas nas funções autorizadas pelo contrato supremo.
- Fixar versão e auditar licença antes de incorporar ferramenta externa.
- Parar diante de conflito de canon, licença incerta, biomecânica insegura, credencial ausente ou ação destrutiva.
- Nunca confundir conceito gerado, placeholder, mockup ou fila de produção com asset final integrado.
