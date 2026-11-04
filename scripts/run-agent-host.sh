#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/.env"
LOG="${ROOT}/.nanovm/host-agent.log"
[[ -f "$ENV_FILE" ]] || { echo "Need ${ENV_FILE}"; exit 1; }
mkdir -p "${ROOT}/.nanovm"
pkill -f "${ROOT}/agent/news_slack.py" 2>/dev/null || true
export NANOVM_ENV_FILE="$ENV_FILE"
nohup "${ROOT}/agent/run.sh" >>"$LOG" 2>&1 &
echo "Host agent started (pid $!); log: $LOG"
