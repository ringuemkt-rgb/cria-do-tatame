# Cria Game Forge v0.6

## Missao

Construir o sistema unico de producao do Cria do Tatame: do design da tecnica ate sprite, Godot, IA de rival, carreira persistente e teste jogavel.

## O que o sistema faz

Cria Game Forge transforma uma demanda em pacote implementavel:

```txt
ideia ou tecnica
-> ficha canonica
-> ficha de gameplay
-> ficha biomecanica
-> keyframes
-> sprite request
-> manifest de atlas
-> dados JSON
-> scripts Godot
-> teste e QA
```

## Camadas

### 1. Studio OS

Organiza agentes, papeis, backlog, sprints e quality gates.

### 2. Runtime Core

Roda no Godot 4.2+ com GDScript e JSON:

- combate posicional;
- carreira persistente;
- oponentes com memoria;
- Cria Live;
- save/load;
- dados versionados.

### 3. Motion Lab

Analisa videos permitidos, extrai fases e transforma movimento em conhecimento de jogo.

### 4. Asset Factory

Gera sprite request, atlas manifest, QA visual, prompt de pixel art e importacao Godot.

### 5. QA Harness

Valida dados, simula tecnicas, registra logs estruturados e prepara relatorio para correcao.

## Workflow oficial por feature

1. Criar briefing.
2. Criar ficha tecnica em PT-BR.
3. Validar canon.
4. Gerar dados JSON.
5. Gerar sprite request.
6. Implementar no Godot.
7. Rodar validacao.
8. Revisar arte e combate.
9. Registrar changelog.

## Quality Gates

- Canon: Ruan Macacao Silva, Baixo Sul e PT-BR.
- BJJ: base, quadril, pegada e transicao coerentes.
- Gameplay: todo movimento altera estado, recurso, pontuacao ou posicao.
- Arte: silhueta clara em 2 segundos.
- Mobile: botoes legiveis e responsivos.
- Legal: sem copia de atleta, frame, logo, marca ou aula.
- Dados: JSON valido e versionado.

## Estrutura criada

```txt
.criaforge/
  config.yaml
  agents.yaml
  quality_gates.yaml
  workflows/technique_to_gameplay.yaml

tools/cria_forge/
  cria_forge.py
  README.md

src/tools/
  CriaForgeBridge.gd

data/production/
  cria_forge_manifest_v06.json
```
