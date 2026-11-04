#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="${ROOT}/.nanovm"
SSH_PORT="${SSH_PORT:-2222}"
KEY="${VM_DIR}/id_ed25519"
REMOTE="${NANOVM_SSH_USER:-alpine}@${NANOVM_SSH_HOST:-127.0.0.1}"
AGENT="${1:?agent id}"
shift || true
CMD="${NANOVM_RUN_CMD:-run}"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

if [[ ! -f "$KEY" ]]; then
  echo "Missing ${KEY}; run make up && make deploy-agents" >&2
  exit 1
fi

SSH=(ssh -p "$SSH_PORT" -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
"${SSH[@]}" "$REMOTE" "nanovm-run ${CMD} ${AGENT} $(printf '%q ' "$@")"
