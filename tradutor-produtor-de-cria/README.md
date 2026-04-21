# Tradutor e Produtor de Cria

Sistema base para **tradução híbrida** e **produção de e-books** com branding BOXE DE CRIA.

## Status

> Scaffold inicial criado com módulos, configurações e estrutura de diretórios.

## Como usar

```bash
cd tradutor-produtor-de-cria
python -m src.cli doctor
```

## Módulos disponíveis

- `translation`: ingestão, tradução, revisão, localização e rodapé.
- `production`: pesquisa, estratégia, escrita e autoridade.
- `neuromarketing`: arquétipos de Jung, cor, gatilhos e layout.
- `instagram`: calendário, hashtags, roteiro e engajamento.
- `sales`: página, checkout, preço, upsell e afiliados.
- `export`: geração de PDF/EPUB e branding final.

## Próximos passos

1. Preencher `.env` com chaves de API.
2. Ajustar arquivos em `config/` para cada nicho.
3. Implementar lógica de cada agente com prompts em `config/prompts/`.
