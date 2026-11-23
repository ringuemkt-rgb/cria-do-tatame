# Godot MCP for Codex — CRIA DO TATAME

**Status:** Codex project profile is ready. MCP server and Godot addon require an explicit local installation on the computer with Godot.

- Upstream: https://github.com/OneStepAt4time/open-godot-mcp (MIT)
- Pinned source: afbf1ed18efc268dca003c692bc3331e98125ba2
- Required engine: Godot 4.3+; do not migrate the game to 4.7.
- Transport: Codex stdio -> Rust binary -> 127.0.0.1:6505 Godot editor addon.
- Codex profile: .codex/config.toml in a trusted checkout.
- This is NOT the different Godot AI MCP 4.7 experiment in PR #133.

## Installation on the machine running Codex + Godot

Prerequisites: Godot >=4.3, Git, Rust Cargo, Python, Codex CLI or IDE and a local clone of the one official game repository.

From the root:

    python tools/codex-godot-mcp/install.py --check
    python tools/codex-godot-mcp/install.py --install
    python tools/codex-godot-mcp/install.py --check
    codex mcp list

The installer clones pinned upstream source into a temporary folder, compiles its Rust server, copies the executable into tools/codex-godot-mcp/.local/bin, and copies the addon into addons/open_godot_mcp. Both are excluded from Git. No network calls on --check, no paid services, and no edits to project.godot or gameplay.

Alternative offline source: add --source /path/to/pinned/checkout after --install (still needs Cargo). For reinstall use --replace only after inspecting the current local copies.

1. Open this CRIA project in Godot >=4.3.
2. Project > Project Settings > Plugins > enable Open Godot MCP. This local action may edit project.godot; avoid including it in the PR.
3. Run Codex CLI/IDE from the trusted game project and restart its session.
4. Ask Codex to invoke ping, get_project_info and inspect a disposable test scene before editing gameplay.
5. Run npm run quality and headless Godot checks before every PR. Review all graphical edits and physical Android QA separately.

Codex Cloud containers cannot access the editor on the user's own 127.0.0.1. Cloud Codex can continue using the GitHub Action headless tests, but not a private live editor unless a separate secure remote infrastructure is provided.

## Safety and rollback

The MCP can edit scenes and run GDScript: use it in a feature branch with trusted Codex clients and never expose port 6505. Respect AGENTS.md, the game's existing managers, stable IDs and shipping=false asset review policy. Disable the Godot editor plugin and delete the two ignored install folders to roll back. Do not commit the local plugin's project.godot changes without reviewing them.
