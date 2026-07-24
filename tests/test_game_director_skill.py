from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / ".agents/skills/cria-do-tatame-game-director/SKILL.md"
VALIDATOR = ROOT / ".agents/skills/cria-do-tatame-game-director/scripts/validate_skill.py"
PROTOCOL = ROOT / "docs/GAME_BUILD_PROTOCOL.md"
PRECEDENCE = ROOT / "docs/DOC_PRECEDENCE.md"
SUPREME = ROOT / "docs/CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md"
VISUAL_STANDARD = ROOT / "docs/art_bible/OFFICIAL_VISUAL_STANDARD_V1.md"
VISUAL_CONTRACT = ROOT / "data/visual/official_visual_contract_v1.json"


def test_skill_uses_agent_skills_frontmatter() -> None:
    text = SKILL.read_text(encoding="utf-8")
    header = re.match(r"^---\n(.*?)\n---\n", text, flags=re.DOTALL)
    assert header, "SKILL.md deve possuir frontmatter YAML"
    assert "name: cria-do-tatame-game-director" in header.group(1)
    assert re.search(r"^description:\s*\S", header.group(1), flags=re.MULTILINE)
    assert 'version: "1.2.0"' in header.group(1)


def test_agents_file_activates_skill_protocol_and_visual_contract() -> None:
    agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
    assert "## 0. PROTOCOLO MESTRE DE CONSTRUÇÃO" in agents
    assert "docs/GAME_BUILD_PROTOCOL.md" in agents
    assert "docs/DOC_PRECEDENCE.md" in agents
    assert ".agents/skills/cria-do-tatame-game-director/SKILL.md" in agents
    assert "OFFICIAL_VISUAL_STANDARD_V1.md" in agents
    assert "official_visual_contract_v1.json" in agents
    assert "validate_skill.py" in agents
    assert "validate_official_visual_contract.py" in agents


def test_protocol_cross_references_are_bidirectional() -> None:
    protocol = PROTOCOL.read_text(encoding="utf-8")
    precedence = PRECEDENCE.read_text(encoding="utf-8")
    supreme = SUPREME.read_text(encoding="utf-8")
    skill = SKILL.read_text(encoding="utf-8")

    assert "CANÔNICO / VINCULANTE" in protocol
    assert "Handshake de abertura" in protocol
    assert "Loop de gestão" in protocol
    assert "GAME_BUILD_PROTOCOL.md" in precedence
    assert "CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md" in precedence
    assert "docs/GAME_BUILD_PROTOCOL.md" in supreme
    assert "docs/DOC_PRECEDENCE.md" in supreme
    assert "docs/GAME_BUILD_PROTOCOL.md" in skill
    assert "OFFICIAL_VISUAL_STANDARD_V1.md" in skill


def test_visual_contract_files_exist() -> None:
    assert VISUAL_STANDARD.exists()
    assert VISUAL_CONTRACT.exists()


def test_skill_validator_passes() -> None:
    result = subprocess.run(
        [sys.executable, str(VALIDATOR)],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    report = json.loads(result.stdout)
    assert result.returncode == 0, report
    assert report["ok"] is True
    assert report["skill"] == "cria-do-tatame-game-director"
    assert report["protocol"] == "docs/GAME_BUILD_PROTOCOL.md"
