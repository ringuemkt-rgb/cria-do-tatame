# Lore Guardian — Fase 1

Serviço editorial local do **Cria do Tatame**. Ele indexa apenas fontes do
repositório, recupera evidências canônicas, reranqueia resultados e valida JSON
antes de qualquer conteúdo candidato entrar em `data/`.

O serviço não participa do combate nem é requisito do APK. Se ChromaDB ou os
modelos não estiverem disponíveis, `/validate` continua operacional e `/query`
usa o índice lexical local.

## Instalação

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -r ai_lore_guardian/requirements.txt
```

Os modelos não são baixados silenciosamente. Coloque `BAAI/bge-m3` e
`BAAI/bge-reranker-v2-m3` no cache local ou habilite explicitamente o download
na primeira preparação da estação:

```bash
export CRIA_ALLOW_MODEL_DOWNLOADS=1
```

O Qwen principal deve estar servido pelo Ollama com o alias configurado em
`models.llm.runtime_model`. É possível sobrescrever sem alterar arquivos:

```bash
export CRIA_LLM_MODEL=qwen3-4b-q4_k_m
export CRIA_OLLAMA_URL=http://127.0.0.1:11434
```

## Execução

```bash
python -m ai_lore_guardian.lore_guardian_server
```

A documentação OpenAPI fica em `http://127.0.0.1:8000/docs`.

## Fluxo mínimo

Indexar/reindexar as fontes configuradas:

```bash
curl -sS -X POST http://127.0.0.1:8000/ingest \
  -H 'Content-Type: application/json' \
  -d '{"paths": [], "rebuild": true}'
```

Consultar evidências sem chamar o LLM:

```bash
curl -sS -X POST http://127.0.0.1:8000/query \
  -H 'Content-Type: application/json' \
  -d '{"query":"Qual é o símbolo de Ruan?", "top_k":5, "synthesize":false}'
```

Validar um conteúdo candidato:

```bash
curl -sS -X POST http://127.0.0.1:8000/validate \
  -H 'Content-Type: application/json' \
  --data-binary @conteudo_candidato.json
```

O envelope de validação deve conter:

```json
{
  "content_type": "mission",
  "strict_mode": true,
  "payload": {}
}
```

Tipos aceitos: `technique`, `character`, `mission` e `enemy`.

## Segurança operacional

- bind padrão somente em `127.0.0.1`;
- caminhos de ingestão não podem sair do repositório;
- extensões são limitadas em `config.yaml`;
- campos desconhecidos são rejeitados;
- sem evidência, a síntese é bloqueada;
- `CRIA_LORE_GUARDIAN_API_KEY` ativa autenticação por `X-API-Key` ou Bearer;
- os índices gerados em `ai_lore_guardian/storage/` são locais e não versionados.

## Validação sem instalar os modelos

```bash
python tools/validate_lore_guardian_phase1.py
python -m unittest discover -s ai_lore_guardian/tests -v
```
