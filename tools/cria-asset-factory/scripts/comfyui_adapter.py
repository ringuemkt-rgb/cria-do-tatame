#!/usr/bin/env python3
"""Validated loopback-only ComfyUI bridge for candidate jobs.

Default is DRY RUN. Requires an existing API-format workflow and --submit to
request local inference. Never downloads models, images, or grants shipping.
"""
from __future__ import annotations

import argparse
import json
import urllib.parse
import urllib.request
from pathlib import Path


def validate_local_url(value: str) -> str:
    parsed = urllib.parse.urlsplit(value)
    if (parsed.scheme != "http" or parsed.hostname not in ("127.0.0.1", "localhost", "::1")
            or parsed.username is not None or parsed.password is not None
            or parsed.path not in ("", "/") or parsed.query or parsed.fragment):
        raise ValueError("ComfyUI endpoint must be plain HTTP loopback only (no URL paths/credentials)")
    if parsed.port is None or not 1 <= parsed.port <= 65535:
        raise ValueError("ComfyUI URL needs an explicit valid port")
    return f"http://{parsed.netloc}/prompt"


def build_payload(job: dict, workflow: dict, prompt_node: str) -> dict:
    if job.get("shipping") is not False or job.get("qa_status") != "pending":
        raise ValueError("Only pending, non-shipping CRIA candidates can be submitted")
    if job.get("schema") != "cria.asset_factory.generation_job.v1" or job.get("output_status") != "NOT_GENERATED":
        raise ValueError("invalid candidate job schema/status")
    if not isinstance(job.get("prompt"), str) or not job["prompt"]:
        raise ValueError("candidate job requires nonempty prompt")
    if job.get("reference_path"):
        # This adapter intentionally does not silently upload a reference;
        # the workflow has to be set up and reviewed in ComfyUI first.
        raise ValueError("reference-based inference needs a separately approved upload workflow")
    if not isinstance(workflow, dict) or not isinstance(prompt_node, str) or prompt_node not in workflow:
        raise ValueError("explicit text-encoder node must exist in API workflow")
    original = workflow[prompt_node]
    if not isinstance(original, dict) or original.get("class_type") != "CLIPTextEncode":
        raise ValueError("prompt node must be a CLIPTextEncode text encoder")
    inputs = original.get("inputs")
    if not isinstance(inputs, dict) or not isinstance(inputs.get("text"), str):
        raise ValueError("text-encoder node requires string inputs.text")
    # JSON roundtrip makes an isolated copy without mutating the user's workflow.
    updated = json.loads(json.dumps(workflow))
    updated[prompt_node]["inputs"]["text"] = job["prompt"]
    return {"prompt": updated, "extra_data": {"extra_pnginfo": {
        "cria_candidate": {
            "technique_id": job["technique_id"], "shipping": False,
            "qa_status": "pending", "model_revision": job.get("model_revision"),
            "adapter_revision": job.get("adapter_revision"),
        }
    }}}


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError("ComfyUI HTTP redirect refused")


def submit_local(payload: dict, server: str = "http://127.0.0.1:8188", timeout: int = 10) -> dict:
    endpoint = validate_local_url(server)
    if not 1 <= timeout <= 30:
        raise ValueError("timeout must be 1..30 seconds")
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(endpoint, data=data, headers={
        "Content-Type": "application/json",
    }, method="POST")
    opener = urllib.request.build_opener(NoRedirect)
    with opener.open(request, timeout=timeout) as response:
        result = json.load(response)
    if not isinstance(result, dict) or not result.get("prompt_id"):
        raise ValueError("ComfyUI did not return a prompt_id")
    return {"prompt_id": result["prompt_id"], "status": "SUBMITTED_CANDIDATE_ONLY",
            "shipping": False, "qa_status": "pending"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--job", required=True, type=Path)
    parser.add_argument("--workflow", required=True, type=Path,
                        help="Already configured local ComfyUI API-format JSON")
    parser.add_argument("--prompt-node", required=True, help="Existing CLIPTextEncode node ID")
    parser.add_argument("--server", default="http://127.0.0.1:8188")
    parser.add_argument("--submit", action="store_true", help="Opt in to LOCAL GPU inference (may use resources)")
    parser.add_argument("--timeout", type=int, default=10)
    args = parser.parse_args()
    try:
        validate_local_url(args.server)
        job = json.loads(args.job.read_text(encoding="utf-8"))
        workflow = json.loads(args.workflow.read_text(encoding="utf-8"))
        payload = build_payload(job, workflow, args.prompt_node)
        if args.submit:
            result = submit_local(payload, args.server, args.timeout)
            print(json.dumps(result, indent=2))
        else:
            print(json.dumps({"status": "DRY_RUN_VALID", "shipping": False,
                              "qa_status": "pending",
                              "workflow_nodes": len(payload["prompt"]),
                              "submit_required": True}, indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError,
            urllib.error.URLError) as exc:
        parser.error(str(exc))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
