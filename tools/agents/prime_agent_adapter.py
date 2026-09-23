#!/usr/bin/env python3
"""Guarded Prime Agent adapter for Cria do Tatame.

This wrapper does not turn Prime Agent into a sandbox. It adds project-level
preflight checks, disables the origin push URL for the child environment,
strips common GitHub write tokens, records the JSONL event stream and stops
when a forbidden tool request is observed.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable

FORBIDDEN_PATTERNS = {
    "git_push": re.compile(r"\bgit\s+push\b", re.I),
    "force_push": re.compile(r"\bgit\s+push\b[^\n]*(--force|-f\b)", re.I),
    "merge_pr": re.compile(r"\bgh\s+pr\s+merge\b", re.I),
    "release": re.compile(r"\bgh\s+release\b", re.I),
    "git_tag": re.compile(r"\bgit\s+tag\b", re.I),
    "switch_main": re.compile(r"\bgit\s+(checkout|switch)\s+main\b", re.I),
    "hard_reset": re.compile(r"\bgit\s+reset\s+--hard\b", re.I),
    "git_clean": re.compile(r"\bgit\s+clean\b", re.I),
    "approved_assets": re.compile(r"assets/aprovados", re.I),
    "credential_file": re.compile(r"(?:\.env\b|client_secret|token\.json|keystore|id_rsa)", re.I),
}


def _git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=repo, check=True, text=True, capture_output=True
    )
    return result.stdout.strip()


def preflight(repo: Path) -> dict:
    repo = repo.resolve()
    if not (repo / ".git").exists() and not (repo / "project.godot").exists():
        raise RuntimeError(f"Diretorio nao parece ser o repositorio CTT: {repo}")
    branch = _git(repo, "branch", "--show-current")
    if branch in {"main", "master", ""}:
        raise RuntimeError("Prime Agent so pode rodar em branch candidata nao-main.")
    dirty = _git(repo, "status", "--porcelain")
    if dirty:
        raise RuntimeError("Worktree precisa iniciar limpa antes do Prime Agent.")
    top = Path(_git(repo, "rev-parse", "--show-toplevel")).resolve()
    return {"repo": str(top), "branch": branch, "clean": True}


def child_environment() -> dict[str, str]:
    env = os.environ.copy()
    for key in ("GH_TOKEN", "GITHUB_TOKEN", "GITHUB_PAT"):
        env.pop(key, None)
    try:
        count = int(env.get("GIT_CONFIG_COUNT", "0"))
    except ValueError:
        count = 0
    env[f"GIT_CONFIG_KEY_{count}"] = "remote.origin.pushurl"
    env[f"GIT_CONFIG_VALUE_{count}"] = "disabled://ctt-prime-agent"
    env["GIT_CONFIG_COUNT"] = str(count + 1)
    env["PI_OFFLINE"] = "1"
    return env


def build_command(
    prompt: str,
    gates: list[str],
    model: str | None = None,
    max_continuations: int = 3,
    max_turns: int = 12,
    max_tokens: int = 80000,
    timeout_ms: int = 1800000,
) -> list[str]:
    cmd = [
        "prime-agent",
        "--mode", "json",
        "--offline",
        "--no-extensions",
        "--no-prompt-templates",
        "--autonomous",
        "--autonomous-gate-retries", "2",
        "--autonomous-gate-timeout-ms", "300000",
        "--autonomous-max-continuations", str(max_continuations),
        "--autonomous-max-turns", str(max_turns),
        "--autonomous-max-tokens", str(max_tokens),
        "--autonomous-timeout-ms", str(timeout_ms),
    ]
    for gate in gates:
        cmd += ["--autonomous-gate", gate]
    if model:
        cmd += ["--model", model]
    cmd += [prompt]
    return cmd


def event_violation(event: dict) -> str | None:
    if event.get("type") != "tool_execution_start":
        return None
    blob = json.dumps(event.get("args", {}), ensure_ascii=False, sort_keys=True)
    for name, pattern in FORBIDDEN_PATTERNS.items():
        if pattern.search(blob):
            return name
    return None


def summarize_events(events: Iterable[dict]) -> dict:
    counter: Counter[str] = Counter()
    violations: list[dict] = []
    agent_end_seen = False
    tool_errors = 0
    for event in events:
        event_type = str(event.get("type", "unknown"))
        counter[event_type] += 1
        if event_type == "agent_end":
            agent_end_seen = True
        if event_type == "tool_execution_end" and bool(event.get("isError", False)):
            tool_errors += 1
        violation = event_violation(event)
        if violation:
            violations.append({"rule": violation, "event": event})
    return {
        "event_counts": dict(counter),
        "agent_end_seen": agent_end_seen,
        "tool_errors": tool_errors,
        "policy_violations": violations,
    }


def run_agent(repo: Path, command: list[str], log_path: Path, stderr_path: Path) -> dict:
    if shutil.which("prime-agent") is None:
        raise RuntimeError("prime-agent nao encontrado no PATH.")
    events: list[dict] = []
    violation_name: str | None = None
    log_path.parent.mkdir(parents=True, exist_ok=True)
    stderr_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8") as out, stderr_path.open("w", encoding="utf-8") as err:
        process = subprocess.Popen(
            command,
            cwd=repo,
            env=child_environment(),
            stdout=subprocess.PIPE,
            stderr=err,
            text=True,
            bufsize=1,
        )
        assert process.stdout is not None
        for raw in process.stdout:
            out.write(raw)
            out.flush()
            line = raw.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(event, dict):
                events.append(event)
                violation_name = event_violation(event)
                if violation_name:
                    process.terminate()
                    break
        try:
            exit_code = process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            exit_code = process.wait()
    summary = summarize_events(events)
    summary.update({
        "exit_code": exit_code,
        "terminated_for_policy": violation_name,
        "status": (
            "POLICY_VIOLATION" if violation_name
            else "COMPLETED" if exit_code == 0 and summary["agent_end_seen"]
            else "FAILED"
        ),
        "l4": "PENDING_HUMAN",
    })
    return summary


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="CTT guarded Prime Agent adapter")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--prompt-file", required=True)
    parser.add_argument("--gate", action="append", default=[])
    parser.add_argument("--model")
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--log", default="reports/prime_agent/session.jsonl")
    parser.add_argument("--stderr", default="reports/prime_agent/session.stderr.log")
    parser.add_argument("--report", default="reports/prime_agent/report.json")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = Path(args.repo).resolve()
    info = preflight(repo)
    prompt_path = (repo / args.prompt_file).resolve()
    if not prompt_path.is_file():
        raise RuntimeError(f"Prompt nao encontrado: {prompt_path}")
    prompt = prompt_path.read_text(encoding="utf-8")
    gates = args.gate or ["npm run quality"]
    command = build_command(prompt, gates, args.model)
    if not args.execute:
        print(json.dumps({"preflight": info, "command": command, "execute": False}, ensure_ascii=False, indent=2))
        return 0
    summary = run_agent(repo, command, repo / args.log, repo / args.stderr)
    report_path = repo / args.report
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0 if summary["status"] == "COMPLETED" else 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"prime-agent-adapter: {exc}", file=sys.stderr)
        raise SystemExit(2)
