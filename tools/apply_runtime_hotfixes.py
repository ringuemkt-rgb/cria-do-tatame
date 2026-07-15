from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "src" / "autoloads" / "FactionDirectorManager.gd"

OLD = '''\t\tvar a := str(rivalry.get("a", ""))
\t\tvar b := str(rivalry.get("b", ""))
\t\tif a == "" or b == "" or a == b:
\t\t\tcontinue
\t\tvar key := _conflict_key(a, b)
\t\tconflicts[key] = {
\t\t\t"id": key,
\t\t\t"a": min(a, b),
\t\t\t"b": max(a, b),
'''

NEW = '''\t\tvar a: String = str(rivalry.get("a", ""))
\t\tvar b: String = str(rivalry.get("b", ""))
\t\tif a == "" or b == "" or a == b:
\t\t\tcontinue
\t\tvar key: String = _conflict_key(a, b)
\t\tvar first: String = a if a < b else b
\t\tvar second: String = b if a < b else a
\t\tconflicts[key] = {
\t\t\t"id": key,
\t\t\t"a": first,
\t\t\t"b": second,
'''


def main() -> None:
    text = PATH.read_text(encoding="utf-8")
    if NEW in text:
        print("Faction conflict ordering already fixed")
        return
    if OLD not in text:
        raise RuntimeError("Expected FactionDirectorManager block was not found")
    PATH.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")
    print("Applied textual faction conflict ordering fix")


if __name__ == "__main__":
    main()
