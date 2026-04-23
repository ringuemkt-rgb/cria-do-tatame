"""Ponto de entrada da API FastAPI."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes.analysis import router as analysis_router
from app.api.routes.health import router as health_router
from app.api.routes.modality import router as modality_router
from app.core.config import get_settings
from app.core.logging import configure_logging

configure_logging()
settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="API inicial do projeto Visão de Cria",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_allow_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router, prefix="/api/v1")
app.include_router(modality_router, prefix="/api/v1")
app.include_router(analysis_router, prefix="/api/v1")


@app.get("/")
async def root() -> dict[str, str]:
    """Rota raiz informativa."""

    return {"mensagem": "Visão de Cria API online", "docs": "/api/docs"}
