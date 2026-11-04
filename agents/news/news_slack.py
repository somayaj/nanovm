#!/usr/bin/env python3
"""Fetch headline RSS feeds and post summaries to a Slack incoming webhook."""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from zoneinfo import ZoneInfo

FEEDS = (
    "https://feeds.bbci.co.uk/news/world/rss.xml",
    "https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en",
)
MAX_HEADLINES = 8
USER_AGENT = "nanovm-agent/1.0"


def load_webhook() -> str:
    url = os.environ.get("SLACK_WEBHOOK_URL", "").strip()
    if not url:
        print("SLACK_WEBHOOK_URL is not set", file=sys.stderr)
        sys.exit(1)
    return url


def tz() -> ZoneInfo:
    name = os.environ.get("NANOVM_TZ", "America/Chicago")
    return ZoneInfo(name)


def fetch_rss(url: str) -> list[tuple[str, str]]:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        raw = resp.read()
    root = ET.fromstring(raw)
    items: list[tuple[str, str]] = []
    for item in root.findall(".//item"):
        title_el = item.find("title")
        link_el = item.find("link")
        if title_el is None or not (title_el.text or "").strip():
            continue
        title = (title_el.text or "").strip()
        link = (link_el.text or "").strip() if link_el is not None else ""
        items.append((title, link))
    return items


def collect_headlines() -> list[tuple[str, str]]:
    seen: set[str] = set()
    out: list[tuple[str, str]] = []
    for feed in FEEDS:
        try:
            for title, link in fetch_rss(feed):
                key = title.lower()
                if key in seen:
                    continue
                seen.add(key)
                out.append((title, link))
                if len(out) >= MAX_HEADLINES:
                    return out
        except (urllib.error.URLError, ET.ParseError, TimeoutError) as exc:
            print(f"feed error {feed}: {exc}", file=sys.stderr)
    return out


def slack_post(webhook: str, text: str) -> None:
    body = json.dumps({"text": text}).encode()
    req = urllib.request.Request(
        webhook,
        data=body,
        headers={"Content-Type": "application/json", "User-Agent": USER_AGENT},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        resp.read()


def format_message(headlines: list[tuple[str, str]]) -> str:
    now = datetime.now(tz())
    lines = [f"*Girdle · NanoVM news* — {now.strftime('%A %b %d, %I:%M %p %Z')}"]
    if not headlines:
        lines.append("_No headlines fetched (check network or feeds)._")
        return "\n".join(lines)
    for i, (title, link) in enumerate(headlines, 1):
        if link:
            lines.append(f"{i}. <{link}|{title}>")
        else:
            lines.append(f"{i}. {title}")
    return "\n".join(lines)


def run_once(webhook: str) -> None:
    headlines = collect_headlines()
    slack_post(webhook, format_message(headlines))
    print(f"posted {len(headlines)} headlines")


def main() -> None:
    webhook = load_webhook()
    run_once(webhook)


if __name__ == "__main__":
    main()
