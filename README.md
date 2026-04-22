# 🥋 Visão de Cria

Plataforma de análise de combate em tempo real (Boxe, MMA, BJJ Gi e No-Gi) com arquitetura modular para produção.

> **Status atual:** Etapa 1 revisada, endurecida e profissionalizada (infra + API + frontend + qualidade).

## ✅ O que foi melhorado nesta revisão

- Stack Docker organizada com healthchecks reais e dependências encadeadas.
- Backend com **liveness/readiness** (`/health/live` e `/health/ready`) validando PostgreSQL, Redis e MinIO.
- CORS configurável por ambiente (`CORS_ORIGINS`).
- Frontend com layout mais profissional, overlay transparente para OBS e lint não interativo.
- Documentação em pt-BR com fluxo de validação local.

## Estrutura do projeto

```text
.
├── backend/                # API FastAPI + worker Celery
├── frontend/               # Dashboard e overlay OBS (Next.js 14)
├── docs/pt-br/             # Documentação técnica em português
├── docker-compose.yml      # Orquestração local
└── .env.example            # Variáveis padrão (copiar para .env)
```

## Como rodar localmente

```bash
cp .env.example .env
docker compose up --build
```

## Endpoints principais

- `GET /api/v1/health/live` → processo da API ativo
- `GET /api/v1/health/ready` → dependências prontas
- `POST /api/v1/modality/override` → fallback manual de modalidade

## Frontend

- Página inicial: `http://localhost:3000`
- Overlay OBS: `http://localhost:3000/overlay/live`

## Validação rápida

```bash
curl http://localhost:8000/api/v1/health/live
curl http://localhost:8000/api/v1/health/ready
curl -X POST http://localhost:8000/api/v1/modality/override \
  -H "Content-Type: application/json" \
  -d '{"modality":"bjj_gi","motivo":"teste local"}'
```

## Próxima etapa sugerida

Etapa 2: ingestão de vídeo com `yt-dlp` + FFmpeg e detector automático de modalidade.
