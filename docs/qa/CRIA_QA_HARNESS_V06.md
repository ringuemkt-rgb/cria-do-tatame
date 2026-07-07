# Cria QA Harness v0.6

## Objetivo

Criar uma rotina de validacao repetivel para dados, combate, carreira, sprites e web/mobile.

## Tipos de teste

### Data Validation

Roda `tools/cria_forge/cria_forge.py validate` e confirma JSON valido e tecnicas com campos obrigatorios.

### Combat Smoke Test

Executa uma luta curta em estado controlado:

- estado inicial: distancia_media;
- tecnica inicial: pegada;
- segunda tecnica: baiana;
- saida esperada: estado muda e pontuacao pode atualizar.

### Sprite QA

Verifica:

- atlas existe;
- manifest existe;
- frames por acao;
- fundo transparente;
- silhueta legivel.

### Mobile QA

Verifica:

- botoes legiveis;
- texto em PT-BR;
- sem blur no pixel art;
- FPS estavel;
- HUD nao cobre lutadores.

## Relatorios

Todos os relatorios devem ir para:

```txt
reports/cria_forge/
```

## Regra

Todo sistema novo precisa gerar evidencias: log, relatorio ou screenshot.
