from tools.data.validate_progression_os_v1 import validate_progression_os


def test_progression_os_contract_is_fail_closed() -> None:
    assert validate_progression_os() == []
