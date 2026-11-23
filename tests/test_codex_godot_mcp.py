"""Offline checks for Codex Godot MCP local-only profile."""
import importlib.util
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "codex-godot-mcp"

def load(name):
    spec = importlib.util.spec_from_file_location("cria_" + name, TOOL / (name + ".py"))
    assert spec and spec.loader
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m

class CodexGodotMCPTests(unittest.TestCase):
    def test_project_mcp_config(self):
        config = tomllib.loads((ROOT / ".codex/config.toml").read_text(encoding="utf-8"))
        server = config["mcp_servers"]["cria_godot"]
        self.assertEqual(server["command"], "python")
        self.assertEqual(server["args"], ["tools/codex-godot-mcp/launch_server.py"])
        self.assertNotIn("url", server)

    def test_doctor_no_mutation(self):
        install = load("install")
        status = install.read_status()
        self.assertTrue(status["godot_project_found"])
        self.assertFalse(status["shipping"])
        self.assertFalse(status["godot_runtime_modified_by_installer"])
        self.assertEqual(status["server_bind"], "localhost:6505")

    def test_binary_local_and_pinned(self):
        install, launch = load("install"), load("launch_server")
        self.assertEqual(launch.ROOT, ROOT)
        self.assertEqual(len(install.UPSTREAM_SHA), 40)
        self.assertEqual(launch.BIN, install.BINARY)
        self.assertEqual(install.ADDON, ROOT / "addons" / "open_godot_mcp")

    def test_vendor_directories_ignored(self):
        txt = (ROOT / ".gitignore").read_text(encoding="utf-8")
        self.assertIn("tools/codex-godot-mcp/.local/", txt)
        self.assertIn("addons/open_godot_mcp/", txt)

if __name__ == "__main__":
    unittest.main()
