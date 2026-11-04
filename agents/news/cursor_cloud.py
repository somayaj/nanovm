"""Cursor Cloud Agents API client (stdlib only — works on Alpine/musl)."""

from __future__ import annotations

import base64
import json
import os
import time
import urllib.error
import urllib.request

API_BASE = os.environ.get("CURSOR_API_BASE", "https://api.cursor.com").rstrip("/")
POLL_INTERVAL = float(os.environ.get("CURSOR_POLL_SECS", "3"))
POLL_TIMEOUT = float(os.environ.get("CURSOR_POLL_TIMEOUT", "600"))
USER_AGENT = "nanovm-agent/1.0"


def _headers(api_key: str) -> dict[str, str]:
    token = base64.b64encode(f"{api_key}:".encode()).decode("ascii")
    return {
        "Authorization": f"Basic {token}",
        "Content-Type": "application/json",
        "User-Agent": USER_AGENT,
    }


def _api(
    method: str,
    path: str,
    api_key: str,
    body: dict | None = None,
) -> dict:
    url = f"{API_BASE}{path}"
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        headers=_headers(api_key),
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode(errors="replace")[:800]
        raise RuntimeError(
            f"Cursor API {method} {path}: HTTP {exc.code}: {raw}"
        ) from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Cursor API network error: {exc}") from exc


def compose_with_cloud_agent(api_key: str, model: str, prompt: str) -> str:
    """Start a no-repo cloud agent and return the final assistant text."""
    created = _api(
        "POST",
        "/v1/agents",
        api_key,
        {
            "prompt": {"text": prompt},
            "model": {"id": model},
            "skipReviewerRequest": True,
        },
    )
    agent_id = created["agent"]["id"]
    run_id = created["run"]["id"]
    deadline = time.time() + POLL_TIMEOUT
    while time.time() < deadline:
        run = _api("GET", f"/v1/agents/{agent_id}/runs/{run_id}", api_key)
        status = run.get("status", "")
        if status == "FINISHED":
            text = (run.get("result") or "").strip()
            if not text:
                raise RuntimeError(f"Cursor run {run_id} finished with empty result")
            return text
        if status in ("ERROR", "CANCELLED", "EXPIRED"):
            raise RuntimeError(f"Cursor run {run_id} ended with status {status}")
        time.sleep(POLL_INTERVAL)
    raise RuntimeError(f"Cursor run {run_id} timed out after {int(POLL_TIMEOUT)}s")
