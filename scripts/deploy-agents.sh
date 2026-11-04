#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="${ROOT}/.nanovm"
SSH_PORT="${SSH_PORT:-2222}"
KEY="${VM_DIR}/id_ed25519"
ENV_FILE="${ROOT}/.env"
REMOTE="${NANOVM_SSH_USER:-alpine}@${NANOVM_SSH_HOST:-127.0.0.1}"

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

if [[ ! -f "$KEY" ]]; then
  echo "Missing ${KEY}; run make up first" >&2
  exit 1
fi

SSH=(ssh -p "$SSH_PORT" -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
SCP=(scp -P "$SSH_PORT" -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

"${SSH[@]}" "$REMOTE" 'doas mkdir -p /opt/nanovm /etc/nanovm/agents /var/log/nanovm /var/run/nanovm && doas chown -R alpine:alpine /opt/nanovm /var/log/nanovm /var/run/nanovm'

TMP=$(mktemp -t nanovm-agents.XXXXXX.tar.gz)
trap 'rm -f "$TMP"' EXIT
tar czf "$TMP" -C "$ROOT" platform agents

"${SCP[@]}" "$TMP" "${REMOTE}:/tmp/nanovm-bundle.tar.gz"
"${SSH[@]}" "$REMOTE" 'doas tar xzf /tmp/nanovm-bundle.tar.gz -C /opt/nanovm && rm -f /tmp/nanovm-bundle.tar.gz'
"${SSH[@]}" "$REMOTE" 'doas find /opt/nanovm/agents -type f \( -name "*.sh" -o -name "nanovm-run" \) -exec chmod +x {} +'
"${SSH[@]}" "$REMOTE" 'doas chmod +x /opt/nanovm/platform/nanovm-run'
"${SSH[@]}" "$REMOTE" 'doas ln -sf /opt/nanovm/platform/nanovm-run /usr/local/bin/nanovm-run'

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  "${SSH[@]}" "$REMOTE" "doas tee /etc/nanovm/agent.env >/dev/null" <<EOF
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-}
NANOVM_TZ=${NANOVM_TZ:-America/Chicago}
EOF
  "${SSH[@]}" "$REMOTE" 'doas chmod 640 /etc/nanovm/agent.env && doas chown root:alpine /etc/nanovm/agent.env'
fi

"${SSH[@]}" "$REMOTE" 'nanovm-run list'
echo "Deployed agents to VM: make vm-run AGENT=example (or news)"
