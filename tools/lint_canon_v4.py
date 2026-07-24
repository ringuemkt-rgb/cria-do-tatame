from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {"LEM", "NTM", "ALE"}
FORBIDDEN_AS_FACTION = {
    "terreiro", "raiz", "cria_live", "circuito_oficial",
    "dragao_vermelho", "fantasma",
}


def main() -> int:
    path = ROOT / "data/factions/factions_v3.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    factions = set(data.get("faccoes", {}).keys())
    assert factions == ALLOWED, f"faccoes_v3 inválidas: {sorted(factions)}"

    nuclei = data.get("nucleos", {})
    for nucleus_id, nucleus in nuclei.items():
        assert nucleus_id not in factions, f"núcleo promovido a facção: {nucleus_id}"
        assert nucleus.get("faccao_pai") in ALLOWED, nucleus_id

    serialized = json.dumps(data, ensure_ascii=False).lower()
    for forbidden in FORBIDDEN_AS_FACTION:
        assert f'"{forbidden}": {{' not in serialized.split('"nucleos"')[0], (
            f"entidade reclassificada voltou ao domínio de facção: {forbidden}"
        )

    print("canon-v4: OK — exatamente LEM, NTM e ALE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
