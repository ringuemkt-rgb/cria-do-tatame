# Etapa 1 — Estrutura, Docker e Configurações

## Objetivo
Estabelecer a base de execução do **Visão de Cria** com serviços obrigatórios, healthchecks e inicialização de API/frontend para evolução incremental.

## Entregáveis implementados

1. **Monorepo inicial** com diretórios `backend`, `frontend` e `docs/pt-br`.
2. **Docker Compose** com PostgreSQL/TimescaleDB, Redis, MinIO, API, worker e frontend.
3. **Backend FastAPI** com:
   - logging estruturado JSON;
   - endpoint de saúde `GET /api/v1/health`;
   - endpoint de fallback `POST /api/v1/modality/override`.
4. **Worker Celery** configurado com Redis.
5. **Frontend Next.js 14** com rota inicial e rota de overlay em `/overlay/live`.
6. **Arquivo `.env.example`** com variáveis padrão para todos os serviços.

## Comandos de validação

```bash
docker compose config
docker compose up --build -d
curl http://localhost:8000/api/v1/health
curl -X POST http://localhost:8000/api/v1/modality/override -H "Content-Type: application/json" -d '{"modality":"mma"}'
```

## Observações de arquitetura

- A persistência temporal será expandida na Etapa 5 (schema TimescaleDB).
- O endpoint de override já está pronto para integração com modal de baixa confiança na Etapa 2.
- O frontend usa pt-BR como idioma principal (`lang="pt-BR"`).
