#!/usr/bin/env python3
"""Format headlines with Cursor Composer (cloud API) and post to Slack."""

from __future__ import annotations

import os
import sys

from cursor_cloud import compose_with_cloud_agent
from news_slack import collect_headlines, load_webhook, run_once, slack_post

MODEL = os.environ.get("CURSOR_MODEL", "composer-2.5")


def modus_operandi() -> str:
    path = os.path.join(os.path.dirname(__file__), "manifest.yaml")
    if not os.path.isfile(path):
        return "Write a concise Slack mrkdwn digest of the headlines."
    in_prompt = False
    lines: list[str] = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("prompt:"):
                in_prompt = True
                rest = line.split(":", 1)[1].strip()
                if rest == "|":
                    continue
                if rest:
                    lines.append(rest)
                continue
            if in_prompt:
                if line and not line.startswith(" ") and not line.startswith("\t"):
                    break
                lines.append(line.rstrip("\n"))
    text = "\n".join(lines).strip()
    return text or "Write a concise Slack mrkdwn digest of the headlines."


def compose_slack_text(headlines: list[tuple[str, str]]) -> str:
    api_key = os.environ.get("CURSOR_API_KEY", "").strip()
    if not api_key:
        print("CURSOR_API_KEY is not set", file=sys.stderr)
        sys.exit(1)

    bullet = "\n".join(
        f"- {title}" + (f" ({link})" if link else "") for title, link in headlines
    )
    instructions = modus_operandi()
    prompt = (
        f"{instructions}\n\n"
        "Headlines (raw):\n"
        f"{bullet or '(none)'}\n\n"
        "Reply with ONLY the Slack message body (mrkdwn). No preamble."
    )

    try:
        return compose_with_cloud_agent(api_key, MODEL, prompt)
    except RuntimeError as err:
        print(str(err), file=sys.stderr)
        sys.exit(2)


def main() -> None:
    webhook = load_webhook()
    headlines = collect_headlines()
    if not os.environ.get("CURSOR_API_KEY", "").strip():
        run_once(webhook)
        return
    text = compose_slack_text(headlines)
    slack_post(webhook, text)
    print(f"posted Composer digest ({len(headlines)} headlines sourced)")


if __name__ == "__main__":
    main()
