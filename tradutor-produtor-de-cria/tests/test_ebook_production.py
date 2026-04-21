from pathlib import Path


def test_workflow_exists() -> None:
    root = Path(__file__).resolve().parents[1]
    assert (root / "src/workflows/ebook_production_workflow.py").exists()
