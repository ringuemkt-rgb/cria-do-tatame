from pathlib import Path


def test_translation_prompt_exists() -> None:
    root = Path(__file__).resolve().parents[1]
    assert (root / "config/prompts/translation/translator_minimax.md").exists()
