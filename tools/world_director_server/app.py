from __future__ import annotations

import hashlib
import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Literal

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict, Field, field_validator

APP_TITLE = "Cria World Director Service"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
HF_ROUTER_URL = "https://router.huggingface.co/v1/chat/completions"
ROOT = Path(__file__).resolve().parents[2]
CATALOG_PATH = ROOT / "data" / "nft" / "nft_catalog_v01.json"
EVENTS_PATH = ROOT / "data" / "world" / "dynamic_events_v01.json"

app = FastAPI(title=APP_TITLE, version="1.0.0")
_cache: dict[str, tuple[float, dict[str, Any]]] = {}


class WorldPlanRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    campaign_id: str = Field(min_length=1, max_length=64)
    snapshot: dict[str, Any]
    constraints: dict[str, Any] = Field(default_factory=dict)


class RivalDirective(BaseModel):
    model_config = ConfigDict(extra="forbid")

    strategy_id: str = Field(default="adaptativo", max_length=48)
    aggression: float = Field(default=0.5, ge=0.0, le=1.0)
    risk_tolerance: float = Field(default=0.5, ge=0.0, le=1.0)
    gas_budget: float = Field(default=0.75, ge=0.0, le=1.0)
    preferred_action: str | None = Field(default=None, max_length=64)


class WorldPlan(BaseModel):
    model_config = ConfigDict(extra="forbid")

    summary: str = Field(max_length=240)
    event_nudges: list[str] = Field(default_factory=list, max_length=2)
    rival_directives: dict[str, RivalDirective] = Field(default_factory=dict)
    faction_pressure: dict[str, float] = Field(default_factory=dict)
    economy_modifiers: dict[str, float] = Field(default_factory=dict)
    narrative_hooks: list[str] = Field(default_factory=list, max_length=3)

    @field_validator("faction_pressure")
    @classmethod
    def clamp_faction_pressure(cls, values: dict[str, float]) -> dict[str, float]:
        return {str(key)[:64]: max(-3.0, min(3.0, float(value))) for key, value in values.items()}

    @field_validator("economy_modifiers")
    @classmethod
    def clamp_economy(cls, values: dict[str, float]) -> dict[str, float]:
        return {str(key)[:64]: max(0.75, min(1.35, float(value))) for key, value in values.items()}


class WorldPlanResponse(BaseModel):
    plan: WorldPlan
    provider: str
    model: str
    cached: bool = False


class NFTEntitlementRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    player_id: str = Field(min_length=1, max_length=64)
    wallet_address: str = Field(min_length=8, max_length=128)
    catalog_version: str = Field(default="0", max_length=32)


class NFTEntitlement(BaseModel):
    item_id: str
    token_id: str
    standard: Literal["ERC-721", "ERC-1155", "offchain"]
    verified: bool = True


class NFTEntitlementResponse(BaseModel):
    wallet_address: str
    entitlements: list[NFTEntitlement]
    verified_at: str
    source: str


def _load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _known_event_ids() -> set[str]:
    return {str(item.get("id", "")) for item in _load_json(EVENTS_PATH).get("events", [])}


def _schema() -> dict[str, Any]:
    return {
        "type": "object",
        "properties": {
            "summary": {"type": "string", "maxLength": 240},
            "event_nudges": {"type": "array", "maxItems": 2, "items": {"type": "string"}},
            "rival_directives": {
                "type": "object",
                "additionalProperties": {
                    "type": "object",
                    "properties": {
                        "strategy_id": {"type": "string", "maxLength": 48},
                        "aggression": {"type": "number", "minimum": 0, "maximum": 1},
                        "risk_tolerance": {"type": "number", "minimum": 0, "maximum": 1},
                        "gas_budget": {"type": "number", "minimum": 0, "maximum": 1},
                        "preferred_action": {"type": ["string", "null"]},
                    },
                    "required": ["strategy_id", "aggression", "risk_tolerance", "gas_budget"],
                    "additionalProperties": False,
                },
            },
            "faction_pressure": {"type": "object", "additionalProperties": {"type": "number", "minimum": -3, "maximum": 3}},
            "economy_modifiers": {"type": "object", "additionalProperties": {"type": "number", "minimum": 0.75, "maximum": 1.35}},
            "narrative_hooks": {"type": "array", "maxItems": 3, "items": {"type": "string", "maxLength": 180}},
        },
        "required": ["summary", "event_nudges", "rival_directives", "faction_pressure", "economy_modifiers", "narrative_hooks"],
        "additionalProperties": False,
    }


def _system_prompt() -> str:
    return (
        "Você é o Diretor de Mundo do RPG Cria do Tatame, ambientado em Ituberá, Salvador, "
        "Zambiapunga e Camamu/Manguezal. Produza apenas um plano estratégico de baixa frequência. "
        "Nunca controle golpes, inputs, animações ou frames de combate. Nunca crie protagonista, facção, "
        "morte, parentesco ou evento canônico maior. Ruan 'Macacão' Silva, Mestre Dendê e Tinker Bell "
        "são cânone fixo. Use português brasileiro. Escolha somente event_nudges já existentes no snapshot. "
        "NFTs são opcionais, cosméticos e nunca concedem vantagem de gameplay."
    )


def _cache_key(request: WorldPlanRequest) -> str:
    raw = request.model_dump_json(exclude_none=True)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _clean_plan(plan: WorldPlan, request: WorldPlanRequest) -> WorldPlan:
    known_events = _known_event_ids()
    plan.event_nudges = [event for event in plan.event_nudges if event in known_events][:2]
    known_rivals = set(request.snapshot.get("rival_directives", {}).keys())
    plan.rival_directives = {rival_id: directive for rival_id, directive in plan.rival_directives.items() if rival_id in known_rivals}
    plan.narrative_hooks = [str(value)[:180] for value in plan.narrative_hooks[:3]]
    return plan


def _fallback_plan(request: WorldPlanRequest) -> WorldPlan:
    snapshot = request.snapshot
    active_events = {str(item.get("id", "")) for item in snapshot.get("active_events", [])}
    known = sorted(_known_event_ids() - active_events)
    tick = int(snapshot.get("tick", 0))
    nudge = [known[tick % len(known)]] if known and tick % 4 == 0 else []
    rivals: dict[str, RivalDirective] = {}
    for rival_id, current in snapshot.get("rival_directives", {}).items():
        rivals[str(rival_id)] = RivalDirective(
            strategy_id=str(current.get("strategy_id", "adaptativo"))[:48],
            aggression=float(current.get("aggression", 0.5)),
            risk_tolerance=float(current.get("risk_tolerance", 0.5)),
            gas_budget=float(current.get("gas_budget", 0.75)),
            preferred_action=current.get("preferred_action"),
        )
    return WorldPlan(
        summary="Plano determinístico local aplicado; a simulação continua sem depender de serviço externo.",
        event_nudges=nudge,
        rival_directives=rivals,
        faction_pressure={},
        economy_modifiers={},
        narrative_hooks=[],
    )


async def _call_openrouter(request: WorldPlanRequest) -> tuple[WorldPlan, str]:
    token = os.getenv("OPENROUTER_API_KEY", "").strip()
    if not token:
        raise RuntimeError("OPENROUTER_API_KEY ausente")
    model = os.getenv("OPENROUTER_MODEL", "openrouter/free")
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": _system_prompt()},
            {"role": "user", "content": json.dumps(request.model_dump(), ensure_ascii=False)},
        ],
        "temperature": 0.35,
        "max_tokens": 1200,
        "response_format": {"type": "json_schema", "json_schema": {"name": "cria_world_plan", "strict": True, "schema": _schema()}},
        "provider": {"require_parameters": True},
        "plugins": [{"id": "response-healing"}],
    }
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "HTTP-Referer": os.getenv("OPENROUTER_APP_URL", "https://github.com/ringuemkt-rgb/cria-do-tatame"),
        "X-OpenRouter-Title": "Cria do Tatame World Director",
    }
    async with httpx.AsyncClient(timeout=25.0) as client:
        response = await client.post(OPENROUTER_URL, headers=headers, json=payload)
        response.raise_for_status()
        body = response.json()
    content = body["choices"][0]["message"]["content"]
    return WorldPlan.model_validate_json(content), model


async def _call_huggingface(request: WorldPlanRequest) -> tuple[WorldPlan, str]:
    token = os.getenv("HF_TOKEN", "").strip()
    if not token:
        raise RuntimeError("HF_TOKEN ausente")
    model = os.getenv("HF_WORLD_MODEL", "Qwen/Qwen3-4B-Instruct-2507")
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": _system_prompt()},
            {"role": "user", "content": json.dumps(request.model_dump(), ensure_ascii=False) + "\nResponda somente JSON válido com as chaves do schema do Diretor de Mundo."},
        ],
        "temperature": 0.35,
        "max_tokens": 1200,
        "response_format": {"type": "json_object"},
    }
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    async with httpx.AsyncClient(timeout=25.0) as client:
        response = await client.post(HF_ROUTER_URL, headers=headers, json=payload)
        response.raise_for_status()
        body = response.json()
    content = body["choices"][0]["message"]["content"]
    return WorldPlan.model_validate_json(content), model


async def _generate_plan(request: WorldPlanRequest) -> tuple[WorldPlan, str, str]:
    provider_order = [item.strip() for item in os.getenv("WORLD_AI_PROVIDER_ORDER", "huggingface,openrouter,deterministic").split(",")]
    errors: list[str] = []
    for provider in provider_order:
        try:
            if provider == "huggingface":
                plan, model = await _call_huggingface(request)
                return _clean_plan(plan, request), "huggingface", model
            if provider == "openrouter":
                plan, model = await _call_openrouter(request)
                return _clean_plan(plan, request), "openrouter", model
            if provider == "deterministic":
                return _clean_plan(_fallback_plan(request), request), "deterministic", "built-in-v1"
        except (httpx.HTTPError, RuntimeError, KeyError, TypeError, ValueError) as exc:
            errors.append(f"{provider}: {exc}")
    raise HTTPException(status_code=503, detail={"message": "Nenhum provedor disponível", "errors": errors})


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "service": APP_TITLE,
        "openrouter_configured": bool(os.getenv("OPENROUTER_API_KEY")),
        "huggingface_configured": bool(os.getenv("HF_TOKEN")),
        "nft_chain_configured": bool(os.getenv("NFT_RPC_URL") and (os.getenv("NFT_ERC721_CONTRACT_ADDRESS") or os.getenv("NFT_ERC1155_CONTRACT_ADDRESS"))),
    }


@app.post("/v1/world/plan", response_model=WorldPlanResponse)
async def world_plan(request: WorldPlanRequest) -> WorldPlanResponse:
    key = _cache_key(request)
    cached = _cache.get(key)
    now = time.monotonic()
    ttl = max(10, int(os.getenv("WORLD_PLAN_CACHE_SECONDS", "300")))
    if cached and now - cached[0] <= ttl:
        payload = cached[1]
        return WorldPlanResponse(**payload, cached=True)
    plan, provider, model = await _generate_plan(request)
    payload = {"plan": plan, "provider": provider, "model": model}
    _cache[key] = (now, payload)
    return WorldPlanResponse(**payload)


@app.get("/v1/nft/catalog")
def nft_catalog() -> dict[str, Any]:
    return _load_json(CATALOG_PATH)


def _dev_entitlements(wallet: str, catalog: dict[str, Any]) -> list[NFTEntitlement]:
    if os.getenv("NFT_DEV_MODE", "false").lower() != "true":
        return []
    requested = {item.strip() for item in os.getenv("NFT_DEV_ENTITLEMENTS", "").split(",") if item.strip()}
    output: list[NFTEntitlement] = []
    for item in catalog.get("items", []):
        if item.get("id") in requested:
            output.append(NFTEntitlement(item_id=str(item["id"]), token_id=str(item.get("token_id", "")), standard="offchain", verified=True))
    return output


def _chain_entitlements(wallet: str, catalog: dict[str, Any]) -> list[NFTEntitlement]:
    rpc_url = os.getenv("NFT_RPC_URL", "").strip()
    erc721_address = os.getenv("NFT_ERC721_CONTRACT_ADDRESS", "").strip()
    erc1155_address = os.getenv("NFT_ERC1155_CONTRACT_ADDRESS", "").strip()
    if not rpc_url or not (erc721_address or erc1155_address):
        return []
    try:
        from web3 import Web3
    except ImportError as exc:
        raise RuntimeError("web3 não instalado") from exc
    web3 = Web3(Web3.HTTPProvider(rpc_url, request_kwargs={"timeout": 10}))
    if not web3.is_connected():
        raise RuntimeError("RPC indisponível")
    address = web3.to_checksum_address(wallet)
    erc721_abi = [{
        "inputs": [{"internalType": "uint256", "name": "tokenId", "type": "uint256"}],
        "name": "ownerOf",
        "outputs": [{"internalType": "address", "name": "owner", "type": "address"}],
        "stateMutability": "view",
        "type": "function",
    }]
    erc1155_abi = [{
        "inputs": [
            {"internalType": "address", "name": "account", "type": "address"},
            {"internalType": "uint256", "name": "id", "type": "uint256"},
        ],
        "name": "balanceOf",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    }]
    c721 = web3.eth.contract(address=web3.to_checksum_address(erc721_address), abi=erc721_abi) if erc721_address else None
    c1155 = web3.eth.contract(address=web3.to_checksum_address(erc1155_address), abi=erc1155_abi) if erc1155_address else None
    output: list[NFTEntitlement] = []
    for item in catalog.get("items", []):
        token_id = int(str(item.get("token_id", "0")))
        standard = str(item.get("standard", "ERC-1155"))
        try:
            if standard == "ERC-721" and c721 is not None:
                owner = c721.functions.ownerOf(token_id).call()
                owned = web3.to_checksum_address(owner) == address
            elif standard == "ERC-1155" and c1155 is not None:
                owned = int(c1155.functions.balanceOf(address, token_id).call()) > 0
            else:
                owned = False
        except Exception:
            owned = False
        if owned:
            output.append(NFTEntitlement(item_id=str(item.get("id", "")), token_id=str(token_id), standard=standard, verified=True))
    return output


@app.post("/v1/nft/entitlements", response_model=NFTEntitlementResponse)
def nft_entitlements(request: NFTEntitlementRequest) -> NFTEntitlementResponse:
    catalog = _load_json(CATALOG_PATH)
    source = "disabled"
    entitlements: list[NFTEntitlement] = []
    try:
        entitlements = _chain_entitlements(request.wallet_address, catalog)
        if os.getenv("NFT_RPC_URL") and (os.getenv("NFT_ERC721_CONTRACT_ADDRESS") or os.getenv("NFT_ERC1155_CONTRACT_ADDRESS")):
            source = "chain_verified"
        elif os.getenv("NFT_DEV_MODE", "false").lower() == "true":
            entitlements = _dev_entitlements(request.wallet_address, catalog)
            source = "dev_catalog"
    except (RuntimeError, ValueError) as exc:
        raise HTTPException(status_code=503, detail=f"Falha ao verificar colecionáveis: {exc}") from exc
    return NFTEntitlementResponse(
        wallet_address=request.wallet_address,
        entitlements=entitlements,
        verified_at=datetime.now(timezone.utc).isoformat(),
        source=source,
    )
