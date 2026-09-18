#!/usr/bin/env python3
"""Fail-closed transport adapter for an OpenHiggsfield-compatible generation API.

This file is an independent CRIA adapter based only on the public API contract
documented by wide-trace/open-higgsfield. It does not copy upstream code.

Required environment:
  HF_API_BASE_URL
  OPEN_HIGGSFIELD_API_KEY   # id:secret

The adapter deliberately does not promote generated media into shipping assets.
"""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any, Mapping


class OpenHiggsfieldConfigError(RuntimeError):
    pass


class OpenHiggsfieldRequestError(RuntimeError):
    pass


def _required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise OpenHiggsfieldConfigError(f"Missing required environment variable: {name}")
    return value


def _validate_key(value: str) -> str:
    left, sep, right = value.partition(":")
    if not sep or not left.strip() or not right.strip():
        raise OpenHiggsfieldConfigError(
            "OPEN_HIGGSFIELD_API_KEY must use the documented id:secret form"
        )
    return value.strip()


@dataclass(frozen=True)
class OpenHiggsfieldClient:
    base_url: str
    api_key: str
    timeout_seconds: float = 120.0

    @classmethod
    def from_env(cls) -> "OpenHiggsfieldClient":
        base_url = _required_env("HF_API_BASE_URL").rstrip("/")
        api_key = _validate_key(_required_env("OPEN_HIGGSFIELD_API_KEY"))
        return cls(base_url=base_url, api_key=api_key)

    def _request(
        self,
        method: str,
        path: str,
        payload: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        url = f"{self.base_url}/{path.lstrip('/')}"
        data = None if payload is None else json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(
            url=url,
            data=data,
            method=method,
            headers={
                "Authorization": f"Key {self.api_key}",
                "Accept": "application/json",
                "Content-Type": "application/json",
                "User-Agent": "cria-do-tatame-open-higgsfield-adapter/1.0",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout_seconds) as response:
                raw = response.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise OpenHiggsfieldRequestError(
                f"HTTP {exc.code} from OpenHiggsfield-compatible API: {detail[:1000]}"
            ) from exc
        except urllib.error.URLError as exc:
            raise OpenHiggsfieldRequestError(f"OpenHiggsfield-compatible API unavailable: {exc}") from exc

        if not raw.strip():
            return {}
        try:
            value = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise OpenHiggsfieldRequestError("Generation API returned non-JSON data") from exc
        if not isinstance(value, dict):
            raise OpenHiggsfieldRequestError("Generation API returned an unexpected payload")
        return value

    def submit_raw(self, model: str, body: Mapping[str, Any]) -> dict[str, Any]:
        model = model.strip()
        if not model or "/" in model or model in {".", ".."}:
            raise OpenHiggsfieldConfigError("Invalid model path")
        return self._request("POST", urllib.parse.quote(model, safe="-._"), body)

    def status(self, request_id: str) -> dict[str, Any]:
        request_id = request_id.strip()
        if not request_id:
            raise OpenHiggsfieldConfigError("request_id is required")
        encoded = urllib.parse.quote(request_id, safe="-._")
        return self._request("GET", f"requests/{encoded}/status")


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description="CRIA OpenHiggsfield transport adapter")
    sub = parser.add_subparsers(dest="command", required=True)

    submit = sub.add_parser("submit", help="Submit a provider-native JSON body")
    submit.add_argument("--model", required=True)
    submit.add_argument("--body-json", required=True)

    status = sub.add_parser("status", help="Read generation request status")
    status.add_argument("--request-id", required=True)

    args = parser.parse_args()
    client = OpenHiggsfieldClient.from_env()

    if args.command == "submit":
        body = json.loads(args.body_json)
        if not isinstance(body, dict):
            raise OpenHiggsfieldConfigError("--body-json must decode to an object")
        result = client.submit_raw(args.model, body)
    else:
        result = client.status(args.request_id)

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
