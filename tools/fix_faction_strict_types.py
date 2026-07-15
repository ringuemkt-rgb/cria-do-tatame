from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REPLACEMENTS: dict[str, list[tuple[str, str]]] = {
    "src/autoloads/WorldDirectorManager.gd": [
        (
            'var interval := max(1, int(config.get("remote_ai", {}).get("interval_ticks", 3)))',
            'var interval: int = maxi(1, int(config.get("remote_ai", {}).get("interval_ticks", 3)))',
        ),
        (
            'var limit := max(4, int(config.get("memory_limit", 16)))',
            'var limit: int = maxi(4, int(config.get("memory_limit", 16)))',
        ),
    ],
    "src/autoloads/FactionDirectorManager.gd": [
        (
            'var new_value := clamp(old_value + delta, 0.0, 100.0)',
            'var new_value: float = clampf(old_value + delta, 0.0, 100.0)',
        ),
        (
            'var decay := 0.8 if axis != "desconfianca_comunitaria" else 0.45',
            'var decay: float = 0.8 if axis != "desconfianca_comunitaria" else 0.45',
        ),
        (
            'var average := total / max(1.0, float(_pressure_axes.size()))',
            'var average: float = total / maxf(1.0, float(_pressure_axes.size()))',
        ),
        (
            'var score := peak * 0.7 + average * 0.3',
            'var score: float = peak * 0.7 + average * 0.3',
        ),
        (
            'var intensity := clamp(float(conflict.get("intensity", 0.0)) + delta, 0.0, 100.0)',
            'var intensity: float = clampf(float(conflict.get("intensity", 0.0)) + delta, 0.0, 100.0)',
        ),
        (
            'var delta := clamp(float(pressure_by_faction[faction_id_value]), -3.0, 3.0)',
            'var delta: float = clampf(float(pressure_by_faction[faction_id_value]), -3.0, 3.0)',
        ),
        (
            '"a": min(a, b),\n\t\t"b": max(a, b),',
            '"a": a if a < b else b,\n\t\t"b": b if a < b else a,',
        ),
        (
            'return "%s|%s" % [min(a, b), max(a, b)]',
            'var first: String = a if a < b else b\n\tvar second: String = b if a < b else a\n\treturn "%s|%s" % [first, second]',
        ),
        (
            'var level := max(1.0, martial_power / 10.0)',
            'var level: float = maxf(1.0, martial_power / 10.0)',
        ),
    ],
    "src/autoloads/RivalAIManager.gd": [
        ('var preferred_action := str(directive.get("preferred_action", ""))', 'var preferred_action: String = str(directive.get("preferred_action", ""))'),
        ('var round_seconds := float(context.get("round_seconds", 0.0))', 'var round_seconds: float = float(context.get("round_seconds", 0.0))'),
        ('var aggression := clamp(float(directive.get("aggression", 0.5)), 0.0, 1.0)', 'var aggression: float = clampf(float(directive.get("aggression", 0.5)), 0.0, 1.0)'),
        ('var risk := clamp(float(directive.get("risk_tolerance", 0.5)), 0.0, 1.0)', 'var risk: float = clampf(float(directive.get("risk_tolerance", 0.5)), 0.0, 1.0)'),
        ('var activation := clamp(0.15 + aggression * 0.35 + risk * 0.2, 0.0, 0.75)', 'var activation: float = clampf(0.15 + aggression * 0.35 + risk * 0.2, 0.0, 0.75)'),
        ('var index := min(actions.size() - 1, int(floor(risk * actions.size())))', 'var index: int = mini(actions.size() - 1, int(floor(risk * actions.size())))'),
        ('var first_id := str(player_memory[0].get("id", ""))', 'var first_id: String = str(player_memory[0].get("id", ""))'),
    ],
    "src/combat/DaviAIController.gd": [
        ('var family := str(family_value)', 'var family: String = str(family_value)'),
        ('var technique := DataRegistry.get_technique(last_chosen_technique)', 'var technique: Dictionary = DataRegistry.get_technique(last_chosen_technique)'),
        ('var gas := float(player_resources.get("gas", 100))', 'var gas: float = float(player_resources.get("gas", 100))'),
    ],
    "tests/faction_director_smoke.gd": [
        ('var feed_before := cria_live.call("get_feed").size()', 'var feed_before: int = int(cria_live.call("get_feed").size())'),
    ],
}


def apply_replacements(relative: str, pairs: list[tuple[str, str]]) -> bool:
    path = ROOT / relative
    text = path.read_text(encoding="utf-8")
    original = text
    for old, new in pairs:
        if old not in text:
            if new in text:
                continue
            raise RuntimeError(f"Expected pattern not found in {relative}: {old!r}")
        text = text.replace(old, new)
    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed: list[str] = []
    for relative, pairs in REPLACEMENTS.items():
        if apply_replacements(relative, pairs):
            changed.append(relative)
    print("Strict type fixes applied:")
    for relative in changed:
        print(f"- {relative}")


if __name__ == "__main__":
    main()

# Workflow registration trigger: the replacements above remain deterministic.
