"""Pixelorama CLI dry-run and path guard; no image generation."""
from __future__ import annotations
import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("pixelorama_adapter", ROOT / "scripts/pixelorama_adapter.py")
assert spec and spec.loader
p = importlib.util.module_from_spec(spec)
spec.loader.exec_module(p)


class PixeloramaDryRunTests(unittest.TestCase):
    def test_external_binary_and_input_required(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            bin_path = folder / "pixelorama"
            project = folder / "licensed.pxo"
            bin_path.write_bytes(b"dummy executable placeholder")
            project.write_bytes(b"test fixture")
            args = p.command(bin_path, project, folder / "preview.png")
            self.assertIn("--headless", args)
            self.assertIn("--spritesheet", args)
            self.assertIn("--output", args)

    def test_nonexistent_project_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            bin_path = folder / "pixelorama"
            bin_path.touch()
            with self.assertRaises(ValueError):
                p.command(bin_path, folder / "missing.pxo", folder / "candidate.png")

    def test_authoritative_path_blocked(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            bin_path = folder / "pixelorama"
            project = folder / "licensed.pxo"
            bin_path.touch()
            project.touch()
            with self.assertRaises(ValueError):
                p.command(bin_path, project, p.ROOT / "assets" / "unauthorized.png")


if __name__ == "__main__":
    unittest.main()
