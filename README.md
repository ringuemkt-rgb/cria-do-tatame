# 🥋 Visão de Cria

Plataforma de análise de combate em tempo real (Boxe, MMA, BJJ Gi e No-Gi), otimizada para baixa latência e uso em produção com overlay para OBS.

## O que foi otimizado nesta revisão completa

- ✅ API com `liveness` e `readiness` cacheado para reduzir custo por requisição.
- ✅ Motor de análise técnica modular (detecção de modalidade, regras BJJ, pontuação e insights).
- ✅ Endpoint de simulação para validar pipeline técnico sem depender de vídeo real.
- ✅ Testes unitários cobrindo regras, pontuação e geração de insight.
- ✅ Frontend com dashboard/overlay prontos para operação inicial.

## Arquitetura base

- **Backend:** FastAPI + Celery + Redis + PostgreSQL/TimescaleDB + MinIO
- **Análise:** módulos dedicados em `backend/app/analysis/`
- **Frontend:** Next.js 14 + Tailwind
- **Infra local:** Docker Compose

## Endpoints principais

- `GET /api/v1/health/live`
- `GET /api/v1/health/ready`
- `POST /api/v1/modality/override`
- `POST /api/v1/analysis/simulate`

## Rodando localmente

```bash
cp .env.example .env
docker compose up --build
```

## Testes rápidos

```bash
python -m compileall backend/app
PYTHONPATH=backend pytest -q backend/tests
cd frontend && npm run lint && npm run build
```

## Simulação da análise técnica (exemplo)

```bash
curl -X POST http://localhost:8000/api/v1/analysis/simulate \
  -H "Content-Type: application/json" \
  -d '{
    "modalidade": "bjj_gi",
    "eventos": [
      {"atleta":"azul","acao":"guard_pass","duracao_ms":3500,"confianca":0.93},
      {"atleta":"branco","acao":"stalling","duracao_ms":900,"confianca":0.71}
    ]
  }'
```

## Inspirações técnicas (adaptação para nosso contexto)

A organização do pipeline foi estruturada com referências de boas práticas de ecossistemas abertos como:
- arquitetura de inferência modular (separação detecção/classificação/regras);
- contracts tipados para eventos;
- readiness para orquestração;
- processamento incremental para stream.

Tudo foi adaptado para o contexto do **Visão de Cria**, priorizando pt-BR, regras de luta e integração com OBS.
