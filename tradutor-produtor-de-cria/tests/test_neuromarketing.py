from pathlib import Path


def test_jung_config_exists() -> None:
    root = Path(__file__).resolve().parents[1]
    assert (root / "config/neuromarketing/jung_archetypes.yaml").exists()
