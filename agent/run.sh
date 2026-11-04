#!/bin/bash
set -euo pipefail

ENV_FILE="${NANOVM_ENV_FILE:-/etc/nanovm/agent.env}"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "${SCRIPT_DIR}/news_slack.py"
