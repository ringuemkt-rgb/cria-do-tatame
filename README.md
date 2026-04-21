# 🥋 Visão de Cria

Plataforma de análise de combate em tempo real com foco em Boxe, MMA e Jiu-Jitsu (Gi/No-Gi), com backend em FastAPI, processamento assíncrono com Celery e frontend em Next.js.

> **Status atual:** Etapa 1 concluída (estrutura monorepo, Docker Compose, serviços base, healthchecks e configuração inicial).

## Estrutura do projeto

```text
.
├── backend/                # API FastAPI + worker Celery
├── frontend/               # Dashboard e overlay OBS (Next.js 14)
├── docs/pt-br/             # Documentação técnica em português
├── docker-compose.yml      # Orquestração local
└── .env.example            # Variáveis de ambiente padrão
```

## Serviços da Etapa 1

- **postgres** (TimescaleDB): persistência transacional e séries temporais.
- **redis**: cache e broker do Celery.
- **minio**: armazenamento de artefatos e mídias.
- **backend**: API FastAPI com rotas iniciais.
- **worker**: execução assíncrona com Celery.
- **frontend**: interface Next.js com rota `/overlay/live`.

## Como rodar localmente

1. Copie as variáveis:

```bash
cp .env.example .env
```

2. Suba a stack:

```bash
docker compose up --build
```

3. Endereços importantes:

- API: `http://localhost:8000`
- Health API: `http://localhost:8000/api/v1/health`
- Override de modalidade: `POST http://localhost:8000/api/v1/modality/override`
- Frontend: `http://localhost:3000`
- Overlay OBS: `http://localhost:3000/overlay/live`
- MinIO Console: `http://localhost:9001`

## Validação rápida do pipeline da Etapa 1

Com os serviços rodando:

```bash
curl http://localhost:8000/api/v1/health
curl -X POST http://localhost:8000/api/v1/modality/override \
  -H "Content-Type: application/json" \
  -d '{"modality":"bjj_gi"}'
```

As respostas devem indicar status saudável e confirmação de modalidade manual.

## Próximos passos (Etapa 2)

- Implementar `video_ingest.py` com `yt-dlp` + FFmpeg.
- Implementar `modality_detector.py` para decisão automática inicial.
- Conectar fallback de modalidade ao frontend com modal de confirmação.
