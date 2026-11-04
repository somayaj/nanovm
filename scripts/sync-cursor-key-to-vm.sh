#!/usr/bin/env bash
# Write CURSOR_API_KEY (+ model) to the guest agent env file.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="${ROOT}/.nanovm"
SSH_PORT="${SSH_PORT:-2222}"
KEY="${VM_DIR}/id_ed25519"
REMOTE="${NANOVM_SSH_USER:-alpine}@${NANOVM_SSH_HOST:-127.0.0.1}"

AGENT="${1:?agent id}"
CURSOR_API_KEY="${CURSOR_API_KEY:?CURSOR_API_KEY must be set}"
CURSOR_MODEL="${CURSOR_MODEL:-composer-2.5}"

SSH=(ssh -p "$SSH_PORT" -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
SCP=(scp -P "$SSH_PORT" -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

TMP=$(mktemp -t nanovm-cursor.XXXXXX.env)
trap 'rm -f "$TMP"' EXIT
printf 'CURSOR_API_KEY=%s\nCURSOR_MODEL=%s\n' "$CURSOR_API_KEY" "$CURSOR_MODEL" >"$TMP"
chmod 600 "$TMP"

"${SSH[@]}" "$REMOTE" 'doas mkdir -p /etc/nanovm/agents && doas chown root:alpine /etc/nanovm/agents && doas chmod 750 /etc/nanovm/agents'
"${SCP[@]}" "$TMP" "${REMOTE}:/tmp/nanovm-cursor.env"
"${SSH[@]}" "$REMOTE" "doas sh -c 'mv /tmp/nanovm-cursor.env /etc/nanovm/agents/${AGENT}.env && chown alpine:alpine /etc/nanovm/agents/${AGENT}.env && chmod 600 /etc/nanovm/agents/${AGENT}.env'"
