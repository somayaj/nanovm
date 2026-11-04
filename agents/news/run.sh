#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export NANOVM_ROOT="${NANOVM_ROOT:-/opt/nanovm}"

uses_cursor() {
  [[ -f "${SCRIPT_DIR}/manifest.yaml" ]] && grep -qE '^cursor:' "${SCRIPT_DIR}/manifest.yaml"
}

if uses_cursor && [[ -n "${CURSOR_API_KEY:-}" ]] && [[ -f "${SCRIPT_DIR}/cursor_news.py" ]]; then
  exec python3 "${SCRIPT_DIR}/cursor_news.py"
fi
exec python3 "${SCRIPT_DIR}/news_slack.py"
