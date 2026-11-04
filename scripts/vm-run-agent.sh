#!/usr/bin/env bash
# Remote-only: run nanovm-run on the guest (agent + Cursor SDK stay on the VM).
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

if ! "${SSH[@]}" -o ConnectTimeout=5 "$REMOTE" true 2>/dev/null; then
  echo "VM is not reachable on port ${SSH_PORT}; run make up && make status" >&2
  exit 1
fi

# Force a TTY on the guest so nanovm-run can prompt (e.g. CURSOR_API_KEY) on the VM.
"${SSH[@]}" -tt "$REMOTE" "nanovm-run ${CMD} ${AGENT} $(printf '%q ' "$@")"
