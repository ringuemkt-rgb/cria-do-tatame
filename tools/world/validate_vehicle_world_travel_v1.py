#!/usr/bin/env python3
"""Fail-closed validator for Vehicle World Travel V1.

This gate validates the travel contract, vehicle-service economy and the currently
consumed world-map shape without pretending the future semantic-map migration is
already live.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data/world/vehicle_world_travel_v1.json"
MAP_PATH = ROOT / "data/world/world_map_v4.json"
ECONOMY_PATH = ROOT / "data/economy.json"
RESOLVER_PATH = ROOT / "src/world/WorldRouteResolver.gd"
SERVICE_MODEL_PATH = ROOT / "src/world/VehicleServiceModel.gd"
SMOKE_PATH = ROOT / "tests/world_route_resolver_smoke.gd"
SERVICE_SMOKE_PATH = ROOT / "tests/vehicle_service_smoke.gd"

ALLOWED_ROUTE_TYPES = {
    "terrestre",
    "maritima",
    "secreta",
    "trilha",
    "ponte",
    "conexao",
    "connection",
    "bloqueada",
    "mare",
    "missao",
}

REQUIRED_AUTHORITIES = {
    "travel": "WorldMapManager",
    "money_energy_reputation": "WorldState",
    "world_events_weather": "WorldDirectorManager",
    "progression_ledger": "ProgressionOS",
    "save": "SaveManager",
    "audio": "AudioManager",
    "combat": "CombatManager",
}

REQUIRED_PROGRESSION_EVENTS = {
    "travel_started",
    "travel_completed",
    "travel_clean",
    "travel_breakdown",
    "route_discovered",
    "route_mastery_changed",
    "travel_poi_discovered",
}


class ValidationError(Exception):
    pass


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise ValidationError(f"missing file: {path.relative_to(ROOT)}")
    try:
        parsed = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        raise ValidationError(f"invalid JSON {path.relative_to(ROOT)}: {exc}") from exc
    if not isinstance(parsed, dict):
        raise ValidationError(f"root must be object: {path.relative_to(ROOT)}")
    return parsed


def endpoint(route: dict[str, Any], primary: str, legacy: str) -> str:
    return str(route.get(primary, route.get(legacy, ""))).strip()


def routes_from(world_map: dict[str, Any]) -> list[dict[str, Any]]:
    raw = world_map.get("routes", world_map.get("rotas", []))
    if not isinstance(raw, list):
        raise ValidationError("world map routes/rotas must be a list")
    return [item for item in raw if isinstance(item, dict)]


def available_endpoint_ids(world_map: dict[str, Any]) -> set[str]:
    ids: set[str] = set()
    for node in world_map.get("nodes", world_map.get("nos", [])):
        if isinstance(node, dict) and node.get("id"):
            ids.add(str(node["id"]))
    for anchor in world_map.get("municipal_anchors", []):
        if isinstance(anchor, dict) and anchor.get("id"):
            ids.add(str(anchor["id"]))
    for municipality in world_map.get("municipalities", []):
        ids.add(str(municipality))
    for page in world_map.get("paginas", []):
        if isinstance(page, dict) and page.get("hub"):
            ids.add(str(page["hub"]))
    aliases = world_map.get("aliases", {})
    if isinstance(aliases, dict):
        ids.update(map(str, aliases.keys()))
        ids.update(map(str, aliases.values()))
    return ids


def validate_contract(contract: dict[str, Any], errors: list[str], warnings: list[str]) -> None:
    if contract.get("contract_id") != "cria_vehicle_world_travel_v1":
        errors.append("unexpected contract_id")
    if contract.get("shipping") is not False:
        errors.append("vehicle travel contract must remain shipping=false until runtime gates pass")

    authorities = contract.get("authorities", {})
    if not isinstance(authorities, dict):
        errors.append("authorities must be an object")
    else:
        for key, expected in REQUIRED_AUTHORITIES.items():
            if authorities.get(key) != expected:
                errors.append(f"authority mismatch {key}: expected {expected}")

    principles = set(map(str, contract.get("principles", [])))
    for principle in {
        "Godot_only_runtime",
        "offline_deterministic_critical_gameplay",
        "no_second_world_manager",
        "travel_is_two_phase_plan_then_commit",
    }:
        if principle not in principles:
            errors.append(f"missing principle: {principle}")

    if contract.get("vehicle_state_owner") != "WorldMapManager.world_travel_state":
        errors.append("vehicle state authority drifted away from WorldMapManager")

    vehicles = contract.get("vehicles", {})
    if not isinstance(vehicles, dict) or "kombi_terreiro" not in vehicles:
        errors.append("kombi_terreiro missing from vehicle catalog")
        return

    kombi = vehicles.get("kombi_terreiro", {})
    if kombi.get("playable_mode") != "rota_101":
        errors.append("kombi_terreiro must use rota_101")
    if "terrestrial_primary" not in kombi.get("route_classes", []):
        errors.append("kombi_terreiro must support terrestrial_primary")
    default_state = kombi.get("default_state", {})
    for field in {"fuel", "condition", "hard_damage", "upgrades"}:
        if field not in default_state:
            errors.append(f"kombi default_state missing {field}")

    forbidden = set(map(str, contract.get("kombi_upgrades", {}).get("forbidden", [])))
    if "weapons" not in forbidden or "combat_damage_bonus" not in forbidden:
        errors.append("vehicle weaponization prohibition missing")

    events = set(map(str, contract.get("progression_events", [])))
    missing_events = sorted(REQUIRED_PROGRESSION_EVENTS - events)
    if missing_events:
        errors.append("missing progression events: " + ", ".join(missing_events))

    pipeline = list(map(str, contract.get("travel_pipeline", [])))
    try:
        plan_idx = pipeline.index("create_travel_plan")
        play_idx = pipeline.index("play_or_resolve_route")
        commit_idx = pipeline.index("commit_world_changes")
    except ValueError:
        errors.append("travel pipeline missing plan/play/commit stages")
    else:
        if not (plan_idx < play_idx < commit_idx):
            errors.append("travel pipeline order must be plan -> play/resolve -> commit")

    required_fields = set(map(str, contract.get("travel_plan", {}).get("required_fields", [])))
    for field in {
        "plan_id",
        "origin_node",
        "destination_node",
        "route_id",
        "route_type",
        "vehicle_id",
        "world_context_snapshot",
        "gates",
        "mode",
    }:
        if field not in required_fields:
            errors.append(f"travel_plan missing required field: {field}")

    if contract.get("travel_plan", {}).get("immutable_after_start") is not True:
        errors.append("TravelPlan must be immutable after start")

    rota_101 = contract.get("rota_101", {})
    not_scored = set(map(str, rota_101.get("not_scored", [])))
    if not {"hitting_pedestrians", "hitting_cyclists"}.issubset(not_scored):
        errors.append("vulnerable road users must never be scoring targets")

    if "maritime_action_minigame" not in contract.get("out_of_scope_v1", []):
        warnings.append("maritime minigame should remain outside V1 scope")


def validate_vehicle_service(
    contract: dict[str, Any], economy: dict[str, Any], errors: list[str]
) -> None:
    service = economy.get("vehicle_service", {})
    if not isinstance(service, dict) or not service:
        errors.append("economy.vehicle_service missing")
        return
    for key in {
        "refuel_block_units",
        "refuel_block_cost",
        "condition_repair_block_units",
        "condition_repair_block_cost",
        "hard_damage_repair_cost_per_level",
    }:
        value = service.get(key)
        if not isinstance(value, (int, float)) or value <= 0:
            errors.append(f"vehicle service rule must be positive: {key}")

    catalog = service.get("upgrade_catalog", {})
    if not isinstance(catalog, dict):
        errors.append("vehicle_service.upgrade_catalog must be an object")
        return
    allowed = set(map(str, contract.get("kombi_upgrades", {}).get("allowed", [])))
    forbidden = set(map(str, contract.get("kombi_upgrades", {}).get("forbidden", [])))
    missing = sorted(allowed - set(catalog))
    if missing:
        errors.append("allowed Kombi upgrades missing economy entries: " + ", ".join(missing))
    overlap = sorted(forbidden & set(catalog))
    if overlap:
        errors.append("forbidden upgrades must not have purchasable economy entries: " + ", ".join(overlap))
    for upgrade_id, definition in catalog.items():
        if not isinstance(definition, dict):
            errors.append(f"upgrade definition must be object: {upgrade_id}")
            continue
        cost = definition.get("cost")
        if not isinstance(cost, int) or cost < 0:
            errors.append(f"upgrade cost must be non-negative integer: {upgrade_id}")
        effects = definition.get("effects", {})
        if not isinstance(effects, dict) or not effects:
            errors.append(f"upgrade effects missing: {upgrade_id}")


def validate_world_map(world_map: dict[str, Any], errors: list[str], warnings: list[str]) -> None:
    routes = routes_from(world_map)
    endpoints = available_endpoint_ids(world_map)
    if not routes:
        errors.append("world map has no routes")
        return

    seen: set[tuple[str, str, str]] = set()
    for index, route in enumerate(routes):
        from_id = endpoint(route, "from", "de")
        to_id = endpoint(route, "to", "para")
        route_type = str(route.get("tipo", route.get("type", "")))
        label = f"route[{index}] {from_id}->{to_id}"
        if not from_id or not to_id:
            errors.append(f"{label}: missing endpoint")
            continue
        if from_id == to_id:
            errors.append(f"{label}: self-route is invalid")
        if route_type not in ALLOWED_ROUTE_TYPES:
            errors.append(f"{label}: unsupported route type {route_type!r}")
        if endpoints and from_id not in endpoints:
            warnings.append(f"{label}: origin not present in current node/anchor/municipality index")
        if endpoints and to_id not in endpoints:
            warnings.append(f"{label}: destination not present in current node/anchor/municipality index")
        key = (from_id, to_id, route_type)
        if key in seen:
            errors.append(f"{label}: duplicate directed route")
        seen.add(key)

        minigame = str(route.get("minigame", ""))
        normalized_type = (
            "terrestre"
            if route_type == "ponte"
            else ("connection" if route_type == "conexao" else route_type)
        )
        if minigame == "rota_101" and normalized_type != "terrestre":
            errors.append(f"{label}: rota_101 is terrestrial-only")

    has_supported_shape = (
        isinstance(world_map.get("pages"), list)
        and isinstance(world_map.get("nodes"), list)
        and isinstance(world_map.get("routes"), list)
    ) or (
        isinstance(world_map.get("paginas"), list)
        and isinstance(world_map.get("nos"), list)
        and isinstance(world_map.get("rotas"), list)
    )
    if not has_supported_shape:
        errors.append("world map must use supported legacy or semantic shape")


def validate_source_files(errors: list[str]) -> None:
    if not RESOLVER_PATH.exists():
        errors.append("WorldRouteResolver.gd missing")
    if not SERVICE_MODEL_PATH.exists():
        errors.append("VehicleServiceModel.gd missing")
    if not SMOKE_PATH.exists():
        errors.append("world_route_resolver_smoke.gd missing")
    if not SERVICE_SMOKE_PATH.exists():
        errors.append("vehicle_service_smoke.gd missing")
    if RESOLVER_PATH.exists():
        text = RESOLVER_PATH.read_text(encoding="utf-8")
        for needle in [
            "resolve_route",
            "resolve_all_from",
            "_evaluate_gates",
            "_evaluate_destination_node_gate",
            "_method_options",
        ]:
            if f"func {needle}" not in text:
                errors.append(f"resolver missing function: {needle}")
        if "WorldMapManager" in text or "WorldState" in text or "SaveManager" in text:
            errors.append("VT1 resolver must remain pure and must not mutate autoload authorities")
    if SERVICE_MODEL_PATH.exists():
        text = SERVICE_MODEL_PATH.read_text(encoding="utf-8")
        for needle in ["initialize", "get_effective_stats", "quote"]:
            if f"func {needle}" not in text:
                errors.append(f"vehicle service model missing function: {needle}")
        for forbidden_reference in ["WorldState", "SaveManager", "WorldMapManager"]:
            if forbidden_reference in text:
                errors.append(
                    "VehicleServiceModel must remain pure; found authority reference: "
                    + forbidden_reference
                )


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    try:
        contract = load_json(CONTRACT_PATH)
        world_map = load_json(MAP_PATH)
        economy = load_json(ECONOMY_PATH)
    except ValidationError as exc:
        print(f"VEHICLE_WORLD_TRAVEL_V1 FAIL: {exc}")
        return 1

    validate_contract(contract, errors, warnings)
    validate_vehicle_service(contract, economy, errors)
    validate_world_map(world_map, errors, warnings)
    validate_source_files(errors)

    print(
        "VEHICLE_WORLD_TRAVEL_V1 "
        f"routes={len(routes_from(world_map))} vehicles={len(contract.get('vehicles', {}))} "
        f"upgrades={len(economy.get('vehicle_service', {}).get('upgrade_catalog', {}))} "
        f"warnings={len(warnings)} errors={len(errors)}"
    )
    for warning in warnings:
        print(f"WARN: {warning}")
    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
