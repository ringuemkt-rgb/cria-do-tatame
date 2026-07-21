"""Índice canônico e regras semânticas que fecham a porta para alucinações."""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from .schemas import (
    CharacterSchema,
    EnemySchema,
    MissionSchema,
    StrictModel,
    TechniqueSchema,
    ValidationIssue,
)
from .settings import PROJECT_ROOT


def normalize_text(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.casefold())
    without_marks = "".join(char for char in decomposed if not unicodedata.combining(char))
    return re.sub(r"\s+", " ", without_marks).strip()


@dataclass(slots=True)
class CanonIndex:
    characters: dict[str, dict[str, Any]] = field(default_factory=dict)
    arenas: dict[str, dict[str, Any]] = field(default_factory=dict)
    techniques: dict[str, dict[str, Any]] = field(default_factory=dict)
    missions: dict[str, dict[str, Any]] = field(default_factory=dict)
    factions: dict[str, dict[str, Any]] = field(default_factory=dict)
    fingerprint: str = ""

    @classmethod
    def load(cls, project_root: Path = PROJECT_ROOT) -> "CanonIndex":
        sources = {
            "characters": project_root / "data/characters.json",
            "arenas": project_root / "data/arenas.json",
            "techniques": project_root / "data/techniques.json",
            "missions": project_root / "data/missions.json",
            "factions": project_root / "data/factions.json",
        }
        digest = hashlib.sha256()
        loaded: dict[str, dict[str, dict[str, Any]]] = {}
        for key, path in sources.items():
            try:
                raw = path.read_bytes()
                document = json.loads(raw)
            except (OSError, json.JSONDecodeError) as exc:
                raise RuntimeError(f"Cânone indisponível ou inválido em {path}: {exc}") from exc
            items = document.get(key)
            if not isinstance(items, list):
                raise RuntimeError(f"{path} precisa conter uma lista '{key}'.")
            by_id: dict[str, dict[str, Any]] = {}
            for item in items:
                if not isinstance(item, dict) or not isinstance(item.get("id"), str):
                    raise RuntimeError(f"Item sem ID válido em {path}.")
                if item["id"] in by_id:
                    raise RuntimeError(f"ID duplicado '{item['id']}' em {path}.")
                by_id[item["id"]] = item
            loaded[key] = by_id
            digest.update(path.relative_to(project_root).as_posix().encode("utf-8"))
            digest.update(raw)
        return cls(**loaded, fingerprint=digest.hexdigest()[:20])


class CanonValidator:
    def __init__(self, index: CanonIndex, validation_config: dict[str, Any]) -> None:
        self.index = index
        self.config = validation_config
        self.home_region_tokens = {
            normalize_text(token) for token in validation_config.get("home_region_tokens", [])
        }
        self.blocked_fragments = {
            normalize_text(fragment) for fragment in validation_config.get("blocked_instruction_fragments", [])
        }
        self.central_roles = set(validation_config.get("central_roles", []))

    @staticmethod
    def _issue(code: str, path: str, message: str) -> ValidationIssue:
        return ValidationIssue(code=code, path=path, message=message)

    def _is_home_region(self, region: str) -> bool:
        normalized = normalize_text(region)
        return any(token in normalized for token in self.home_region_tokens)

    def _check_safety(self, model: StrictModel) -> list[ValidationIssue]:
        normalized = normalize_text(json.dumps(model.model_dump(mode="json"), ensure_ascii=False))
        errors: list[ValidationIssue] = []
        for fragment in sorted(self.blocked_fragments):
            if fragment and fragment in normalized:
                errors.append(
                    self._issue(
                        "unsafe_real_world_instruction",
                        "$",
                        "O conteúdo descreve violência real; use apenas mecânica gamificada, tap, escape ou arbitragem.",
                    )
                )
                break
        return errors

    def validate(self, model: StrictModel, strict_mode: bool = True) -> tuple[list[ValidationIssue], list[ValidationIssue]]:
        errors = self._check_safety(model)
        warnings: list[ValidationIssue] = []
        if isinstance(model, TechniqueSchema):
            errors.extend(self._validate_technique(model))
        elif isinstance(model, CharacterSchema):
            errors.extend(self._validate_character(model, strict_mode))
        elif isinstance(model, MissionSchema):
            errors.extend(self._validate_mission(model))
        elif isinstance(model, EnemySchema):
            errors.extend(self._validate_enemy(model, strict_mode))
        return errors, warnings

    def _validate_technique(self, model: TechniqueSchema) -> list[ValidationIssue]:
        errors: list[ValidationIssue] = []
        canonical = self.index.techniques.get(model.id)
        if canonical is None:
            errors.append(self._issue("unknown_technique", "$.id", f"Técnica '{model.id}' não existe em data/techniques.json."))
        elif normalize_text(str(canonical.get("name", canonical.get("nome", "")))) != normalize_text(model.name):
            errors.append(self._issue("technique_name_conflict", "$.name", "O nome diverge da técnica canônica com o mesmo ID."))
        if model.owner_id and model.owner_id not in self.index.characters:
            errors.append(self._issue("unknown_owner", "$.owner_id", f"Personagem '{model.owner_id}' não existe no cânone."))
        return errors

    def _validate_character(self, model: CharacterSchema, strict_mode: bool) -> list[ValidationIssue]:
        errors: list[ValidationIssue] = []
        canonical = self.index.characters.get(model.id)
        if strict_mode and canonical is None:
            errors.append(self._issue("unknown_character", "$.id", f"Personagem '{model.id}' não existe em data/characters.json."))
        if canonical and normalize_text(str(canonical.get("name", ""))) != normalize_text(model.name):
            errors.append(self._issue("character_name_conflict", "$.name", "O nome diverge do personagem canônico com o mesmo ID."))
        protagonist_id = str(self.config.get("protagonist_id", "ruan_macacao"))
        if model.id == protagonist_id:
            required_symbol = str(self.config.get("protagonist_symbol", "Gorila Silverback"))
            if model.symbol != required_symbol:
                errors.append(self._issue("protagonist_symbol_conflict", "$.symbol", f"O símbolo de Ruan deve ser exatamente '{required_symbol}'."))
        if model.role in self.central_roles and not self._is_home_region(f"{model.origin} {model.region}"):
            if not model.outside_region_justification:
                errors.append(self._issue("missing_region_justification", "$.outside_region_justification", "Personagem central fora do Baixo Sul exige justificativa narrativa."))
        return errors

    def _validate_mission(self, model: MissionSchema) -> list[ValidationIssue]:
        errors: list[ValidationIssue] = []
        references = (
            ("opponent_id", model.opponent_id, self.index.characters, "oponente"),
            ("arena_id", model.arena_id, self.index.arenas, "arena"),
            ("faction_id", model.faction_id, self.index.factions, "facção"),
        )
        for path, value, index, label in references:
            if value not in index:
                errors.append(self._issue(f"unknown_{path}", f"$.{path}", f"{label.capitalize()} '{value}' não existe no cânone."))
        for position, technique_id in enumerate(model.technique_ids):
            if technique_id not in self.index.techniques:
                errors.append(self._issue("unknown_technique", f"$.technique_ids[{position}]", f"Técnica '{technique_id}' não existe no cânone."))
        for position, requirement_id in enumerate(model.requirements):
            if requirement_id not in self.index.missions:
                errors.append(
                    self._issue(
                        "unknown_mission_requirement",
                        f"$.requirements[{position}]",
                        f"Pré-requisito '{requirement_id}' não existe no cânone.",
                    )
                )
        if not self._is_home_region(model.region) and not model.outside_region_justification:
            errors.append(self._issue("missing_region_justification", "$.outside_region_justification", "Missão fora do Baixo Sul exige justificativa narrativa."))
        return errors

    def _validate_enemy(self, model: EnemySchema, strict_mode: bool) -> list[ValidationIssue]:
        errors: list[ValidationIssue] = []
        if model.source_character_id not in self.index.characters:
            errors.append(self._issue("unknown_source_character", "$.source_character_id", f"Personagem-base '{model.source_character_id}' não existe no cânone."))
        if strict_mode and model.id not in self.index.characters:
            errors.append(self._issue("unknown_enemy", "$.id", "Em strict_mode, o adversário precisa existir em data/characters.json."))
        if model.faction_id not in self.index.factions:
            errors.append(self._issue("unknown_faction", "$.faction_id", f"Facção '{model.faction_id}' não existe no cânone."))
        for position, technique_id in enumerate(model.technique_ids):
            if technique_id not in self.index.techniques:
                errors.append(self._issue("unknown_technique", f"$.technique_ids[{position}]", f"Técnica '{technique_id}' não existe no cânone."))
        if not self._is_home_region(model.region) and not model.outside_region_justification:
            errors.append(self._issue("missing_region_justification", "$.outside_region_justification", "Adversário fora do Baixo Sul exige justificativa narrativa."))
        return errors
