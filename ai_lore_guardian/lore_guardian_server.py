"""API FastAPI local do Lore Guardian.

Execução recomendada:
    python -m ai_lore_guardian.lore_guardian_server
"""

from __future__ import annotations

import hmac
import os
from contextlib import asynccontextmanager
from typing import Annotated, Any, AsyncIterator

import uvicorn
from fastapi import Depends, FastAPI, Header, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import ORJSONResponse
from jsonschema import Draft202012Validator
from pydantic import ValidationError

from .lore_rules import CanonIndex, CanonValidator
from .rag_service import RagService
from .schemas import (
    CONTENT_MODELS,
    IngestRequest,
    IngestResponse,
    QueryRequest,
    QueryResponse,
    ValidateRequest,
    ValidateResponse,
    ValidationIssue,
)
from .settings import load_settings


SETTINGS = load_settings()


def _configured_api_key() -> str:
    variable = str(SETTINGS["security"].get("api_key_env", "CRIA_LORE_GUARDIAN_API_KEY"))
    return os.getenv(variable, "").strip()


async def require_api_key(
    authorization: Annotated[str | None, Header()] = None,
    x_api_key: Annotated[str | None, Header()] = None,
) -> None:
    """Exige segredo apenas quando o operador configurou um.

    Em loopback a chave é opcional. Se o serviço um dia for exposto, definir
    CRIA_LORE_GUARDIAN_API_KEY ativa a proteção sem mudar clientes.
    """

    expected = _configured_api_key()
    if not expected:
        return
    bearer = authorization.removeprefix("Bearer ").strip() if authorization else ""
    supplied = x_api_key or bearer
    if not supplied or not hmac.compare_digest(supplied, expected):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credencial local inválida.")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    index = CanonIndex.load()
    app.state.canon_index = index
    app.state.canon_validator = CanonValidator(index, SETTINGS["validation"])
    app.state.rag_service = RagService(SETTINGS)
    app.state.startup_warnings = []
    try:
        _, _, warnings = app.state.rag_service.ingest([], rebuild=False)
        app.state.startup_warnings.extend(warnings)
    except Exception as exc:
        # A API permanece disponível para /validate mesmo se a indexação falhar.
        app.state.startup_warnings.append(f"Ingestão inicial falhou: {type(exc).__name__}: {exc}")
    yield


app = FastAPI(
    title="Cria do Tatame — Lore Guardian",
    description="RAG editorial local e validação fail-closed do cânone.",
    version="1.0.0",
    default_response_class=ORJSONResponse,
    lifespan=lifespan,
)

allowed_origins = list(SETTINGS["security"].get("allowed_origins", []))
if allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["Authorization", "Content-Type", "X-API-Key"],
    )


@app.middleware("http")
async def limit_request_size(request: Request, call_next: Any) -> Any:
    maximum = int(SETTINGS["server"]["max_request_chars"])
    content_length = request.headers.get("content-length")
    if content_length and content_length.isdigit() and int(content_length) > maximum:
        return ORJSONResponse(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            content={"detail": f"Corpo excede o limite de {maximum} bytes."},
        )
    return await call_next(request)


@app.get("/health", tags=["operacao"])
async def health(request: Request) -> dict[str, Any]:
    rag: RagService = request.app.state.rag_service
    index: CanonIndex = request.app.state.canon_index
    return {
        "ok": True,
        "service": "cria-lore-guardian",
        "version": app.version,
        "canon_fingerprint": index.fingerprint,
        "vector_backend": rag.vector_backend,
        "reranker_backend": rag.reranker_backend,
        "startup_warnings": list(request.app.state.startup_warnings),
    }


@app.post(
    "/ingest",
    response_model=IngestResponse,
    tags=["rag"],
    dependencies=[Depends(require_api_key)],
)
async def ingest(payload: IngestRequest, request: Request) -> IngestResponse:
    rag: RagService = request.app.state.rag_service
    try:
        documents, chunks, warnings = rag.ingest(payload.paths, payload.rebuild)
        # Dados podem ter sido alterados entre chamadas; recarregar o índice faz
        # a validação sempre refletir o checkout atual do repositório.
        index = CanonIndex.load()
        request.app.state.canon_index = index
        request.app.state.canon_validator = CanonValidator(index, SETTINGS["validation"])
    except (FileNotFoundError, ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    return IngestResponse(
        ok=True,
        documents_indexed=documents,
        chunks_indexed=chunks,
        vector_backend=rag.vector_backend,
        warnings=warnings,
    )


@app.post(
    "/query",
    response_model=QueryResponse,
    tags=["rag"],
    dependencies=[Depends(require_api_key)],
)
async def query(payload: QueryRequest, request: Request) -> QueryResponse:
    rag: RagService = request.app.state.rag_service
    evidence, warnings = rag.query(payload.query, payload.top_k, payload.filters)
    answer: str | None = None
    generation_backend = "disabled_evidence_only"
    if payload.synthesize:
        answer, generation_backend, generation_warnings = rag.synthesize(payload.query, evidence)
        warnings.extend(generation_warnings)
    return QueryResponse(
        ok=bool(evidence),
        answer=answer,
        evidence=evidence,
        retrieval_backend=rag.vector_backend,
        reranker_backend=rag.reranker_backend,
        generation_backend=generation_backend,
        warnings=warnings,
    )


def _validation_issue_from_pydantic(error: dict[str, Any]) -> ValidationIssue:
    path = "$" + "".join(f"[{part}]" if isinstance(part, int) else f".{part}" for part in error.get("loc", []))
    return ValidationIssue(
        code="schema_validation_error",
        path=path,
        message=str(error.get("msg", "Conteúdo incompatível com o schema.")),
    )


@app.post(
    "/validate",
    response_model=ValidateResponse,
    tags=["validacao"],
    dependencies=[Depends(require_api_key)],
)
async def validate_content(payload: ValidateRequest, request: Request) -> ValidateResponse:
    model_type = CONTENT_MODELS[payload.content_type]
    index: CanonIndex = request.app.state.canon_index
    errors: list[ValidationIssue] = []
    try:
        model = model_type.model_validate(payload.payload)
    except ValidationError as exc:
        errors.extend(_validation_issue_from_pydantic(error) for error in exc.errors(include_url=False))
        return ValidateResponse(
            valid=False,
            content_type=payload.content_type,
            errors=errors,
            canon_fingerprint=index.fingerprint,
        )

    normalized = model.model_dump(mode="json")
    json_schema_validator = Draft202012Validator(model_type.model_json_schema())
    for error in sorted(json_schema_validator.iter_errors(normalized), key=lambda item: list(item.path)):
        path = "$" + "".join(f"[{part}]" if isinstance(part, int) else f".{part}" for part in error.path)
        errors.append(
            ValidationIssue(code="jsonschema_validation_error", path=path, message=error.message)
        )

    canon_validator: CanonValidator = request.app.state.canon_validator
    # O cliente pode pedir mais rigor, nunca menos do que o servidor determina.
    effective_strict_mode = bool(SETTINGS["validation"].get("strict_mode", True)) or payload.strict_mode
    canon_errors, warnings = canon_validator.validate(model, strict_mode=effective_strict_mode)
    errors.extend(canon_errors)
    return ValidateResponse(
        valid=not errors,
        content_type=payload.content_type,
        normalized=normalized if not errors else None,
        errors=errors,
        warnings=warnings,
        canon_fingerprint=index.fingerprint,
    )


def main() -> None:
    server = SETTINGS["server"]
    uvicorn.run(
        "ai_lore_guardian.lore_guardian_server:app",
        host=str(server["host"]),
        port=int(server["port"]),
        log_level=str(server["log_level"]),
        workers=int(server["workers"]),
    )


if __name__ == "__main__":
    main()
