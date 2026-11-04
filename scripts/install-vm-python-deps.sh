#!/usr/bin/env bash
# Ensure python3 exists on the guest; skip venv when requirements.txt has no packages.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="${ROOT}/.nanovm"
SSH_PORT="${SSH_PORT:-2222}"
KEY="${VM_DIR}/id_ed25519"
REMOTE="${NANOVM_SSH_USER:-alpine}@${NANOVM_SSH_HOST:-127.0.0.1}"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

if [[ ! -f "$KEY" ]]; then
  echo "Missing ${KEY}; run make up first" >&2
  exit 1
fi

SSH=(ssh -p "$SSH_PORT" -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

"${SSH[@]}" "$REMOTE" bash -s <<'REMOTE'
set -euo pipefail
REQ=/opt/nanovm/agents/news/requirements.txt

doas apk add --no-cache python3 ca-certificates

needs_pip=0
if [[ -f "$REQ" ]] && grep -qE '^[A-Za-z0-9_+-]+' "$REQ"; then
  needs_pip=1
fi

if [[ "$needs_pip" -eq 0 ]]; then
  echo "OK: python3 on guest (Cursor Cloud API; no extra pip packages)."
  python3 --version
  exit 0
fi

doas apk add --no-cache py3-pip py3-virtualenv
VENV=/opt/nanovm/venv
doas chown -R alpine:alpine /opt/nanovm
rm -rf "$VENV"
python3 -m venv "$VENV" || python3 -m virtualenv "$VENV"
"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/pip" install -r "$REQ"
echo "OK: pip packages in ${VENV}"
REMOTE
