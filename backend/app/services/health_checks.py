"""Checagens de prontidão para dependências externas."""

from __future__ import annotations

import asyncio

import asyncpg
import httpx
from minio import Minio
from redis.asyncio import Redis

from app.core.config import Settings
from app.schemas.health import DependencyStatus


async def check_postgres(settings: Settings) -> DependencyStatus:
    """Valida conectividade com PostgreSQL/TimescaleDB."""

    try:
        conn = await asyncpg.connect(settings.database_url.replace("+asyncpg", ""), timeout=2)
        await conn.execute("SELECT 1")
        await conn.close()
        return DependencyStatus(nome="postgres", status="ok")
    except Exception as exc:  # pragma: no cover - proteção de ambiente
        return DependencyStatus(nome="postgres", status="erro", detalhe=str(exc))


async def check_redis(settings: Settings) -> DependencyStatus:
    """Valida ping no Redis."""

    redis = Redis.from_url(settings.redis_url, socket_timeout=2)
    try:
        await redis.ping()
        return DependencyStatus(nome="redis", status="ok")
    except Exception as exc:  # pragma: no cover
        return DependencyStatus(nome="redis", status="erro", detalhe=str(exc))
    finally:
        await redis.aclose()


async def check_minio(settings: Settings) -> DependencyStatus:
    """Valida endpoint HTTP de saúde do MinIO."""

    protocol = "https" if settings.minio_secure else "http"
    url = f"{protocol}://{settings.minio_endpoint}/minio/health/live"

    try:
        async with httpx.AsyncClient(timeout=2) as client:
            response = await client.get(url)
            response.raise_for_status()

        _ = Minio(
            endpoint=settings.minio_endpoint,
            access_key=settings.minio_access_key,
            secret_key=settings.minio_secret_key,
            secure=settings.minio_secure,
        )
        return DependencyStatus(nome="minio", status="ok")
    except Exception as exc:  # pragma: no cover
        return DependencyStatus(nome="minio", status="erro", detalhe=str(exc))


async def run_readiness_checks(settings: Settings) -> list[DependencyStatus]:
    """Executa checks em paralelo para reduzir latência do endpoint."""

    return await asyncio.gather(
        check_postgres(settings),
        check_redis(settings),
        check_minio(settings),
    )
