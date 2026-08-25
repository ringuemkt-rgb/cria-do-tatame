from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mobile.pack_builder import PackBuildError, build_packs


class MobilePackBuilderTest(unittest.TestCase):
    def _write_fixture(self, root: Path, approved: bool = True) -> tuple[Path, Path]:
        assets = root / "approved"
        assets.mkdir()
        payload = assets / "ui_core_confirm.ogg"
        payload.write_bytes(b"deterministic-audio")
        sidecar = {
            "sha256": hashlib.sha256(payload.read_bytes()).hexdigest(),
            "license": {"status": "LIBERADO" if approved else "QUARENTENA"},
            "promotion": {"status": "approved", "method": "human", "reserved": False},
            "qa": {
                "visual": {"applicable": False, "pass": False},
                "biomechanical": {"applicable": False, "pass": False},
            },
        }
        (assets / "ui_core_confirm.ogg.license.json").write_text(json.dumps(sidecar), encoding="utf-8")
        config = root / "packs.json"
        config.write_text(json.dumps({
            "versao": "test", "base_max_mb": 100, "pack_max_mb": 50,
            "max_unpacked_ratio": 8, "release_tag": "packs-test",
            "packs": [{"id": "base", "obrigatorio": True, "selectors": [{"mode": "contains", "values": ["ui_core"]}]}],
        }), encoding="utf-8")
        return config, assets

    def test_build_is_byte_reproducible(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config, assets = self._write_fixture(root)
            manifest_a = build_packs(config, assets, root / "out-a", root / "runtime-a.json", "example/repo")
            manifest_b = build_packs(config, assets, root / "out-b", root / "runtime-b.json", "example/repo")
            zip_a = root / "out-a" / "base.zip"
            zip_b = root / "out-b" / "base.zip"
            self.assertEqual(zip_a.read_bytes(), zip_b.read_bytes())
            self.assertEqual(manifest_a["packs"][0]["sha256"], manifest_b["packs"][0]["sha256"])
            self.assertEqual(manifest_a["status"], "built_not_published")

    def test_quarantined_license_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config, assets = self._write_fixture(root, approved=False)
            with self.assertRaises(PackBuildError):
                build_packs(config, assets, root / "out", root / "runtime.json", "example/repo")

    def test_reserved_delegated_promotion_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config, assets = self._write_fixture(root)
            sidecar_path = assets / "ui_core_confirm.ogg.license.json"
            sidecar = json.loads(sidecar_path.read_text(encoding="utf-8"))
            sidecar["promotion"] = {"status": "approved", "method": "delegated", "reserved": True}
            sidecar_path.write_text(json.dumps(sidecar), encoding="utf-8")
            with self.assertRaises(PackBuildError):
                build_packs(config, assets, root / "out", root / "runtime.json", "example/repo")


if __name__ == "__main__":
    unittest.main()
