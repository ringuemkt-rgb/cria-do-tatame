import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools/art/validate_p1_fight_graphics_execution_v1.py"


def load_module():
    spec = importlib.util.spec_from_file_location("p1_fight_graphics_validator", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


class P1FightGraphicsExecutionTest(unittest.TestCase):
    def test_board_is_fail_closed_and_complete(self):
        module = load_module()
        self.assertEqual(module.validate(), [])

    def test_focus_requirement_ids_are_deterministic(self):
        module = load_module()
        queue = module.load_json(module.QUEUE)
        commands = module.flatten_queue(queue)
        self.assertEqual(
            module.requirement_id_for_command(commands["P1-CHAR-001"]),
            "p1_char:ruan_macacao:char_turnaround",
        )
        self.assertEqual(
            module.requirement_id_for_command(commands["P1-CHAR-006"]),
            "p1_char:davi_relampago:char_turnaround",
        )
        self.assertEqual(
            module.requirement_id_for_command(commands["P1-TECH-001"]),
            "p1_paired:t001:paired_technique",
        )


if __name__ == "__main__":
    unittest.main()
