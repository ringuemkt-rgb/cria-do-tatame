from pathlib import Path


def test_sales_platform_configs_exist() -> None:
    root = Path(__file__).resolve().parents[1]
    assert (root / "config/sales/platforms/hotmart_config.yaml").exists()
