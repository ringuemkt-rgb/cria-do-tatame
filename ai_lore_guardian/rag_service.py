"""Ingestão, recuperação híbrida, reranking e síntese local do cânone."""

from __future__ import annotations

import hashlib
import json
import math
import os
import re
import threading
from collections import Counter
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable

from .schemas import Evidence
from .settings import PROJECT_ROOT


TOKEN_PATTERN = re.compile(r"[\wÀ-ÿ]{2,}", re.UNICODE)


def _tokens(text: str) -> list[str]:
    return [token.casefold() for token in TOKEN_PATTERN.findall(text)]


@dataclass(slots=True)
class CanonChunk:
    chunk_id: str
    source: str
    text: str
    metadata: dict[str, Any]


class RagService:
    """RAG com dependências pesadas carregadas apenas no primeiro uso."""

    def __init__(self, settings: dict[str, Any]) -> None:
        self.settings = settings
        self.rag_config = settings["rag"]
        self.model_config = settings["models"]
        self._chunks: dict[str, CanonChunk] = {}
        self._vector_collection: Any = None
        self._embedding_model: Any = None
        self._reranker: Any = None
        self._vector_error: str | None = None
        self._reranker_error: str | None = None
        self._lock = threading.RLock()
        self._load_lexical_index()

    @property
    def vector_backend(self) -> str:
        return "chromadb+bge-m3" if self._vector_collection is not None else "lexical_offline"

    @property
    def reranker_backend(self) -> str:
        return "bge-reranker-v2-m3" if self._reranker is not None else "lexical_score"

    def _resolve_safe_path(self, raw_path: str) -> Path:
        candidate = Path(raw_path)
        resolved = candidate.resolve() if candidate.is_absolute() else (PROJECT_ROOT / candidate).resolve()
        try:
            resolved.relative_to(PROJECT_ROOT)
        except ValueError as exc:
            raise ValueError(f"Caminho fora do repositório: {raw_path}") from exc
        allowed_extensions = {str(ext).lower() for ext in self.rag_config["allowed_extensions"]}
        if resolved.is_file() and resolved.suffix.lower() not in allowed_extensions:
            raise ValueError(f"Extensão não autorizada para ingestão: {resolved.suffix}")
        return resolved

    def _source_files(self, raw_paths: list[str]) -> list[Path]:
        requested = raw_paths or list(self.rag_config["canonical_sources"])
        allowed_extensions = {str(ext).lower() for ext in self.rag_config["allowed_extensions"]}
        files: set[Path] = set()
        for raw_path in requested:
            resolved = self._resolve_safe_path(raw_path)
            if not resolved.exists():
                raise FileNotFoundError(f"Fonte canônica não encontrada: {resolved}")
            if resolved.is_dir():
                files.update(
                    path.resolve()
                    for path in resolved.rglob("*")
                    if path.is_file() and path.suffix.lower() in allowed_extensions
                )
            else:
                files.add(resolved)
        return sorted(files)

    def _chunks_from_file(self, path: Path) -> Iterable[CanonChunk]:
        relative = path.relative_to(PROJECT_ROOT).as_posix()
        if path.suffix.lower() == ".json":
            try:
                document = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as exc:
                raise ValueError(f"JSON inválido em {relative}: {exc}") from exc
            yield from self._chunks_from_json(relative, document)
            return
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            raise ValueError(f"Não foi possível ler {relative}: {exc}") from exc
        yield from self._split_text(relative, text, {"format": path.suffix.lower().lstrip(".")})

    def _chunks_from_json(self, source: str, document: Any) -> Iterable[CanonChunk]:
        if isinstance(document, dict):
            list_fields = [(key, value) for key, value in document.items() if isinstance(value, list)]
            if list_fields:
                for collection, items in list_fields:
                    for position, item in enumerate(items):
                        text = json.dumps(item, ensure_ascii=False, sort_keys=True)
                        item_id = item.get("id") if isinstance(item, dict) else None
                        metadata = {
                            "format": "json",
                            "collection": collection,
                            "position": position,
                            "entity_id": str(item_id or ""),
                        }
                        yield from self._split_text(source, text, metadata)
                scalar_root = {key: value for key, value in document.items() if not isinstance(value, list)}
                if scalar_root:
                    yield from self._split_text(
                        source,
                        json.dumps(scalar_root, ensure_ascii=False, sort_keys=True),
                        {"format": "json", "collection": "metadata"},
                    )
                return
        yield from self._split_text(
            source,
            json.dumps(document, ensure_ascii=False, sort_keys=True),
            {"format": "json", "collection": "root"},
        )

    def _split_text(self, source: str, text: str, metadata: dict[str, Any]) -> Iterable[CanonChunk]:
        size = int(self.rag_config["chunk_size_chars"])
        overlap = int(self.rag_config["chunk_overlap_chars"])
        clean = re.sub(r"\n{3,}", "\n\n", text).strip()
        if not clean:
            return
        start = 0
        part = 0
        while start < len(clean):
            end = min(len(clean), start + size)
            if end < len(clean):
                boundary = max(clean.rfind("\n", start, end), clean.rfind(". ", start, end))
                if boundary > start + size // 2:
                    end = boundary + 1
            chunk_text = clean[start:end].strip()
            if chunk_text:
                identity = f"{source}|{part}|{chunk_text}".encode("utf-8")
                chunk_metadata = dict(metadata)
                chunk_metadata["part"] = part
                yield CanonChunk(
                    chunk_id=hashlib.sha256(identity).hexdigest()[:32],
                    source=source,
                    text=chunk_text,
                    metadata=chunk_metadata,
                )
            if end >= len(clean):
                break
            start = max(end - overlap, start + 1)
            part += 1

    def ingest(self, raw_paths: list[str], rebuild: bool = False) -> tuple[int, int, list[str]]:
        files = self._source_files(raw_paths)
        chunks = [chunk for path in files for chunk in self._chunks_from_file(path)]
        ingested_sources = {path.relative_to(PROJECT_ROOT).as_posix() for path in files}
        warnings: list[str] = []
        with self._lock:
            previous_ids = {
                chunk_id
                for chunk_id, chunk in self._chunks.items()
                if rebuild or chunk.source in ingested_sources
            }
            if rebuild:
                self._chunks.clear()
            else:
                # Substitui integralmente cada fonte reingerida. Assim, um item
                # removido do JSON não permanece como evidência fantasma.
                self._chunks = {
                    chunk_id: chunk
                    for chunk_id, chunk in self._chunks.items()
                    if chunk.source not in ingested_sources
                }
            self._chunks.update({chunk.chunk_id: chunk for chunk in chunks})
            obsolete_ids = previous_ids.difference(chunk.chunk_id for chunk in chunks)
            self._save_lexical_index()
            try:
                self._upsert_vectors(chunks, rebuild)
                if obsolete_ids and not rebuild and self._vector_collection is not None:
                    self._vector_collection.delete(ids=sorted(obsolete_ids))
            except Exception as exc:  # dependências/modelos locais são opcionais
                self._vector_error = f"Vector backend indisponível: {type(exc).__name__}: {exc}"
                warnings.append(self._vector_error)
        return len(files), len(chunks), warnings

    def _local_files_only(self) -> bool:
        return not bool(self.model_config.get("allow_downloads", False))

    def _ensure_vector_backend(self, rebuild: bool = False) -> None:
        if self._vector_collection is not None:
            return
        import chromadb  # type: ignore[import-not-found]
        from sentence_transformers import SentenceTransformer  # type: ignore[import-not-found]

        embedding_config = self.model_config["embeddings"]
        self._embedding_model = SentenceTransformer(
            str(embedding_config["repository"]),
            device=str(embedding_config.get("device", "cpu")),
            local_files_only=self._local_files_only(),
        )
        client = chromadb.PersistentClient(path=str(self.rag_config["persist_directory"]))
        collection_name = str(self.rag_config["collection_name"])
        if rebuild:
            try:
                client.delete_collection(collection_name)
            except Exception:
                pass
        self._vector_collection = client.get_or_create_collection(
            name=collection_name,
            metadata={"hnsw:space": "cosine"},
        )

    def _encode(self, texts: list[str]) -> list[list[float]]:
        embedding_config = self.model_config["embeddings"]
        encoded = self._embedding_model.encode(
            texts,
            batch_size=int(embedding_config.get("batch_size", 16)),
            normalize_embeddings=bool(embedding_config.get("normalize", True)),
            show_progress_bar=False,
        )
        return encoded.tolist()

    def _upsert_vectors(self, chunks: list[CanonChunk], rebuild: bool) -> None:
        if not chunks:
            return
        self._ensure_vector_backend(rebuild=rebuild)
        batch_size = 64
        for start in range(0, len(chunks), batch_size):
            batch = chunks[start : start + batch_size]
            self._vector_collection.upsert(
                ids=[chunk.chunk_id for chunk in batch],
                documents=[chunk.text for chunk in batch],
                embeddings=self._encode([chunk.text for chunk in batch]),
                metadatas=[{"source": chunk.source, **chunk.metadata} for chunk in batch],
            )

    def query(self, query: str, top_k: int, filters: dict[str, Any]) -> tuple[list[Evidence], list[str]]:
        warnings: list[str] = []
        candidate_count = max(top_k, int(self.rag_config["candidate_count"]))
        candidates: list[Evidence] = []
        try:
            if self._vector_collection is None:
                self._ensure_vector_backend()
            kwargs: dict[str, Any] = {
                "query_embeddings": self._encode([query]),
                "n_results": min(candidate_count, max(1, len(self._chunks))),
                "include": ["documents", "metadatas", "distances"],
            }
            if filters:
                kwargs["where"] = filters
            result = self._vector_collection.query(**kwargs)
            for chunk_id, text, metadata, distance in zip(
                result.get("ids", [[]])[0],
                result.get("documents", [[]])[0],
                result.get("metadatas", [[]])[0],
                result.get("distances", [[]])[0],
                strict=False,
            ):
                metadata = dict(metadata or {})
                candidates.append(
                    Evidence(
                        chunk_id=str(chunk_id),
                        source=str(metadata.pop("source", "unknown")),
                        text=str(text),
                        score=float(1.0 - float(distance)),
                        metadata=metadata,
                    )
                )
        except Exception as exc:
            self._vector_error = f"Busca vetorial indisponível: {type(exc).__name__}: {exc}"
            warnings.append(self._vector_error)
            candidates = self._lexical_query(query, candidate_count, filters)
        if not candidates:
            candidates = self._lexical_query(query, candidate_count, filters)
        reranked, rerank_warning = self._rerank(query, candidates)
        if rerank_warning:
            warnings.append(rerank_warning)
        return reranked[:top_k], warnings

    def _lexical_query(self, query: str, limit: int, filters: dict[str, Any]) -> list[Evidence]:
        query_terms = Counter(_tokens(query))
        if not query_terms:
            return []
        document_frequencies: Counter[str] = Counter()
        tokenized: dict[str, Counter[str]] = {}
        eligible: list[CanonChunk] = []
        for chunk in self._chunks.values():
            combined_metadata = {"source": chunk.source, **chunk.metadata}
            if any(combined_metadata.get(key) != value for key, value in filters.items()):
                continue
            counts = Counter(_tokens(chunk.text))
            tokenized[chunk.chunk_id] = counts
            document_frequencies.update(counts.keys())
            eligible.append(chunk)
        total = max(1, len(eligible))
        scored: list[Evidence] = []
        for chunk in eligible:
            counts = tokenized[chunk.chunk_id]
            score = 0.0
            for term, query_frequency in query_terms.items():
                frequency = counts.get(term, 0)
                if frequency:
                    inverse_frequency = math.log(1.0 + total / (1.0 + document_frequencies[term]))
                    score += query_frequency * (1.0 + math.log(frequency)) * inverse_frequency
            if score > 0:
                scored.append(
                    Evidence(
                        chunk_id=chunk.chunk_id,
                        source=chunk.source,
                        text=chunk.text,
                        score=score,
                        metadata=chunk.metadata,
                    )
                )
        return sorted(scored, key=lambda item: item.score, reverse=True)[:limit]

    def _rerank(self, query: str, candidates: list[Evidence]) -> tuple[list[Evidence], str | None]:
        if len(candidates) < 2:
            return candidates, None
        try:
            if self._reranker is None:
                from sentence_transformers import CrossEncoder  # type: ignore[import-not-found]

                reranker_config = self.model_config["reranker"]
                self._reranker = CrossEncoder(
                    str(reranker_config["repository"]),
                    device=str(reranker_config.get("device", "cpu")),
                    local_files_only=self._local_files_only(),
                )
            scores = self._reranker.predict(
                [(query, candidate.text) for candidate in candidates],
                batch_size=int(self.model_config["reranker"].get("batch_size", 8)),
                show_progress_bar=False,
            )
            rescored = [candidate.model_copy(update={"score": float(score)}) for candidate, score in zip(candidates, scores, strict=True)]
            return sorted(rescored, key=lambda item: item.score, reverse=True), None
        except Exception as exc:
            self._reranker_error = f"Reranker indisponível: {type(exc).__name__}: {exc}"
            return sorted(candidates, key=lambda item: item.score, reverse=True), self._reranker_error

    def synthesize(self, question: str, evidence: list[Evidence]) -> tuple[str | None, str, list[str]]:
        if not evidence:
            return None, "disabled_no_evidence", ["Síntese bloqueada: nenhuma evidência canônica foi recuperada."]
        llm_config = self.model_config["llm"]
        context = "\n\n".join(
            f"[FONTE {position}: {item.source}]\n{item.text}"
            for position, item in enumerate(evidence, start=1)
        )
        system_prompt = (
            "Você é o Lore Guardian editorial de Cria do Tatame. Responda somente com base nas fontes "
            "fornecidas, em português brasileiro. Se a resposta não estiver nas fontes, diga que o cânone "
            "não fornece essa informação. Não invente personagens, arenas, técnicas ou eventos. Trate BJJ "
            "somente como mecânica gamificada segura, com tap, escape ou arbitragem. Cite as fontes como [FONTE N]."
        )
        payload = {
            "model": str(llm_config["runtime_model"]),
            "stream": False,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"PERGUNTA:\n{question}\n\nCONTEXTO CANÔNICO:\n{context}"},
            ],
            "options": {
                "temperature": float(llm_config.get("temperature", 0.2)),
                "num_predict": int(llm_config.get("max_tokens", 700)),
            },
        }
        try:
            import httpx  # type: ignore[import-not-found]

            response = httpx.post(
                f"{str(llm_config['base_url']).rstrip('/')}/api/chat",
                json=payload,
                timeout=float(llm_config.get("timeout_seconds", 25.0)),
            )
            response.raise_for_status()
            answer = str(response.json().get("message", {}).get("content", "")).strip()
            if not answer:
                raise ValueError("Ollama retornou conteúdo vazio.")
            return answer, "ollama_qwen3", []
        except Exception as exc:
            return None, "offline_evidence_only", [f"Síntese local indisponível: {type(exc).__name__}: {exc}"]

    def _save_lexical_index(self) -> None:
        path = Path(str(self.rag_config["lexical_index_path"]))
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(path.suffix + ".tmp")
        payload = {
            "version": 1,
            "chunks": [asdict(chunk) for chunk in sorted(self._chunks.values(), key=lambda value: value.chunk_id)],
        }
        temporary.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        os.replace(temporary, path)

    def _load_lexical_index(self) -> None:
        path = Path(str(self.rag_config["lexical_index_path"]))
        if not path.exists():
            return
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            chunks = [CanonChunk(**item) for item in payload.get("chunks", [])]
        except (OSError, json.JSONDecodeError, TypeError):
            return
        self._chunks = {chunk.chunk_id: chunk for chunk in chunks}
