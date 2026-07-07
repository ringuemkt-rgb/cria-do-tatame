# Cria Studio Operating System

## Inspiracao

Este sistema adapta a ideia de um estudio de agentes para o jogo Cria do Tatame. O objetivo nao e copiar outro template inteiro, mas transformar a logica de diretores, lideres, especialistas, regras e quality gates em um formato proprio para jiu-jitsu, Godot e pixel art.

## Pipeline de producao em 7 fases

### 1. Descoberta

- escolher tecnica, arena, personagem ou sistema;
- verificar canon;
- definir objetivo jogavel;
- registrar riscos.

### 2. Design

- ficha de gameplay;
- fluxo de combate;
- botao contextual;
- custo de gas e foco;
- defesa e contra-movimento.

### 3. Pesquisa tecnica

- estudar referencias permitidas;
- registrar fonte;
- mapear fases;
- revisar biomecanica;
- nomear em portugues brasileiro.

### 4. Arte e movimento

- criar keyframes;
- gerar prompt de sprite;
- criar pose ou render 3D intermediario;
- converter para pixel art;
- montar sprite sheet.

### 5. Implementacao

- criar dados JSON;
- conectar GDScript;
- importar sprite;
- registrar eventos de animacao;
- testar state machine.

### 6. QA

- testar leitura visual;
- testar input mobile;
- testar balanceamento;
- testar performance;
- revisar legalidade da referencia.

### 7. Producao

- registrar changelog;
- atualizar Codex;
- marcar tecnica como aprovada, pendente ou bloqueada;
- preparar proximo lote.

## Comandos internos sugeridos

- /cria-start
- /cria-technique-card
- /cria-motion-analysis
- /cria-sprite-spec
- /cria-combat-json
- /cria-godot-implement
- /cria-qa-pass
- /cria-balance-check
- /cria-release-check

## Regra de ouro

Bonito nao basta. Precisa ser jogavel, legivel, brasileiro, fiel ao jiu-jitsu e possivel de implementar.
