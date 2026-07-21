"""Contratos tipados de conteúdo e de transporte do Lore Guardian."""

from __future__ import annotations

from enum import Enum
from typing import Annotated, Any, Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StringConstraints,
    field_validator,
    model_validator,
)


Identifier = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=2, max_length=96, pattern=r"^[a-z0-9][a-z0-9_\-]*$"),
]
ShortText = Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=240)]


class StrictModel(BaseModel):
    """Base que impede campos inventados de passarem silenciosamente."""

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True, validate_assignment=True)


class ContentType(str, Enum):
    TECHNIQUE = "technique"
    CHARACTER = "character"
    MISSION = "mission"
    ENEMY = "enemy"


class RiskLevel(str, Enum):
    LOW = "baixo"
    MEDIUM = "medio"
    HIGH = "alto"
    EXTREME = "extremo"


class BeltLevel(str, Enum):
    WHITE = "branca"
    BLUE = "azul"
    PURPLE = "roxa"
    BROWN = "marrom"
    BLACK = "preta"


class ResourceCost(StrictModel):
    gas: int = Field(default=0, ge=0, le=100)
    focus: int = Field(default=0, ge=0, le=100)
    moral: int = Field(default=0, ge=0, le=100)


class TechniqueSchema(StrictModel):
    id: Identifier
    name: ShortText
    category: Identifier
    entry_state: Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=96)]
    exit_state: Annotated[str, StringConstraints(strip_whitespace=True, min_length=2, max_length=96)]
    mechanic_summary: Annotated[str, StringConstraints(strip_whitespace=True, min_length=12, max_length=500)]
    cost: ResourceCost = Field(default_factory=ResourceCost)
    risk: RiskLevel
    owner_id: Identifier | None = None
    gamified: Literal[True] = True


class CharacterSchema(StrictModel):
    id: Identifier
    name: ShortText
    role: Identifier
    origin: ShortText
    region: ShortText
    style: Identifier
    symbol: ShortText | None = None
    narrative_function: Annotated[str, StringConstraints(strip_whitespace=True, min_length=8, max_length=500)]
    outside_region_justification: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=12, max_length=500)
    ] | None = None


class MoralConsequenceSchema(StrictModel):
    dilemma: Annotated[str, StringConstraints(strip_whitespace=True, min_length=12, max_length=500)]
    axis: Annotated[
        list[Identifier],
        Field(min_length=1, max_length=4),
    ]
    on_accept: Annotated[str, StringConstraints(strip_whitespace=True, min_length=8, max_length=500)]
    on_refuse: Annotated[str, StringConstraints(strip_whitespace=True, min_length=8, max_length=500)]


class RewardSchema(StrictModel):
    xp: int = Field(default=0, ge=0, le=100000)
    money: int = Field(default=0, ge=0, le=1000000)
    honra: int = Field(default=0, ge=-100, le=100)
    hype: int = Field(default=0, ge=-100, le=100)
    legado: int = Field(default=0, ge=-100, le=100)


class MissionSchema(StrictModel):
    id: Identifier
    title: ShortText
    act: int = Field(ge=1, le=5)
    difficulty: int = Field(ge=1, le=10)
    region: ShortText
    arena_id: Identifier
    faction_id: Identifier
    opponent_id: Identifier
    summary: Annotated[str, StringConstraints(strip_whitespace=True, min_length=20, max_length=900)]
    objectives: Annotated[list[ShortText], Field(min_length=1, max_length=8)]
    technique_ids: Annotated[list[Identifier], Field(default_factory=list, max_length=12)]
    requirements: Annotated[list[Identifier], Field(default_factory=list, max_length=20)]
    rewards: RewardSchema
    moral_consequence: MoralConsequenceSchema
    outside_region_justification: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=12, max_length=500)
    ] | None = None

    @field_validator("objectives", "technique_ids", "requirements")
    @classmethod
    def unique_items(cls, values: list[str]) -> list[str]:
        if len(values) != len(set(values)):
            raise ValueError("a lista não pode conter valores duplicados")
        return values


class EnemyStatsSchema(StrictModel):
    gas: int = Field(ge=1, le=100)
    focus: int = Field(ge=1, le=100)
    grip: int = Field(ge=1, le=100)
    control: int = Field(ge=1, le=100)
    speed: int = Field(ge=1, le=100)
    technique: int = Field(ge=1, le=100)
    pressure: int = Field(ge=1, le=100)
    defense: int = Field(ge=1, le=100)


class EnemySchema(StrictModel):
    id: Identifier
    source_character_id: Identifier
    name: ShortText
    faction_id: Identifier
    region: ShortText
    style: Identifier
    belt: BeltLevel
    technique_ids: Annotated[list[Identifier], Field(min_length=1, max_length=12)]
    stats: EnemyStatsSchema
    intro_dialogue: Annotated[str, StringConstraints(strip_whitespace=True, min_length=4, max_length=420)]
    narrative_role: Annotated[str, StringConstraints(strip_whitespace=True, min_length=8, max_length=500)]
    outside_region_justification: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=12, max_length=500)
    ] | None = None

    @field_validator("technique_ids")
    @classmethod
    def unique_techniques(cls, values: list[str]) -> list[str]:
        if len(values) != len(set(values)):
            raise ValueError("technique_ids não pode conter duplicatas")
        return values

    @model_validator(mode="after")
    def source_matches_candidate(self) -> "EnemySchema":
        # Variantes de gameplay podem ter ID próprio, mas sempre ancoram em um
        # personagem canônico explícito para impedir a criação de NPC solto.
        if not self.source_character_id:
            raise ValueError("source_character_id é obrigatório")
        return self


class IngestRequest(StrictModel):
    paths: list[str] = Field(default_factory=list, max_length=64)
    rebuild: bool = False


class IngestResponse(StrictModel):
    ok: bool
    documents_indexed: int = Field(ge=0)
    chunks_indexed: int = Field(ge=0)
    vector_backend: str
    warnings: list[str] = Field(default_factory=list)


class QueryRequest(StrictModel):
    query: Annotated[str, StringConstraints(strip_whitespace=True, min_length=3, max_length=4000)]
    top_k: int = Field(default=5, ge=1, le=20)
    filters: dict[str, str | int | float | bool] = Field(default_factory=dict)
    synthesize: bool = False


class Evidence(StrictModel):
    chunk_id: str
    source: str
    text: str
    score: float
    metadata: dict[str, Any] = Field(default_factory=dict)


class QueryResponse(StrictModel):
    ok: bool
    answer: str | None = None
    evidence: list[Evidence] = Field(default_factory=list)
    retrieval_backend: str
    reranker_backend: str
    generation_backend: str
    warnings: list[str] = Field(default_factory=list)


class ValidateRequest(StrictModel):
    content_type: ContentType
    payload: dict[str, Any]
    strict_mode: bool = True


class ValidationIssue(StrictModel):
    code: Identifier
    path: str
    message: str


class ValidateResponse(StrictModel):
    valid: bool
    content_type: ContentType
    normalized: dict[str, Any] | None = None
    errors: list[ValidationIssue] = Field(default_factory=list)
    warnings: list[ValidationIssue] = Field(default_factory=list)
    canon_fingerprint: str


CONTENT_MODELS: dict[ContentType, type[StrictModel]] = {
    ContentType.TECHNIQUE: TechniqueSchema,
    ContentType.CHARACTER: CharacterSchema,
    ContentType.MISSION: MissionSchema,
    ContentType.ENEMY: EnemySchema,
}
