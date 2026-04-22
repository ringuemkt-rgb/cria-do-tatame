"""Configurações centrais da aplicação."""

from functools import lru_cache

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configurações carregadas via variáveis de ambiente."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "Visão de Cria"
    app_env: str = Field(default="development", alias="APP_ENV")
    app_port: int = 8000
    app_version: str = "0.2.0"

    cors_origins: str = Field(default="http://localhost:3000", alias="CORS_ORIGINS")

    database_url: str = Field(
        default="postgresql+asyncpg://visaouser:visaopass@localhost:5432/visaodecria",
        alias="DATABASE_URL",
    )
    redis_url: str = Field(default="redis://localhost:6379/0", alias="REDIS_URL")
    celery_broker_url: str = Field(default="redis://localhost:6379/1", alias="CELERY_BROKER_URL")
    celery_result_backend: str = Field(default="redis://localhost:6379/2", alias="CELERY_RESULT_BACKEND")

    minio_endpoint: str = Field(default="localhost:9000", alias="MINIO_ENDPOINT")
    minio_access_key: str = Field(default="minioadmin", alias="MINIO_ROOT_USER")
    minio_secret_key: str = Field(default="minioadmin123", alias="MINIO_ROOT_PASSWORD")
    minio_secure: bool = Field(default=False, alias="MINIO_SECURE")

    @computed_field
    @property
    def cors_allow_list(self) -> list[str]:
        """Converte lista de CORS separada por vírgula para vetor."""

        return [item.strip() for item in self.cors_origins.split(",") if item.strip()]


@lru_cache
def get_settings() -> Settings:
    """Retorna instância singleton de configurações."""

    return Settings()
