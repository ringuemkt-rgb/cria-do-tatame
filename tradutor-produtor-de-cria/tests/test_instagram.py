from pathlib import Path


def test_instagram_config_exists() -> None:
    root = Path(__file__).resolve().parents[1]
    assert (root / "config/instagram/posting_times.json").exists()
