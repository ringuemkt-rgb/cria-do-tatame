# Etapa 1 — Revisão Profissional (Infra + Base de Produto)

## Objetivo
Consolidar uma base realmente utilizável para evolução das próximas etapas, com confiabilidade operacional e UX inicial de nível profissional.

## Entregáveis desta revisão

1. **Infra Docker** com serviços obrigatórios e healthchecks consistentes.
2. **API FastAPI** com:
   - `/api/v1/health/live` (liveness);
   - `/api/v1/health/ready` (readiness com checks de PostgreSQL, Redis e MinIO);
   - fallback manual em `/api/v1/modality/override` com rastreabilidade (`origem` e `timestamp_utc`).
3. **Frontend Next.js** com:
   - dashboard inicial visualmente mais profissional;
   - overlay com fundo transparente para OBS;
   - ESLint configurado de forma não interativa.
4. **Configuração por ambiente** via `.env` e `.env.example`.

## Comandos de validação

```bash
cp .env.example .env
python -m compileall backend/app
cd frontend && npm install && npm run lint && npm run build
curl http://localhost:8000/api/v1/health/live
curl http://localhost:8000/api/v1/health/ready
```

## Observações

- `health/ready` foi desenhado para uso em orquestração (K8s, ECS, Nomad).
- O endpoint de fallback já atende ao cenário de baixa confiança da detecção automática.
- O overlay está pronto para acoplamento com WebSocket na Etapa 5.
