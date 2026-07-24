from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / ".agents/skills/cria-do-tatame-game-director/SKILL.md"
VALIDATOR = ROOT / ".agents/skills/cria-do-tatame-game-director/scripts/validate_skill.py"


def test_skill_uses_agent_skills_frontmatter() -> None:
    text = SKILL.read_text(encoding="utf-8")
    header = re.match(r"^---\n(.*?)\n---\n", text, flags=re.DOTALL)
    assert header, "SKILL.md deve possuir frontmatter YAML"
    assert "name: cria-do-tatame-game-director" in header.group(1)
    assert re.search(r"^description:\s*\S", header.group(1), flags=re.MULTILINE)


def test_agents_file_activates_the_skill() -> None:
    agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
    assert ".agents/skills/cria-do-tatame-game-director/SKILL.md" in agents
    assert "validate_skill.py" in agents


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
