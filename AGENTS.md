# AGENTS.md — Cria do Tatame

Este arquivo orienta Manus AI, Codex, agentes locais e qualquer assistente automatizado que trabalhe neste repositório.

## Missão
Construir **Cria do Tatame – Pressão**, jogo Godot 4.2+ para Android, PC e Web, com combate tático de Jiu-Jitsu Brasileiro, carreira, reputação, mundo vivo do Baixo Sul da Bahia e identidade visual preto/dourado premium.

## Regra de ouro
Não transformar o projeto em galeria de arte. Primeiro deve abrir, rodar, salvar, lutar, avançar a semana e exportar.

## Canon inviolável
- Protagonista: Ruan “Macacão” Silva.
- Símbolo: Gorila Silverback.
- Origem: Ituberá, Baixo Sul da Bahia.
- Estilo: pressão pesada, grip de ferro, top game dominante.
- Poder: Silverback Grip.
- Frase eixo: Ser forte é ser gentil.

Qualquer referência antiga a Caio Ravel ou Ruan “Cria” é legado e não deve ir para UI, campanha principal ou dados finais.

## Ordem técnica obrigatória
1. Validar JSON em `data/`.
2. Garantir `project.godot` abrindo.
3. Ligar autoloads.
4. Criar fluxo mínimo: Main Menu → Terreiro → Combate → Resultado → Save.
5. Implementar combate por estados BJJ.
6. Integrar carreira semanal, reputação, Cria Live, facções e patrocinadores.
7. Só depois polir sprites, áudio, VFX e cutscenes.

## Restrições
- Não usar assets comerciais sem licença.
- Não copiar jogos existentes.
- Não criar sistema de soco/chute genérico como núcleo.
- Não afirmar APK pronto se não houve build validado.
- Não apagar arquivos úteis sem relatório.

## Saída esperada de cada agente
Todo agente deve entregar:
1. Arquivos criados.
2. Arquivos modificados.
3. Testes executados.
4. Erros encontrados.
5. Próximo passo recomendado.
